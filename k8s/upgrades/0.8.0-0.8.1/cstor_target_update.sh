#!/bin/bash

################################################################
# STEP: Get Persistent Volume (PV) name as argument            #
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
    echo "  pods are installed"
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

pv=$1
ns=$2

# Check if pv exists
kubectl get pv $pv &>/dev/null;check_pv=$?
if [ $check_pv -ne 0 ]; then
    echo "$pv not found";exit 1;    
fi

# Check if CASType is cstor
cas_type=`kubectl get pv $pv -o jsonpath="{.metadata.annotations.openebs\.io/cas-type}"`
if [ $cas_type != "cstor" ]; then
    echo "Cstor volume not found";exit 1;
fi

pvc=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.name}"`
sc_ns=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.namespace}"`
sc_name=`kubectl get pv $pv -o jsonpath="{.spec.storageClassName}"`
sc_res_ver=`kubectl get sc $sc_name -n $sc_ns -o jsonpath="{.metadata.resourceVersion}"`

################################################################# 
# STEP: Generate deploy, replicaset and container names from PV #
#                                                               #
# NOTES: Ex: If PV="pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc",  #
#                                                               #
# c-dep: pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc-target        # 
#################################################################

c_dep=$(echo $pv-target)
c_svc=$(echo $pv)
c_vol=$(echo $pv)

# Fetch the older target and replica - ReplicaSet objects which need to be 
# deleted before upgrading. If not deleted, the new pods will be stuck in 
# creating state - due to affinity rules. 

c_rs=$(kubectl get rs -o name --namespace $ns | grep $c_dep | cut -d '/' -f 2)

################################################################ 
# STEP: Update patch files with appropriate resource names     #
#                                                              # 
# NOTES: Placeholder for resourcename in the patch files are   #
# replaced with respective values derived from the PV in the   #
# previous step                                                #  
################################################################

sed "s/@sc_name/$sc_name/g" cstor-target-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > cstor-target-patch.json
sed "s/@sc_name/$sc_name/g" cstor-target-svc-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > cstor-target-svc-patch.json
sed "s/@sc_name/$sc_name/g" cstor-volume-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > cstor-volume-patch.json
sed "s/@sc_name/$sc_name/g" cstor-volume-replica-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > cstor-volume-replica-patch.json

#################################################################################
# STEP: Patch OpenEBS volume deployments (cstor-target, cstor-svc)              #  
#################################################################################


# #### PATCH TARGET DEPLOYMENT ####
echo "Upgrading Target Deployment to 0.8.1"
kubectl patch deployment  --namespace $ns $c_dep -p "$(cat cstor-target-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

kubectl delete rs $c_rs --namespace $ns
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status --namespace $ns  deployment/$c_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi


# #### PATCH TARGET SERVICE ####
echo "Upgrading Target Service to 0.8.1"
kubectl patch service --namespace $ns $c_svc -p "$(cat cstor-target-svc-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

# #### PATCH CSTOR Volume CR ####
echo "Upgrading cstor volume CR to 0.8.1"
kubectl patch cstorvolume --namespace $ns $c_svc -p "$(cat cstor-volume-patch.json)" --type=merge
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

# #### PATCH CSTOR Volume Replica CR ####
echo "Upgrading cstor volume replicas CR to 0.8.1"
replicas=$(kubectl get cvr -n $ns -l cstorvolume.openebs.io/name=$pv -o jsonpath="{range .items[*]}{@.metadata.name};{end}" | tr ";" "\n")

for replica in $replicas
do
    echo "Patching replic: $replica"
    kubectl patch cvr $replica --namespace $ns -p "$(cat cstor-volume-replica-patch.json)" --type=merge
    rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi
    echo "Successfully updated replica: $replica"
done

echo "Clearing temporary files"
rm cstor-target-patch.json
rm cstor-target-svc-patch.json
rm cstor-volume-patch.json
rm cstor-volume-replica-patch.json

echo "Successfully upgraded $pv to 0.8.1 Please run your application checks."
exit 0

