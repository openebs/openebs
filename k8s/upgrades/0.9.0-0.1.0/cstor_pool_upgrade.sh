#!/bin/bash

###########################################################################
# STEP: Get SPC name and namespace where OpenEBS is deployed as arguments #
#                                                                         #
# NOTES: Obtain the pool deployments to perform upgrade operation         #
###########################################################################

##TODO: Need to Update the function names

pool_upgrade_version="0.1.0"
current_version="0.9.0"

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
function verify_openebs_version() {
    local resource=$1
    local name_res=$2
    local openebs_version=$(kubectl get $resource $name_res -n $ns \
                 -o jsonpath="{.metadata.labels.openebs\.io/version}")

    if [[ $openebs_version != $current_version ]] && [[ $openebs_version != $pool_upgrade_version ]]; then
        echo "Expected version of $name_res in $resource is $current_version but got $openebs_version";exit 1;
    fi
    echo $openebs_version
}

## get_csp_list will return the csp list related corresponding spc
function get_csp_list() {
    local csp_list=""
    local spc_name=$1
    csp_list=$(kubectl get csp -l openebs.io/storage-pool-claim=$spc_name \
             -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to get csp related to spc $spc"
        exit 1
    fi
    echo $csp_list
}

## insert_node_disk_list updates the map[nodeName]diskNames
function insert_node_disk_list() {
    local node_name=$1
    local disk_name=$2
    node_disklist["$node_name"]=$(echo "${node_disklist[$node_name]},$disk_name")
}

## make_map_node_disk_list get the disk info
function make_map_node_disk_list() {
    local disk_list=$1
    local node_name=""
    for disk_name in `echo $disk_list | tr "," " "`; do
        node_name=$(kubectl get disk $disk_name -o jsonpath="{.metadata.labels.kubernetes\.io/hostname}")
        insert_node_disk_list $node_name $disk_name
    done
}

## get_disk_list_for_sp_list return the disk names present in given sp_list
function get_disk_list_for_sp_list() {
    local sp_list=$1
    local disk_list=""
    for sp in `echo $sp_list | tr ":" " "`; do
        version=$(verify_openebs_version "sp" $sp)
        rc=$?
        if [ $rc -ne 0 ]; then
            exit 1
        elif [ $version == $pool_upgrade_version ]; then
            continue
        fi
        local tmp_disk_list=$(kubectl get sp $sp -o jsonpath="{.spec.disks.diskList}")
        tmp_disk_list=$(echo $tmp_disk_list | sed  's|\[||g; s|\]||g; s| |,|g')
        if [ -z $disk_list ]; then
            disk_list=$(echo $tmp_disk_list)
        else
            disk_list=$(echo $disk_list,$tmp_disk_list)
        fi
    done
    echo $disk_list
}

## get_disk_list_for_spc get the disks related to spc
function get_disk_list_for_spc() {
    local spc_name=$1
    local sp_list=$2
    local disk_list=$(kubectl get spc $spc_name -o jsonpath='{.spec.disks.diskList}')
    disk_list=$(echo $disk_list | sed  's|\[||g; s|\]||g; s| |,|g')
    if [ -n "$disk_list" ]; then
        disk_list=$(get_disk_list_for_sp_list $sp_list)
        make_map_node_disk_list $disk_list
    else
        disk_list=$(echo $disk_list | sed  's|\[||g; s|\]||g; s| |,|g')
        make_map_node_disk_list $disk_list
    fi
}

## make_csp_disk_list will return the jsonpath required to update the csp
function make_csp_disk_list() {
    local csp_disk_list=$1
    local disk_device_id=$2
    local disk_name=$3
    if [ "$csp_disk_list" == "init" ]; then
        echo "{\"deviceID\": \"$disk_device_id\",\"inUseByPool\": true,\"name\": \"$disk_name\"}"
    else
        echo "$csp_disk_list,{\"deviceID\": \"$disk_device_id\",\"inUseByPool\": true,\"name\": \"$disk_name\"}"
    fi
}

## Starting point
if [ "$#" -ne 2 ]; then
    usage
fi

spc=$1
ns=$2
declare -A node_disklist

### Get the deployment pods which are in not running state that are related to provided spc ###
pending_pods=$(kubectl get po -n $ns \
    -l app=cstor-pool,openebs.io/storage-pool-claim=$spc \
    -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}')


## If any deployments pods are in not running state then exit the upgrade process ###
if [ $(echo $pending_pods | wc -w) -ne 0 ]; then
    echo "To continue with upgrade script make sure all the pool deployment pods corresponding to $spc must be in running state"
    exit 1
fi

### Get the csp list which are related to the given spc ###
csp_list=$(get_csp_list $spc)

### Get the sp list which are related to the given spc ###
sp_list=$(kubectl get sp -l openebs.io/cas-type=cstor,openebs.io/storage-pool-claim=$spc \
        -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
rc=$?
if [ $rc -ne 0 ]; then
    echo "Failed to get sp related to spc $spc"
    exit 1
fi

#### Get required info from current csp and use the info while upgrading ####
for csp_name in `echo $csp_list | tr ":" " "`; do
    ## Check CSP version ##
    version=$(verify_openebs_version "csp" $csp_name)
    rc=$?
    if [ $rc -ne 0 ]; then
        exit 1
   # elif [ $version == $pool_upgrade_version ]; then
        #continue
    fi

    ## Get disk info from corresponding sp ##
    sp_name=$(kubectl get sp -l openebs.io/cstor-pool=$csp_name \
                  -o jsonpath="{.items[*].metadata.name}")
    sp_disk_list=$(kubectl get sp $sp_name -o jsonpath="{.spec.disks.diskList}" | sed 's|\[||g; s|\]||g; s| |,|g')
    csp_disk_list="init"
    for disk_name in `echo $sp_disk_list | tr "," " "`; do
         ## TODO: Assuming device Id present in first index
         device_id=$(kubectl get disk $disk_name -o jsonpath="{.spec.devlinks[0].links[0]}")
         if [ -z device_id ]; then
             device_id=$(kubectl get disk $disk_name -o jsonpath="{.spec.path}")
         fi
         csp_disk_list=$(make_csp_disk_list "$csp_disk_list" "$device_id" "$disk_name")
    done
#    echo "DISK groups $csp_disk_list"
    sed "s|@pool_version@|$pool_upgrade_version|g" csp-patch.tpl.json | sed "s|@disk_list@|$csp_disk_list|g" > csp-patch.json
    echo "FILE OUTPUT"
    cat csp-patch.json
    kubectl patch csp $csp_name -p "$(cat csp-patch.json)" --type=merge
    rc=$?; if [ $rc -ne 0 ]; then echo "Error occured while upgrading the csp: $csp_name Exit Code: $rc"; exit; fi
done

rm csp-patch.json

### Make node_disklist which contains map of nodeName & disks attached to the node
get_disk_list_for_spc $spc $sp_list

##TODO for testing purpose and below snippet will be removed after WIP tag
# removed ####
echo "node disk list${!node_disklist[@]}"

for key in `echo ${!node_disklist[@]}`; do
    echo "$key - ${node_disklist[$key]}"
done
