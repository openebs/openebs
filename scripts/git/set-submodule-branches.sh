#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$(realpath $SCRIPT_DIR/../..)"
CHART_DIR="$ROOT_DIR/charts"
MAYASTOR_NAME="mayastor"

echo_stderr() {
  echo -e "${1}" >&2
}

die() {
  local _return="${2:-1}"
  echo_stderr "$1"
  exit "${_return}"
}

mayastor_helm_version() {
  helm show chart "$CHART_DIR" | dep="$MAYASTOR_NAME" yq '.dependencies[]|select(.name == strenv(dep)).version'
}

submodule_set_branch_all() {
  branch=${1:-}
  if [ -n "$branch" ]; then
    branch="--branch $branch"
  else
    branch="--default"
  fi
  for mod in `git config --file .gitmodules --get-regexp path | awk '{ print $2 }'`; do
    git submodule set-branch $branch $mod
  done
}

submodule_update() {
  for mod in `git config --file .gitmodules --get-regexp path | awk '{ print $2 }'`; do
    git submodule update --remote "$mod"
    pushd "$mod" >/dev/null
    git submodule update --init --recursive .
    popd >/dev/null
  done
}

mayastor_branch_exists() {
  local branch="$1"
  cd "$ROOT_DIR/$MAYASTOR_NAME"
  branch=$(git branch --list -r origin/$branch)
  if [ $? -ne 0 ]; then
    die "Failed to run Git branch command"
  fi
  [ -n "$branch" ]
}

mayastor_branch() {
  version="$(mayastor_helm_version)"

  local major="$(semver get major "$version")"
  local minor="$(semver get minor "$version")"
  local patch="$(semver get patch "$version")"
  local prerel="$(semver get prerel "$version")"

   if [[ "$version" == "0.0.0" ]] || [[ "$prerel" == "develop" ]]; then
     BRANCH="develop"
   else
     BRANCH="release/${major}.${minor}"
   fi

   if mayastor_branch_exists "$BRANCH"; then
     return 0
   else
     die "Cannot determine the correct $MAYASTOR_NAME branch!"
   fi
}

BRANCH=
SET_BRANCH=
CLEAR_BRANCH=
UPDATE=
while [ "$#" -gt 0 ]; do
  case $1 in
    -b|--branch)
      shift
      BRANCH=$1
      shift
      ;;
    -c|--clear)
      CLEAR_BRANCH="y"
      shift
      ;;
    -u|--update)
      UPDATE="y"
      shift
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

if [ -n "$UPDATE" ]; then
  submodule_update
elif [ -n "$CLEAR_BRANCH" ]; then
  submodule_set_branch_all ""
elif [ -n "$SET_BRANCH" ]; then
  submodule_set_branch_all "$SET_BRANCH"
else
  # If nothing is specified do it from the charts.
  mayastor_branch
  submodule_set_branch_all "$BRANCH"
fi
