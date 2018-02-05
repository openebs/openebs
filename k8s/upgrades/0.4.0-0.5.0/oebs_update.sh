#!/bin/bash

#### GET PV NAME AS ARGUMENT #### 
pv=$1

#### GENERATE DEPLOY, REPLICASET AND CONTAINER NAMES FROM PV ####
c_dep=$(echo $pv-ctrl); c_name=$(echo $c_dep-con)
r_dep=$(echo $pv-rep); r_name=$(echo $r_dep-con)

c_rs=$(kubectl get rs -o name | grep $c_dep | cut -d '/' -f 2)

#### EDIT PATCH FILES WITH APPROPRIATE CONTAINER NAMES ####
sed -i "s/pvc[^ \"]*/$r_name/g" replica.patch.yml
sed -i "s/pvc[^ \"]*/$c_name/g" controller.patch.yml

#### PATCH JIVA REPLICA DEPLOYMENT ####
kubectl patch deployment $r_dep -p "$(cat replica.patch.yml)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status deployment/$r_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

#### PATCH CONTROLLER DEPLOYMENT ####
kubectl patch deployment $c_dep -p "$(cat controller.patch.yml)"
rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

rollout_status=$(kubectl rollout status deployment/$c_dep)
rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
then echo "ERROR: $rc"; exit; fi

#### REMOVE STALE CONTROLLER REPLICASET #### 
kubectl delete rs $c_rs 



