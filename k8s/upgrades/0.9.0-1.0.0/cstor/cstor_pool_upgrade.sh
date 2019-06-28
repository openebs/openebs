#!/bin/bash

###########################################################################
# STEP: Get SPC name and namespace where OpenEBS is deployed as arguments #
#                                                                         #
# NOTES: Obtain the pool deployments to perform upgrade operation         #
###########################################################################

upgrade_version="1.0.0"
current_version="0.9.0"

source util.sh

function error_msg() {
    echo -n "Failed to upgrade pool $spc. Please make sure that the pool $spc "
    echo -n "upgrade should be successful before continuing for next step. "
    echo -n "Contact OpenEBS team over slack for any further help."
}

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

function pre_check() {
    local ns=$1
    local pod_version=""
    ## name=maya-apiserver label is common for both helm and operator yaml
    maya_pod_name=$(kubectl get pod -n $ns \
                 -l name=maya-apiserver    \
                 -o jsonpath='{.items[0].metadata.name}')
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get maya apiserver pod name | Exit code: $rc"; exit 1; error_msg; fi
    pod_version=$(verify_openebs_version "pod" $maya_pod_name $ns)
    rc=$?
    if [ $rc -ne 0 ]; then
        error_msg
        exit 1
    fi
    if [ $pod_version != $upgrade_version ]; then
        echo "Pre-checks failed. Please upgrade OpenEBS control components before upgrading the pool"
        error_msg
        exit 1
    fi
}

function make_spc_blockdevice_list() {
    local spc_bd_list=$1
    local disk_name=$2
    ## For sparse block device name looks like sparse-1234567
    local bd_name=$(echo $disk_name | sed 's|disk-|blockdevice-|g')

    if [ -z $spc_bd_list ]; then
        echo "\"$bd_name\""
    else
        echo "$spc_bd_list,\"$bd_name\""
    fi
}

## patch_blockdevice_list_for_spc to patch block device changes related to spc
function patch_blockdevice_list_for_spc() {
    local spc_name=$1

    local spc_disk_list=$(kubectl get spc $spc_name \
                          -o jsonpath='{.spec.disks.diskList}' | \
                          tr "[]" " ")
    local spc_bd_list=""
    local no_of_blockdevices=$(echo $spc_disk_list | wc -w)

    ##Patch SPC only if it is manual provisioning
    if [ $no_of_blockdevices != 0 ]; then
        for disk_name in $spc_disk_list; do
             spc_bd_list=$(make_spc_blockdevice_list "$spc_bd_list" "$disk_name")
        done
        sed "s|@blockdevice_list@|$spc_bd_list|g" spc-patch.tpl.json > spc-patch.json

        kubectl patch spc $spc_name -p "$(cat spc-patch.json)" --type=merge
        rc=$?
        if [ $rc -ne 0 ]; then
            echo "Failed to patch spc: $spc_name with block device information | Exit Code: $rc"
            error_msg
            rm spc-patch.json
            exit 1
        fi

        rm spc-patch.json
    fi
}

## make_csp_disk_list will return the jsonpath required to update the csp
function make_csp_disk_list() {
    local csp_disk_list=$1
    local disk_device_id=$2
    local disk_name=$3
    local bd_name=$(echo $disk_name | sed 's|disk-|blockdevice-|g')
    if [ -z "$csp_disk_list" ]; then
        echo "{\"deviceID\": \"$disk_device_id\",\"inUseByPool\": true,\"name\": \"$bd_name\"}"
    else
        echo "$csp_disk_list,{\"deviceID\": \"$disk_device_id\",\"inUseByPool\": true,\"name\": \"$bd_name\"}"
    fi
}

########################################################################
#                                                                      #
#                          Starting point                              #
#                                                                      #
########################################################################
if [ "$#" -ne 2 ]; then
    usage
fi

spc=$1
ns=$2
declare -A csp_blockdevice_list

## Assumption OpenEBS control plane components will be in same namespace where
## pool pods are running
pre_check $ns

### Get the deployment pods which are in not running state that are related to provided spc ###
pending_pods=$(kubectl get pod -n $ns \
    -l app=cstor-pool,openebs.io/storage-pool-claim=$spc \
    -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get pool pods related to spc: $spc | Exit Code: $rc"; error_msg; exit 1; fi


## If any deployments pods are in not running state then exit the upgrade process ###
if [ $(echo $pending_pods | wc -w) -ne 0 ]; then
    echo "To continue with upgrade script make sure all the pool deployment pods corresponding to $spc must be in running state"
    error_msg
    exit 1
fi

patch_blockdevice_list_for_spc $spc

### Get the csp list which are related to the given spc ###
csp_list=$(get_csp_list $spc)

#### Get required info from current csp and use the info while upgrading ####
for csp_name in `echo $csp_list | tr ":" " "`; do
    ## Check CSP version ##
    version=$(verify_openebs_version "csp" $csp_name $ns)
    rc=$?
    if [ $rc -ne 0 ]; then
        error_msg
        exit 1
    fi
    if [ $version == $upgrade_version ]; then
        continue
    fi

    ## Get disk info from corresponding sp ##
    sp_name=$(kubectl get sp \
              -l openebs.io/cstor-pool=$csp_name \
              -o jsonpath="{.items[*].metadata.name}")
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get sp related to csp: $csp_name | Exit Code: $rc"; error_msg; exit 1; fi

    ## Below command will give the output in form of
    ## [disk-1 disk-2 disk-3 disk-4]
    sp_disk_list=$(kubectl get sp $sp_name \
                   -o jsonpath="{.spec.disks.diskList}" | \
                    tr "[]" " ")
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get disks related to sp: $sp_name | Exit Code: $rc"; error_msg; exit 1; fi

    ## Below snippet will get related info regarding block device and format
    ## information in below format and save it to corresponding csp name
    ## "group": [
    ##    {
    ##         "blockDevice": [
    ##             {
    ##                 "deviceID": "/var/openebs/sparse/6-ndm-sparse.img",
    ##                 "inUseByPool": true,
    ##                 "name": "sparse-177b6bc2ae2dd332c7a384a02179368b"
    ##             },
    ##             {
    ##                 "deviceID": "/var/openebs/sparse/9-ndm-sparse.img",
    ##                 "inUseByPool": true,
    ##                 "name": "sparse-2239d60eb46b3c26b0428fae4d15c88a"
    ##             }
    ##         ]
    ##    }
    ## ]
    csp_disk_list=""
    for disk_name in $sp_disk_list; do
         ## Assuming device Id present in first index
         device_id=$(kubectl get disk $disk_name -o jsonpath="{.spec.devlinks[0].links[0]}")
         if [ -z $device_id ]; then
             device_id=$(kubectl get disk $disk_name -o jsonpath="{.spec.path}")
         fi
         csp_disk_list=$(make_csp_disk_list "$csp_disk_list" "$device_id" "$disk_name")
    done
    csp_blockdevice_list[$csp_name]=$csp_disk_list
done

echo "Patching Pool Deployment with new image"
for csp_name in `echo $csp_list | tr ":" " "`; do
    ## Get the pool deployment corresponding to csp
    pool_dep=$(kubectl get deploy -n $ns \
        -l app=cstor-pool,openebs.io/storage-pool-claim=$spc \
        -o jsonpath="{.items[?(@.metadata.labels.openebs\.io/cstor-pool=='$csp_name')].metadata.name}")
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to get deployment related to csp: $csp_name | Exit Code: $rc"
        error_msg
        exit 1
    fi

    ## We are patching csp after deployment so checking csp version is good
    version=$(verify_openebs_version "csp" $csp_name $ns)
    rc=$?
    if [ $rc -ne 0 ]; then
        error_msg
        exit 1
    fi
    if [ $version == $upgrade_version ]; then
        continue
    fi

    version=$(verify_openebs_version "deploy" $pool_dep $ns)
    rc=$?
    if [ $rc -ne 0 ]; then
        error_msg
        exit 1
    fi
    if [ $version == $current_version ]; then
        ## Get the replica set corresponding to the deployment ##
        pool_rs=$(kubectl get rs -n $ns \
            -l openebs.io/cstor-pool=$csp_name -o jsonpath='{.items[0].metadata.name}')
        echo "$pool_dep -> rs is $pool_rs"


        ## Modifies the cstor-pool-patch template with the original values ##
        sed "s/@pool_version@/$upgrade_version/g" cstor-pool-patch.tpl.json > cstor-pool-patch.json

        ## Patch the deployment file ###
        kubectl patch deployment --namespace $ns $pool_dep -p "$(cat cstor-pool-patch.json)"
        rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: Failed to patch $pool_dep"; error_msg; rm cstor-pool-patch.json ;exit 1; fi
        rollout_status=$(kubectl rollout status --namespace $ns deployment/$pool_dep)
        rc=$?; if [[ ($rc -ne 0) || ! ($rollout_status =~ "successfully rolled out") ]];
        then echo "ERROR: Failed to rollout status for $pool_dep error: $rc"; error_msg; rm cstor-pool-patch.json; exit 1; fi

        ## Deleting the old replica set corresponding to deployment
        kubectl delete rs $pool_rs --namespace $ns
    fi

    ## Remove the reconcile.openebs.io/disable annotation and patch with block
    ## device information to csp
    sed "s|@blockdevice_list@|${csp_blockdevice_list[$csp_name]}|g" csp-patch.tpl.json | sed "s|@pool_version@|$upgrade_version|g" > csp-patch.json
    kubectl patch csp $csp_name -p "$(cat csp-patch.json)" --type=merge
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to patch spec and annotation for csp: $csp | Exit Code: $rc"
        error_msg
        rm csp-patch.json
        rm cstor-pool-patch.json
        exit 1
    fi

    ## Cleaning the temporary patch file
    rm cstor-pool-patch.json
    rm csp-patch.json
done

## Delete sp realated to the spc
kubectl delete sp -l openebs.io/cas-type=cstor,openebs.io/storage-pool-claim=$spc
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to delete sp related to spc: $spc_name Exit Code: $rc"; error_msg; exit 1; fi

echo "Upgrade steps are done on pool $spc"

./verify_pool_upgrade.sh $spc $ns
rc=$?
if [ $rc -eq 0 ]; then
    echo "Verification of pool $spc upgrade is successful. Please run volume upgrade scripts"
fi
