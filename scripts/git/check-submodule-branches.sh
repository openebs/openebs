#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/.."

submodule_check() {
  failed=
  pushd $ROOT_DIR >/dev/null
  for mod in `git config --file .gitmodules --get-regexp path | awk '{ print $2 }'`; do
    branch="$(git config -f .gitmodules submodule.$mod.branch)"
    if [ -f $mod/.git ]; then
      pushd $mod >/dev/null
      if ! git branch -r --contains HEAD | grep "origin/$branch" >/dev/null; then
        echo "git submodule $mod::HEAD is not contained in branch $branch"
        failed="yes"
      fi
      popd >/dev/null
    fi
  done
  popd >/dev/null
  if [ -n "$failed" ]; then exit 1; fi
}

submodule_check
