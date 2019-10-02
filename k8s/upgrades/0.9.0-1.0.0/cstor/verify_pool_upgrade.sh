#!/bin/bash

upgrade_version="1.0.0"
current_version="0.9.0"


##  No need to catch kubectl command errors because we need to continue with
##  other checks
source util.sh

function error_msg() {
    echo -n "Upgrade pool $spc is in pending or failed. Please make sure that the pool $spc "
    echo -n "upgrade is successful before continuing for next step. "
    echo -n "Contact OpenEBS team over slack for any further help."
}

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <spc-name> <openebs-namespace>"
    echo
    echo "  <spc-name> Get the SPC name using: kubectl get spc"
    echo "  <openebs-namespace> namespace where pool pods"
    echo "    corresponding to SPC are deployed"
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

spc=$1
ns=$2
is_upgrade_failed=0
echo "Verifying pool $spc upgrade..."

csp_list=$(get_csp_list $spc)

for csp_name in `echo $csp_list | tr ":" " "`; do
    version=$(verify_openebs_version "csp" $csp_name $ns)
    rc=$?
    if [ $rc -ne 0 ]; then
        exit 1
    fi
    if [ $version != $upgrade_version ]; then
        echo -n "CSP: $csp_name is not upgraded expected version: $upgrade_version "
        echo "Got version: $version"
        is_upgrade_failed=1
    fi
done

for csp_name in `echo $csp_list | tr ":" " "`; do
    pod_name=$(kubectl get pod -n $ns \
        -l openebs.io/storage-pool-claim=$spc,openebs.io/cstor-pool=$csp_name \
        -o jsonpath='{.items[0].metadata.name}')
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to get pool pod related to csp: $csp_name | Exit Code: $rc"
        exit 1
    fi

    version=$(verify_openebs_version "pod" $pod_name $ns)
    rc=$?
    if [ $rc -ne 0 ]; then
        exit 1
    fi
    if [ $version != $upgrade_version ]; then
        echo -n "pool pod: $pod_name is not upgraded expected version: $upgrade_version "
        echo "Got version: $version"
        is_upgrade_failed=1
    fi

    image_version=$(verify_pod_image_tag "$pod_name" "cstor-pool" "$ns")
    if [ $image_version != $upgrade_version ]; then
        echo -n "pool pod: $pod_name \"cstor-pool\" container image is not upgraded expected version: $upgrade_version "
        echo "Got version: $image_version"
        is_upgrade_failed=1
    fi

    image_version=$(verify_pod_image_tag "$pod_name" "cstor-pool-mgmt" "$ns")
    if [ $image_version != $upgrade_version ]; then
        echo -n "pool pod: $pod_name \"cstor-pool-mgmt\" image is not upgraded expected version: $upgrade_version "
        echo "Got version: $image_version"
        is_upgrade_failed=1
    fi

    image_version=$(verify_pod_image_tag "$pod_name" "maya-exporter" "$ns")
    if [ $image_version != $upgrade_version ]; then
        echo -n "pool pod: $pod_name \"maya-exporter\" image is not upgraded expected version: $upgrade_version "
        echo "Got version: $image_version"
        is_upgrade_failed=1
    fi

    bd_list=$(kubectl get csp $csp_name \
            -o jsonpath='{range .spec.group[*].blockDevice[*]}{.name}:{end}')
    is_bd_present="false"

    for bd_name in `echo $bd_list | tr ":" " "`; do
        claim_state=$(kubectl get bd $bd_name -n $ns \
                  -o jsonpath='{.status.claimState}')
        if [ "$claim_state" != "Claimed" ]; then
             echo "blockdevice: $bd_name is not yet claimed"
             is_upgrade_failed=1
        fi
        is_bd_present="true"
    done
    if [ $is_bd_present == "false" ]; then
        echo "blockdevice is not found in csp: $csp_name"
        is_upgrade_failed=1
    fi
done

sp_list=$(kubectl get sp -l openebs.io/storage-pool-claim=$spc \
          -o jsonpath='{range .items[*]}{@.metadata.name} {end}')

sp_count=$(echo $sp_list | wc -w)

if [ $sp_count != 0 ]; then
    echo "SP is deprecated for cStor but still it is available in cluster. SP {$sp_list} list"
    is_upgrade_failed=1
fi

if [ $is_upgrade_failed == 0 ]; then
    echo "pool upgrade $spc verification is successful"
else
    echo -n "Validation steps are failed on pool $spc. This might be"
    echo "due to ongoing upgrade or errors during upgrade."
    echo -n "Please run ./verify_pool_upgrade.sh <spc_name> <namespace> again after "
    echo "some time. If issue still persist, contact OpenEBS team over slack for any further help."
    exit 1
fi
exit 0
