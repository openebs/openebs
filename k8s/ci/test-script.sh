#!/usr/bin/env bash
# set -x

kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/${CI_BRANCH}/k8s/openebs-operator.yaml

function waitForDeployment() {
  DEPLOY=$1
  NS=$2

  for i in $(seq 1 50) ; do
    kubectl get deployment -n ${NS} ${DEPLOY}
    replicas=$(kubectl get deployment -n ${NS} ${DEPLOY} -o json | jq ".status.readyReplicas")
    if [ "$replicas" == "1" ]; then
      break
    else
      echo "Waiting for ${DEPLOY} to be ready"
      if [ ${DEPLOY} != "maya-apiserver" ] && [ ${DEPLOY} != "openebs-provisioner" ]; then
        dumpMayaAPIServerLogs 10
      fi
      sleep 10
    fi
  done
}

function checkApi() {
    printf "\n"
    echo $1
    printf "\n"
    for i in `seq 1 100`; do
        sleep 2
        responseCode=$($1)
        echo "Response Code from ApiServer: $responseCode"
        if [ $responseCode -ne 200 ]; then
            echo "Retrying.... $i"
            printf "Logs of api-server: \n\n"
            kubectl logs --tail=20 $MAPIPOD -n openebs
            printf "\n\n"
        else
            break
        fi
    done
}

function dumpMayaAPIServerLogs() {
  LC=$1
  MAPIPOD=$(kubectl get pods -o jsonpath='{.items[?(@.spec.containers[0].name=="maya-apiserver")].metadata.name}' -n openebs)
  kubectl logs --tail=${LC} $MAPIPOD -n openebs
  printf "\n\n"
}

waitForDeployment maya-apiserver openebs
waitForDeployment openebs-provisioner openebs
waitForDeployment openebs-ndm-operator openebs
dumpMayaAPIServerLogs 200

kubectl get pods --all-namespaces


#Print the default cstor pools Created
kubectl get csp

#Print the default StoragePoolClaim Created
kubectl get spc

#Print the default StorageClasses Created
kubectl get sc

sleep 10
#echo "------------------ Deploy Pre-release features ---------------------------"
#kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-pre-release-features.yaml

echo "------------------------ Create block device sparse storagepoolclaim --------------- "
# delete the storagepoolclaim created earlier and create new spc with min/max pool
# count 1
kubectl delete spc --all
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/sample-pv-yamls/spc-sparse-single.yaml
sleep 10

echo "--------------- Maya apiserver later logs -----------------------------"
dumpMayaAPIServerLogs 200

echo "---------------Run overprovisioning test case for SPC volumes -----------------------------"
# runVolumeOverProvisioningTest function deploys overprovisioning artifacts for test
# and verify the test case for success/failure
runVolumeOverProvisioningTest(){
deployVolumeOverProvisioningArtifacts
checkForPVC1GStatus
checkForPVC10GStatus
}

# deployVolumeOverProvisioningArtifacts deploys overprovisioning artifacts
deployVolumeOverProvisioningArtifacts(){
echo "------------------------ Create block device sparse storagepoolclaim(overprovisioning-disabled-sparse-pool) with overprovisioning restriction on --------------- "
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/overprovisioning/overprovisioning-disabled-sparse-pool.yaml
echo "------------------------ Create storage class referring to spc overprovisioning-disabled-sparse-pool------------------------------------------------------------ "
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/overprovisioning/cstor-sc-overprovisioning-disabled.yaml

wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/overprovisioning/patch.yaml

echo "------------------------ Patch ndm daemonset to set SPARSE_FILE_COUNT to 2 --------------- "
kubectl patch ds openebs-ndm -n openebs --patch "$(cat patch.yaml)"

sleep 10

echo "Create PVC with 1G capacity request "
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/overprovisioning/pvc1g.yaml
echo "Create PVC with 10G capacity request "
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/overprovisioning/pvc10g.yaml
}

checkForPVC1GStatus(){
PVC_NAME=$1
PVC1G_MAX_RETRY=10
for i in $(seq 1 $PVC1G_MAX_RETRY) ; do
	PVC1GStatus=$(kubectl get pvc test-pvc-1gig --output="jsonpath={.status.phase}")
		if [ "$PVC1GStatus" == "Bound" ]; then
			echo "PVC test-pvc-1gig bound successfully"
			break
		else
      			echo "Waiting for PVC test-pvc-1gig to be bound"
                        kubectl get pvc test-pvc-1gig
			if [ "$i" == "$PVC1G_MAX_RETRY" ] && [ "$PVC1GStatus" != "Bound" ]; then
				echo "PVC test-pvc-1gig NOT bound"
				exit 1
			fi
		fi
      			sleep 5
		done
}
checkForPVC10GStatus(){
PVC10G_MAX_RETRY=5
for i in $(seq 1 $PVC10G_MAX_RETRY) ; do
	PVC10GStatus=$(kubectl get pvc test-pvc-10gigs --output="jsonpath={.status.phase}")
		if [ "$PVC10GStatus" == "Bound" ]; then
			echo "PVC test-pvc-10gigs should NOT bound successfully due to overprovisioning restriction but got bound"
                        kubectl get pvc test-pvc-10gigs
			exit 1
		else
      			echo "Waiting for few iterations to check that PVC test-pvc-10gigs does not get bound after sometime"
                        kubectl get pvc test-pvc-10gigs
			if [ "$i" == "$PVC10G_MAX_RETRY" ] && [ "$PVC1GStatus" != "Bound" ]; then
				echo "PVC test-pvc-10gigs NOT bound and hence test case passed"
			fi
		fi
      			sleep 5
		done
}
## Running OverProvisioning before general tests
runVolumeOverProvisioningTest


echo "--------------- Create Cstor and Jiva PersistentVolume ------------------"
#kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/sample-pv-yamls/pvc-jiva-sc-1r.yaml
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/pvc-single-replica-jiva.yaml
sleep 10
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/sample-pv-yamls/pvc-sparse-claim-cstor.yaml

sleep 30
echo "--------------------- List SC,PVC,PV and pods ---------------------------"
kubectl get sc,pvc,pv
kubectl get pods --all-namespaces

kubectl get deploy -l openebs.io/controller=jiva-controller
JIVACTRL=$(kubectl get deploy -l openebs.io/controller=jiva-controller --no-headers | awk {'print $1'})
for ctrl in `echo "${JIVACTRL[@]}" | tr "\n" " "`;
do
waitForDeployment ${ctrl} default
done

kubectl get deploy -l openebs.io/replica=jiva-replica
JIVAREP=$(kubectl get deploy -l openebs.io/replica=jiva-replica --no-headers | awk {'print $1'})
for rep in `echo "${JIVAREP[@]}" | tr "\n" " "`;
do
waitForDeployment ${rep} default
done

kubectl get deploy -n openebs -l openebs.io/target=cstor-target
CSTORTARGET=$(kubectl get deploy -n openebs -l openebs.io/target=cstor-target --no-headers | awk {'print $1'})
for target in `echo  "${CSTORTARGET[@]}" | tr "\n" " "`;
do
waitForDeployment ${target} openebs
done

echo "-------------------- Checking RO threshold limit for CSP ----------------"
cspList=( $(kubectl get csp  -o jsonpath='{.items[?(@.metadata.labels.openebs\.io/storage-pool-claim=="sparse-claim-auto")].metadata.name}') )
csp=${cspList[0]}
cspROThreshold=$(kubectl get csp  -o jsonpath='{.items[?(@.metadata.labels.openebs\.io/storage-pool-claim=="sparse-claim-auto")].spec.poolSpec.roThresholdLimit}')
spcROThreshold=$(kubectl get spc sparse-claim-auto    --output="jsonpath={.spec.poolSpec.roThresholdLimit}")
if [ $cspROThreshold != $spcROThreshold ]; then
	echo "mismatch between SPC($spcROThreshold) and CSP($cspROThreshold) read-only threshold limit"
	exit 1
fi


echo "-------------- Verifying the existence of udev inside the cstor pool container--------"
cstor_pool_pods=$(kubectl get pods -n openebs -l app=cstor-pool -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
rc=$?
if [ $rc != 0 ]; then
	echo "Error occured while getting the cstor pool pod names; exit code: $rc"
	exit $rc
fi

for pool_pod in $(echo "$cstor_pool_pods" | tr ":" " "); do

	echo "======================================="
	echo "Running lsblk command inside the cstor pool pod: $pool_pod to get device names"
	device_list=$(kubectl exec -it -n openebs "$pool_pod" -c cstor-pool -- lsblk --noheadings --list)
	echo "Device list $device_list"

	############### lsblk --noheadings --list #######################
	##      sdb     8:16   0   10G  0 disk                         ##
	##	sdb9    8:25   0    8M  0 part                         ##
	##	sdb1    8:17   0   10G  0 part                         ##
	##	sda     8:0    0  100G  0 disk                         ##
	##	sda14   8:14   0    4M  0 part                         ##
	##	sda15   8:15   0  106M  0 part                         ##
	##	sda1    8:1    0 99.9G  0 part /var/openebs/sparse     ##
	#################################################################

	## Fetching device name from above output(first row and first column)
	device_name=$(echo "$device_list" | grep disk | awk 'NR==1{print $1}')

	echo "Verifying whether '$device_name' is initilized by udev or not"
	output=$(kubectl exec -it -n openebs "$pool_pod" -c cstor-pool -- ./var/openebs/sparse/udev_checks/udev_check "$device_name")
	rc=$?
	echo "$output"

	## If exit code was not 0 then exit the process
	if [ $rc != 0 ]; then
		echo "Printing pool pod yaml output"
		kubectl get pod "$pool_pod" -n openebs -o yaml
		exit 1
	fi
	echo "======================================="
	break
done

echo "-------------------- Checking Finalizer Existence On CSP -------------------------"
## 5 retry count is good enough since the cstor-pool-mgmt container is already in Running State
retry_cnt=5
cspList=$(kubectl get csp  -o jsonpath='{.items[?(@.metadata.labels.openebs\.io/storage-pool-claim=="sparse-claim-auto")].metadata.name}')
csp=${cspList[0]}
finalizer_found=0
for i in $(seq 1 $retry_cnt) ; do
	## Below command will give [openebs.io/pool-protection,openebs.io/storage-pool-claim].
	finalizers=$(kubectl get csp $csp -o jsonpath='{.metadata.finalizers}')
	## Below one will remove the square brackets around the output so it will be converted into
	## openebs.io/pool-protection,openebs.io/storage-pool-claim
	finalizerList=$(echo "${finalizers:1:${#finalizers}-2}")
	## Iterate over all the finalizers and verify for existence of pool protection
	## finalizer.
	for finalizer in $(echo "$finalizerList" | tr "," " "); do
		if [ "$finalizer" == "openebs.io/pool-protection" ]; then
			finalizer_found=1
			break
		fi
	done
	if [ $finalizer_found -eq 1 ]; then
		break
	fi
	sleep 1
done

if [ $finalizer_found -eq 0 ]; then
	echo "Error: Finalizer: openebs.io/pool-protection not found on CSP: ${csp} finalizerList: ${finalizerList}"
	exit 1
fi
echo "---------------- Finalizer Exists On CSP -----------------------"

echo "---------------Testing deployment in pvc namespace---------------"

kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/volume/cstor/service-account.yaml

kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/volume/cstor/sc_app_ns.yaml

echo "---------------Creating in pvc---------------"
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/volume/cstor/pvc_app_ns.yaml

sleep 10

kubectl get deploy -n openebs -l openebs.io/target=cstor-target
kubectl get cstorvolume
kubectl get service

## To fix intermittent travis failure
sleep 20
CSTORTARGET=$(kubectl get deploy -l openebs.io/persistent-volume-claim=openebs-pvc-in-custom-ns --no-headers | awk {'print $1'})
echo $CSTORTARGET
waitForDeployment ${CSTORTARGET} default

MAPI_SVC_ADDR=`kubectl get service -n openebs maya-apiserver-service -o json | grep clusterIP | awk -F\" '{print $4}'`
export MAPI_ADDR="http://${MAPI_SVC_ADDR}:5656"
export KUBERNETES_SERVICE_HOST="127.0.0.1"
export KUBECONFIG=$HOME/.kube/config


export MAPIPOD=$(kubectl get pods -o jsonpath='{.items[?(@.spec.containers[0].name=="maya-apiserver")].metadata.name}' -n openebs)
export CSTORVOL=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="cstor-vol1-1r-claim")].metadata.name}')
export CSTORVOLNS=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="openebs-pvc-in-custom-ns")].metadata.name}')
export JIVAVOL=$(kubectl get pv -o jsonpath='{.items[?(@.metadata.annotations.openebs\.io/cas-type=="jiva")].metadata.name}')
export POOLNAME=$(kubectl get csp -o jsonpath='{.items[?(@.metadata.labels.openebs\.io/storage-pool-claim=="sparse-claim-auto")].metadata.name}')

echo "------------------Extracted Pod names---------------------"
echo MAPIPOD: $MAPIPOD
echo CSTORVOL: $CSTORVOL
echo CSTORVOLNS: $CSTORVOLNS
echo JIVAVOL: $JIVAVOL

echo "++++++++++++++++ Waiting for MAYA API's to get ready ++++++++++++++++++++++"


printf "\n\n"
echo "---------------- Checking Volume list API -------------------"

checkApi "curl -X GET --write-out %{http_code} --silent --output /dev/null $MAPI_ADDR/latest/volumes/"

printf "\n\n"

echo "---------------- Checking Volume API for jiva volume -------------------"

checkApi "curl -X GET --write-out %{http_code} --silent --output /dev/null $MAPI_ADDR/latest/volumes/$JIVAVOL -H namespace:default"

printf "\n\n"

echo "---------------- Checking Volume API for cstor volume -------------------"

checkApi "curl -X GET --write-out %{http_code} --silent --output /dev/null $MAPI_ADDR/latest/volumes/$CSTORVOL -H namespace:openebs"

printf "\n\n"

echo "------------ Checking Volume STATS API for cstor volume -----------------"

checkApi "curl -X GET --write-out %{http_code} --silent --output /dev/null $MAPI_ADDR/latest/volumes/stats/$CSTORVOL -H namespace:openebs"

printf "\n\n"

echo "------------ Checking Volume STATS API for jiva volume -----------------"

checkApi "curl -X GET --write-out %{http_code} --silent --output /dev/null $MAPI_ADDR/latest/volumes/stats/$JIVAVOL -H namespace:default"

printf "\n\n"

echo "+++++++++++++++++++++ MAYA API's are ready ++++++++++++++++++++++++++++++++"

printf "\n\n"


echo "************** Snapshot and Clone related tests***************************"
# Create jiva volume for snapshot clone test ( cstor volume already exists)
#kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/pvc-single-replica-jiva.yaml

kubectl get pods --all-namespaces
kubectl get sc

sleep 30

echo "******************* Describe disks **************************"
kubectl describe disks

echo "******************* Describe spc,sp,csp **************************"
kubectl describe spc,sp,csp

echo "******************* List all pods **************************"
kubectl get po --all-namespaces

echo "******************* List PVC,PV and pods **************************"
kubectl get pvc,pv

# Create the application
echo "Creating busybox-jiva and busybox-cstor application pod"
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/jiva/busybox.yaml
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/busybox.yaml
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/busybox_ns.yaml

for i in $(seq 1 100) ; do
    phaseJiva=$(kubectl get pods busybox-jiva --output="jsonpath={.status.phase}")
    phaseCstor=$(kubectl get pods busybox-cstor --output="jsonpath={.status.phase}")
    phaseCstorNs=$(kubectl get pods busybox-cstor-ns --output="jsonpath={.status.phase}")
    if [ "$phaseJiva" == "Running" ] && [ "$phaseCstor" == "Running" ] && [ "$phaseCstorNs" == "Running" ]; then
        break
	else
        echo "busybox-jiva pod is in:" $phaseJiva
        echo "busybox-cstor pod is in:" $phaseCstor
        echo "busybox-cstor-ns pod is in:" $phaseCstorNs

        if [ "$phaseJiva" != "Running" ]; then
           kubectl describe pods busybox-jiva
        fi
        if [ "$phaseCstor" != "Running" ]; then
           kubectl describe pods busybox-cstor
        fi
        if [ "$phaseCstorNs" != "Running" ]; then
           kubectl describe pods busybox-cstor-ns
        fi
        sleep 10
    fi
done

dumpMayaAPIServerLogs 100

echo "********************Creating volume snapshot*****************************"
kubectl create -f  https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/jiva/snapshot.yaml
kubectl create -f  https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/snapshot.yaml
kubectl create -f  https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/snapshot_ns.yaml
kubectl logs --tail=20 -n openebs deployment/openebs-snapshot-operator -c snapshot-controller

# It might take some time for cstor snapshot to get created. Wait for snapshot to get created
for i in $(seq 1 100) ; do
    kubectl get volumesnapshotdata
    count=$(kubectl get volumesnapshotdata | wc -l)
    # count should be 3 as one header line would also be present
    if [ "$count" == "4" ]; then
        break
    else
        echo "snapshot/(s) not created yet"
        kubectl get volumesnapshot,volumesnapshotdata
        sleep 10
    fi
done

kubectl logs --tail=20 -n openebs deployment/openebs-snapshot-operator -c snapshot-controller

# Promote/restore snapshot as persistent volume
sleep 30
echo "*****************Promoting snapshot as new PVC***************************"
kubectl create -f  https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/jiva/snapshot_claim.yaml
kubectl logs --tail=20 -n openebs deployment/openebs-snapshot-operator -c snapshot-provisioner
kubectl create -f  https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/snapshot_claim.yaml
kubectl logs --tail=20 -n openebs deployment/openebs-snapshot-operator -c snapshot-provisioner
kubectl create -f  https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/snapshot_claim_ns.yaml
kubectl logs --tail=20 -n openebs deployment/openebs-snapshot-operator -c snapshot-provisioner

sleep 30
# get clone replica pod IP to make a curl request to get the clone status
cloned_replica_ip=$(kubectl get pods -owide -l openebs.io/persistent-volume-claim=demo-snap-vol-claim-jiva --no-headers | grep -v ctrl | awk {'print $6'})
echo "***************** checking clone status *********************************"
for i in $(seq 1 5) ; do
		clonestatus=`curl http://$cloned_replica_ip:9502/v1/replicas/1 | jq '.clonestatus' | tr -d '"'`
		if [ "$clonestatus" == "completed" ]; then
            break
		else
            echo "Clone process in not completed ${clonestatus}"
            sleep 60
        fi
done

# Clone is in Alpha state, and kind of flaky sometimes, comment this integration test below for time being,
# util its stable in backend storage engine
echo "***************Creating busybox-clone-jiva application pod********************"
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/jiva/busybox_clone.yaml
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/busybox_clone.yaml
kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/ci/maya/snapshot/cstor/busybox_clone_ns.yaml


kubectl get pods --all-namespaces
kubectl get pvc --all-namespaces

for i in $(seq 1 15) ; do
    phaseJiva=$(kubectl get pods busybox-clone-jiva --output="jsonpath={.status.phase}")
    phaseCstor=$(kubectl get pods busybox-clone-cstor --output="jsonpath={.status.phase}")
    phaseCstorNs=$(kubectl get pods busybox-clone-cstor-ns --output="jsonpath={.status.phase}")
    if [ "$phaseJiva" == "Running" ] && [ "$phaseCstor" == "Running" ] && [ "$phaseCstorNs" == "Running" ]; then
        break
    else
        echo "busybox-clone-jiva pod is in:" $phaseJiva
        echo "busybox-clone-cstor pod is in:" $phaseCstor
        echo "busybox-clone-cstor-ns pod is in:" $phaseCstorNs

        if [ "$phaseJiva" != "Running" ]; then
            kubectl describe pods busybox-clone-jiva
        fi
        if [ "$phaseCstor" != "Running" ]; then
            kubectl describe pods busybox-clone-cstor
        fi
        if [ "$phaseCstorNs" != "Running" ]; then
            kubectl describe pods busybox-clone-cstor-ns
        fi
		sleep 30
        fi
done


echo "********************** cvr status *************************"
kubectl get cvr -n openebs -o yaml

dumpMayaAPIServerLogs 100

kubectl get pods
kubectl get pvc

echo "*************Verifying data validity and Md5Sum Check********************"
hashjiva1=$(kubectl exec busybox-jiva -- md5sum /mnt/store1/date.txt | awk '{print $1}')
hashjiva2=$(kubectl exec busybox-clone-jiva -- md5sum /mnt/store2/date.txt | awk '{print $1}')

hashcstor1=$(kubectl exec busybox-cstor -- md5sum /mnt/store1/date.txt | awk '{print $1}')
hashcstor2=$(kubectl exec busybox-clone-cstor -- md5sum /mnt/store2/date.txt | awk '{print $1}')

hashcstorns1=$(kubectl exec busybox-cstor-ns -- md5sum /mnt/store1/date.txt | awk '{print $1}')
hashcstorns2=$(kubectl exec busybox-clone-cstor-ns -- md5sum /mnt/store2/date.txt | awk '{print $1}')

echo "busybox jiva hash: $hashjiva1"
echo "busybox-clone-jiva hash: $hashjiva2"
echo "busybox cstor hash: $hashcstor1"
echo "busybox-clone-cstor hash: $hashcstor2"
echo "busybox cstor ns hash: $hashcstorns1"
echo "busybox-clone-cstor-ns hash: $hashcstorns2"

if [ "$hashjiva1" != "" ] && [ "$hashcstor1" != "" ] && [ "$hashjiva1" == "$hashjiva2" ] && [ "$hashcstor1" == "$hashcstor2" ] && [ "$hashcstorns1" == "$hashcstorns2" ]; then
	echo "Md5Sum Check: PASSED"
else
    echo "Md5Sum Check: FAILED"; exit 1
fi

testPoolReadOnly() {
	for i in 1 2 3 ; do
		kubectl exec -it busybox-cstor -- sh  -c "dd if=/dev/urandom of=/mnt/store1/$RANDOM count=10000 bs=4k && sync"
	done
	kubectl get csp

	# update csp readonly threshold to 1%
	kubectl patch  csp ${csp} --type='json' -p='[{"op":"replace", "path":"/spec/poolSpec/roThresholdLimit", "value":1}]'
	# default sync period for csp is 30 second
	sleep 60

	readOnly=$(kubectl get csp ${csp} -o jsonpath='{.status.readOnly}')
	if [ $readOnly == "false" ]; then
		echo "CSP should be readonly"
		exit 2
	fi

	cspPod=`kubectl get pods  -o jsonpath="{.items[?(@.metadata.labels.openebs\.io/cstor-pool=='$csp')].metadata.name}" -n openebs`
	readOnly=$(kubectl exec -it ${cspPod} -n openebs -ccstor-pool -- zpool get io.openebs:readonly -Hp -ovalue)
	if [ $readOnly == "off" ]; then
		echo "Pool should be readonly"
		exit 2
	fi

	# update csp readonly threshold to 90%
	kubectl patch  csp ${csp} --type='json' -p='[{"op":"replace", "path":"/spec/poolSpec/roThresholdLimit", "value":90}]'
	# default sync period for csp is 30 second
	sleep 60

	readOnly=$(kubectl get csp ${csp} -o jsonpath='{.status.readOnly}')
	if [ $readOnly == "true" ]; then
		echo "CSP should not be readonly"
		exit 2
	fi

	readOnly=$(kubectl exec -it ${cspPod} -n openebs -ccstor-pool -- zpool get io.openebs:readonly -Hp -ovalue)
	if [ $readOnly == "on" ]; then
		echo "Pool should not be readonly"
		exit 2
	fi
}
# check pool read threshold limit
testPoolReadOnly
