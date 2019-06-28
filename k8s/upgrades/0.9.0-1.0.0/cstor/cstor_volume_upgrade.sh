#!/bin/bash

################################################################
# STEP: Get Persistent Volume (PV) name as argument            #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################
upgrade_version="1.0.0"
current_version="0.9.0"

source util.sh

function error_msg() {
    echo "Failed to upgrade volume $pv in namespace $ns. Please make sure that volume upgrade should be successful before moving to application checks"
}

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <pv-name> <openebs-namespace>"
    echo
    echo "  <pv-name> Get the PV name using: kubectl get pv"
    echo "  <openebs-namespace> Get the namespace where openebs"
    echo "  pods are installed"
    exit 1
}

function pre_check() {
    local pv=$1
    local ns=$2
    local pod_version=""
    local csp_name=""
    local pod_name=""
    local csp_list=""
    local spc_name=""
    csp_list=$(kubectl get cvr -n $ns \
          -l openebs.io/persistent-volume=$pv \
          -o jsonpath="{range .items[*]}{@.metadata.labels.cstorpool\.openebs\.io/name};{end}" | tr ";" " ")
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get csp list | Exit code: $rc"; exit 1; error_msg; fi

    for csp_name in $csp_list; do
        pod_name=$(kubectl get pod -n $ns \
              -l app=cstor-pool,openebs.io/cstor-pool=$csp_name \
              -o jsonpath="{.items[0].metadata.name}")
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get pool pod name of csp: $csp_name | Exit code: $rc"; exit 1; error_msg; fi

        pod_version=$(verify_openebs_version "pod" "$pod_name" "$ns")
        rc=$?
        if [ $rc -ne 0 ]; then
            error_msg
            exit 1
        fi
        if [ $pod_version != $upgrade_version ]; then
            spc_name=$(kubectl get csp $csp_name \
                  -o jsonpath="{.metadata.labels.openebs\.io/storage-pool-claim}")
            echo "Pre-checks failed. Please upgrade pool: $spc_name before upgrading the volume $pv in namespace $ns"
            error_msg
            exit 1
        fi
    done
}

if [ "$#" -ne 2 ]; then
    usage
fi

pv=$1
ns=$2

# Check if pv exists
kubectl get pv $pv &>/dev/null;check_pv=$?
if [ $check_pv -ne 0 ]; then
    echo "$pv not found"; error_msg; exit 1;
fi

# Check if CASType is cstor
cas_type=`kubectl get pv $pv -o jsonpath="{.metadata.annotations.openebs\.io/cas-type}"`
if [ $cas_type != "cstor" ]; then
    echo "Cstor volume not found";exit 1;
elif [ $cas_type == "cstor" ]; then
    echo "$pv is a cstor volume"
else
    echo "Volume is neither cstor or cstor"; exit 1;
fi

pvc_name=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.name}"`
pvc_namespace=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.namespace}"`
#################################################################
# STEP: Generate deploy, replicaset and container names from PV #
#                                                               #
# NOTES: Ex: If PV="pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc",  #
#                                                               #
# c-dep: pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc-target        #
#################################################################

c_dep=$(kubectl get deploy -n $ns \
        -l openebs.io/persistent-volume=$pv,openebs.io/target=cstor-target \
        -o jsonpath="{.items[*].metadata.name}")
c_svc=$(kubectl get svc -n $ns \
        -l openebs.io/persistent-volume=$pv,openebs.io/target-service=cstor-target-svc \
        -o jsonpath="{.items[*].metadata.name}")
c_vol=$(kubectl get cstorvolumes \
        -l openebs.io/persistent-volume=$pv -n $ns \
        -o jsonpath="{.items[*].metadata.name}")
c_replicas=$(kubectl get cvr -n $ns \
        -l openebs.io/persistent-volume=$pv \
        -o jsonpath="{range .items[*]}{@.metadata.name};{end}" | tr ";" "\n")

# Fetch the older target and replica - ReplicaSet objects which need to be
# deleted after upgrading. If not deleted, the new pods will be stuck in
# creating state - due to affinity rules.

c_rs=$(kubectl get rs -n $ns -o name -l openebs.io/persistent-volume=$pv | cut -d '/' -f 2)


# Check if openebs resources exist and provisioned version is 0.9

if [[ -z $c_rs ]]; then
    echo "Target Replica set not found"; error_msg; exit 1;
fi

if [[ -z $c_dep ]]; then
    echo "Target deployment not found"; error_msg; exit 1;
fi

if [[ -z $c_svc ]]; then
    echo "Target svc not found"; error_msg; exit 1;
fi

if [[ -z $c_vol ]]; then
    echo "CstorVolumes CR not found"; error_msg; exit 1;
fi

if [[ -z $c_replicas ]]; then
    echo "Cstor Volume Replica CR not found"; error_msg; exit 1;
fi

controller_version=`kubectl get deployment $c_dep -n $ns -o jsonpath='{.metadata.labels.openebs\.io/version}'`
if [[ "$controller_version" != "$current_version" ]] && [[ "$controller_version" != "$upgrade_version" ]] ; then
    echo "Current cstor target deloyment $c_dep version is not $current_version or $upgrade_version"
    error_msg
    exit 1
fi

controller_service_version=`kubectl get svc $c_svc -n $ns -o jsonpath='{.metadata.labels.openebs\.io/version}'`
if [[ "$controller_service_version" != "$current_version" ]] && [[ "$controller_service_version" != "$upgrade_version" ]]; then
    echo "Current cstor target service $c_svc version is not $current_version or $upgrade_version"
    error_msg
    exit 1
fi

cstor_volume_version=`kubectl get cstorvolumes $c_vol -n $ns -o jsonpath='{.metadata.labels.openebs\.io/version}'`
if [[ "$cstor_volume_version" != "$current_version" ]] && [[ "$cstor_volume_version" != "$upgrade_version" ]]; then
    echo "Current cstor volume  $c_vol version is not $current_version or $upgrade_version"; error_msg; exit 1;
fi

for replica in $c_replicas
do
    replica_version=`kubectl get cvr $replica -n $ns -o jsonpath='{.metadata.labels.openebs\.io/version}'`
    if [[ "$replica_version" != "$current_version" ]] && [[ "$replica_version" != "$upgrade_version" ]]; then
        echo "CStor volume replica $replica version is not $current_version"; error_msg; exit 1;
    fi
done


################################################################
# STEP: Update patch files with appropriate resource names     #
#                                                              #
# NOTES: Placeholder for resourcename in the patch files are   #
# replaced with respective values derived from the PV in the   #
# previous step                                                #
################################################################

sed "s/@target_version@/$upgrade_version/g" cstor-target-patch.tpl.json > cstor-target-patch.json
sed "s/@target_version@/$upgrade_version/g" cstor-target-svc-patch.tpl.json > cstor-target-svc-patch.json
sed "s/@target_version@/$upgrade_version/g" cstor-volume-patch.tpl.json > cstor-volume-patch.json
sed "s/@target_version@/$upgrade_version/g" cstor-volume-replica-patch.tpl.json> cstor-volume-replica-patch.json

#################################################################################
# STEP: Patch OpenEBS volume deployments (cstor-target, cstor-svc)              #
#################################################################################


# #### PATCH TARGET DEPLOYMENT ####

if [[ "$controller_version" != "$upgrade_version" ]]; then
    echo "Upgrading Target Deployment to $upgrade_version"

    kubectl patch deployment  --namespace $ns $c_dep -p "$(cat cstor-target-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch cstor target deployment $c_dep | Exit code: $rc"; error_msg; exit 1; fi

    kubectl delete rs $c_rs --namespace $ns
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to delete cstor replica set $c_rs | Exit code: $rc"; error_msg; exit 1; fi

    rollout_status=$(kubectl rollout status --namespace $ns  deployment/$c_dep)
    rc=$?; if [[ ($rc -ne 0) || ! ($rollout_status =~ "successfully rolled out") ]];
    then echo "Failed to rollout for deployment $c_dep | Exit code: $rc"; error_msg; exit 1; fi
else
    echo "Target deployment $c_dep is already at $upgrade_version"
fi

# #### PATCH TARGET SERVICE ####
if [[ "$controller_service_version" != "$upgrade_version" ]]; then
    echo "Upgrading Target Service to $upgrade_version"
    kubectl patch service --namespace $ns $c_svc -p "$(cat cstor-target-svc-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch service $svc | Exit code: $rc"; error_msg; exit 1; fi
else
    echo "Target service $c_svc is already at $upgrade_version"
fi

# #### PATCH CSTOR Volume CR ####
if [[ "$cstor_volume_version" != "$upgrade_version" ]]; then
    echo "Upgrading cstor volume CR to $upgrade_version"
    kubectl patch cstorvolume --namespace $ns $c_vol -p "$(cat cstor-volume-patch.json)" --type=merge
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch cstor volumes CR $c_vol | Exit code: $rc"; error_msg; exit 1; fi
else
    echo "CStor volume CR  $c_vol is already at $upgrade_version"
fi

# #### PATCH CSTOR Volume Replica CR ####

for replica in $c_replicas
do
    if [[ "`kubectl get cvr $replica -n $ns -o jsonpath='{.metadata.labels.openebs\.io/version}'`" != "$upgrade_version" ]]; then
        echo "Upgrading cstor volume replica $replica to $upgrade_version"
        kubectl patch cvr $replica --namespace $ns -p "$(cat cstor-volume-replica-patch.json)" --type=merge
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch CstorVolumeReplica $replica | Exit code: $rc"; error_msg; exit 1; fi
        echo "Successfully updated replica: $replica"
    else
        echo "cstor replica  $replica is already at $upgrade_version"
    fi
done

echo "Clearing temporary files"
rm cstor-target-patch.json
rm cstor-target-svc-patch.json
rm cstor-volume-patch.json
rm cstor-volume-replica-patch.json

echo "Upgrade steps are done on volume $pv"

./verify_volume_upgrade.sh $pv $ns
rc=$?
if [ $rc -eq 0 ]; then
    echo "Verification of volume $pv upgrade is successful. Please run your application checks"
fi
