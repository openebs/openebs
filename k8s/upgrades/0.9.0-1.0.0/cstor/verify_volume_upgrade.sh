#!/bin/bash

upgrade_version="1.0.0"
current_version="0.9.0"

source util.sh

function error_msg() {
    echo -n "Upgrade volume $pv in $ns is in pending or failed. Please make sure that the volume $pv "
    echo -n "upgrade is successful before continuing for next step. "
    echo -n "Contact OpenEBS team over slack for any further help."
}

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <pv-name> <openebs-namespace>"
    echo
    echo "  <pv-name> Get the PV name using: kubectl get pv"
    echo "  <openebs-namespace> Get the namespace where openebs"
    echo "  pods are installed"
    exit 1
}

## Starting point
if [ "$#" -ne 2 ]; then
    usage
fi

pv=$1
ns=$2
is_upgrade_failed=0
echo "Verifying volume $pv upgrade in namespace $ns..."

# Check if pv exists
kubectl get pv $pv &>/dev/null;check_pv=$?
if [ $check_pv -ne 0 ]; then
    echo "$pv not found"; error_msg; exit 1;
fi

# Check if CASType is cstor
cas_type=`kubectl get pv $pv -o jsonpath="{.metadata.annotations.openebs\.io/cas-type}"`
if [ $cas_type != "cstor" ]; then
    echo "Cstor volume not found";exit 1;
elif [ $cas_type == "cstor" ]; then
    echo "$pv is a cstor volume"
else
    echo "Volume is neither cstor or cstor"; exit 1;
fi

c_svc=$(kubectl get service -n $ns \
        -l openebs.io/persistent-volume=$pv,openebs.io/target-service=cstor-target-svc \
        -o jsonpath="{.items[*].metadata.name}")
version=$(verify_openebs_version "service" $c_svc $ns)

if [ "$version" != $upgrade_version ]; then
    echo -n "cstor target service: $c_svc is not upgraded expected version: $upgrade_version "
    echo "Got version: $version"
    is_upgrade_failed=1
fi

c_tgt_pod_name=$(kubectl get pod -n $ns \
        -l openebs.io/persistent-volume=$pv,openebs.io/target=cstor-target \
        -o jsonpath="{.items[*].metadata.name}")
version=$(verify_openebs_version "pod" $c_tgt_pod_name $ns)

if [ "$version" != $upgrade_version ]; then
    echo -n "cstor target pod: $c_tgt_pod_name is not upgraded expected version: $upgrade_version "
    echo "Got version: $version"
    is_upgrade_failed=1
fi

image_version=$(verify_pod_image_tag "$c_tgt_pod_name" "cstor-istgt" "$ns")
if [ "$image_version" != $upgrade_version ]; then
    echo -n "cstor target pod: $c_tgt_pod_name \"cstor-istgt\" container image is not upgraded expected version: $upgrade_version "
    echo "Got version: $image_version"
    is_upgrade_failed=1
fi

image_version=$(verify_pod_image_tag "$c_tgt_pod_name" "cstor-volume-mgmt" "$ns")
if [ "$image_version" != $upgrade_version ]; then
    echo -n "cstor target pod: $c_tgt_pod_name \"cstor-volume-mgmt\" container image is not upgraded expected version: $upgrade_version "
    echo "Got version: $image_version"
    is_upgrade_failed=1
fi

image_version=$(verify_pod_image_tag "$c_tgt_pod_name" "maya-volume-exporter" "$ns")
if [ "$image_version" != $upgrade_version ]; then
    echo -n "cstor target pod: $c_tgt_pod_name \"maya-volume-exporter\" container image is not upgraded expected version: $upgrade_version "
    echo "Got version: $image_version"
    is_upgrade_failed=1
fi

## Get cstorvolume related to given pv
c_vol=$(kubectl get cstorvolumes \
        -l openebs.io/persistent-volume=$pv -n $ns \
        -o jsonpath="{.items[*].metadata.name}")
version=$(verify_openebs_version "cstorvolume" $c_vol $ns)

## Verify version of cstorvolume related to given pv
if [ "$version" != $upgrade_version ]; then
    echo -n "cstorvolume CR: $c_vol is not upgraded expected version: $upgrade_version "
    echo "Got version: $version"
    is_upgrade_failed=1
fi

## Get cstor volume replicas related to given pv
c_replicas=$(kubectl get cvr -n $ns \
        -l openebs.io/persistent-volume=$pv \
        -o jsonpath="{range .items[*]}{@.metadata.name};{end}" | tr ";" "\n")

## Verify version of cstor volume replicas
for replica in $c_replicas; do
    version=$(verify_openebs_version "cvr" $replica $ns)

    if [ "$version" != $upgrade_version ]; then
        echo -n "cstorvolumereplica CR: $c_vol is not upgraded expected version: $upgrade_version "
        echo "Got version: $version"
        is_upgrade_failed=1
    fi
done

if [ $is_upgrade_failed == 0 ]; then
    echo "volume upgrade $pv verification is successful"
else
    echo
    echo
    echo -n "Validation steps are failed on volume $pv in $ns. This might be"
    echo "due to ongoing upgrade or errors during upgrade."
    echo -n "Please run ./verify_volume_upgrade.sh <pv_name> <namespace> again after "
    echo "some time. If issue still persist, contact OpenEBS team over slack for any further help."
    exit 1
fi
exit 0
