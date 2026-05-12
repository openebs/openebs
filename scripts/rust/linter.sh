#!/usr/bin/env sh

set -e

FMT_ERROR=
FMT_OPTS=${FMT_OPTS:-"--config imports_granularity=Crate"}

OP="${1:-}"

case "$OP" in
  "" | "fmt" | "clippy")
    ;;
  *)
    echo "linter $OP not supported"
    exit 2
esac

cargo fmt -- --version
cargo clippy -- --version

if [ -z "$OP" ] || [  "$OP" = "fmt" ]; then
  cargo fmt --all --check -- $FMT_OPTS || FMT_ERROR=$?
  if [ -n "$FMT_ERROR" ]; then
    cargo fmt --all -- $FMT_OPTS
  fi
fi

if [ -z "$OP" ] || [  "$OP" = "clippy" ]; then
  cargo clippy --all --all-targets -- -D warnings
fi

exit ${FMT_ERROR:-0}

