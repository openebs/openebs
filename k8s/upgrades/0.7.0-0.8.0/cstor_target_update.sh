#!/bin/bash

################################################################
# STEP: Get PV name as argument                               #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################

function usage() {
    echo 
    echo "Usage:"
    echo 
    echo "$0 <pv-name> <openebs-namespace>"
    echo 
    echo "  <pv-name> Get the PV name using: kubectl get pv"
    echo "  <openebs-namespace> Get the namespace where openebs"
    echo "    pods are installed"
    exit 1
}

function setDeploymentRecreateStrategy() {
    ns=$1
    dn=$2
    currStrategy=`kubectl get deploy -n $ns $dn -o jsonpath="{.spec.strategy.type}"`

    if [ $currStrategy = "RollingUpdate" ]; then
       kubectl patch deployment --namespace $ns --type json $dn -p "$(cat patch-strategy-recreate.json)"
       rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi
       echo "Deployment upgrade strategy set as recreate"
    else
       echo "Deployment upgrade strategy was already set as recreate"
    fi
}


if [ "$#" -ne 2 ]; then
    usage
fi

pv=$1
ns=$2

# Get the target deployment for given PV
target_dep=$(kubectl get deploy -n $ns \
 -l openebs.io/persistent-volume=$pv \
 -o jsonpath="{range .items[*]}{@.metadata.name}{end}")

echo "Patching Target Deployment ${target_deploy}"

setDeploymentRecreateStrategy $ns $target_dep

target_rs=$(kubectl get rs -n openebs \
 -l openebs.io/persistent-volume=$pv \
 -o jsonpath="{range .items[?(@.metadata.ownerReferences[0].name=='$target_dep')]}{@.metadata.name}{end}")
echo "$target_dep -> rs is $target_rs"

#fetch the cstor volume uid as cv_uuid
cv_uuid="";cv_uuid=`kubectl get cstorvolume -n $ns $pv -o jsonpath="{.metadata.uid}"`
echo "$target_dep -> cv uuid is $cv_uuid"
if [  -z "$cv_uuid" ];
then
    echo "Error: Unable to fetch cv uuid";
    exit 1
fi

sed "s/@cv_uuid[^ \"]*/$cv_uuid/g" cstor-target-patch.tpl.json > cstor-target-patch.json

kubectl patch deployment --namespace $ns $target_dep -p "$(cat cstor-target-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi
rollout_status=$(kubectl rollout status --namespace $ns deployment/$target_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi
kubectl delete rs $target_rs --namespace $ns
rm cstor-target-patch.json

# Get the target deployment for given PV
target_svc=$(kubectl get service -n $ns \
 -l openebs.io/persistent-volume=$pv \
 -o jsonpath="{range .items[*]}{@.metadata.name}{end}")

echo "Patching Target Service ${target_svc}"
kubectl patch service --namespace $ns $target_svc -p "$(cat cstor-target-svc-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

echo "Successfully upgraded $pv target to 0.8. Please run your application checks."
exit 0

