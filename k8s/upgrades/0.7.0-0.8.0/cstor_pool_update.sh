#!/bin/bash

################################################################
# STEP: Get SPC name as argument                               #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################

function usage() {
    echo 
    echo "Usage:"
    echo 
    echo "$0 <spc-name> <openebs-namespace>"
    echo 
    echo "  <spc-name> Get the SPC name using: kubectl get spc"
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

spc=$1
ns=$2

# Get the list of pool deployments for given SPC, delimited by ':'
pool_deploys=`kubectl get deploy -n $ns \
 -l openebs.io/storage-pool-claim=$spc \
 -o jsonpath="{range .items[*]}{@.metadata.name}:{end}"`

echo "Patching Pool Deployment upgrade strategy as recreate"
for pool_dep in `echo $pool_deploys | tr ":" " "`; do
    setDeploymentRecreateStrategy $ns $pool_dep
done


echo "Patching Pool Deployment with new image"
for pool_dep in `echo $pool_deploys | tr ":" " "`; do
    pool_rs=$(kubectl get rs -n openebs \
 -o jsonpath="{range .items[?(@.metadata.ownerReferences[0].name=='$pool_dep')]}{@.metadata.name}{end}")
    echo "$pool_dep -> rs is $pool_rs"

    #fetch the csp_uuid
    csp_uuid="";csp_uuid=`kubectl get csp -n $ns $pool_dep -o jsonpath="{.metadata.uid}"`
    echo "$pool_dep -> csp uuid is $csp_uuid"
    if [  -z "$csp_uuid" ];
    then
       echo "Error: Unable to fetch csp uuid";
       exit 1
    fi

    sed "s/@csp_uuid[^ \"]*/$csp_uuid/g" cstor-pool-patch.tpl.json > cstor-pool-patch.json

    kubectl patch deployment --namespace $ns $pool_dep -p "$(cat cstor-pool-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi
    rollout_status=$(kubectl rollout status --namespace $ns deployment/$pool_dep)
    rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
    then echo "ERROR: $rc"; exit; fi
    kubectl delete rs $pool_rs --namespace $ns
    rm cstor-pool-patch.json
done

echo "Successfully upgraded $spc to 0.8. Please run your application checks."
exit 0

