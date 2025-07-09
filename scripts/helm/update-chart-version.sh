#!/usr/bin/env bash

# Help text
help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --dry-run                                 Get the final version without modifying.
  --chart-version <version>                 Version of the current chart.
  --app-version <version>                   App Version
  --publish-release                         To modify the charts for a release.
  --localpv-provisioner-version <version>   LocalPV Provisioner version.
  --zfs-localpv-version <version>           ZFS LocalPV version.
  --lvm-localpv-version <version>           LVM LocalPV version.
  --mayastor-version <version>              Mayastor version.

Examples:
  $(basename "$0") --chart-version 1.2.3 --app-version 1.2.3  \
                   --localpv-provisioner-version <version>  --zfs-localpv-version <version> \
                   --lvm-localpv-version <version>  --mayastor-version <version>
EOF
}

# Chart update
update_chart_yaml() {
  local VERSION=${1#v}
  local APP_VERSION=${2#v}
  local LOCALPV_HOSTPATH_VERSION=${3#v}
  local LOCALPV_ZFS_VERSION=${4#v}
  local LOCALPV_LVM_VERSION=${5#v}
  local MAYASTOR_VERSION=${6#v}

  yq_ibl ".version = \"$VERSION\" | .appVersion = \"$APP_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"openebs-crds\") | .version) = \"$APP_VERSION\"" "$CHART_YAML"
  yq_ibl ".version = \"$APP_VERSION\"" "$CRD_CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"localpv-provisioner\") | .version) = \"$LOCALPV_HOSTPATH_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"zfs-localpv\") | .version) = \"$LOCALPV_ZFS_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"lvm-localpv\") | .version) = \"$LOCALPV_LVM_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"mayastor\") | .version) = \"$MAYASTOR_VERSION\"" "$CHART_YAML"
}

# Initialize variables
DRY_RUN=
VERSION=""
APP_VERSION=""
LOCALPV_HOSTPATH_VERSION=""
LOCALPV_ZFS_VERSION=""
LOCALPV_LVM_VERSION=""
MAYASTOR_VERSION=""

# Paths
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
ROOT_DIR="$SCRIPT_DIR/../.."
CHART_DIR="$ROOT_DIR/charts"
CHART_YAML="$CHART_DIR/Chart.yaml"
CRD_CHART_NAME="openebs-crds"
CRD_CHART_YAML="$CHART_DIR/charts/$CRD_CHART_NAME/Chart.yaml"

# Import
source "$ROOT_DIR/mayastor/scripts/utils/yaml.sh"
source "$ROOT_DIR/mayastor/scripts/utils/log.sh"

# Parse arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    -d|--dry-run) DRY_RUN=1; shift ;;
    -h|--help) help; exit 0 ;;
    --chart-version) shift; VERSION=$1; shift ;;
    --app-version) shift; APP_VERSION=$1; shift ;;
    --localpv-provisioner-version) shift; LOCALPV_HOSTPATH_VERSION=$1; shift ;;
    --zfs-localpv-version) shift; LOCALPV_ZFS_VERSION=$1; shift ;;
    --lvm-localpv-version) shift; LOCALPV_LVM_VERSION=$1; shift ;;
    --mayastor-version) shift; MAYASTOR_VERSION=$1; shift ;;
    *) help; log_fatal "Unknown option: $1" ;;
  esac
done

validate_inputs() {
  [[ -z "$APP_VERSION" ]] && log_fatal "Missing required input: --app-version"
  [[ -z "$LOCALPV_HOSTPATH_VERSION" ]] && log_fatal "Missing required input: --localpv-provisioner-version"
  [[ -z "$LOCALPV_ZFS_VERSION" ]] && log_fatal "Missing required input: --zfs-localpv-version"
  [[ -z "$LOCALPV_LVM_VERSION" ]] && log_fatal "Missing required input: --lvm-localpv-version"
  [[ -z "$MAYASTOR_VERSION" ]] && log_fatal "Missing required input: --mayastor-version"
}

if [[ -n $VERSION ]]; then
   validate_inputs
  if [[ -z $DRY_RUN ]];then
    update_chart_yaml "$VERSION" "$APP_VERSION" "$LOCALPV_HOSTPATH_VERSION" "$LOCALPV_ZFS_VERSION" "$LOCALPV_LVM_VERSION" "$MAYASTOR_VERSION"
  else
    log "Dry run mode. The following versions would be used:"
    log "Chart Version:              $VERSION"
    log "App Version:                $APP_VERSION"
    log "LocalPV Provisioner:        $LOCALPV_HOSTPATH_VERSION"
    log "ZFS LocalPV:                $LOCALPV_ZFS_VERSION"
    log "LVM LocalPV:                $LOCALPV_LVM_VERSION"
    log "Mayastor:                   $MAYASTOR_VERSION"
  fi
else
   log_fatal "Failed to update the chart versions"
fi
