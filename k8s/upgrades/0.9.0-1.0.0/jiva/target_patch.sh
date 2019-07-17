#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/../" && pwd )"
source $DIR/util.sh

target_image_1=$(kubectl get deploy -n "$ns" "$c_deploy_name" \
     -o jsonpath="{range .spec.template.spec.containers[0]}{@.image}{'\n'}{end}" \
     | cut -d ':' -f 1)

target_image_2=$(kubectl get deploy -n "$ns" "$c_deploy_name" \
     -o jsonpath="{range .spec.template.spec.containers[1]}{@.image}{'\n'}{end}" \
     | cut -d ':' -f 1)


sed "s/@c_name@/$c_con_name/g" jiva-target-patch.tpl.json \
    | sed "s|@target_image_1@|$target_image_1|g" \
    | sed "s|@target_image_2@|$target_image_2|g" \
    | sed "s/@target_version@/$upgrade_version/g" \
    > upgrade_tmp/jiva-target-patch.json

if [[ "$controller_version" != "$upgrade_version" ]]; then
    # Upgrading target Deployment to $upgrade_version

    patch_status=$(kubectl patch deployment  --namespace "$ns" "$c_deploy_name" \
        -p "$(cat upgrade_tmp/jiva-target-patch.json)" 2>&1)
    rc=$?;
    
    if [ $rc -ne 0 ]; then 
        reason=$(echo "$patch_status" | tr --delete ":")
        patch_upgrade_task_error  "TARGET_UPRADE" "failed to patch deployment "$c_deploy_name"" "$reason"
        exit 1
    fi

    delete_status=$(kubectl delete rs "$c_rs_old" --namespace "$ns" 2>&1);
    rc=$?
    if [ $rc -ne 0 ]; then 
        reason=$(echo "$delete_status" | tr --delete ":")
        patch_upgrade_task_error  "TARGET_UPRADE" "failed to delete replicaset "$c_rs_old"" "$reason"
        exit 1
    fi

    rollout_status=$(kubectl rollout status --namespace "$ns"  deployment/"$c_deploy_name" 2>&1)
    rc=$?; 
    if [[ ($rc -ne 0) || ! ($rollout_status =~ "successfully rolled out") ]]; then
        reason=$(echo "$rollout_status" | tr --delete ":")
        patch_upgrade_task_error  "TARGET_UPRADE" "rollout for deployment $c_deploy_name failed" "$reason"
        exit 1
    fi
else
    echo "controller Deployment $c_deploy_name is already at $upgrade_version"
    exit 0
fi

echo "patched deployment/$c_deploy_name"
exit 0