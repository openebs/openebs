#!/bin/bash

################################################################
# STEP: Get Persistent Volume (PV) name as argument            #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################

source ../util.sh

mkdir upgrade_tmp

function on_exit() {
    echo "Clearing temporary files"
    rm -r upgrade_tmp
}
trap 'on_exit' EXIT

upgrade_version="1.0.0"
current_version="0.9.0"

export upgrade_version
export current_version

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <pv-name>"
    echo
    echo "  <pv-name> Get the PV name using: kubectl get pv"
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

pv=$1
upgrade_task=$2
export pv
export upgrade_task

# Check if pv exists
get_status=$(kubectl get pv "$pv" 2>&1);check_pv=$?
if [ $check_pv -ne 0 ]; then
    reason=$(echo $get_status | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi

# Check if CASType is jiva
cas_type=$(kubectl get pv "$pv" -o jsonpath="{.metadata.annotations.openebs\.io/cas-type}")
if [ "$cas_type" != "jiva" ]; then
    reason=$(echo $get_status | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "invalid castype $cas_type"; 
    exit 1
fi

ns=$(kubectl get pv "$pv" -o jsonpath="{.spec.claimRef.namespace}")
export ns

#pre checks for replica

r_deploy_name=$(kubectl get deploy -n "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/replica=jiva-replica \
        -o jsonpath="{.items[*].metadata.name}" 2>&1 )
rc=$?
if [[ $rc -ne 0 ]]; then
    reason=$(echo $r_deploy_name | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi
if [[ -z $r_deploy_name ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "replica deployment not found"; 
    exit 1 
fi
export r_deploy_name

r_con_name=$(kubectl get deploy -n "$ns" "$r_deploy_name" \
        -o jsonpath="{range .spec.template.spec.containers[*]}{@.name}{'\n'}{end}" \
        | grep "rep-con" 2>&1)
rc=$?
if [[ $rc -ne 0 ]]; then
    reason=$(echo $r_con_name | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi
if [[ -z $r_con_name ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "replica conatiner not found"; 
    exit 1 
fi
export r_con_name

r_rs_old_list=$(kubectl get rs -o name --namespace "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/replica=jiva-replica \
        -o jsonpath='{range .items[*]}{@.metadata.name}:{end}' 2>&1)
rc=$?
if [[ $rc -ne 0 ]]; then
    reason=$(echo $r_rs_old_list | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi
for r_rs in $(echo "$r_rs_old_list" | tr ":" " "); do
    if [[ -z $r_rs ]]; then
        patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "replica replicaset not found"
        exit 1
    fi
done
export r_rs_old_list

replica_version=$(kubectl get deployment "$r_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [[ "$replica_version" != "$current_version" ]] && \
    [[ "$replica_version" != "$upgrade_version" ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "Current Replica deployment $r_deploy_name version is not $current_version or $upgrade_version"
    exit 1
fi
export replica_version

#pre checks for target 

c_deploy_name=$(kubectl get deploy -n "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/controller=jiva-controller \
        -o jsonpath="{.items[*].metadata.name}" 2>&1)
rc=$?
if [[ $rc -ne 0 ]]; then
    reason=$(echo $c_deploy_name | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi
if [[ -z $c_deploy_name ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "target deployment not found"
    exit 1
fi
export c_deploy_name

c_con_name=$(kubectl get deploy -n "$ns" "$c_deploy_name" \
        -o jsonpath="{range .spec.template.spec.containers[*]}{@.name}{'\n'}{end}" \
        | grep "ctrl-con" 2>&1)
rc=$?
if [[ $rc -ne 0 ]]; then
    reason=$(echo $c_con_name | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi
if [[ -z $c_con_name ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "target container not found"
    exit 1
fi
export c_con_name

c_rs_old=$(kubectl get rs -o name --namespace "$ns" \
        -l openebs.io/persistent-volume="$pv",openebs.io/controller=jiva-controller \
        | cut -d '/' -f 2 2>&1)
rc=$?
if [[ $rc -ne 0 ]]; then
    reason=$(echo $c_rs_old | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi
if [[ -z $c_rs_old ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "target replicaset not found"
    exit 1
fi
export c_rs_old

controller_version=$(kubectl get deployment "$c_deploy_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [[ "$controller_version" != "$current_version" ]] && \
    [[ "$controller_version" != "$upgrade_version" ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "Current target deployment $c_deploy_name version is not $current_version or $upgrade_version"
    exit 1
fi
export controller_version

#pre checks for target service
c_svc_name=$(kubectl get svc -n "$ns" \
        -l openebs.io/persistent-volume="$pv" \
        -o jsonpath="{.items[*].metadata.name}" 2>&1)
rc=$?
if [[ $rc -ne 0 ]]; then
    reason=$(echo $c_svc_name | tr --delete ":")
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "$reason"; 
    exit 1
fi
if [[ -z $c_svc_name ]]; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "target service not found"
    exit 1
fi
export c_svc_name

controller_svc_version=$(kubectl get svc "$c_svc_name" -n "$ns" \
        -o jsonpath='{.metadata.labels.openebs\.io/version}')
if [[ "$controller_svc_version" != "$current_version" ]] && \
    [[ "$controller_svc_version" != "$upgrade_version" ]] ; then
    patch_upgrade_task_error "$upgrade_task" "PRE_UPGRADE" "failed to upgrade $pv" "Current target service $c_svc_name version is not $current_version or $upgrade_version"
    exit 1
fi
export controller_svc_version

patch_upgrade_task "$upgrade_task" "PRE_UPGRADE" "complete" "Pre-upgrade steps successful"

#Fetch replica pod node names
before_node_names=$(kubectl get pods -n "$ns" \
    -l openebs.io/replica=jiva-replica,openebs.io/persistent-volume="$pv" \
    -o jsonpath='{range .items[*]}{@.spec.nodeName}:{end}')

export before_node_names

#################################################################################
# STEP: Patch OpenEBS volume deployments (jiva-target, jiva-replica & jiva-svc) #
#################################################################################

#### PATCH JIVA REPLICA DEPLOYMENT ####
x=$(bash replica_patch.sh); rc=$?
echo $rc "$x"
if [ $rc -eq 0 ]; then
    patch_upgrade_task "$upgrade_task" "REPLICA_UPGRADE" "complete" "$x"
else 
    exit 1
fi

#### PATCH TARGET DEPLOYMENT ####
x=$(bash target_patch.sh) ; rc=$?
echo $rc "$x"
if [ $rc -eq 0 ]; then
    patch_upgrade_task "$upgrade_task" "TARGET_UPGRADE" "complete" "$x"
else
    exit 1
fi

#### PATCH TARGET SERVICE ####
x=$(bash service_patch.sh) ; rc=$?
echo $rc "$x"
if [ $rc -eq 0 ]; then
    patch_upgrade_task "$upgrade_task" "SERVICE_UPGRADE" "complete" "$x"
else
    exit 1
fi

#### VERFIRY VOLUME UPGRADE ####
x=$(bash verify_volume_upgrade_auto.sh) ; rc=$?
echo $rc "$x"
if [ $rc -eq 0 ]; then
    patch_upgrade_task "$upgrade_task" "VERIFY_UPGRADE" "complete" "$x"
else
    patch_upgrade_task_error "$upgrade_task" "VERIFY_UPGRADE" "upgrade verification failed for $pv" "$x"
    exit 1
fi

exit 0