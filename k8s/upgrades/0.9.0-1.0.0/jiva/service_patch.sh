#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/../" && pwd )"
source $DIR/util.sh

sed "s|@target_version@|$upgrade_version|g" jiva-target-svc-patch.tpl.json \
    > upgrade_tmp/jiva-target-svc-patch.json

if [[ "$controller_svc_version" != "$upgrade_version" ]]; then
    # Upgrading target service to $upgrade_version
    patch_status=$(kubectl patch service --namespace "$ns" "$c_svc_name" \
        -p "$(cat upgrade_tmp/jiva-target-svc-patch.json)" 2>&1);rc=$?
    
    if [ $rc -ne 0 ]; then 
        reason=$(echo $patch_status | tr --delete ":")
        patch_upgrade_task_error  "SERVICE_UPRADE" "failed to patch the service $c_svc_name" "$reason"
        exit 1
    fi
else
    echo "controller service $c_svc_name is already at $upgrade_version"
    exit 0
fi

echo "patched service/$c_svc_name"
exit 0