#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(dirname "$0")"

TMP_KIND="/tmp/kind/openebs/"
TMP_KIND_CONFIG="$TMP_KIND/config.yaml"
TMP_KIND_ZFS="$TMP_KIND/zfs"
WORKERS=2
DELAY="false"
CORES=1
POOL_SIZE="200MiB"
DRY_RUN=
KIND="kind"
FALLOCATE="fallocate"
KUBECTL="kubectl"
DOCKER="docker"
HUGE_PAGES=1800
SETUP_ZFS="false"
SETUP_LVM="false"
SETUP_MAYASTOR="false"
CLEANUP="false"
LABEL=
SUDO=${SUDO:-"sudo"}

help() {
  cat <<EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

Options:
  -h, --help                        Display this text.
  --workers       <num>             The number of worker nodes (Default: $WORKERS).
  --cores         <num>             How many cores to set to each io-engine (Default: $CORES).
  --delay                           Enable developer delayed mode on the io-engine (Default: false).
  --disk          <size>            Add disk of this size to each worker node.
  --dry-run                         Don't do anything, just output steps.
  --hugepages     <num>             Add <num> 2MiB hugepages (Default: $HUGE_PAGES).
  --zfs                             Install ZFS utilities.
  --lvm                             Install LVM utilities and load required modules.
  --mayastor                        Setup pre-requisites, install and load required modules.
  --label                           Label worker nodes with the io-engine selector.
  --cleanup                         Prior to starting, stops the running instance of the deployer.

Command:
  start                             Start the k8s cluster.
  stop                              Stop the k8s cluster.

Examples:
  $(basename "$0") start --workers 2 --disk 1GiB --install-zfs
EOF
}

echo_stderr() {
  echo -e "${1}" >&2
}

die() {
  local _return="${2:-1}"
  echo_stderr "$1"
  exit "${_return}"
}

COMMAND=
DO_ARGS=
while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--help)
      help
      exit 0
      shift;;
    start)
      [ -n "$COMMAND" ] && die "Command already specified"
      COMMAND="start"
      DO_ARGS="y"
      shift;;
    stop)
      [ -n "$COMMAND" ] && die "Command already specified"
      COMMAND="stop"
      DO_ARGS="y"
      shift;;
    *)
      [ -z "$DO_ARGS" ] && die "Must specify command before args"
      case $1 in
        --workers)
          shift
          test $# -lt 1 && die "Missing Number of Workers"
          WORKERS=$1
          shift;;
        --cores)
          shift
          CORES=$1
          shift;;
        --disk)
          shift
          test $# -lt 1 && die "Missing Disk Size"
          POOL_SIZE=$1
          shift;;
        --delay)
          DELAY="true"
          shift;;
        --label)
          LABEL="true"
          shift;;
        --cleanup)
          CLEANUP="true"
          shift;;
        --hugepages)
          shift
          test $# -lt 1 && die "Missing hugepage number"
          HUGE_PAGES=$1
          shift;;
        --mayastor)
          SETUP_MAYASTOR="true"
          shift;;
        --zfs)
          SETUP_ZFS="true"
          shift;;
        --lvm)
          SETUP_LVM="true"
          shift;;
        --dry-run)
          if [ -z "$DRY_RUN" ]; then
            DRY_RUN="--dry-run"
            KIND="echo $KIND"
            FALLOCATE="echo $FALLOCATE"
            KUBECTL="echo $KUBECTL"
            DOCKER="echo $DOCKER"
            SUDO="echo"
          fi
          shift;;
        *)
          die "Unknown cli argument: $1"
          ;;
      esac
  esac
done

if [ -z "$COMMAND" ]; then
  die "No command specified!\n$(help)"
fi

if [ "$COMMAND" = "stop" ] || [ "$CLEANUP" = "true" ]; then
  if command -v nvme &>/dev/null; then
    $SUDO nvme disconnect-all
  fi
  $KIND delete cluster
  if [ "$COMMAND" = "stop" ]; then
    exit 0
  fi
fi

# Install prerequisites
if [ "$SETUP_MAYASTOR" = "true" ]; then
  "$SCRIPT_DIR"/setup-io-prereq.sh --hugepages "$HUGE_PAGES" --mayastor $DRY_RUN
fi

if [ "$SETUP_ZFS" = "true" ]; then
  "$SCRIPT_DIR"/setup-io-prereq.sh --zfs $DRY_RUN
fi

if [ "$SETUP_LVM" = "true" ]; then
  "$SCRIPT_DIR"/setup-io-prereq.sh --lvm $DRY_RUN
fi

# Create and cleanup the tmp folder
# Note: this is static in case you want to restart the worker node
mkdir -p "$TMP_KIND"
$SUDO rm -rf "$TMP_KIND"/*

# Adds the control-plane/master node
cat <<EOF > "$TMP_KIND_CONFIG"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
EOF

start_core=1
nodes=()
for node_index in $(seq 1 $WORKERS); do
  if [ "$node_index" == 1 ]; then
    node="kind-worker"
  else
    node="kind-worker$node_index"
  fi
  nodes+=($node)

  host_path="$TMP_KIND/$node"
  cat <<EOF >> "$TMP_KIND_CONFIG"
- role: worker
  extraMounts:
    - hostPath: /dev
      containerPath: /dev
      propagation: HostToContainer
    - hostPath: /run/udev
      containerPath: /run/udev
      propagation: HostToContainer
    - hostPath: $TMP_KIND/$node
      containerPath: /var/local/mayastor
      propagation: HostToContainer
    - hostPath: /
      containerPath: /host
      propagation: HostToContainer
EOF
  if [ "$SETUP_ZFS" = "true" ]; then
    # Should already be installed by prereq script
    ZFS=$(realpath $(which zfs))
    cat <<EOF >>$TMP_KIND_ZFS
    #/bin/sh
    chroot /host $ZFS "\$@"
EOF
    chmod +x $TMP_KIND_ZFS
    cat <<EOF >> "$TMP_KIND_CONFIG"
    - hostPath: $TMP_KIND_ZFS
      containerPath: /sbin/zfs
      propagation: HostToContainer
EOF
  fi

  if [ "$SETUP_MAYASTOR" = "true" ]; then
    if [ "$LABEL" = "true" ]; then
      cat <<EOF >> "$TMP_KIND_CONFIG"
  labels:
    openebs.io/engine: mayastor
EOF
    fi
    mkdir -p $host_path/io-engine
    if [ -n "$POOL_SIZE" ]; then
      $FALLOCATE -l $POOL_SIZE $host_path/io-engine/disk.io
    fi
    corelist=$(seq -s, $((start_core+((node_index-1)*CORES))) 1 $((start_core-1+((node_index)*CORES))))
    printf "eal_opts:\n  core_list: $corelist\n  developer_delay: $DELAY\n" >$host_path/io-engine/config.yaml
  fi
done

if [ -n "$DRY_RUN" ]; then
  cat "$TMP_KIND_CONFIG"
fi

$KIND create cluster --config "$TMP_KIND_CONFIG"

$KUBECTL cluster-info --context kind-kind
if [ -z "$DRY_RUN" ]; then
  host_ip=$($DOCKER network inspect kind | jq -r 'first (.[0].IPAM.Config[].Gateway | select(.))')
fi
echo "HostIP: $host_ip"

# shellcheck disable=SC2068
for node in ${nodes[@]}; do
  $DOCKER exec "$node" mount -o remount,rw /sys

  # Note: this will go away if the node restarts...
  $DOCKER exec "$node" bash -c 'printf "'"$host_ip"' kvmhost\n" >> /etc/hosts'
done
