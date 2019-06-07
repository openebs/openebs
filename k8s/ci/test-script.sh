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
waitForDeployment ${JIVACTRL} default

kubectl get deploy -l openebs.io/replica=jiva-replica
JIVAREP=$(kubectl get deploy -l openebs.io/replica=jiva-replica --no-headers | awk {'print $1'})
waitForDeployment ${JIVAREP} default

kubectl get deploy -n openebs -l openebs.io/target=cstor-target
CSTORTARGET=$(kubectl get deploy -n openebs -l openebs.io/target=cstor-target --no-headers | awk {'print $1'})
waitForDeployment ${CSTORTARGET} openebs

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
