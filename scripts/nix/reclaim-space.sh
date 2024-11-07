#!/usr/bin/env sh

#
# The script tries to free as much space as possible by removing nix packages
# and docker images that aren't used.
#

set -e

MIN_FREE_GIB=$1

get_avail_gib() {
    echo $(( $(df --output=avail / | awk 'NR == 2 { print $1 }' ) / 1024 / 1024 ))
}

free=$(get_avail_gib)
echo "Available space in root partition: $free GiB"

if [ -n "$MIN_FREE_GIB" ]; then
    if [ "$free" -gt "$MIN_FREE_GIB" ]; then
        exit 0
    fi
fi

set -x
nix-collect-garbage
docker image prune --force --all
set +x

echo "Available space after cleanup: $(get_avail_gib) GiB"
