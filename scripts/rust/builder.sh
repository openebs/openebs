#!/usr/bin/env sh

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$(realpath -- "${0}" )")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
PLUGIN_DIR="${ROOT_DIR}/plugin"

cd "${PLUGIN_DIR}" || exit 1

cargo build --bins
