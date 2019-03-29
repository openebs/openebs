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


if [ "$#" -ne 1 ]; then
    usage
fi

pv=$1
replica_node_label="openebs-jiva"

pvc=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.name}"`
ns=`kubectl get pv $pv -o jsonpath="{.spec.claimRef.namespace}"`

################################################################ 
# STEP: Generate deploy, replicaset and container names from PV#
#                                                              #
# NOTES: Ex: If PV="pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc", #
#                                                              #
# ctrl-dep: pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc-ctrl      #  
# ctrl-cont: pvc-cec8e86d-0bcc-11e8-be1c-000c298ff5fc-ctrl-con #  
################################################################

c_dep=$(echo $pv-ctrl); c_name=$(echo $c_dep-con)
r_dep=$(echo $pv-rep); r_name=$(echo $r_dep-con)
c_svc=$(echo $c_dep-svc)

# Get the number of replicas configured. 
# This field is currently not used, but can add additional validations
# based on the nodes and expected number of replicas
rep_count=`kubectl get deploy $r_dep --namespace $ns -o jsonpath="{.spec.replicas}"`

# Get the list of nodes where replica pods are running, delimited by ':'
rep_nodenames=`kubectl get pods -n $ns $rep_labels \
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


echo "Patching Replica Deployment upgrade strategy as recreate"
setDeploymentRecreateStrategy $ns $r_dep

echo "Patching Target Deployment upgrade strategy as recreate"
setDeploymentRecreateStrategy $ns $c_dep

# Fetch the older target and replica - ReplicaSet objects which need to be 
# deleted before upgrading. If not deleted, the new pods will be stuck in 
# creating state - due to affinity rules. 
c_rs=$(kubectl get rs -o name --namespace $ns | grep $c_dep | cut -d '/' -f 2)
r_rs=$(kubectl get rs -o name --namespace $ns | grep $r_dep | cut -d '/' -f 2)

################################################################ 
# STEP: Update patch files with appropriate container names    #
#                                                              # 
# NOTES: Placeholder "pvc-<deploy-hash>-ctrl/rep-con in the    #
# patch files are replaced with container names derived from   #
# the PV in the previous step                                  #  
################################################################

sed "s/@replica_node_label[^ \"]*/$replica_node_label/g" jiva-replica-patch.tpl.json > jiva-replica-patch.tpl.json.0
sed "s/@pv-name[^ \"]*/$pv/g" jiva-replica-patch.tpl.json.0 > jiva-replica-patch.tpl.json.1
sed "s/@r_name[^ \"]*/$r_name/g" jiva-replica-patch.tpl.json.1 > jiva-replica-patch.json

sed "s/@c_name[^ \"]*/$c_name/g" jiva-target-patch.tpl.json > jiva-target-patch.json


######################################################################
# STEP: Patch OpenEBS volume deployments (jiva-target, jiva-replica) #  
#                                                                    #
# NOTES: Strategic merge patch is used to update the volume w/       #  
# rollout status verification                                        #  
######################################################################

# PATCH JIVA REPLICA DEPLOYMENT ####
echo "Upgrading Replica Deployment to 0.8"
kubectl patch deployment --namespace $ns $r_dep -p "$(cat jiva-replica-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

kubectl delete rs $r_rs --namespace $ns

rollout_status=$(kubectl rollout status --namespace $ns deployment/$r_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

#### PATCH TARGET DEPLOYMENT ####
echo "Upgrading Target Deployment to 0.8"
kubectl patch deployment  --namespace $ns $c_dep -p "$(cat jiva-target-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

kubectl delete rs $c_rs --namespace $ns

rollout_status=$(kubectl rollout status --namespace $ns  deployment/$c_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi


#### PATCH TARGET SERVICE ####
echo "Upgrading Target Service to 0.8"
kubectl patch service --namespace $ns $c_svc -p "$(cat jiva-target-svc-patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

echo "Clearing temporary files"
rm jiva-replica-patch.tpl.json.0
rm jiva-replica-patch.tpl.json.1
rm jiva-replica-patch.json
rm jiva-target-patch.json

echo "Successfully upgraded $pv to 0.8. Please run your application checks."
exit 0

