#!/usr/bin/env bash

set -euo pipefail

TIMEOUT="5m"
WAIT=
DRY_RUN=
HELM_DRY_RUN=""
SCRIPT_DIR="$(dirname "$0")"
CHART_DIR="$SCRIPT_DIR"/../../charts
DEP_UPDATE=
RELEASE_NAME="openebs"
K8S_NAMESPACE="openebs"
FAIL_IF_INSTALLED=
HELM_UPGRADE=
HELM_ARGS=
INS_MAYASTOR=
INS_LVM=
INS_ZFS=
INS_HOSTPATH="true"
HELM="helm"
KUBECTL="kubectl"
TEMPLATE=

help() {
  cat <<EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

Options:
  -h, --help                            Display this text.
  --timeout         <timeout>           How long to wait for helm to complete install (Default: $TIMEOUT).
  --wait                                Wait for helm to complete install.
  --helm-dry-run                        Install helm with --dry-run.
  --dry-run                             Show all install commands, but don't actually run them.
  --dep-update                          Run helm dependency update.
  --fail-if-installed                   Fail with a status code 1 if the helm release '$RELEASE_NAME' already exists in the $K8S_NAMESPACE namespace.
  --upgrade                             Upgrades an existing installation.
  --replicated                          Install the replicated pv engines.
  --locals                              Install all the local engines.
  --mayastor                            Install the replica pv mayastor.
  --lvm                                 Install the local pv lvm.
  --zfs                                 Install the local pv zfs.
  --hostpath                            Install the local pv hostpath (always enabled!).
  --helm            <stringArray>       Pass Helm Args directly to the install/upgrade commands.

Examples:
  $(basename "$0")
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

ins_replicated() {
  [ "$INS_MAYASTOR" = "true" ]
}
ins_locals() {
  [ "$INS_LVM" = "true" ] || [ "$INS_ZFS" = "true" ] || [ "$INS_HOSTPATH" = "true" ]
}

prefix_args() {
  local prefix="$1"
  if [ -n "$prefix" ]; then
    prefix="$prefix."
  fi
  local sep=""
  for set in $(echo "${@:2}" | awk -F, '{ for(i=1; i<=NF; i++) print $i; }'); do
    echo -n "$sep$prefix$set"
    if [ -z "$sep" ]; then
      sep=","
    fi
  done
}

make_mayastor_args() {
  prefix_args "mayastor" "$@"
}
make_zfs_args() {
  prefix_args "zfs-localpv" "$@"
}
make_lvm_args() {
  prefix_args "lvm-localpv" "$@"
}
make_hostpath_args() {
  prefix_args "localpv-provisioner" "$@"
}

mayastor_set_args() {
  echo -n "--set="
  make_mayastor_args "$@"
}
openebs_set_args() {
  echo -n "--set="
  prefix_args "" "$@"
}

mayastor_analytics_disable() {
  make_mayastor_args "obs.callhome.enabled=true,obs.callhome.sendReport=false,localpv-provisioner.analytics.enabled=false"
}
lvm_analytics_disable() {
  make_lvm_args "analytics.enabled=false"
}
zfs_analytics_disable() {
  make_zfs_args "analytics.enabled=false"
}
hostpath_analytics_disable() {
 make_hostpath_args "analytics.enabled=false"
}

mayastor_args() {
  if ! [ "$INS_MAYASTOR" = "true" ]; then
    openebs_set_args "engines.replicated.mayastor.enabled=false"
    return 0
  fi
  echo -n "$(mayastor_set_args "etcd.livenessProbe.initialDelaySeconds=5,etcd.readinessProbe.initialDelaySeconds=5,etcd.replicaCount=1")" \
          "$(mayastor_set_args "eventing.enabled=true")" \
          "$(openebs_set_args "$(mayastor_analytics_disable)")" \
          "$(openebs_set_args "engines.replicated.mayastor.enabled=true")"
}
lvm_args() {
  if ! [ "$INS_LVM" = "true" ]; then
    openebs_set_args "engines.local.lvm.enabled=false"
    return 0
  fi
  echo -n "$(openebs_set_args "engines.local.lvm.enabled=true")" \
          "$(openebs_set_args "$(lvm_analytics_disable)")"
}
zfs_args() {
  if ! [ "$INS_ZFS" = "true" ]; then
    openebs_set_args "engines.local.zfs.enabled=false"
    return 0
  fi
  echo -n "$(openebs_set_args "engines.local.zfs.enabled=true")" \
          "$(openebs_set_args "$(zfs_analytics_disable)")"
}
hostpath_args() {
  echo -n "$(openebs_set_args "$(hostpath_analytics_disable)")"
}

helm_installed() {
  if ! helm ls &>/dev/null; then
    if [ -n "$DRY_RUN" ]; then
      return 1
    fi
  fi
  [ "$(helm ls -n "$K8S_NAMESPACE" 2>/dev/null -o json | jq --arg release_name "$RELEASE_NAME" 'any(.[]; .name == $release_name)')" = "true" ]
}
helm_install() {
  local action="${1:-install}"

  if [ "$action" = "install" ]; then
    if [ "$HELM_UPGRADE" = "true" ]; then
      echo "Upgrading $RELEASE_NAME Chart"
      # todo: support opting for --reset-then-reuse-values"
      action="upgrade --reuse-values"
    else
      echo "Installing $RELEASE_NAME Chart"
    fi
  fi

  args=$(echo "
        $(mayastor_args) \
        $(lvm_args) \
        $(zfs_args) \
        $(hostpath_args)" \
        | xargs)
  if [ -z "$DRY_RUN" ] && [ "$action" != "template" ]; then
    set -x
  fi
  # shellcheck disable=SC2086
  $HELM "$action" "$RELEASE_NAME" "$CHART_DIR" -n "$K8S_NAMESPACE" --create-namespace \
       $args \
       $HELM_DRY_RUN ${WAIT_ARG:-} ${HELM_ARGS:-}
  if [ -z "$DRY_RUN" ] && [ "$action" != "template" ]; then
    set +x
  fi
}

while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--help)
      help
      exit 0
      ;;
    --timeout)
      shift
      test $# -lt 1 && die "Missing timeout value"
      TIMEOUT=$1
      shift;;
    --wait)
      WAIT="true"
      shift;;
    --helm-dry-run)
      HELM_DRY_RUN=" --dry-run"
      shift;;
    --dry-run)
      DRY_RUN="true"
      HELM="echo $HELM"
      KUBECTL="echo $KUBECTL"
      shift;;
    --dep-update)
      DEP_UPDATE="true"
      shift;;
    --fail-if-installed)
      FAIL_IF_INSTALLED="true"
      shift;;
     --upgrade)
      HELM_UPGRADE="true"
      shift;;
    --replicated | --mayastor)
      INS_MAYASTOR="true"
      shift;;
    --locals)
      INS_LVM="true"
      INS_ZFS="true"
      INS_HOSTPATH="true"
      shift;;
    --lvm)
      INS_LVM="true"
      shift;;
    --zfs)
      INS_ZFS="true"
      shift;;
    --hostpath)
      INS_HOSTPATH="true"
      shift;;
    --template)
      TEMPLATE="true"
      shift;;
    --helm)
      shift
      test $# -lt 1 && die "Missing helm args"
      HELM_ARGS="${HELM_ARGS:-} $1"
      shift;;
    *)
      die "Unknown argument $1!"
      ;;
  esac
done

if [ -n "$DEP_UPDATE" ]; then
  $HELM dependency update "$CHART_DIR" --kubeconfig "$CHART_DIR/fake"
fi

if [ -n "$WAIT" ]; then
  WAIT_ARG=" --wait --timeout $TIMEOUT"
fi

if ! (ins_replicated || ins_locals); then
  die "No engine specified, please select at least one engine"
fi

if [ -n "$TEMPLATE" ]; then
  helm_install "template"
  exit 0
fi

if helm_installed; then
  already_exists_log="Helm release $RELEASE_NAME already exists in namespace $K8S_NAMESPACE"
  if [ -n "$FAIL_IF_INSTALLED" ]; then
    die "ERROR: $already_exists_log" 1
  fi
  echo "$already_exists_log"
  if [ "$HELM_UPGRADE" = "true" ]; then
    helm_install
  fi
else
  helm_install
fi

$KUBECTL get pods -n "$K8S_NAMESPACE" -o wide
