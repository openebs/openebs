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

function setDeploymentRecreateStrategy() {
    dns=$1 # deployment namespace
    dn=$2  # deployment name
    currStrategy=`kubectl get deploy -n $dns $dn -o jsonpath="{.spec.strategy.type}"`

    if [ $currStrategy = "RollingUpdate" ]; then
       kubectl patch deployment --namespace $dns --type json $dn -p "$(cat patch-strategy-recreate.json)"
       rc=$?; if [ $rc -ne 0 ]; then echo " Upgrade failed | ERROR: $rc"; exit; fi
       echo "Deployment upgrade strategy set as recreate"
    else
       echo "Deployment upgrade strategy was already set as recreate"
    fi
}

if [ "$#" -ne 1 ]; then
    usage
fi

pv=$1
replica_node_label="openebs-jiva"

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

################################################################# 
# STEP: Generate deploy, replicaset and container names from PV #
#                                                               #
# NOTES: Ex: If PV="pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc"   #
#                                                               #
# ctrl-dep: pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc-ctrl       # 
#################################################################

c_dep=$(echo $pv-ctrl)
r_dep=$(echo $pv-rep)
c_svc=$(echo $c_dep-svc)
c_name=$(echo $c_dep-con)
r_name=$(echo $r_dep-con)

# Get the number of replicas configured. 
# This field is currently not used, but can add additional validations
# based on the nodes and expected number of replicas
rep_count=`kubectl get deploy $r_dep --namespace $ns -o jsonpath="{.spec.replicas}"`

# Get the list of nodes where replica pods are running, delimited by ':'
rep_nodenames=`kubectl get pods -n $ns \
 -l "openebs.io/persistent-volume=$pv" -l "openebs.io/replica=jiva-replica" \
 -o jsonpath="{range .items[*]}{@.spec.nodeName}:{end}"`

echo "Checking if the node with replica pod has been labeled with $replica_node_label"
for rep_node in `echo $rep_nodenames | tr ":" " "`; do
    nl="";nl=`kubectl get nodes $rep_node -o jsonpath="{.metadata.labels.openebs-pv-$pv}"`
    if [  -z "$nl" ];
    then
       echo "Labeling $rep_node";
       kubectl label node $rep_node "openebs-pv-${pv}=$replica_node_label"
    fi
done

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

# Check if openebs resources exist and provisioned version is 0.8

kubectl get deployment $c_dep -n $ns &>/dev/null
rc=$?; if [ $rc -ne 0 ]; then echo "Target deployment not found: $rc"; exit; fi

openebs_version=`kubectl get deployment $c_dep -n $ns -o jsonpath='{.metadata.labels.openebs\.io/version}'`
if [ $openebs_version != "0.8.0" ]; then
    echo "Current volumes version is not 0.8.0";exit 1;    
fi

kubectl get deployment $r_dep -n $ns &>/dev/null
rc=$?; if [ $rc -ne 0 ]; then echo "Replica deplyment not found $rc"; exit; fi

kubectl get svc $c_svc -n $ns &>/dev/null
rc=$?; if [ $rc -ne 0 ]; then echo "Service not found: $rc"; exit; fi

sed "s/@sc_name/$sc_name/g" jiva-replica-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" | sed -u "s/@replica_node_label/$replica_node_label/g" | sed -u "s/@r_name/$r_name/g" | sed -u "s/@pv-name/$pv/g" > jiva-replica-patch.json
sed "s/@sc_name/$sc_name/g" jiva-target-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" | sed -u "s/@c_name/$c_name/g" > jiva-target-patch.json
sed "s/@sc_name/$sc_name/g" jiva-target-svc-patch.tpl.json | sed -u "s/@sc_resource_version/$sc_res_ver/g" > jiva-target-svc-patch.json

#################################################################################
# STEP: Patch OpenEBS volume deployments (jiva-target, jiva-replica & jiva-svc) #  
#################################################################################

# PATCH JIVA REPLICA DEPLOYMENT ####
echo "Upgrading Replica Deployment to 0.8.1"

# Setting the update stratergy to recreate
setDeploymentRecreateStrategy $ns $r_dep

kubectl patch deployment --namespace $ns $r_dep -p "$(cat jiva-replica-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "Upgrade failed | ERROR: $rc"; exit; fi

kubectl delete rs $r_rs --namespace $ns
rc=$?; if [ $rc -ne 0 ]; then echo " Upgrade failed | ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status --namespace $ns deployment/$r_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo " Upgrade failed | ERROR: $rc"; exit; fi

# #### PATCH TARGET DEPLOYMENT ####
echo "Upgrading Target Deployment to 0.8.1"

# Setting the update stratergy to recreate
setDeploymentRecreateStrategy $ns $c_dep

kubectl patch deployment  --namespace $ns $c_dep -p "$(cat jiva-target-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo " Upgrade failed | ERROR: $rc"; exit; fi

kubectl delete rs $c_rs --namespace $ns
rc=$?; if [ $rc -ne 0 ]; then echo " Upgrade failed | ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status --namespace $ns  deployment/$c_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo " Upgrade failed | ERROR: $rc"; exit; fi


# #### PATCH TARGET SERVICE ####
echo "Upgrading Target Service to 0.8.1"
kubectl patch service --namespace $ns $c_svc -p "$(cat jiva-target-svc-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo " Upgrade failed | ERROR: $rc"; exit; fi

echo "Clearing temporary files"
rm jiva-replica-patch.json
rm jiva-target-patch.json
rm jiva-target-svc-patch.json

echo "Successfully upgraded $pv to 0.8.1 Please run your application checks."
exit 0

