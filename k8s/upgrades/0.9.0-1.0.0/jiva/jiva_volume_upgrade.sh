#!/bin/bash

################################################################
# STEP: Get Persistent Volume (PV) name as argument            #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################


function on_exit() {
    echo "Clearing temporary files"
    rm jiva-replica-patch.json
    rm jiva-target-patch.json
    rm jiva-target-svc-patch.json
}
trap 'on_exit' EXIT

target_upgrade_version="1.0.0-RC3"
current_version="0.9.0"

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <pv-name>"
    echo
    echo "  <pv-name> Get the PV name using: kubectl get pv"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

pv=$1

# Check if pv exists
kubectl get pv "$pv" &>/dev/null;check_pv=$?
if [ $check_pv -ne 0 ]; then
    echo "$pv not found";exit 1;
fi

# Check if CASType is jiva
cas_type=$(kubectl get pv "$pv" -o jsonpath="{.metadata.annotations.openebs\.io/cas-type}")
if [ "$cas_type" != "jiva" ]; then
    echo "Jiva volume not found";exit 1;
else [ "$cas_type" == "jiva" ];
    echo "$pv is a jiva volume"
fi

ns=$(kubectl get pv "$pv" -o jsonpath="{.spec.claimRef.namespace}")

#################################################################
# STEP: Generate deploy, replicaset and container names from PV #
#                                                               #
# NOTES: Ex: If PV="pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc"   #
#                                                               #
# ctrl-dep: pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc-ctrl       #
#################################################################

c_deploy_name=$(kubectl get deploy -n "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/controller=jiva-controller \
        -o jsonpath="{.items[*].metadata.name}" \
    )
r_deploy_name=$(kubectl get deploy -n "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/replica=jiva-replica \
        -o jsonpath="{.items[*].metadata.name}" \
    )
c_svc_name=$(kubectl get svc -n "$ns" \
        -l openebs.io/persistent-volume="$pv" \
        -o jsonpath="{.items[*].metadata.name}" \
    )
c_con_name=$(kubectl get deploy -n "$ns" "$c_deploy_name" \
        -o jsonpath="{range .spec.template.spec.containers[*]}{@.name}{'\n'}{end}" \
        | grep "ctrl-con" \
    )
r_con_name=$(kubectl get deploy -n "$ns" "$r_deploy_name" \
        -o jsonpath="{range .spec.template.spec.containers[*]}{@.name}{'\n'}{end}" \
        | grep "rep-con" \
    )

# Fetch the older target and replica - ReplicaSet objects which need to be
# deleted before upgrading. If not deleted, the new pods will be stuck in
# creating state - due to affinity rules.

c_rs_old=$(kubectl get rs -o name --namespace "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/controller=jiva-controller \
        | cut -d '/' -f 2 \
    )
r_rs_old_list=$(kubectl get rs -o name --namespace "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/replica=jiva-replica \
        -o jsonpath='{range .items[*]}{@.metadata.name}:{end}' \
    )

################################################################
# STEP: Update patch files with appropriate resource names     #
#                                                              #
# NOTES: Placeholder for resourcename in the patch files are   #
# replaced with respective values derived from the PV in the   #
# previous step                                                #
################################################################

# Check if openebs resources exist and provisioned version is 0.9.0

if [[ -z $c_rs_old ]]; then
    echo "Target Replica set not found"; exit 1;
fi

for r_rs in $(echo "$r_rs_old_list" | tr ":" " "); do
    if [[ -z $r_rs ]]; then
        echo "Replica Replica set not found"; exit 1;
    fi
done

if [[ -z $c_deploy_name ]]; then
    echo "Target deployment not found"; exit 1;
fi

if [[ -z $r_deploy_name ]]; then
    echo "Replica deployment not found"; exit 1;
fi

if [[ -z $c_svc_name ]]; then
    echo "Target service not found"; exit 1;
fi

if [[ -z $r_con_name ]]; then
    echo "Replica container not found"; exit 1;
fi

if [[ -z $c_con_name ]]; then
    echo "Target container not found"; exit 1;
fi

controller_version=$(kubectl get deployment "$c_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [[ "$controller_version" != "$current_version" ]] && \
    [[ "$controller_version" != "$target_upgrade_version" ]]; then
    echo "Current Target deployment $c_deploy_name version is not $current_version or $target_upgrade_version";exit 1;
fi
replica_version=$(kubectl get deployment "$r_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [[ "$replica_version" != "$current_version" ]] && \
    [[ "$replica_version" != "$target_upgrade_version" ]]; then
    echo "Current Replica deployment $r_deploy_name version is not $current_version or $target_upgrade_version";exit 1;
fi

controller_svc_version=$(kubectl get svc "$c_svc_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [[ "$controller_svc_version" != "$current_version" ]] && \
    [[ "$controller_svc_version" != "$target_upgrade_version" ]] ; then
    echo "Current Target service $c_svc_name version is not $current_version or $target_upgrade_version";exit 1;
fi

sed -u "s/@r_name@/$r_con_name/g" jiva-replica-patch.tpl.json \
    | sed -u "s/@target_version@/$target_upgrade_version/g" \
    | sed -u "s/@pv_name@/$pv/g" \
    > jiva-replica-patch.json
sed -u "s/@c_name@/$c_con_name/g" jiva-target-patch.tpl.json \
    | sed -u "s/@target_version@/$target_upgrade_version/g" \
    > jiva-target-patch.json
sed -u "s/@target_version@/$target_upgrade_version/g" jiva-target-svc-patch.tpl.json \
    > jiva-target-svc-patch.json

#Fetch replica count before upgrade
container_name=$(echo "$pv""-ctrl-con")
replication_factor=$(kubectl get deploy "$c_deploy_name" \
-o jsonpath="{.spec.template.spec.containers[?(@.name=='"$container_name"')].env[?(@.name=='REPLICATION_FACTOR')].value}")

#Fetch replica pod node names
before_node_names=$(kubectl get pods \
    -l openebs.io/replica=jiva-replica,openebs.io/persistent-volume="$pv" \
    -o jsonpath='{range .items[*]}{@.spec.nodeName}:{end}')

#################################################################################
# STEP: Patch OpenEBS volume deployments (jiva-target, jiva-replica & jiva-svc) #
#################################################################################

# PATCH JIVA REPLICA DEPLOYMENT ####
if [[ "$replica_version" != "$target_upgrade_version" ]]; then
    echo "Upgrading Replica Deployment to $target_upgrade_version"

    kubectl patch deployment --namespace "$ns" "$r_deploy_name" -p "$(cat jiva-replica-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then 
    echo "Failed to patch the deployment $r_deploy_name | Exit code: $rc"; exit; fi

    for r_rs in $(echo "$r_rs_old_list" | tr ":" " "); do
        kubectl delete rs "$r_rs" --namespace "$ns"
        rc=$?; if [ $rc -ne 0 ]; then 
        echo "Failed to delete replicaset $r_rs | Exit code: $rc"; exit; fi
    done

    rollout_status=$(kubectl rollout status --namespace "$ns" deployment/"$r_deploy_name")
    rc=$?; if [[ ($rc -ne 0) || ! ($rollout_status =~ "successfully rolled out") ]];
    then echo " RollOut for $r_deploy_name failed | Exit code: $rc"; exit; fi
else
    echo "Replica Deployment $r_deploy_name is already at $target_upgrade_version"
fi

# #### PATCH TARGET DEPLOYMENT ####
if [[ "$controller_version" != "$target_upgrade_version" ]]; then
    echo "Upgrading Target Deployment to $target_upgrade_version"

    kubectl patch deployment  --namespace "$ns" "$c_deploy_name" \
        -p "$(cat jiva-target-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then 
    echo "Failed to patch deployment $c_deploy_name | Exit code: $rc"; exit; fi

    kubectl delete rs "$c_rs_old" --namespace "$ns"
    rc=$?; if [ $rc -ne 0 ]; then 
    echo "Failed to deleted replicaset $c_rs_old | Exit code: $rc"; exit; fi

    rollout_status=$(kubectl rollout status --namespace "$ns"  deployment/"$c_deploy_name")
    rc=$?; if [[ ($rc -ne 0) || ! ($rollout_status =~ "successfully rolled out") ]];
    then echo " Failed to patch the deployment | Exit code: $rc"; exit; fi
else
    echo "Controller Deployment $c_deploy_name is already at $target_upgrade_version"

fi

# #### PATCH TARGET SERVICE ####
if [[ "$controller_svc_version" != "$target_upgrade_version" ]]; then
    echo "Upgrading Target Service to $target_upgrade_version"
    kubectl patch service --namespace "$ns" "$c_svc_name" \
        -p "$(cat jiva-target-svc-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then 
    echo "Failed to patch the service $c_svc_name | Exit code: $rc"; exit; 
fi
else
    echo "Controller service $c_svc_name is already at $target_upgrade_version"
fi

#Verifying the upgraded deployment versions
controller_version=$(kubectl get deployment "$c_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [ "$controller_version" != "$target_upgrade_version" ]; then
    echo "Failed to upgrade Target deployment $c_deploy_name labels";exit 1;
fi
replica_version=$(kubectl get deployment "$r_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [ "$replica_version" != "$target_upgrade_version" ]; then
    echo "Failed to upgrade Replica deployment $r_deploy_name labels";exit 1;
fi

#Verifying the upgraded service versions
controller_svc_version=$(kubectl get svc "$c_svc_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [ "$controller_svc_version" != "$target_upgrade_version" ] ; then
    echo "Failed to upgrade Target service $c_svc_name labels";exit 1;
fi

#Verifying the upgraded deployment images
controller_images=$(kubectl get deployment "$c_deploy_name" -n "$ns" \
        -o jsonpath='{range .spec.template.spec.containers[*]}{@.image}?{end}')
for image in $(echo "$controller_images" | tr "?" " "); do
    image_version=$(echo "$image" | cut -d ':' -f 2) 
    if [ $image_version != $target_upgrade_version ] ; then
        echo "Failed to upgrade Controller deployment $c_deploy_name images" ; exit 1; fi
done

replica_images=$(kubectl get deployment "$r_deploy_name" -n "$ns" \
        -o jsonpath='{range .spec.template.spec.containers[*]}{@.image}?{end}')
for image in $(echo "$replica_images" | tr "?" " "); do 
    image_version=$(echo "$image" | cut -d ':' -f 2)
    if [ $image_version != $target_upgrade_version ] ; then
        echo "Failed to upgrade Replica deployment $r_deploy_name images" ; exit 1; fi
done

#Verifying running status of controller and replica pods
running_ctrl_pod_count=$(kubectl get pods \
-l openebs.io/controller=jiva-controller,openebs.io/persistent-volume="$pv" \
--no-headers | wc -l)
if [ "$running_ctrl_pod_count" != 1 ]; then
    echo "Failed to upgrade controller pod not running"; exit 1; fi

running_rep_pod_count=$(kubectl get pods \
-l openebs.io/replica=jiva-replica,openebs.io/persistent-volume="$pv" \
--no-headers | wc -l)
if [ "$running_rep_pod_count" != "$replication_factor" ]; then
    echo "Failed to upgrade replica pods not running"; exit 1; fi

#Verifying registered replica count
retry=0
replica_count=0
while [[ $replica_count != $replication_factor && $retry < 60 ]]
do 
    ctr_pod=$(kubectl get pod -n "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/controller=jiva-controller \
        -o jsonpath="{.items[*].metadata.name}" \
    )
    
    replica_count=$(echo $(kubectl exec -it $ctr_pod --container $container_name \
        -- bash -c "curl -s http://localhost:9501/v1/volumes") \
        | grep -oP '("replicaCount":)[0-9]' | cut -d ':' -f 2
    )
    
    retry=$(( retry+1 ))
    sleep 5
done

if [ $replica_count != $replication_factor ]; then
    echo "Failed to upgrade jiva replicas not registered"; exit 1; fi

#Checking node stickiness
after_node_names=$(kubectl get pods \
    -l openebs.io/replica=jiva-replica,openebs.io/persistent-volume="$pv" \
    -o jsonpath='{range .items[*]}{@.spec.nodeName}:{end}')

for after_node in $(echo "$after_node_names" | tr ":" " "); do 
    count=0
    for before_node in $(echo "$before_node_names" | tr ":" " "); do
        if [ "$after_node" == "$before_node" ]; then
            count=$(( count+1 )) 
            fi
    done
    if [ $count != 1 ]; then
        echo "Node stickiness failed after upgrade"; exit 1; fi 
done           

echo "Successfully upgraded $pv to $target_upgrade_version Please run your application checks."
exit 0
