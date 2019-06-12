#!/bin/bash

############################################################################
# STEP: Get all block devices present on the cluster and corresponding disk#
#                                                                          #
#                                                                          #
# NOTES: Obtain the pool deployments to perform upgrade operatio           #
############################################################################

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

function create_bdc_claim_bd() {
    local spc_name=$1
    local disk_name=$2
    local bd_name=$(echo $disk_name | sed 's|disk|blockdevice|')
    local bd_details=""
    local bd_details=$(kubectl get bd $bd_name -n $ns \
                         -o jsonpath='{.metadata.labels.kubernetes\.io/hostname}:bdc-{.metadata.uid}:{.metadata.namespace}')
    local node_name=$(echo $bd_details | cut -d ":" -f 1)
    local bdc_name=$(echo $bd_details | cut -d ":" -f 2)
    local bdc_namespace=$(echo $bd_details | cut -d ":" -f 3)

     local spc_uid=$(kubectl get spc $spc -o jsonpath='{.metadata.uid}')

    sed "s|@spc_name@|$spc_name|g" bdc-create.tpl.json | sed "s|@bdc_name@|$bdc_name|g" | sed "s|@bdc_namespace@|$bdc_namespace|g" | sed "s|@spc_uid@|$spc_uid|g" | sed "s|@bd_name@|$bd_name|g" | sed "s|@node_name@|$node_name" > bdc-create.json
    kubectl apply -f bdc-create.json
    rm bdc-create.json
}

function claim_blockdevices_sp() {
    local $spc_name=$1
    local sp_name=$2
    local bd_name=""
    sp_disk_list=$(kubectl get sp $sp_name -o jsonpath="{.spec.disks.diskList}" | sed 's|\[||g; s|\]||g; s| |,|g')
    for disk_name in `echo $sp_disk_list | tr "," " "`; do
        create_bdc_claim_bd $spc_name $disk_name
    done
}

function claim_blockdevices_csp() {
    local spc_name=$1
    local csp_list=$2
    local sp_name=""
    for csp_name in `echo $csp_list | tr ":" " "`; do
        sp_name=$(kubectl get sp -l openebs.io/cstor-pool=$csp_name \
                      -o jsonpath="{.items[*].metadata.name}")
        claim_blockdevices_sp $spc_name $sp_name
    done
}

### Get the spc list which are present in the cluster ###
spc_list=$(kubectl get spc -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")

#### Get required info from current spc and use the info while upgrading ####
for spc_name in `echo $spc_list | tr ":" " "`; do
    csp_list=$(get_csp_list $spc_name)
    claim_blockdevices_csp $spc_name $csp_list
done
