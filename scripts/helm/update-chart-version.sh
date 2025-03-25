#!/usr/bin/env bash

# Write output to error output stream.
echo_stderr() {
  echo -e "${1}" >&2
}

die()
{
  local _return="${2:-1}"
  echo_stderr "$1"
  exit "${_return}"
}

help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --dry-run                                 Get the final version without modifying.
  --branch <branch name>                    Name of the target branch.
  --tag <tag>                               Release tag.
  --type <release/develop>                  Which branch to modify.
  --chart-version <version>                 Version of the current chart.
  --publish-release                         To modify the charts for a release.
  --localpv-provisioner-version <version>   LocalPV Provisioner version.
  --zfs-localpv-version <version>           ZFS LocalPV version.
  --lvm-localpv-version <version>           LVM LocalPV version.
  --mayastor-version <version>              Mayastor version.

Examples:
  $(basename "$0") --branch release/x.y --chart-version 1.2.3 --openebs-crds-version 2.0.1
EOF
}

check_tag_is_valid() {
    local tag="$1"
    local current_chart_version="$2"

    if [[ "$(semver validate $tag)" != "valid" ]]; then
      die "Tag is not a valid semver complaint version"
    fi

    if [[ $current_chart_version != *"-prerelease" ]]; then
      die "Chart version($current_chart_version) should be a prerelease format to proceed for tag creation flow"
    fi

    allowed_diff=("" "patch" "prerelease")
    diff="$(semver diff "$tag" "$current_chart_version")"
    if ! [[ " ${allowed_diff[*]} " =~ " $diff " ]]; then
      die "For release/x.y branch the current chart version($current_chart_version)'s X.Y must exactly match X.Y from tag ($tag)"
    fi
}

# yq-go eats up blank lines
# this function gets around that using diff with --ignore-blank-lines
yq_ibl()
{
  set +e
  diff_out=$(diff -B <(yq '.' "$2") <(yq "$1" "$2"))
  error=$?
  if [ "$error" != "0" ] && [ "$error" != "1" ]; then
    exit "$error"
  fi
  if [ -n "$diff_out" ]; then
    echo "$diff_out" | patch --quiet --no-backup-if-mismatch "$2" -
  fi
  set -euo pipefail
}

# RULES: This would run only when changes are pushed to a release/x.y branch.
# 1. Branch name can only be of format release/x.y
# 2. If current chart version of type develop(on branch creation), 
#    then version generated is of format x.y.0-prerelease if type is "release"
# 3. If current chart version of type develop(on branch creation), 
#    then version generated is of format x.y+1.0-develop if type is develop.
# 4. If current chart version of type prerelease(after branch creation), 
#    then for type release it's a no op as it's already a prerelease format.
# 5. If current chart version of type prerelease(after branch creation), 
#    then for type develop it's a no op as the version to be would be same as it is currently.
# 6. Let's say for somereason someone tries to create a release/x.y branch from develop but chart version 
#    on develop is newer than x.y, example, release/2.2 and develop chart version is 2.5.0-develop.
#    In that case for type release, the version would be 2.2.0-prerelease and for type develop it would be
#    a no op as develop is already newer.
create_version_from_release_branch() {
  if [[ "$BRANCH_NAME" =~ ^(release/[0-9]+\.[0-9]+)$ ]]; then
    local EXTRACTED_VERSION=$(echo "$BRANCH_NAME" | grep -oP '(?<=release/)\d+\.\d+')
    if [[ "$TYPE" ==  "release" ]]; then
      if [[ "$CURRENT_CHART_VERSION" == *"-develop" ]]; then
        VERSION="${EXTRACTED_VERSION}.0-prerelease"
      elif [[ "$CURRENT_CHART_VERSION" == *"-prerelease" ]]; then
        NO_OP=1
      else
        die "Current chart version doesn't match a develop or prerel format"
      fi
    elif [[ "$TYPE" ==  "develop" ]]; then
      EXPECTED_VERSION="$(semver bump minor "$EXTRACTED_VERSION.0")-develop"
      if [[ "$(semver compare $EXPECTED_VERSION $CURRENT_CHART_VERSION)" == 1 ]]; then
        VERSION=$EXPECTED_VERSION
      else
        NO_OP=1
      fi
    fi
  else
    die "Branch name($BRANCH_NAME) is not of format release/x.y"
  fi
}

# RULES: This would run only when tag is created.
# 1. Tag should be of format vX.Y.Z.
# 2. If tag is of format vX.Y.Z-rc, it would be a no op for the workflow.
# 3. The tag can only be vX.Y.Z if the current chart version is X.Y*-prerelease. Ex, v2.6.1 for v2.6.*-prerelease
# 4. For release branches if all the above holds then it bumps the patch version. Ex, v2.6.1 --> 2.6.2-prerelease
create_version_from_tag() {
  if [[ "$TAG" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    local EXTRACTED_VERSION=$(echo "$TAG" | grep -oP '(?<=v)\d+\.\d+.\d+')
    check_tag_is_valid "$EXTRACTED_VERSION" "$CURRENT_CHART_VERSION"
    if [[ -z $PUBLISH_RELEASE ]]; then
       VERSION="$(semver bump patch $EXTRACTED_VERSION)-prerelease"
      if [[ -z $DRY_RUN ]]; then
        echo "release/$(echo $EXTRACTED_VERSION | cut -d'.' -f1,2)"
      fi
    else
      VERSION="$EXTRACTED_VERSION"
    fi
  elif [[ "$TAG" == *"-rc" ]]; then
    if [[ -z $PUBLISH_RELEASE ]]; then
      NO_OP=1
    else
      local EXTRACTED_VERSION=$(echo "$TAG" | grep -oP '(?<=v)\d+\.\d+\.\d+(-\w+)?')
      check_tag_is_valid "$EXTRACTED_VERSION" "$CURRENT_CHART_VERSION"
      VERSION="$EXTRACTED_VERSION"
    fi
  else
    die "Invalid tag format. Expected 'vX.Y.Z'"
  fi
}

update_chart_yaml() {
  local VERSION=$1
  local APP_VERSION=$2
  local LOCALPV_PROVISIONER_VERSION=$3
  local ZFS_LOCALPV_VERSION=$4
  local LVM_LOCALPV_VERSION=$5
  local MAYASTOR_VERSION=$6

 if [[ "$VERSION" =~ (-develop|-prerelease) ]]; then
    SUFFIX="${BASH_REMATCH[1]}"
    LOCALPV_PROVISIONER_VERSION="$LOCALPV_PROVISIONER_VERSION$SUFFIX"
    ZFS_LOCALPV_VERSION="$ZFS_LOCALPV_VERSION$SUFFIX"
    LVM_LOCALPV_VERSION="$LVM_LOCALPV_VERSION$SUFFIX"
  fi
  echo "Updating Helm Chart.yaml versions..."

  # Debug: Print variables
  echo "Helm Version: $VERSION"
  echo "App Version: $APP_VERSION"
  echo "OpenEBS CRDS Version: $APP_VERSION"
  echo "LocalPV Provisioner Version: $LOCALPV_PROVISIONER_VERSION"
  echo "ZFS LocalPV Version: $ZFS_LOCALPV_VERSION"
  echo "LVM LocalPV Version: $LVM_LOCALPV_VERSION"
  echo "Mayastor Version: $MAYASTOR_VERSION"

  yq_ibl ".version = \"$VERSION\" | .appVersion = \"$APP_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"openebs-crds\") | .version) = \"$APP_VERSION\"" "$CHART_YAML"
  yq_ibl ".version = \"$APP_VERSION\"" "$CRD_CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"localpv-provisioner\") | .version) = \"$LOCALPV_PROVISIONER_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"zfs-localpv\") | .version) = \"$ZFS_LOCALPV_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"lvm-localpv\") | .version) = \"$LVM_LOCALPV_VERSION\"" "$CHART_YAML"
  yq_ibl "(.dependencies[] | select(.name == \"mayastor\") | .version) = \"$MAYASTOR_VERSION\"" "$CHART_YAML"
}

set -euo pipefail

DRY_RUN=
NO_OP=
CURRENT_CHART_VERSION=
PUBLISH_RELEASE=
# Set the path to the Chart.yaml file
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
ROOT_DIR="$SCRIPT_DIR/../../"
CHART_DIR="$ROOT_DIR/charts"
CHART_YAML="$CHART_DIR/Chart.yaml"
# VALUES_YAML="$CHART_DIR/values.yaml"
CRD_CHART_NAME="openebs-crds"
CRD_CHART_YAML="$CHART_DIR/charts/$CRD_CHART_NAME/Chart.yaml"
# Final computed version to be set in this.
VERSION=""
LOCALPV_PROVISIONER_VERSION=""
ZFS_LOCALPV_VERSION=""
LVM_LOCALPV_VERSION=""
MAYASTOR_VERSION=""

# Parse arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    -d|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -b|--branch)
      shift
      BRANCH_NAME=$1
      shift
      ;;
    -t|--tag)
      shift
      TAG=$1
      shift
      ;;
    --type)
      shift
      TYPE=$1
      shift
      ;;
    --chart-version)
      shift
      CURRENT_CHART_VERSION=$1
      shift
      ;;
    --publish-release)
      PUBLISH_RELEASE=1
      shift
      ;;
    --localpv-provisioner-version)
      shift
      LOCALPV_PROVISIONER_VERSION=$1
      shift
      ;;
    --zfs-localpv-version)
      shift
      ZFS_LOCALPV_VERSION=$1
      shift
      ;;
    --lvm-localpv-version)
      shift
      LVM_LOCALPV_VERSION=$1
      shift
      ;;
    --mayastor-version)
      shift
      MAYASTOR_VERSION=$1
      shift
      ;;
    *)
      help
      die "Unknown option: $1"
      ;;
  esac
done

# # Validate required arguments
# if [[ -z "$LOCALPV_PROVISIONER_VERSION" || -z "$ZFS_LOCALPV_VERSION" || -z "$LVM_LOCALPV_VERSION" || -z "$MAYASTOR_VERSION" ]]; then
#   echo "Error: All mandatory dependencies versions must be provided."
#   help
#   exit 1
# fi

if [[ -z $CURRENT_CHART_VERSION ]]; then
  CURRENT_CHART_VERSION=$(yq e '.version' "$CHART_YAML")
fi

if [[ -n "${BRANCH_NAME-}" && -n "${TYPE-}" ]]; then
  create_version_from_release_branch
elif [[ -n "${TAG-}" ]]; then
  create_version_from_tag
else
  help
  die "Either --branch and --type or --tag and must be specified."
fi

if [[ -z $NO_OP ]]; then
  if [[ -n $VERSION ]]; then
    if [[ -z $DRY_RUN ]];then
      update_chart_yaml "$VERSION" "$VERSION" "$LOCALPV_PROVISIONER_VERSION" "$ZFS_LOCALPV_VERSION" "$LVM_LOCALPV_VERSION" "$MAYASTOR_VERSION"
    else
      echo "$VERSION"
    fi
  else
    die "Failed to update the chart versions"
  fi
fi