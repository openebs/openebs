#!/usr/bin/env bash
# Manage kubectl plugin binaries as GHCR OCI artifacts.
# Supports both pushing and pulling operations.
# Usage:
#   Push: ./kubectl-oci.sh push --tag <tag> --namespace <ghcr-path> --username <user> --password <token>
#   Pull: ./kubectl-oci.sh pull --tag <tag> --namespace <ghcr-path> --username <user> --password <token>

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
ROOT_DIR="$SCRIPT_DIR/../.."

source "$ROOT_DIR/mayastor/scripts/utils/log.sh"

ACTION=""
TAG=""
NAMESPACE=""
USERNAME=""
PASSWORD=""

usage() {
  cat << EOF
Usage: $0 <action> [options]

Actions:
  push    Push kubectl binaries to GHCR as OCI artifacts
  pull    Pull kubectl binaries from GHCR OCI artifacts

Options:
  --tag <tag>             Release tag (required)
  --namespace <namespace> GHCR namespace path (required)
  --username <username>   GHCR username (required)
  --password <password>   GHCR token/password (required)

Examples:
  $0 push --tag v1.0.0 --namespace ghcr.io/openebs/kubectl-plugins --username user --password token
  $0 pull --tag v1.0.0 --namespace ghcr.io/openebs/kubectl-plugins --username user --password token
EOF
}

parse_args() {
  if [[ $# -lt 1 ]]; then
    usage
    log_fatal "Error: Action required (push or pull)"
  fi

  ACTION="$1"
  shift

  case "$ACTION" in
    push|pull)
      ;;
    *)
      usage
      log_fatal "Error: Invalid action '$ACTION'. Must be 'push' or 'pull'"
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case $1 in
      --tag)
        TAG="$2"
        shift 2
        ;;
      --namespace)
        NAMESPACE="$2"
        shift 2
        ;;
      --username)
        USERNAME="$2"
        shift 2
        ;;
      --password)
        PASSWORD="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage
        log_fatal "Unknown option: $1"
        ;;
    esac
  done

  if [[ -z "$TAG" ]] || [[ -z "$NAMESPACE" ]] || [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
    usage
    log_fatal "Error: All options (--tag, --namespace, --username, --password) are required"
  fi
}

# Login to registry
login_registry() {
  local registry_host
  NAMESPACE="${NAMESPACE%/}"
  registry_host=$(echo "$NAMESPACE" | cut -d'/' -f1)

  echo "Logging in to ${registry_host}..."
  echo "${PASSWORD}" | oras login "${registry_host}" --username "${USERNAME}" --password-stdin
}

# Push kubectl binaries to GHCR
push_artifacts() {
  echo "Pushing kubectl binaries to ${NAMESPACE} with tag ${TAG}"

  # Check if artifacts directory exists
  if [[ ! -d "artifacts" ]]; then
    log_fatal "Error: artifacts directory not found"
  fi

  # Create a combined tarball of all kubectl binaries
  echo "Creating combined tarball of all kubectl binaries..."
  local combined_tar="kubectl-openebs-all-platforms-${TAG}.tar.gz"

  tar -czf "${combined_tar}" -C artifacts .

  echo "Pushing combined tarball to ${NAMESPACE}:${TAG}"

  oras push "${NAMESPACE}:${TAG}" \
    --artifact-type application/vnd.openebs.kubectl.bundle.v1+tar+gzip \
    "${combined_tar}"

  rm -f "${combined_tar}"

  echo "✓ All kubectl binaries pushed successfully as a single bundle!"
  echo "Bundle available at: ${NAMESPACE}:${TAG}"
}

# Pull kubectl binaries from GHCR
pull_artifacts() {
  echo "Pulling kubectl binaries bundle from ${NAMESPACE} for release ${TAG}"

  echo "Pulling kubectl bundle..."
  oras pull "${NAMESPACE}:${TAG}"

  local bundle_tar="kubectl-openebs-all-platforms-${TAG}.tar.gz"

  if [[ ! -f "$bundle_tar" ]]; then
    log_fatal "Error: Could not find kubectl bundle tarball"
  fi

  echo "Extracting bundle to artifacts directory"

  mkdir -p artifacts/
  tar -xzf "$bundle_tar" -C artifacts/
  rm -f "$bundle_tar"

  echo "Contents of artifacts directory after extraction:"
  ls -la artifacts/

  echo "✓ All kubectl binaries pulled successfully!"
}

main() {
  parse_args "$@"
  login_registry

  case "$ACTION" in
    push)
      push_artifacts
      ;;
    pull)
      pull_artifacts
      ;;
  esac
}

main "$@"
