#!/bin/bash

##Checking the version of OpenEBS ####
function verify_openebs_version() {
    local resource=$1
    local name_res=$2
    local ns=$ns
    local openebs_version=$(kubectl get $resource $name_res -n $ns \
                 -o jsonpath="{.metadata.labels.openebs\.io/version}")
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to get version from $resource: $name_res | Exit Code: $rc"
        error_msg
        exit 1
    fi

    if [[ $openebs_version != $current_version ]] && \
          [[ $openebs_version != $upgrade_version ]]; then
        echo "Expected version of $name_res in $resource is $current_version but got $openebs_version"
        error_msg
        exit 1;
    fi
    echo $openebs_version
}

## get_csp_list will return the csp list related corresponding spc
function get_csp_list() {
    local csp_list=""
    local spc_name=$1
    csp_list=$(kubectl get csp \
               -l openebs.io/storage-pool-claim=$spc_name \
               -o jsonpath="{range .items[*]}{@.metadata.name}:{end}")
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Failed to get csp related to spc $spc_name"
        error_msg
        exit 1
    fi
    echo $csp_list
}

function verify_pod_image_tag() {
    local pod_name=$1
    local container_name=$2
    local ns=$3

    local image=$(kubectl get pod $pod_name -n $ns \
               -o jsonpath="{.spec.containers[?(@.name=='$container_name')].image}")
    local image_tag=$(echo "$image" | cut -d ':' -f '2')
    echo "$image_tag"
}
