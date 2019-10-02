#!/bin/bash
usage()
{
    echo "Usage: ./ snapshot-cleanup.sh <pv-name> <number_of_snapshots_to_delete>"
    exit 1
}

warning()
{
    echo "WARNING: Snapshot cleanup involves disconnecting the application from the storage. Also, while the snapshot cleanup is in progress - you will need to ensure that the connectivity to the Kubernetes Clusters is active. In case of unexpected disconnect, you will have to run the following command to restore the volume service. snapshot-cleanup.sh <pv-name> restore_service."
    echo "Do you want to continue (Y/N)"
    read access
    if [ $access == "N" ] || [ $access == "n" ]; then
    exit 1;
    fi
}

# spin prints ('|','/','-','\','|') in cyclic order while snapshot deletion is in progress.
spin()
{
    while true
    do
      stat /proc/$pid > /dev/null
      if [ $? -ne 0 ]
      then
          break
      fi
      printf "\b${sp:i++%${#sp}:1}"
      sleep 1
    done
}

# delete_jiva_snapshot deletes jiva-snapshots(based on the arguments passed for number of snapshots to be deleted) using jivactl 
delete_jiva_snapshot()
{   
    warning
    min_required_snapshot=4
    count=0
    
    snapshot_list_cmd=$(kubectl exec -it $ctrl_pod_name -n $pvc_namespace -- jivactl snapshot ls)
    if [ "$?" != "0" ]; then
       exit 1;
    fi

    snapshot_number_cmd="kubectl exec -it $ctrl_pod_name -n $pvc_namespace -- jivactl snapshot ls | grep -v ID | wc -l"
    snapshot_name_cmd="kubectl exec -it $ctrl_pod_name -n $pvc_namespace -- jivactl snapshot ls | grep -v ID | tail -1"
    
    if [ $(eval $snapshot_number_cmd) -lt $min_required_snapshot ]; then
        echo "Error: You can initiate snapshot deletion only when the volume has more than $min_required_snapshot snapshots. There are only $(eval $snapshot_number_cmd) snapshots at the moment. You need not cleanup any more snapshots."
        exit 1;
    fi

    if [ $(eval $snapshot_number_cmd) -le $number_of_snapshot ]; then
        echo "Error: You have requested to delete $number_of_snapshot. There are only $(($(eval $snapshot_number_cmd) - $min_required_snapshot)) snapshot available that can be deleted on this volume. Please re-run this command with by specifying the number of snapshots to be deleted as $(($(eval $snapshot_number_cmd) - $min_required_snapshot)) or less."
        exit 1 ;
    else
            if [ $(eval $snapshot_number_cmd) -ge $(($min_required_snapshot + $number_of_snapshot)) ]; then
                block_service
                echo "Deleting snapshots"
                delete_snap > /dev/null 2&>1 &
                pid=$!
                spin
                cat log.txt
                unblock_service
                rm -rf log.txt
            else
                echo "Error: You have requested to delete $number_of_snapshot. There are only $(($(eval $snapshot_number_cmd) - $min_required_snapshot)) snapshot available that can be deleted on this volume. Please re-run this command with by specifying the number of snapshots to be deleted as $(($(eval $snapshot_number_cmd) - $min_required_snapshot)) or less." ;
            fi
        fi
}

# block_service changes target port value with different value
# To restrict io's to happen
block_service()
{
    kubectl patch svc $ctrl_service_name -n $pvc_namespace --type merge -p "$(cat tmp.json)"  
}


# unblock_service restores the actual target port value to allow io's
unblock_service()
{
    restart_ctrl
    sed -i 's/50000/3260/g' tmp.json
    kubectl patch svc $ctrl_service_name -n $pvc_namespace --type merge -p "$(cat tmp.json)"
    rm tmp.json
}

# restart_ctrl restart the controller pod
restart_ctrl()
{
    kubectl delete pod $ctrl_pod_name -n $pvc_namespace
}

validate_snap_delete()
{
    del_snapshot_name=$1
    validate_cmd="kubectl exec -it $ctrl_pod_name -n $pvc_namespace -- jivactl snapshot ls | grep $del_snapshot_name"
    eval $validate_cmd
    if [ $? == "0" ]; then
        echo "Unable to delete $del_snapshot_name" ;
        unblock_service ;
        exit 1;
    fi
}

delete_snap()
{
    while [ $count -lt $number_of_snapshot ]
    do
       snapshot_name=$(eval $snapshot_name_cmd | tr -d '\r')
       del_cmd="kubectl exec -it $ctrl_pod_name -n $pvc_namespace -- jivactl snapshot rm $snapshot_name"
       eval $($del_cmd >> log.txt)
       count=$((count+1))
       validate_snap_delete $snapshot_name 
    done 
}
 
i=1
sp="/-\|"
echo -n ' '
touch log.txt
rm -rf tmp.json 
cat patch.json > tmp.json 
pv_name=$1
number_of_snapshot=$2
pvc_namespace=$(kubectl get pv $pv_name -o jsonpath='{.spec.claimRef.namespace}')
ctrl_pod_name=$(kubectl get pod -n $pvc_namespace -l openebs.io/persistent-volume=$pv_name,openebs.io/controller=jiva-controller -o jsonpath='{.items[0].metadata.name}')
ctrl_service_name=$(kubectl get service -n $pvc_namespace -l openebs.io/controller-service=jiva-controller-svc,openebs.io/persistent-volume=$pv_name -o jsonpath='{.items[0].metadata.name}')

    
if [ $# -ne 2 ]; then
    usage
elif [ $# -eq 2 ] && [ $2 == "restore_service" ]; then
    unblock_service ;
    exit 1
elif [ $# -eq 2 ] && [ $2 != "restore_service" ]; then
    if [ $2 -ge 0 2>/dev/null ]; then
       delete_jiva_snapshot $1 $2 ;
    else
       usage
    fi
fi