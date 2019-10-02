#!/bin/bash

################################################################
# STEP: Get Persistent Volume (PV) name as argument            #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################
volume_upgrade_version="v0.8.x-ci"
volume_current_version="0.8.1"

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

##Checking the version of OpenEBS ####
function verify_volume_version() {
    local resource=$1
    local name_res=$2
    local openebs_version=$(kubectl get $resource $name_res -n $ns \
                 -o jsonpath="{.metadata.labels.openebs\.io/version}")

    if [[ $openebs_version != $volume_current_version ]] && [[ $openebs_version != $volume_upgrade_version ]]; then
        echo "Expected version of $name_res in $resource is $volume_current_version but got $openebs_version";exit 1;
    fi
    echo $openebs_version
}

if [ "$#" -ne 2 ]; then
    usage
fi

pv=$1
ns=$2

source snapshotdata_upgrade.sh
# Check if pv exists
kubectl get pv $pv &>/dev/null;check_pv=$?
if [ $check_pv -ne 0 ]; then
    echo "$pv not found";exit 1;
fi

## Get storageclass and PVC related details to patch target service
sc_ns=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.namespace}"`
sc_name=`kubectl get pv $pv -o jsonpath="{.spec.storageClassName}"`
sc_res_ver=`kubectl get sc $sc_name -n $sc_ns -o jsonpath="{.metadata.resourceVersion}"`
pvc_name=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.name}"`
pvc_namespace=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.namespace}"`

# Check if CASType is cstor for PV
cas_type=`kubectl get pv $pv -o jsonpath="{.metadata.labels.openebs\.io/cas-type}"`
if [ $cas_type != "cstor" ]; then
    echo "Cstor volume not found";exit 1;
fi

### 1. Get the cstorvolume name related to the given PV ###
### get the cloned volume cstorvolume name if exists
echo "Upgrading Cstor Volume resource $volume_upgrade_version"
cv_name=$(kubectl get cvr -n openebs\
           -l openebs.io/persistent-volume=$pv\
           -o 'jsonpath={.items[?(@.metadata.labels.openebs\.io/cloned=="true")].metadata.annotations.openebs\.io/source-volume}' | awk '{print $1}')

version=$(verify_volume_version "cstorvolume" $pv)
rc=$?
if [ $rc -ne 0 ]; then
   exit 1
fi

## 2. Update cstorvolume patch file with volume upgrade version.
##    if cstorvolume(cv_name) name is nil, update the patch file only with version
##    details, elsse update patch file with version and source-volume label details
if [ -z $cv_name ]; then
    sed "s|\"openebs.io/source-volume\": \"@sourcevolume@\",||g" cstor-volume-patch.tpl.json |  sed "s|@target_version@|$volume_upgrade_version|g" > cstor-volume-patch.json
     else
    sed "s|@sourcevolume@|$cv_name|g" cstor-volume-patch.tpl.json |  sed "s/@target_version@/$volume_upgrade_version/g" > cstor-volume-patch.json
fi
    ## 3. Patching the cstorvolume resource
    kubectl patch cstorvolume $pv -n $ns -p "$(cat cstor-volume-patch.json)" --type=merge
    rc=$?; if [ $rc -ne 0 ]; then echo "Error occurred while upgrading cstorvolume: $cv_name Exit Code: $rc"; exit; fi

    ## 4. Remove the temporary patch file
    rm cstor-volume-patch.json


### 1. Get the cstorvolume name related to the given PV ###
echo "Upgrading Target Service to $volume_upgrade_version"
c_svc=$(kubectl get svc -n $ns\
          -l openebs.io/persistent-volume=$pv,openebs.io/target-service=cstor-target-svc\
          -o jsonpath="{.items[*].metadata.name}")

version=$(verify_volume_version "service" $pv)
rc=$?
if [ $rc -ne 0 ]; then
   exit 1
fi

    ## 2. Update target svc patch file with upgrade version and pvc name
    ## namespace details
    sed "s/@sc_name@/$sc_name/g" cstor-target-svc-patch.tpl.json | sed "s/@sc_resource_version@/$sc_res_ver/g" | sed "s/@target_version@/$volume_upgrade_version/g" | sed "s/@pvc-name@/$pvc_name/g" | sed "s/@pvc-namespace@/$pvc_namespace/g" > cstor-target-svc-patch.json

    ## 3. Patching the target service
    kubectl patch service --namespace $ns $c_svc -p "$(cat cstor-target-svc-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch service $pv | Exit code: $rc"; exit; fi

rm cstor-target-svc-patch.json

### 1. Get the cvr list which are related to the given PV ###
echo "Upgrading CstorVolume-Replica resource to $volume_upgrade_version"
cvr_list=$(kubectl get cvr -n $ns -l openebs.io/persistent-volume=$pv\
            -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")

rc=$?
if [ $rc -ne 0 ]; then
    echo "Failed to get cstorvolume-replica related to PV $pv"
    exit 1
fi

for cvr in `echo $cvr_list | tr ":" " "`; do
    version=$(verify_volume_version "cvr" $cvr)
    rc=$?
    if [ $rc -ne 0 ]; then
        exit 1
    fi

    ## 2. Update cstorvolume-replica patch file with volume upgrade version
    sed "s/@target_version@/$volume_upgrade_version/g" cstor-volume-replica-patch.tpl.json > cstor-volume-replica-patch.json

    ## 3. Patching the cvr resource
    kubectl patch cvr $cvr --namespace openebs -p "$(cat cstor-volume-replica-patch.json)" --type=merge
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch cstorvolume-replica $cvr | Exit code: $rc"; exit; fi
    echo "Successfully updated cstorvolume-replica: $cvr at $volume_upgrade_version"

    ## 4. Remove the temporary patch file
    rm cstor-volume-replica-patch.json

done

### 1. Get the cstorvolume deployment related to the given PV ###
echo "Upgrading CstorVolume Deployment with new image version $volume_upgrade_version"
cv_deploy=$(kubectl get deploy -n $ns \
         -l openebs.io/persistent-volume=$pv,openebs.io/target=cstor-target \
         -o jsonpath="{.items[*].metadata.name}")

cv_rs=$(kubectl get rs -n $ns -o name \
         -l openebs.io/persistent-volume=$pv | cut -d '/' -f 2)

version=$(verify_volume_version "deploy" $cv_deploy)
    rc=$?
    if [ $rc -ne 0 ]; then
        exit 1
    fi

    ## 2. Update cstorvolume target patch file with volume upgrade version
    sed "s/@target_version@/$volume_upgrade_version/g" cstor-target-patch.tpl.json > cstor-target-patch.json

    ## 3. Update cstorvolume deployment using patch file with upgraded image version
    kubectl patch deployment  --namespace $ns $cv_deploy -p "$(cat cstor-target-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch cstor target deployment $cv_deploy | Exit code: $rc"; exit; fi

    ## 3. Deleting the old replica set corresponding to deployment
    kubectl delete rs $cv_rs --namespace $ns
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to delete cstor replica set $c_rs | Exit code: $rc"; exit; fi

    ## 4. Check the rollout status of a cstorvolume deployment
    rollout_status=$(kubectl rollout status --namespace $ns deployment/$cv_deploy)
    rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
    then echo "Failed to rollout for deployment $c_dep | Exit code: $rc"; exit; fi

    ## 5. Remove the temporary patch file
    rm cstor-target-patch.json

##Patch cstor snapshotdata crs related to pv
run_snapshotdata_upgrades $pv
rc=$?
if [ $rc -ne 0 ]; then
   exit 1
fi

echo "Successfully upgraded $pv to $target_upgrade_version Please run your application checks."
exit 0
