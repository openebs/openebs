#!/usr/bin/env sh

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="${SCRIPT_DIR}/../.."
PLUGIN_DIR="${ROOT_DIR}/plugin"

cd "${PLUGIN_DIR}"

cargo build --bins
