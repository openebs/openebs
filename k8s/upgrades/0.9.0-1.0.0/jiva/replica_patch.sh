#!/bin/bash

source ../util.sh

replica_image=$(kubectl get deploy -n "$ns" "$r_deploy_name" \
    -o jsonpath="{range .spec.template.spec.containers[*]}{@.image}{'\n'}{end}" \
    | cut -d ':' -f 1)

sed "s|@r_name@|$r_con_name|g" jiva-replica-patch.tpl.json \
    | sed "s|@target_version@|$upgrade_version|g" \
    | sed "s|@pv_name@|$pv|g" \
    | sed "s|@replica_image@|$replica_image|g" \
    > upgrade_tmp/jiva-replica-patch.json

# PATCH JIVA REPLICA DEPLOYMENT ####
if [[ "$replica_version" != "$upgrade_version" ]]; then
    # Upgrading Replica Deployment to $upgrade_version

    patch_status=$(kubectl patch deployment --namespace "$ns" "$r_deploy_name"\
    -p "$(cat upgrade_tmp/jiva-replica-patch.json)" 2>&1);rc=$?
    
    if [ $rc -ne 0 ]; then 
        reason=$(echo $patch_status | tr --delete ":")
        patch_upgrade_task_error "$upgrade_task" "REPLICA_UPRADE" "failed to patch the deployment $r_deploy_name" "$reason"; 
        exit 1
    fi

    for r_rs in $(echo "$r_rs_old_list" | tr ":" " "); do
        delete_status=$(kubectl delete rs "$r_rs" --namespace "$ns" 2>&1);rc=$?

        if [ $rc -ne 0 ]; then 
            reason=$(echo $delete_status | tr --delete ":")
            patch_upgrade_task_error "$upgrade_task" "REPLICA_UPRADE" "failed to delete replicaset $r_rs" "$reason"; 
            exit 1
        fi
    done

    rollout_status=$(kubectl rollout status --namespace "$ns" deployment/"$r_deploy_name" 2>&1)
    rc=$?; 
    if [[ ($rc -ne 0) || ! ($rollout_status =~ "successfully rolled out") ]]; then
        reason=$(echo $patch_status | tr --delete ":")
        patch_upgrade_task_error "$upgrade_task" "REPLICA_UPRADE" " rollout for deployment $r_deploy_name failed" "$reason"
        exit 1
    fi
else
    echo "replica deployment $r_deploy_name is already at $upgrade_version"
    exit 0
fi

echo "patched deployment/$r_deploy_name"
exit 0