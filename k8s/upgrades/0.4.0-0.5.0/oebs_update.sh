#!/usr/bin/env bash

################################################################
# STEP: Get Persistent Volume (PV) name as argument            #
#                                                              #
# NOTES: Obtain the pv to upgrade via "kubectl get pv"         #
################################################################

pv=$1

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

c_rs=$(kubectl get rs -o name | grep $c_dep | cut -d '/' -f 2)

################################################################ 
# STEP: Update patch files with appropriate container names    #
#                                                              # 
# NOTES: Placeholder "pvc-<deploy-hash>-ctrl/rep-con in the    #
# patch files are replaced with container names derived from   #
# the PV in the previous step                                  #  
################################################################

sed -i "s/pvc[^ \"]*/$r_name/g" replica.patch.tpl.yml
sed -i "s/pvc[^ \"]*/$c_name/g" controller.patch.tpl.yml

################################################################
# STEP: Patch OpenEBS volume deployments (controller, replica) #  
#                                                              #
# NOTES: Strategic merge patch is used to update the volume w/ #  
# rollout status verification                                  #  
################################################################

# PATCH JIVA REPLICA DEPLOYMENT ####
kubectl patch deployment $r_dep -p "$(cat replica.patch.tpl.yml)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status deployment/$r_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

#### PATCH CONTROLLER DEPLOYMENT ####
kubectl patch deployment $c_dep -p "$(cat controller.patch.tpl.yml)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status deployment/$c_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

################################################################
# STEP: Remove Stale Controller Replicaset                     #
#                                                              # 
# NOTES: This step is applicable upon label selector updates,  #
# where the deployment creates orphaned replicasets            #
################################################################
kubectl delete rs $c_rs 



