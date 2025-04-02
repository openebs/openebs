#!/usr/bin/env bash

set -euo pipefail

# Path to the script to be tested
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
SCRIPT_TO_TEST="$SCRIPT_DIR/update-chart-version.sh"
FAILED=

# Function to run a test case
run_test() {
  local test_name=$1
  local expected_output=$2
  shift 2
  local output

  echo "Running: $test_name"
  set +e
  output=$("$SCRIPT_TO_TEST" "$@" 2>&1)
  set -e
  if [ "$output" == "$expected_output" ]; then
    echo "PASS"
  else
    echo "FAIL"
    echo "Expected: $expected_output"
    echo "Got: $output"
    FAILED=1
  fi
  echo "----------------------------------------"
}

# Define test cases
run_test "Test 1: On branch creation, version to be reflected on release branch" \
         "1.2.0-prerelease" \
         --branch "release/1.2" --type "release" --dry-run --chart-version "1.2.0-develop"

run_test "Test 2: On branch creation, version to be reflected on develop branch" \
         "1.3.0-develop" \
         --branch "release/1.2" --type "develop" --dry-run --chart-version "1.2.0-prerelease"

run_test "Test 3: After branch creation on push, version to be reflected on release branch" \
         "" \
         --branch "release/1.2" --type "release" --dry-run --chart-version "1.2.0-prerelease"

run_test "Test 4: After branch creation on push, version to be reflected on develop branch" \
         "" \
         --branch "release/1.2" --type "develop" --dry-run --chart-version "1.3.0-develop"

run_test "Test 5: On branch creation, version to be reflected on release branch, x.y is newer" \
         "1.5.0-prerelease" \
         --branch "release/1.5" --type "release" --dry-run --chart-version "1.2.0-develop"

run_test "Test 6: On branch creation, version to be reflected on develop branch, x.y is newer" \
         "1.6.0-develop" \
         --branch "release/1.5" --type "develop" --dry-run --chart-version "1.2.0-develop"

run_test "Test 7: On branch creation, version to be reflected on release branch, x.y is older" \
         "1.2.0-prerelease" \
         --branch "release/1.2" --type "release" --dry-run --chart-version "1.5.0-develop"

run_test "Test 8: On branch creation, version to be reflected on develop branch, x.y is older" \
         "" \
         --branch "release/1.2" --type "develop" --dry-run --chart-version "1.5.0-develop"

run_test "Test 9: On tag creation, version to be reflected on release/x.y branch" \
         "1.2.1-prerelease" \
         --tag "v1.2.0" --dry-run --chart-version "1.2.0-prerelease"

run_test "Test 10: On tag creation, version to be reflected on release/x.y branch, tag is in future" \
         "For release/x.y branch the current chart version(1.2.0-prerelease)'s X.Y must exactly match X.Y from tag (1.5.0)" \
         --tag "v1.5.0" --dry-run --chart-version "1.2.0-prerelease"

run_test "Test 11: On tag creation, version to be reflected on release/x.y branch, tag is in past" \
         "For release/x.y branch the current chart version(1.2.0-prerelease)'s X.Y must exactly match X.Y from tag (1.0.0)" \
         --tag "v1.0.0" --dry-run --chart-version "1.2.0-prerelease"

run_test "Test 12: On tag creation, version to be reflected on release/x.y branch, the current chart version is not prerelease" \
         "Chart version(1.2.0-develop) should be a prerelease format to proceed for tag creation flow" \
         --tag "v1.0.0" --dry-run --chart-version "1.2.0-develop"

run_test "Test 13: rc tag, with chart type prerelease" \
         "" \
         --tag "v1.2.3-rc" --dry-run --chart-version "1.2.3-prerelease"

run_test "Test 14: Actual release tag to modify the chart versions" \
         "1.2.3" \
         --tag "v1.2.3" --dry-run --chart-version "1.2.3-prerelease" --publish-release

run_test "Test 15: Actual release rc tag to modify the chart versions" \
         "1.2.3-rc" \
         --tag "v1.2.3-rc" --dry-run --chart-version "1.2.3-prerelease" --publish-release

if [ -n "$FAILED" ]; then
  echo "Some of the tests have failed..."
  exit 1
fi
