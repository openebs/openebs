#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
ROOT_DIR="${SCRIPT_DIR}/../.."
: "${PARENT_ROOT_DIR:=$ROOT_DIR}"

source "$ROOT_DIR/mayastor/scripts/utils/log.sh"
NO_RUN=true . "$PARENT_ROOT_DIR/scripts/release.sh"

DOCKERHUB_ORG="${DOCKERHUB_ORG:-openebs}"
GITHUB_ORG="${GITHUB_ORG:-openebs}"
IMAGE_REGISTRY="${IMAGE_REGISTRY:-docker.io}"
CHART_REGISTRY="${CHART_REGISTRY:-gh-pages}"
CHART_NAME="${CHART_NAME:-openebs}"
NAMESPACE="${NAMESPACE:-${GITHUB_ORG}/helm}"
INDEX_REMOTE="${INDEX_REMOTE:-origin}"
INDEX_BRANCH="${INDEX_BRANCH:-gh-pages}"
INDEX_BRANCH_FILE="${INDEX_BRANCH_FILE:-index.yaml}"
CHART_FILE="${CHART_FILE:-${PARENT_ROOT_DIR}/charts/Chart.yaml}"

TRIGGER=""
TAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --trigger|--type) TRIGGER="$2"; shift 2 ;;
        --tag) TAG="$2"; shift 2 ;;
        -h|--help)
            cat <<EOF
Usage: $0 --trigger <trigger> [--tag <tag>]
Options:
  --trigger <type>        release, staging, develop, prerelease
  --type <type>           Alias for --trigger
  --tag <tag>             Release tag (e.g., v2.9.0)
EOF
            exit 0 ;;
        *) log_fatal "Unknown option $1" ;;
    esac
done

echo "Validating trigger: $TRIGGER"

case "$TRIGGER" in
    release|staging|develop|prerelease) echo "✅ Valid trigger: $TRIGGER" ;;
    *) log_fatal "❌ Error: Invalid trigger '$TRIGGER'." ;;
esac

if [[ -z "$TAG" ]]; then
    if [[ ! -f "$CHART_FILE" ]]; then
        log_fatal "❌ Error: Chart.yaml not found at ${CHART_FILE} and no tag provided"
    fi
    CHART_VERSION=$(awk -F': ' '/^version:/ {print $2}' "$CHART_FILE" | tr -d ' ')
    TAG="v${CHART_VERSION}"
    echo "Using chart version from $CHART_FILE: $TAG"
fi

echo "Validating tag: $TAG"

case "$TRIGGER" in
    release|staging)
        [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]] \
            || log_fatal "❌ Tag must be in format vX.Y.Z or vX.Y.Z-rc.N"
        ;;
    develop)
        [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-develop$ ]] \
            || log_fatal "❌ Tag must be in format vX.Y.Z-develop"
        ;;
    prerelease)
        [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-prerelease$ ]] \
            || log_fatal "❌ Tag must be in format vX.Y.Z-prerelease"
        ;;
esac

if [[ "$TRIGGER" == "staging" ]]; then
    if git -C "$PARENT_ROOT_DIR" ls-remote -t "$INDEX_REMOTE" | grep -q "refs/tags/${TAG}$"; then
        log_fatal "❌ Tag ${TAG} exists on remote ${INDEX_REMOTE}"
    else
        echo "Tag ${TAG} does not exist on remote ${INDEX_REMOTE}"
    fi
fi

echo "✅ Input validations passed"

VERSION="${TAG#v}"
VALIDATION_FAILED=false

dockerhub_tag_exists() {
    local repository="$1" tag="$2"
    curl --silent -f -lSL "https://hub.docker.com/v2/repositories/${repository#docker.io/}/tags/${tag}" >/dev/null 2>&1
}
check_images() {
    if [[ -n "${DEFAULT_IMAGES:-}" ]]; then
        for name in $DEFAULT_IMAGES; do
            image=$($NIX_EVAL -f "$PARENT_ROOT_DIR" "images.$BUILD_TYPE.$name.imageName" --raw --quiet --argstr product_prefix "$PRODUCT_PREFIX")
            image_name="${image##*/}"
            if dockerhub_tag_exists "${DOCKERHUB_ORG}/${image_name}" "${TAG}"; then
                log_fatal "Image ${DOCKERHUB_ORG}/${image_name}:${TAG} already exists"
            else
                echo "Image ${DOCKERHUB_ORG}/${image_name}:${TAG} does not exist"
            fi
        done
    fi
}

index_yaml() {
    git -C "$PARENT_ROOT_DIR" fetch "$INDEX_REMOTE" "$INDEX_BRANCH" --depth 1 >/dev/null 2>&1
    git -C "$PARENT_ROOT_DIR" show "$INDEX_REMOTE"/"$INDEX_BRANCH":"$INDEX_BRANCH_FILE"
}
check_chart() {
    case "$CHART_REGISTRY" in
        gh-pages)
            INDEX_FILE_YAML=$(index_yaml)
            if echo "$INDEX_FILE_YAML" | yq ".entries.${CHART_NAME}[].version" | grep -qx "$VERSION"; then
                log_fatal "Chart ${CHART_NAME}:${VERSION} already exists on GitHub Pages"
            else
                echo "Chart ${CHART_NAME}:${VERSION} does not exist on GitHub Pages"
            fi
            ;;
        oci://*)
            if helm show chart "${CHART_REGISTRY}/${NAMESPACE}/${CHART_NAME}" --version "$VERSION" >/dev/null 2>&1; then
                log_fatal "Helm chart already exists in ${CHART_REGISTRY}"
            else
                echo "Helm chart ${CHART_NAME}:${VERSION} does not exist in ${CHART_REGISTRY}"
            fi
            ;;
        *) log_fatal "Invalid chart location: $CHART_REGISTRY" ;;
    esac
}

case "$TRIGGER" in
    staging)
        check_images
        check_chart
        ;;
    release)
        check_chart
        ;;
    develop|prerelease)
        echo "Skipping artifact checks for $TRIGGER"
        ;;
esac

echo "✅ All validations completed successfully"
