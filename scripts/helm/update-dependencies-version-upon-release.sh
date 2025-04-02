#!/usr/bin/env bash

set -euo pipefail

# Function to print messages to stderr
echo_stderr() {
  echo -e "${1}" >&2
}

die() {
  local _return="${2:-1}"
  echo_stderr "$1"
  exit "${_return}"
}

help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help   Show this help message.

This script removes the "-prerelease" suffix from dependencies in Chart.yaml.
EOF
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

update_chart_yaml() {
  echo "Updating Helm Chart.yaml dependencies versions for release publish"

  yq_ibl '(.dependencies[] | select(.name == "localpv-provisioner") | .version) |= sub("-prerelease$"; "")' "$CHART_YAML"
  yq_ibl '(.dependencies[] | select(.name == "zfs-localpv") | .version) |= sub("-prerelease$"; "")' "$CHART_YAML"
  yq_ibl '(.dependencies[] | select(.name == "lvm-localpv") | .version) |= sub("-prerelease$"; "")' "$CHART_YAML"
  yq_ibl '(.dependencies[] | select(.name == "mayastor") | .version) |= sub("-prerelease$"; "")' "$CHART_YAML"
}

set -euo pipefail

# Determine script and chart directory
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
CHART_YAML="$SCRIPT_DIR/../../charts/Chart.yaml"

# Parse arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--help)
      help
      exit 0
      ;;
    *)
      help
      die "Unknown option: $1"
      ;;
  esac
done

update_chart_yaml
