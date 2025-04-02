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

set -euo pipefail

# Set the path to the Chart.yaml file
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
ROOT_DIR="$SCRIPT_DIR/.."
CHART_DIR="$ROOT_DIR/charts"
CHART_YAML="$CHART_DIR/Chart.yaml"

# Check if the Chart.yaml file exists
if [ ! -f "$CHART_YAML" ]; then
  die "Chart.yaml file not found in $CHART_YAML"
fi

# Extract the chart version and app version using yq
CHART_VERSION=$(yq e '.version' "$CHART_YAML")
APP_VERSION=$(yq e '.appVersion' "$CHART_YAML")

# Check if extraction was successful
if [ -z "$CHART_VERSION" ] || [ -z "$APP_VERSION" ]; then
  die "Failed to extract versions from Chart.yaml"
fi

# Print the extracted versions
echo "Chart Version: $CHART_VERSION"
echo "App Version: $APP_VERSION"

# Validate that the versions are valid semver
if [ "$(semver validate "$CHART_VERSION")" != "valid" ]; then
  die "Invalid chart version: $CHART_VERSION"
fi

if [ "$(semver validate "$APP_VERSION")" != "valid" ]; then
  die "Invalid app version: $APP_VERSION"
fi

help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --branch <branch name>                    Name of the branch on which this workflow is running.

Examples:
  $(basename "$0") --branch develop
EOF
}

# Parse arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    -b|--branch)
      BRANCH_NAME=$2
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    *)
      help
      die "Unknown option: $1"
      ;;
  esac
  shift
done

# Extract major and minor version from the branch name
extract_major_minor() {
  echo "$1" | awk -F/ '{print $2}'
}

if [[ "$BRANCH_NAME" == "develop" ]]; then
  if [[ "$CHART_VERSION" != *"-develop" ]]; then
    die "Chart version must include '-develop' for develop branch"
  fi
  if [[ "$APP_VERSION" != *"-develop" ]]; then
    die "App version must include '-develop' for develop branch"
  fi
elif [[ "$BRANCH_NAME" =~ ^(release/[0-9]+\.[0-9]+)$ ]]; then
  RELEASE_VERSION=$(extract_major_minor "$BRANCH_NAME")
  if [[ "$CHART_VERSION" != "$RELEASE_VERSION."*"-prerelease" ]]; then
    die "Chart version must be in format $RELEASE_VERSION.X-prerelease for release branch"
  fi
  if [[ "$APP_VERSION" != "$RELEASE_VERSION."*"-prerelease" ]]; then
    die "App version must be in format $RELEASE_VERSION.X-prerelease for release branch"
  fi
else
   die "Unknown branch name: $BRANCH_NAME"
fi
