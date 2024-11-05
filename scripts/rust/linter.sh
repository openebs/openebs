#!/usr/bin/env sh

set -e

FMT_ERROR=

cargo fmt -- --version
cargo clippy -- --version

cargo fmt --all --check || FMT_ERROR=$?
if [ -n "$FMT_ERROR" ]; then
  cargo fmt --all
fi

cargo clippy --all --all-targets -- -D warnings

exit ${FMT_ERROR:-0}
