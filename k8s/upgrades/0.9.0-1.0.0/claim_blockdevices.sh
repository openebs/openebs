#!/bin/bash

###############################################################################
# STEP 1: Get all block devices present on the cluster and corresponding disk #
# STEP 2: Create block device claim to claim corresponding block device       #
# STEP 3: Patch SPC to stop reconciliation                                    #
#                                                                             #
###############################################################################
function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <openebs-namespace>"
    echo
    echo "  <openebs-namespace> Get the namespace where openebs setup is running"
    exit 1
}

## get_csp_list accepts spc_name as a argument and returns csp list
## corresponding to csp
function get_csp_list() {
    local csp_list=""
    local spc_name=$1

    csp_list=$(kubectl get csp \
               -l openebs.io/storage-pool-claim=$spc_name \
               -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to get csp related to spc $spc"
        exit 1
    fi
    echo $csp_list
}

## create_bdc_claim_bd accepts spc and disk names as a argument and create block
## device claims to claim corresponding block device
function create_bdc_claim_bd() {
    local spc_name=$1
    local disk_name=$2
    local bd_name=$(echo $disk_name | sed 's|disk|blockdevice|')

    ## Below command will get the output as below format
    ## nodename:bdc-123454321
    local bd_details=$(kubectl get disk $bd_name \
                       -o jsonpath='{.metadata.labels.kubernetes\.io/hostname}:bdc-{.metadata.uid}')
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get disk: $disk_name details Exit Code: $rc"; exit; fi

    local node_name=$(echo $bd_details | cut -d ":" -f 1)
    local bdc_name=$(echo $bd_details | cut -d ":" -f 2)

    local spc_uid=$(kubectl get spc $spc_name -o jsonpath='{.metadata.uid}')
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get spc: $spc_name UID Exit Code: $rc"; exit; fi

    sed "s|@spc_name@|$spc_name|g" bdc-create.tpl.json | \
                        sed "s|@bdc_name@|$bdc_name|g" | \
                        sed "s|@bdc_namespace@|$ns|g" | \
                        sed "s|@spc_uid@|$spc_uid|g" | \
                        sed "s|@bd_name@|$bd_name|g" | \
                        sed "s|@node_name@|$node_name|g" > bdc-create.json

    ## Create block device claim
    kubectl apply -f bdc-create.json
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to create bdc: $bdc_name in namespace $ns Exit Code: $rc"; exit; fi

    ## cleanup temporary file
    rm bdc-create.json
}

## claim_blockdevices_sp accepts spc and sp names as a parameters
function claim_blockdevices_sp() {
    local spc_name=$1
    local sp_name=$2
    ## kubectl command get output in below format
    ## [sparse-37a7de580322f43a sparse-5a92ced3e2ee21 sparse-5e508018b4dd2c8]
    ## and then converts to below format
    ## sparse-37a7de580322f43a,sparse-5a92ced3e2ee21,sparse-5e508018b4dd2c8
    sp_disk_list=$(kubectl get sp $sp_name \
                   -o jsonpath="{.spec.disks.diskList}" | sed 's|\[||g; s|\]||g; s| |,|g')
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to list disks related to sp: $sp_name Exit Code: $rc"; exit; fi

    for disk_name in `echo $sp_disk_list | tr "," " "`; do
        create_bdc_claim_bd $spc_name $disk_name
    done
}

## Output of below command
## kubectl exec cstor-sparse-d9r7-66cd7b798c-4qjnt -n openebs -c cstor-pool -- zpool list -v -H -P | awk '{print $1}'
## cstor-49a012ee-8f1a-11e9-8773-54e1ad4a9dd4
## mirror
## /var/openebs/sparse/3-ndm-sparse.img
## /var/openebs/sparse/0-ndm-sparse.img
## from the above output extracting disk names
function get_underlying_disks() {
    local pod_name=$1
    local pool_type=$2
    local zpool_disk_list=$(kubectl exec $pod_name -n $ns -c cstor-pool \
                          -- zpool list -v -H -P | \
                          awk '{print $1}' | grep -v cstor | grep -v ${map_pool_type[$pool_type]} | sort)
    echo $zpool_disk_list
}

## claim_blockdevices_csp accepts spc name and csp list as a parameters
function claim_blockdevices_csp() {
    local spc_name=$1
    local csp_list=$2
    local sp_name=""
    local pool_pod_name=""
    for csp_name in `echo $csp_list | tr ":" " "`; do
        pool_pod_name=$(kubectl get pod -n $ns \
                        -l app=cstor-pool,openebs.io/cstor-pool=$csp_name,openebs.io/storage-pool-claim=$spc_name \
                        -o jsonpath="{.items[0].metadata.name}")

        pool_type=$(kubectl get csp $csp_name \
                    -o jsonpath='{.spec.poolSpec.poolType}')


        csp_disk_list=$(kubectl get csp $csp_name \
                        -o jsonpath='{.spec.disks.diskList}' | \
                        sed 's|\[||g; s|\]||g; s| |,|g'  | tr , "\n" | sort)
        ## csp_disk_list holds the same format for commparision with
        ## zpool_disk_list
        csp_disk_list=$(echo $csp_disk_list)

        zpool_disk_list=$(get_underlying_disks $pool_pod_name $pool_type)

        if [ "$csp_disk_list" != "$zpool_disk_list" ]; then
            echo "missmatch of disks in csp $csp_name"
            exit 1
        fi
        sp_name=$(kubectl get sp \
                  -l openebs.io/cstor-pool=$csp_name \
                  -o jsonpath="{.items[*].metadata.name}")
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get sp related to csp: $csp_name Exit Code: $rc"; exit; fi

        claim_blockdevices_sp $spc_name $sp_name
    done
}


## Starting point
if [ "$#" -ne 1 ]; then
    usage
fi
ns=$1
declare -A map_pool_type
map_pool_type["mirrored"]="mirror"
map_pool_type["striped"]="striped"
map_pool_type["raidz"]="raidz"
map_pool_type["raidz2"]="raidz2"

## Apply blockdeviceclaim crd yaml to create CR
kubectl apply -f blockdeviceclaim_crd.yaml
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to create blockdevice crd Exit Code: $rc"; exit; fi


### Get the spc list which are present in the cluster ###
spc_list=$(kubectl get spc -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to list spc present in cluster Exit Code: $rc"; exit; fi

#### Get required info from current spc and use the info to claim block device ####
for spc_name in `echo $spc_list | tr ":" " "`; do
    csp_list=$(get_csp_list $spc_name)
    claim_blockdevices_csp $spc_name $csp_list

    ## Patching the spc resource with label
    kubectl patch spc $spc_name -p "$(cat spc-patch.tpl.json)" --type=merge
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch spc: $spc_name with reconcile label Exit Code: $rc"; exit; fi
done

## Below snippet will remove the openebs.io/version label from
## deployment.spec.selector.matchLabels

## Remove openebs.io/version from maya-apiserver
## Get maya-apiserver deployment name
maya_deploy_name=$(kubectl get deploy \
                   -l name=maya-apiserver -n $ns\
                   -o jsonpath='{.items[0].metadata.name}')

kubectl patch deploy $maya_deploy_name -p "$(cat deploy-patch.json)" -n $ns

## Remove openebs.io/version from admission-server
## Get admission-server deployment name
admission_deploy_name=$(kubectl get deploy \
                   -l app=admission-webhook -n $ns\
                   -o jsonpath='{.items[0].metadata.name}')

kubectl patch deploy $admission_deploy_name -p "$(cat deploy-patch.json)" -n $ns

## Remove openebs.io/version from openebs-provisioner
## Get openebs-provisioner deployment name
provisioner_deploy_name=$(kubectl get deploy \
                   -l name=openebs-provisioner -n $ns\
                   -o jsonpath='{.items[0].metadata.name}')
kubectl patch deploy $provisioner_deploy_name -p "$(cat deploy-patch.json)" -n $ns

## Remove openebs.io/version from snapshot-provisioner
## Get snapshot-provisioner deployment name
snapshot_deploy_name=$(kubectl get deploy \
                   -l name=openebs-snapshot-operator -n $ns\
                   -o jsonpath='{.items[0].metadata.name}')
kubectl patch deploy $snapshot_deploy_name -p "$(cat deploy-patch.json)" -n $ns

## Remove openebs.io/version from local-pvprovisioner
## Get local-pvprovisioner deployment name
local_pvprovisioner_deploy_name=$(kubectl get deploy \
                   -l name=openebs-localpv-provisioner -n $ns\
                   -o jsonpath='{.items[0].metadata.name}')
kubectl patch deploy $local_pvprovisioner_deploy_name -p "$(cat deploy-patch.json)" -n $ns

daemonset_name=$(kubectl get daemonset \
                   -l name=openebs-ndm,openebs.io/component-name=ndm -n $ns \
                   -o jsonpath='{.items[0].metadata.name}')
kubectl patch daemonset $daemonset_name -p "$(cat deploy-patch.json)" -n $ns
