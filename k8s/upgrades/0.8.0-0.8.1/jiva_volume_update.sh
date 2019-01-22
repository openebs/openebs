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
kubectl get pv $pv &>/dev/null;check_pv=$?
if [ $check_pv -ne 0 ]; then
    echo "$pv not found";exit 1;    
fi

# Check if CASType is jiva
cas_type=`kubectl get pv $pv -o jsonpath="{.metadata.annotations.openebs\.io/cas-type}"`
if [ $cas_type != "jiva" ]; then
    echo "Jiva volume not found";exit 1;
fi

pvc=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.name}"`
ns=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.namespace}"`
sc_name=`kubectl get pv $pv -o jsonpath="{.spec.storageClassName}"`
sc_res_ver=`kubectl get sc $sc_name -n $ns -o jsonpath="{.metadata.resourceVersion}"`

################################################################ 
# STEP: Generate deploy, replicaset and container names from PV#
#                                                              #
# NOTES: Ex: If PV="pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc", #
#                                                              #
# ctrl-dep: pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc-ctrl      # 
################################################################

c_dep=$(echo $pv-ctrl);
r_dep=$(echo $pv-rep);
c_svc=$(echo $c_dep-svc)

# Fetch the older target and replica - ReplicaSet objects which need to be 
# deleted before upgrading. If not deleted, the new pods will be stuck in 
# creating state - due to affinity rules. 

c_rs=$(kubectl get rs -o name --namespace $ns | grep $c_dep | cut -d '/' -f 2)
r_rs=$(kubectl get rs -o name --namespace $ns | grep $r_dep | cut -d '/' -f 2)

################################################################ 
# STEP: Update patch files with appropriate resource names     #
#                                                              # 
# NOTES: Placeholder for resourcename in the patch files are   #
# replaced with respective values derived from the PV in the   #
# previous step                                                #  
################################################################

sed "s/@sc_name/$sc_name/g" jiva-replica-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > jiva-replica-patch.json
sed "s/@sc_name/$sc_name/g" jiva-target-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > jiva-target-patch.json
sed "s/@sc_name/$sc_name/g" jiva-target-svc-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > jiva-target-svc-patch.json

#################################################################################
# STEP: Patch OpenEBS volume deployments (jiva-target, jiva-replica & jiva-svc) #  
#################################################################################

# PATCH JIVA REPLICA DEPLOYMENT ####
echo "Upgrading Replica Deployment to 0.8.1"
kubectl patch deployment --namespace $ns $r_dep -p "$(cat jiva-replica-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

kubectl delete rs $r_rs --namespace $ns
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status --namespace $ns deployment/$r_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

# #### PATCH TARGET DEPLOYMENT ####
echo "Upgrading Target Deployment to 0.8.1"
kubectl patch deployment  --namespace $ns $c_dep -p "$(cat jiva-target-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

kubectl delete rs $c_rs --namespace $ns
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status --namespace $ns  deployment/$c_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi


# #### PATCH TARGET SERVICE ####
echo "Upgrading Target Service to 0.8.1"
kubectl patch service --namespace $ns $c_svc -p "$(cat jiva-target-svc-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

echo "Clearing temporary files"
rm jiva-replica-patch.json
rm jiva-target-patch.json
rm jiva-target-svc-patch.json

echo "Successfully upgraded $pv to 0.8.1 Please run your application checks."
exit 0

