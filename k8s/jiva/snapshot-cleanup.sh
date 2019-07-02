#!/bin/bash

usage()
{
    echo "Usage: bash script.sh <controller_pod_name> <application_namespace> <numbber_of_snapshots_to_delete>"
    exit 1
}

delete_jiva_snapshot()
{
ctrl_pod_name=$1
application_namespace=$2
number_of_snapshot=$3
count=0
snapshot_list_cmd='kubectl exec -it $ctrl_pod_name -n $application_namespace -- jivactl snapshot ls | grep -v ID | wc -l'
snapshot_name_cmd='kubectl exec -it $ctrl_pod_name -n $application_namespace -- jivactl snapshot ls | grep -v ID | awk 'NR==2''

if [ $(eval $snapshot_list_cmd) -le $((number_of_snapshot)) ]; then
 echo "Provided number of snapshots are not present"
else
 block_service
 while [ $count -lt $number_of_snapshot ]
 do 
   snapshot_name=$(eval $snapshot_name_cmd | tr -d '\r')
   del_cmd="kubectl exec -it $ctrl_pod_name -n $application_namespace -- jivactl snapshot rm $snapshot_name"
   eval $del_cmd
   count=$((count+1))
   validate_snap_delete $snapshot_name
 done
 unblock_service
fi
}

#This fuction is changeing the selector field the of controller service to block connection requests.
block_service()
{
ctrl_service_name=$(kubectl get service -n $application_namespace -l openebs.io/controller-service=jiva-controller-svc -o jsonpath='{.items[0].metadata.name}')
ctrl_val=$(kubectl get svc $ctrl_service_name -n $application_namespace -o jsonpath='{.spec.selector.openebs\.io/controller}')
pv_name=$(kubectl get svc $ctrl_service_name -n $application_namespace -o jsonpath='{.spec.selector.openebs\.io/persistent-volume}')
  
kubectl patch svc $ctrl_service_name -n $application_namespace -p '{"spec":{"selector":{"openebs.io/persistent-volume": "snap-del"}}}'
kubectl patch svc $ctrl_service_name -n $application_namespace -p '{"spec":{"selector":{"openebs.io/controller": "snap-del"}}}'
}

#This fuction is restoring the selector field of the controller service.
unblock_service()
{
kubectl patch svc $ctrl_service_name -n $application_namespace -p "{\"spec\":{\"selector\":{\"openebs.io/persistent-volume\": \"$pv_name\"}}}"
kubectl patch svc $ctrl_service_name -n $application_namespace -p "{\"spec\":{\"selector\":{\"openebs.io/controller\": \"$ctrl_val\"}}}"
}

#This function validates for snapshot deletetion using jivactl
validate_snap_delete()
{
del_snapshot_name=$1
validate_cmd='kubectl exec -it $ctrl_pod_name -n $application_namespace -- jivactl snapshot ls | grep $del_snapshot_name'
eval $validate_cmd
if [ $? == "0" ]; then
 echo "Unable to delete $del_snapshot_name"
 unblock_service ;
 exit 1;
fi
}


if [ $# -ne 3 ]; then
    usage
fi 

delete_jiva_snapshot $1 $2 $3