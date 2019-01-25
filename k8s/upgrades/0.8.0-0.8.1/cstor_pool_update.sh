#!/bin/bash
set -e

##################################################################
# STEP: Get SPC name as argument                                 #
#                                                                #
# NOTES: Obtain the pool deployments to perform upgrade operation#
##################################################################

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

##Checking the version of OpenEBS ####
openebs_version=$(kubectl get csp -o jsonpath="{.items[0].metadata.labels.openebs\.io/version}")
if [ $openebs_version != "0.8.0" ]; then
		echo "Current replica version is not 0.8.0";exit 1;
fi

###Get the no.of pool pods are running #######
pool_cnt=$(kubectl get po -n $ns -l app=cstor-pool -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'| wc -w)

# Get the list of pool deployments for given SPC, delimited by ':'
pool_deploys=`kubectl get deploy -n $ns \
 -l app=cstor-pool,openebs.io/storage-pool-claim=$spc \
 -o jsonpath="{range .items[*]}{@.metadata.name}:{end}"`

echo "Patching the csp resource"
for csp_res in `echo $pool_deploys | tr ":" " "`; do
		kubectl patch csp $csp_res -p "$(cat csp_patch.json)" --type=merge
		rc=$?; if [ $rc -ne 0 ]; then echo "Error occured while applying the patch for $csp_res Exit Code: $rc"; exit; fi
done

echo "Patching Pool Deployment with new image"
for pool_dep in `echo $pool_deploys | tr ":" " "`; do

		## Get the node name of the corresponding deployments
		node_name_bfr_upg=$(kubectl get deploy -n $ns $pool_dep -o jsonpath='{.spec.template.spec.nodeSelector.kubernetes\.io/hostname}')
		pool_rs=$(kubectl get rs -n openebs \
     -o jsonpath="{range .items[?(@.metadata.ownerReferences[0].name=='$pool_dep')]}{@.metadata.name}{end}")
    echo "$pool_dep -> rs is $pool_rs"

    #fetch the csp_uuid
    csp_uuid="";csp_uuid=`kubectl get csp -n $ns $pool_dep -o jsonpath="{.metadata.uid}"`
    echo "$pool_dep -> csp uuid is $csp_uuid"
    if [  -z "$csp_uuid" ];
    then
       echo "Error: Unable to fetch csp uuid";
       exit 1
    fi

    sed "s/@csp_uuid[^ \"]*/$csp_uuid/g" cstor-pool-patch.tpl.json > cstor-pool-patch.json

    kubectl patch deployment --namespace $ns $pool_dep -p "$(cat cstor-pool-patch.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi
    rollout_status=$(kubectl rollout status --namespace $ns deployment/$pool_dep)
    rc=$?; if [[ ($rc -ne 0) || !($rollout_status =~ "successfully rolled out") ]];
    then echo "ERROR: $rc"; exit; fi
    kubectl delete rs $pool_rs --namespace $ns

		node_name_aftr_upg=$(kubectl get deploy -n $ns $pool_dep -o jsonpath='{.spec.template.spec.nodeSelector.kubernetes\.io/hostname}')
		if [ $node_name_bfr_upg != $node_name_aftr_upg ]
		then
				echo "Pool is migrated to different node expected node: $node_name_bfr_upg and got: $node_name_aftr_upg"
				exit 1
		fi
    rm cstor-pool-patch.json

done

## Cross check whether the pods are in running status or not if not wait untill it comes to running####
while [ true ]
do
		cnt_aft_upg=$(kubectl get po -n $ns -l app=cstor-pool \
						       -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
		if [ $cnt_aft_upg -eq $pool_cnt ]
		then
				break
		else
			  sleep 5
		fi
done

## Fetching the Running pod names
running_pool_pods=$(kubectl get po -n $ns -l app=cstor-pool -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'| tr " " "\n")

## Setting the quorum enabled in the new pool pods ###
for pool_pod in $running_pool_pods
do
		pool_name=""
		cstor_uid=""
		cstor_uid="$(kubectl get pod $pool_pod -n $ns -o jsonpath="{.spec.containers[*].env[?(@.name=='OPENEBS_IO_CSTOR_ID')].value}" | awk '{print $1}')"
		pool_name="cstor-$cstor_uid"
		quorum_set=$(kubectl exec $pool_pod -n $ns -c cstor-pool-mgmt -- zfs set quorum=on $pool_name)
		rc=$?
		if [[ ($rc -ne 0) ]]; then
				echo "Actual error msg: failed to set quorum=on at $pool_name: exit code: $rc"; exit 1; fi

		output=$(kubectl exec $pool_pod -n $ns -c cstor-pool-mgmt -- zfs get quorum)
    rc=$?
		if [ $rc -ne 0 ]; then
				echo "ERROR: while executing zfs get quorum for pool $pool_name. Exit code: $rc"
		exit 1; fi

		no_of_non_quorum_vol=$(echo $output | grep -wc off)
		if [ $no_of_non_quorum_vol -ne 0 ]; then
				echo "Failed to get quorum values from pool $pool_name, exit code: $rc"
		 exit 1; fi
done

echo "Successfully upgraded $spc to 0.8.1 Please run your application checks."
exit 0
