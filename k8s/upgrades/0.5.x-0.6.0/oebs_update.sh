#!/bin/bash

################################################################
# STEP: Get Persistent Volume (PV) name as argument            #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################

if [ "$#" -ne 2 ]; then
    echo 
    echo "Usage:"
    echo 
    echo "$0 <pv-name> <node-label>"
    echo 
    echo "  <pv-name> Get the PV name using: kubectl get pv"
    echo "  <node-label> Label applied to the nodes where replicas of"
    echo "    this PV are present. Get the nodes by running:"
    echo "    kubectl get pods --all-namespaces -o wide | grep <pv-name>"
    exit 1
fi

pv=$1
replica_node_label=$2

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

# Get the number of replicas configured. 
# This field is currently not used, but can add additional validations
# based on the nodes and expected number of replicas
rep_count=`kubectl get deploy $r_dep --namespace $ns -o jsonpath="{.spec.replicas}"`

# Get the list of nodes where replica pods are running, delimited by ':'
rep_nodenames=`kubectl get pods -n $ns $rep_labels \
 -l "vsm=$pv" -l "openebs/replica=jiva-replica" \
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
kubectl patch deployment --namespace $ns --type json $r_dep -p "$(cat patch-strategy-recreate.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

echo "Patching Controller Deployment upgrade strategy as recreate"
kubectl patch deployment --namespace $ns --type json $c_dep -p "$(cat patch-strategy-recreate.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

# Fetch the older controller and replica - ReplicaSet objects which need to be 
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

sed "s/@pvc-name[^ \"]*/$pvc/g" replica.patch.tpl.json > replica.patch.tpl.json.0
sed "s/@replica_node_label[^ \"]*/$replica_node_label/g" replica.patch.tpl.json.0 > replica.patch.tpl.json.1
sed "s/@pv-name[^ \"]*/$pv/g" replica.patch.tpl.json.1 > replica.patch.tpl.json.2
sed "s/@r_name[^ \"]*/$r_name/g" replica.patch.tpl.json.2 > replica.patch.json

sed "s/@pvc-name[^ \"]*/$pvc/g" controller.patch.tpl.json > controller.patch.tpl.json.0
sed "s/@c_name[^ \"]*/$c_name/g" controller.patch.tpl.json.0 > controller.patch.tpl.json.1
sed "s/@rep_count[^ \"]*/$rep_count/g" controller.patch.tpl.json.1 > controller.patch.json

################################################################
# STEP: Patch OpenEBS volume deployments (controller, replica) #  
#                                                              #
# NOTES: Strategic merge patch is used to update the volume w/ #  
# rollout status verification                                  #  
################################################################

# PATCH JIVA REPLICA DEPLOYMENT ####
echo "Upgrading Replica Deployment to 0.6"
kubectl patch deployment --namespace $ns $r_dep -p "$(cat replica.patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

kubectl delete rs $r_rs --namespace $ns

rollout_status=$(kubectl rollout status --namespace $ns deployment/$r_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

#### PATCH CONTROLLER DEPLOYMENT ####
echo "Upgrading Controller Deployment to 0.6"
kubectl patch deployment  --namespace $ns $c_dep -p "$(cat controller.patch.json)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

kubectl delete rs $c_rs --namespace $ns

rollout_status=$(kubectl rollout status --namespace $ns  deployment/$c_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

################################################################
# STEP: Remove Stale Controller Replicaset                     #
#                                                              # 
# NOTES: This step is applicable upon label selector updates,  #
# where the deployment creates orphaned replicasets            #
################################################################

echo "Clearing temporary files"
rm replica.patch.tpl.json.0
rm replica.patch.tpl.json.1
rm replica.patch.tpl.json.2
rm replica.patch.json
rm controller.patch.tpl.json.0
rm controller.patch.tpl.json.1
rm controller.patch.json

echo "Successfully upgraded $pv to 0.6. Please run your application checks."
exit 0

