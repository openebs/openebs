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
 while [ $count -lt $number_of_snapshot ]
 do 
   snapshot_name=$(eval $snapshot_name_cmd | tr -d '\r')
   del_cmd="kubectl exec -it $ctrl_pod_name -n $application_namespace -- jivactl snapshot rm $snapshot_name"
   eval $del_cmd
   count=$((count+1))
   validate_snap_delete $snapshot_name
 done
fi
}

validate_snap_delete()
{
del_snapshot_name=$1
validate_cmd='kubectl exec -it $ctrl_pod_name -n $application_namespace -- jivactl snapshot ls | grep $del_snapshot_name'
eval $validate_cmd
if [ $? == "0" ]; then
 echo "Unable to delete $del_snapshot_name"
 exit 1;
fi
}


if [ $# -ne 3 ]; then
    usage
fi 

delete_jiva_snapshot $1 $2 $3