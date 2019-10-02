#!/bin/bash

echo "---------pre-upgrade logs----------" > log.txt

###############################################################################
# STEP 1: Get all block devices present on the cluster and corresponding disk #
# STEP 2: Create block device claim to claim corresponding block device       #
# STEP 3: Patch SPC to stop reconciliation                                    #
#                                                                             #
###############################################################################
updated_version="1.0.0"
current_version="0.9.0"

function error_msg() {
    echo -n "Pre-upgrade script failed. Please make sure pre-upgrade script is "
    echo -n "successful before continuing for next step. Contact OpenEBS team over slack for any further help."
}

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <openebs-namespace> <installation_mode>"
    echo
    echo "  <openebs-namespace> Namespace in which openebs control plane components are installed"
    echo "  <installation_mode> installation_mode would be \"helm\" if OpenEBS"
    echo "  is installed using \"helm\" charts (or) \"operator\" if OpenEBS is installed using \"operator yaml\""
    exit 1
}

function patch_disk() {
    disk=$1
    currentFS=$(kubectl get disk $disk -o jsonpath="{.spec.fileSystem}")
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get FS details of $disk : $rc"; exit 1; fi
    currentPartition=$(kubectl get disk $disk -o jsonpath="{.spec.partitionDetails}")
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get Partition details of $disk : $rc"; exit 1; fi


    # if current filesystem is not nil, patch and remove the field
    if [ ! -z "$currentFS" ]; then
        kubectl patch disk --type json ${disk} -p "$(cat patch-remove-filesystem.json)"
        rc=$?; if [ $rc -ne 0 ]; then echo "ERRORFS: $disk : $rc"; exit 1; fi
        echo "FS of ${disk} patched"
    fi

    # if current partition struct is not nil, patch and remove the field
    if [ ! -z "$currentPartition" ]; then
        kubectl patch disk --type json ${disk} -p "$(cat patch-remove-partition.json)"
        rc=$?; if [ $rc -ne 0 ]; then echo "ERRORPT: $disk : $rc"; exit 1; fi
        echo "Partition of ${disk} patched"
    fi
}

function is_annotation_patch_continue() {
    local spc_name=$1
    local reconcile_value=$(kubectl get spc $spc_name \
              -o jsonpath='{.metadata.annotations.reconcile\.openebs\.io/disable}')
    if [ -z "$reconcile_value" ]; then
        echo "true"
    else
        echo "false"
    fi
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
        error_msg
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
    local bd_details=$(kubectl get disk $disk_name \
                       -o jsonpath='{.metadata.labels.kubernetes\.io/hostname}:bdc-{.metadata.uid}')
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get disk: $disk_name details | Exit Code: $rc"; error_msg; exit 1; fi

    local node_name=$(echo $bd_details | cut -d ":" -f 1)
    local bdc_name=$(echo $bd_details | cut -d ":" -f 2)

    local spc_uid=$(kubectl get spc $spc_name -o jsonpath='{.metadata.uid}')
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get spc: $spc_name UID | Exit Code: $rc"; error_msg; exit 1; fi

    sed "s|@spc_name@|$spc_name|g" bdc-create.tpl.json | \
                        sed "s|@bdc_name@|$bdc_name|g" | \
                        sed "s|@bdc_namespace@|$ns|g"  | \
                        sed "s|@spc_uid@|$spc_uid|g"   | \
                        sed "s|@bd_name@|$bd_name|g"   | \
                        sed "s|@node_name@|$node_name|g" > bdc-create.json

    ## Create block device claim
    kubectl apply -f bdc-create.json
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to create bdc: $bdc_name in namespace $ns | Exit Code: $rc"
        error_msg
        rm bdc-create.json
        exit 1
    fi

    ## cleanup temporary file
    rm bdc-create.json
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
                          awk '{print $1}' | grep -v cstor | grep -v ${map_pool_type[$pool_type]})
    echo $zpool_disk_list
}

## claim_blockdevices_csp accepts spc name and csp list as a parameters
function claim_blockdevices_csp() {
    local spc_name=$1
    local csp_list=$2
    local sp_name=""
    local pool_pod_name=""
    local found=0
    local csp_disk_len=0
    local sp_disk_len=0
    local csp_disk_list=""
    local zpool_disk_list=""
    local sp_disk_list=""
    for csp_name in `echo $csp_list | tr ":" " "`; do
        echo "-----------------CSP $csp_name----------------" >> log.txt
        kubectl get csp $csp_name -o yaml >> log.txt

        local csp_version=$(kubectl get csp $csp_name \
                        -o jsonpath="{.metadata.labels.openebs\.io/version}")
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get csp: $csp_name version | Exit Code: $rc"; error_msg; exit 1; fi
        if [ $csp_version != $updated_version ] && [ $csp_version != $current_version ]; then
            echo -n "csp $csp_name is not in current version $current_version or "
            echo "updated version $updated_version"
            exit 1
        fi

        if [ $csp_version == $updated_version ]; then
            continue
        fi
        pool_pod_name=$(kubectl get pod -n $ns \
                        -l app=cstor-pool,openebs.io/cstor-pool=$csp_name,openebs.io/storage-pool-claim=$spc_name \
                        -o jsonpath="{.items[0].metadata.name}")
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get pool pod name for csp: $csp_name | Exit Code: $rc"; error_msg; exit 1; fi

        pool_type=$(kubectl get csp $csp_name \
                    -o jsonpath='{.spec.poolSpec.poolType}')
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get pool type for csp: $csp_name | Exit Code: $rc"; error_msg; exit 1; fi


        csp_disk_list=$(kubectl get csp $csp_name \
                        -o jsonpath='{.spec.disks.diskList}' | \
                        tr "[]" " ")
        csp_disk_len=$(echo $csp_disk_list | wc -w)

        zpool_disk_list=$(get_underlying_disks $pool_pod_name $pool_type)

        if [ -z "$zpool_disk_list" ]; then
            echo "zpool disk list is empty"
            error_msg
            exit 1
        fi

        if [ $csp_disk_len == 0 ]; then
            echo "csp disk list is empty"
            error_msg
            exit 1
        fi

        ## In some platforms we are getting some suffix to the zpool_disk_list
        for zpool_disk in $zpool_disk_list; do
            found=0
            for csp_disk in $csp_disk_list; do
                if [[ "$zpool_disk" == "$csp_disk"* ]]; then
                    found=1
                    break
                fi
            done
            if [ $found == 0 ]; then
                echo "zpool disk: $zpool_disk is not found in csp: $csp_name disk list: {$csp_disk_list}"
                error_msg
                exit 1
            fi
        done

        sp_name=$(kubectl get sp \
                  -l openebs.io/cstor-pool=$csp_name \
                  -o jsonpath="{.items[*].metadata.name}")
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get sp name related to csp: $csp_name | Exit Code: $rc"; error_msg; exit 1; fi
        echo "- - - - - - SP $sp_name- - - - - -" >> log.txt
        kubectl get sp $sp_name -o yaml >> log.txt
        echo "- - - - - - - - - - - - - - - - - " >> log.txt

        ## kubectl command get output in below format
        ## [sparse-37a7de580322f43a sparse-5a92ced3e2ee21 sparse-5e508018b4dd2c8]
        ## and then converts to below format
        ## sparse-37a7de580322f43a sparse-5a92ced3e2ee21 sparse-5e508018b4dd2c8
        sp_disk_list=$(kubectl get sp $sp_name \
                       -o jsonpath="{.spec.disks.diskList}" | tr "[]" " ")

        sp_disk_len=$(echo $sp_disk_list | wc -w)

        if [ $sp_disk_len -ne $csp_disk_len ]; then
            echo "Length of csp disk list $csp_disk_len and sp disk list $sp_disk_len is not matched"
            error_msg
            exit 1
        fi


        for disk_name in $sp_disk_list; do
            echo "######disk $disk_name#######" >> log.txt
            kubectl get disk $disk_name -o yaml >> log.txt
            echo "############################" >> log.txt
            create_bdc_claim_bd $spc_name $disk_name
        done
        echo "---------------------------------------------" >> log.txt
    done
}


## Starting point
if [ "$#" -ne 2 ]; then
    usage
fi
ns=$1
install_option=$2

if [ "$install_option" != "operator" ] && [ "$install_option" != "helm" ]; then
    echo "Second argument must be either \"operator\" or \"helm\""
    exit 1
fi

declare -A map_pool_type
map_pool_type["mirrored"]="mirror"
map_pool_type["striped"]="striped"
map_pool_type["raidz"]="raidz"
map_pool_type["raidz2"]="raidz2"


## Apply blockdeviceclaim crd yaml to create CR
kubectl apply -f blockdeviceclaim_crd.yaml
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to create blockdevice crd | Exit Code: $rc"; error_msg; exit 1; fi

kubectl get nodes -n $ns --show-labels >> log.txt
echo >> log.txt
echo >> log.txt

kubectl get pods -n $ns --show-labels >> log.txt
echo >> log.txt
echo >> log.txt

### Get the spc list which are present in the cluster ###
spc_list=$(kubectl get spc -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to list spc in cluster | Exit Code: $rc"; error_msg; exit 1; fi

#### Get required info from current spc and use the info to claim block device ####
for spc_name in `echo $spc_list | tr ":" " "`; do
    echo "========================SPC $spc_name==========================" >> log.txt
    kubectl get spc $spc_name -o yaml >> log.txt
    csp_list=$(get_csp_list $spc_name)
    claim_blockdevices_csp $spc_name $csp_list
    echo "==============================================================" >> log.txt

    is_patch=$(is_annotation_patch_continue $spc_name)
    if [ $is_patch == "true" ]; then
        ## Patching the spc resource with label
        kubectl patch spc $spc_name -p "$(cat stop-reconcile-patch.json)" --type=merge
        rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch spc: $spc_name with reconcile annotation | Exit Code: $rc"; error_msg; exit 1; fi
    fi
done

ds_name=$(kubectl get pod -n $ns -l openebs.io/component-name=ndm \
         -o jsonpath='{.items[0].metadata.ownerReferences[?(@.kind=="DaemonSet")].name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get ndm daemonset name in namespace: $ns | Exit Code: $rc"; error_msg; exit 1; fi

desired_count=$(kubectl get daemonset $ds_name -n $ns \
         -o jsonpath='{.status.desiredNumberScheduled}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get desired scheduled pod count from $ds_name in namespace: $ns | Exit Code: $rc"; error_msg; exit 1; fi

current_count=$(kubectl get daemonset $ds_name -n $ns \
         -o jsonpath='{.status.currentNumberScheduled}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get current scheduled pod count from $ds_name in namespace: $ns | Exit Code: $rc"; error_msg; exit 1; fi

if [ $desired_count != $current_count ]; then
    echo "Daemonset desired pod count: $desired_count is not matched with current pod count: $current_count"
    error_msg
    exit 1
fi

disk_list=$(kubectl get disks -o jsonpath="{range .items[*]}{.metadata.name}:{end}")
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get disk list : $rc"; exit 1; fi

for disk_name in `echo $disk_list | tr ":" " "`; do
    patch_disk $disk_name
done

if [ $install_option == "operator" ]; then
    ./label_patch.sh $ns
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to patch control plane deployments"
        error_msg
        exit 1
    fi
fi

echo "Pre-Upgrade is successful Please update openebs components"
