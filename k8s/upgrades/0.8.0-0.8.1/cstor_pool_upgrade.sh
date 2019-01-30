#!/bin/bash

###########################################################################
# STEP: Get SPC name and namespace where OpenEBS is deployed as arguments #                               #
#                                                                         #
# NOTES: Obtain the pool deployments to perform upgrade operation         #
###########################################################################

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

##Checking the version of OpenEBS ####
function check_version_openebs() {
		local resource=$1
		local name_res=$2
		if [ $resource == "deploy" ]; then
			local namespace=$3
			local openebs_version=$(kubectl get $resource $name_res -n $namespace -o jsonpath="{.metadata.labels.openebs\.io/version}")
		else
			local openebs_version=$(kubectl get $resource $name_res -o jsonpath="{.metadata.labels.openebs\.io/version}")
		fi

		if [ $openebs_version == "0.8.1" ]; then
			echo "The $name_res in $resource has been upgraded"
			skip_upgrade=false
		elif [ $openebs_version != "0.8.0" ]; then
			echo "Current cStor pool version is not 0.8.0";exit 1;
		fi
}

## Starting point
if [ "$#" -ne 2 ]; then
		usage
fi

spc=$1
ns=$2
skip_upgrade=true

### Check is there any deployment pods are in Pending state which are related to provided spc ###
pending_pods=$(kubectl get po -n $ns -l app=cstor-pool,openebs.io/storage-pool-claim=$spc -o jsonpath='{.items[?(@.status.phase=="Pending")].metadata.name}')

## Check if any deployments pods are in pending state then exit the upgrade process ###
if [ $(echo $pending_pods | wc -w ) -ne 0 ]
then
		echo "Deployment pods are not in running state: $pending_pods"
		echo "To continue with upgrade script make sure all the deployment pods corresponding to $spc must be in running state"
		exit 1
fi

### Get the no.of pool pods that are running #######
pool_cnt=$(kubectl get po -n $ns -l app=cstor-pool,openebs.io/storage-pool-claim=$spc -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'| wc -w)

### Get the csp list which are related to the given spc ###
csp_list=$(kubectl get csp -l openebs.io/storage-pool-claim=$spc -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")

echo "Patching the csp resource"
for csp_res in `echo $csp_list | tr ":" " "`; do

		check_version_openebs "csp" $csp_res
		if [ $skip_upgrade == true ]; then
				kubectl patch csp $csp_res -p "$(cat cr_patch.json)" --type=merge
				rc=$?; if [ $rc -ne 0 ]; then echo "Error occured while applying the patch for csp: $csp_res Exit Code: $rc"; exit; fi
		fi
		if [ $skip_upgrade == false ]; then
				skip_upgrade=true
		fi
done



### Get the list of pool deployments for given SPC, delimited by ':'
pool_deploys=`kubectl get deploy -n $ns \
 -l app=cstor-pool,openebs.io/storage-pool-claim=$spc \
 -o jsonpath="{range .items[*]}{@.metadata.name}:{end}"`

echo "Patching Pool Deployment with new image"
for pool_dep in `echo $pool_deploys | tr ":" " "`; do

		check_version_openebs "deploy" $pool_dep $ns

		if [ $skip_upgrade == true ]; then
				## Get the node name of the corresponding deployments
				node_name_bfr_upg=$(kubectl get deploy -n $ns $pool_dep -o jsonpath='{.spec.template.spec.nodeSelector.kubernetes\.io/hostname}')
				pool_rs=$(kubectl get rs -n openebs \
				-o jsonpath="{range .items[?(@.metadata.ownerReferences[0].name=='$pool_dep')]}{@.metadata.name}{end}")
				echo "$pool_dep -> rs is $pool_rs"

				csp_uuid="";csp_uuid=`kubectl get csp -n $ns $pool_dep -o jsonpath="{.metadata.uid}"`
				echo "$pool_dep -> csp uuid is $csp_uuid"
				if [  -z "$csp_uuid" ];
				then
						echo "Error: Unable to fetch csp uuid"; exit 1
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
		fi
		if [ $skip_upgrade == false ]; then
				skip_upgrade=true
		fi
done

## Cross check whether the pods are in running status or not if not wait untill it comes to running####
while [ true ]
do
		cnt_aft_upg=$(kubectl get po -n $ns -l app=cstor-pool,openebs.io/storage-pool-claim=$spc \
										-o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
		if [ $cnt_aft_upg -eq $pool_cnt ]
		then
				break
		else
				sleep 5
		fi
done

## Fetching the Running pod names
running_pool_pods=$(kubectl get po -n $ns -l app=cstor-pool,openebs.io/storage-pool-claim=$spc -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'| tr " " "\n")

## Setting the quorum enabled in the new pool pods ###
for pool_pod in $running_pool_pods
do

		## Check whether containers(cstor-pool, cstor-pool-mgmt) in pod are in running state.
		no_of_running_containers=0
		no_of_running_containers=$(kubectl get po $pool_pod -n $ns -o jsonpath='{.status.containerStatuses[*].state}' | grep running | wc -w)
		if [ $no_of_running_containers == 2 ]; then
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

				no_of_non_quorum_vol=$(echo $output | grep -wo off | wc -l)
				if [ $no_of_non_quorum_vol -ne 0 ]; then
						echo "Failed to get quorum values from pool $pool_name, exit code: $rc"
				exit 1; fi
		else
				echo "Containers in $pool_pod are not in running state"
				exit 1
		fi

done


### Get the sp list which are related to the given spc ###
sp_list=$(kubectl get sp -l openebs.io/cas-type=cstor,openebs.io/storage-pool-claim=$spc -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
### Patch sp resource###
echo "Patching the SP resource"
for sp_res in `echo $sp_list | tr ":" " "`; do

		check_version_openebs "sp" $sp_res
		if [ $skip_upgrade == true ]; then
				kubectl patch sp $sp_res -p "$(cat cr_patch.json)" --type=merge
				rc=$?; if [ $rc -ne 0 ]; then echo "Error occured while applying the patch for SP resource $sp_res Exit Code: $rc"; exit; fi
		fi
		if [ $skip_upgrade == false ]; then
				skip_upgrade=true
		fi
done

echo "Successfully upgraded $spc to 0.8.1 Please run your application checks."
exit 0
