#!/usr/bin/env bash

# Mirror container images from source registry to target registry using crane.
# Preserves multi-platform support and image digests.

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"

# if ROOT_DIR is not defined use the one below
: "${ROOT_DIR:=${SCRIPT_DIR}/../..}"

source "$ROOT_DIR/mayastor/scripts/utils/log.sh"
NO_RUN=true . "$ROOT_DIR/scripts/release.sh"

IMAGES=()
for name in $DEFAULT_IMAGES; do
  image=$($NIX_EVAL -f "$ROOT_DIR" "images.$BUILD_TYPE.$name.imageName" --raw --quiet --argstr product_prefix "$PRODUCT_PREFIX")
  IMAGES+=("${image##*/}")
done

SOURCE_NAMESPACE=""
TARGET_NAMESPACE=""
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --source-namespace)
      SOURCE_NAMESPACE="$2"
      shift 2
      ;;
    --target-namespace)
      TARGET_NAMESPACE="$2"
      shift 2
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    *)
      log_fatal "Unknown option: $1"
      ;;
  esac
done

if [[ -z "$SOURCE_NAMESPACE" ]] || [[ -z "$TARGET_NAMESPACE" ]] || [[ -z "$TAG" ]]; then
  log_fatal "Usage: $0 --source-namespace <source> --target-namespace <target> --tag <tag>"
fi

echo "Mirroring images from ${SOURCE_NAMESPACE} to ${TARGET_NAMESPACE} with tag ${TAG}"

for IMAGE in "${IMAGES[@]}"; do
  echo "Mirroring ${IMAGE}:${TAG}..."

  SRC="${SOURCE_NAMESPACE}/${IMAGE}:${TAG}"
  DEST="${TARGET_NAMESPACE}/${IMAGE}:${TAG}"
  crane copy --platform all "${SRC}" "${DEST}"

  echo "✓ Successfully mirrored ${IMAGE}:${TAG}"
done
