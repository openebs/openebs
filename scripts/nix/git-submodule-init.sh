#!/usr/bin/env bash

set -euo pipefail

FORCE=
while [ "$#" -gt 0 ]; do
  case $1 in
    -f|--force)
      FORCE="--force"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

submodule_init() {
  for mod in `git config --file .gitmodules --get-regexp path | awk '{ print $2 }'`; do
    if [ -n "$FORCE" ] || [ ! -f $mod/.git ]; then
      git submodule deinit $FORCE $mod
      git submodule update $FORCE --init --recursive $mod
    fi
    pushd $mod 1>/dev/null
    submodule_init
    popd 1>/dev/null
done
}

submodule_init

