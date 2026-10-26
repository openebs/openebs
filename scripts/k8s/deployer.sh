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
IPFAM="ipv4"
USE_DOCKER_CFG="true"
SUDO=${SUDO:-"sudo"}
REGISTRY_MIRROR="true"
# Nodes reach the mirrors by container name over the "kind" docker network (see
# connect_registry_mirrors/configure_registry_mirror_hosts). These host ports are just for
# convenience, e.g. local debugging with curl.
declare -A REGISTRY_MIRROR_UPSTREAMS=(
  ["docker.io"]="https://registry-1.docker.io"
  ["quay.io"]="https://quay.io"
  ["registry.k8s.io"]="https://registry.k8s.io"
)
declare -A REGISTRY_MIRROR_PORTS=(
  ["docker.io"]="5001"
  ["quay.io"]="5002"
  ["registry.k8s.io"]="5003"
)

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
  --ip-family     <str>             KIND has support for IPv4, IPv6 and dual-stack clusters, with the default being ipv4.
  --no-login                        Don't use the docker config json file.
  --no-registry-mirror              Don't run local pull-through registry mirrors for docker.io/quay.io/registry.k8s.io.
                                     These mirrors cache images on the host so repeated (re)installs/clusters don't
                                     re-pull the same images from the internet on every node.

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

registry_mirror_name() {
  local upstream="$1"
  echo "kind-registry-mirror-${upstream//./-}"
}

# Starts (if not already running) one `registry:3` pull-through cache per upstream registry.
# Each is also published on its own host port purely for convenience (e.g. local debugging
# with curl) - the cluster nodes reach it by container name on the "kind" docker network
# instead, via connect_registry_mirrors, since that's resolved fresh by Docker's embedded DNS
# every time the container (re)starts rather than being baked into a file once. Each cache is
# backed by a named docker volume so it survives cluster recreations.
start_registry_mirrors() {
  local upstream remote port name

  for upstream in "${!REGISTRY_MIRROR_UPSTREAMS[@]}"; do
    remote="${REGISTRY_MIRROR_UPSTREAMS[$upstream]}"
    port="${REGISTRY_MIRROR_PORTS[$upstream]}"
    name="$(registry_mirror_name "$upstream")"

    if [ "$($DOCKER inspect -f '{{.State.Running}}' "$name" 2>/dev/null)" != "true" ]; then
      echo "Starting registry mirror $name ($upstream -> $remote) on port $port"
      $DOCKER run -d --restart=always --name "$name" \
        -p "$port:5000" \
        -v "$name-cache:/var/lib/registry" \
        -e REGISTRY_PROXY_REMOTEURL="$remote" \
        registry:3 > /dev/null
    fi
  done
}

# Attaches the registry mirrors to the "kind" docker network (created by `kind create cluster`,
# so this can only run afterwards) so nodes can resolve them by container name via Docker's
# embedded DNS. Idempotent, and since the mirrors run with --restart=always, Docker reattaches
# them to this network automatically on daemon/host restart too.
connect_registry_mirrors() {
  local upstream name

  for upstream in "${!REGISTRY_MIRROR_UPSTREAMS[@]}"; do
    name="$(registry_mirror_name "$upstream")"
    if [ "$($DOCKER inspect -f '{{json .NetworkSettings.Networks.kind}}' "$name")" = "null" ]; then
      $DOCKER network connect kind "$name"
    fi
  done
}

# Emits the containerd `containerdConfigPatches` block enabling the certs.d-based registry
# config (hosts.toml per upstream, written by configure_registry_mirror_hosts below). This is
# the mechanism kind's own docs recommend; the older `registry.mirrors` TOML stanza is deprecated.
registry_mirror_config_patch() {
  cat <<'EOF'
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF
}

# Writes /etc/containerd/certs.d/<upstream>/hosts.toml on the given node, pointing it at the
# local mirror by container name on the "kind" network (resolved via Docker's embedded DNS).
configure_registry_mirror_hosts() {
  local node="$1"
  local upstream name dir

  for upstream in "${!REGISTRY_MIRROR_UPSTREAMS[@]}"; do
    name="$(registry_mirror_name "$upstream")"
    dir="/etc/containerd/certs.d/$upstream"

    $DOCKER exec "$node" mkdir -p "$dir"
    printf '[host."http://%s:5000"]\n  capabilities = ["pull", "resolve"]\n' "$name" \
      | $DOCKER exec -i "$node" tee "$dir/hosts.toml" > /dev/null
  done
}

# Removes the registry mirror containers. Their cache volumes are left intact (removing a
# container never removes a named volume), so the next `start` reuses the warm cache.
stop_registry_mirrors() {
  local upstream name

  for upstream in "${!REGISTRY_MIRROR_UPSTREAMS[@]}"; do
    name="$(registry_mirror_name "$upstream")"
    $DOCKER rm -f "$name" 2>/dev/null || true
  done
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
        --ip-family)
          shift
          test $# -lt 1 && die "Missing Ip Family"
          case $1 in
            ipv4 | IPv4 | ip4 | 4)
              IPFAM="ipv4"
              shift;;
            ipv6 | IPv6 | ip6 | 6)
              IPFAM="ipv6"
              shift;;
            dual | dual-stack)
              IPFAM="dual"
              shift;;
            *)
              die "Invalid ip family: $1"
              ;;
          esac
          ;;
        --no-login)
          USE_DOCKER_CFG="false"
          shift;;
        --no-registry-mirror)
          REGISTRY_MIRROR="false"
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
  if [ "$REGISTRY_MIRROR" = "true" ]; then
    stop_registry_mirrors
  fi
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

if [ "$REGISTRY_MIRROR" = "true" ] && [ -z "$DRY_RUN" ]; then
  start_registry_mirrors
fi

# Create and cleanup the tmp folder
# Note: this is static in case you want to restart the worker node
mkdir -p "$TMP_KIND"
$SUDO rm -rf "$TMP_KIND"/*

# Adds the control-plane/master node
cat <<EOF > "$TMP_KIND_CONFIG"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: $IPFAM
EOF
if [ "$REGISTRY_MIRROR" = "true" ]; then
  registry_mirror_config_patch >> "$TMP_KIND_CONFIG"
fi
cat <<EOF >> "$TMP_KIND_CONFIG"
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
  DOCKER_CONFIG="$HOME/.docker/config.json"
  if [ "$USE_DOCKER_CFG" = "true" ] && [ -f "$DOCKER_CONFIG" ]; then
    cat <<EOF >> "$TMP_KIND_CONFIG"
    - hostPath: $DOCKER_CONFIG
      containerPath: /var/lib/kubelet/config.json
EOF
  fi
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

if [ "$REGISTRY_MIRROR" = "true" ] && [ -z "$DRY_RUN" ]; then
  connect_registry_mirrors
fi

$KUBECTL cluster-info --context kind-kind
if [ -z "$DRY_RUN" ]; then
  host_ip=$($DOCKER network inspect kind | jq -r 'first (.[0].IPAM.Config[].Gateway | select(.))')
fi
echo "HostIP: $host_ip"

# shellcheck disable=SC2068
for node in kind-control-plane ${nodes[@]}; do
  $DOCKER exec "$node" mount -o remount,rw /sys

  # Note: this will go away if the node restarts...
  $DOCKER exec "$node" bash -c 'printf "'"$host_ip"' kvmhost\n" >> /etc/hosts'

  if [ "$REGISTRY_MIRROR" = "true" ] && [ -z "$DRY_RUN" ]; then
    configure_registry_mirror_hosts "$node"
  fi
done
