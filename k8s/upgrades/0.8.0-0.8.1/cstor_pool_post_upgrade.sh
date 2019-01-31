#!/bin/bash

function usage() {
 echo
 echo "Usage:"
 echo
 echo "$0 <spc-name> <openebs-namespace>"
 echo
 echo "  <spc-name> Get the SPC name using: kubectl get spc"
 echo "  <openebs-namespace> Get the namespace where pool pods"
 echo "    corresponding to SPC are deployed"
 exit 1
}

if [ "$#" -ne 2 ]; then
 usage
fi

spc=$1
ns=$2
retry=false

## Fetching the pod names corresponding to spc
running_pool_pods=$(kubectl get po -n $ns -l app=cstor-pool,openebs.io/storage-pool-claim=$spc \
                 -o jsonpath='{range .items[*]}{@.metadata.name}:{end}')

## Setting the quorum enabled in pool pods ###
for pool_pod in `echo $running_pool_pods | tr ":" " "`; do

pool_name=""
cstor_uid=""
cstor_uid="$(kubectl get pod $pool_pod -n $ns \
            -o jsonpath="{.spec.containers[*].env[?(@.name=='OPENEBS_IO_CSTOR_ID')].value}" | awk '{print $1}')"

pool_name="cstor-$cstor_uid"
quorum_set=$(kubectl exec $pool_pod -n $ns -c cstor-pool-mgmt -- zfs set quorum=on $pool_name)
rc=$?
if [[ ($rc -ne 0) ]]; then
 echo "Actual error msg: failed to set quorum=on at $pool_name"
 retry=true
fi

output=$(kubectl exec $pool_pod -n $ns -c cstor-pool-mgmt -- zfs get quorum)
rc=$?
if [ $rc -ne 0 ]; then
 echo "ERROR: while executing zfs get quorum for pool $pool_name, error: $rc"
 retry=true
fi

no_of_non_quorum_vol=$(echo $output | grep -wo off | wc -l)
if [ $no_of_non_quorum_vol -ne 0 ]; then
 echo "Failed to get quorum values from pool $pool_name, error: $rc"
 retry=true
fi

done

if [ $retry == true ]; then
 echo "Post upgrade is failed."
 echo "Please retry by runnig ./$0 $spc $ns"
 exit 1
fi

echo "Post upgrade is done successfully"
