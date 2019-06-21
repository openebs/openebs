#!/bin/bash
## Below snippet will remove the openebs.io/version label from
## deployment.spec.selector.matchLabels

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <openebs-namespace>"
    echo
    echo "Get the namespace where openebs setup is running."
    exit 1
}

## is_patch_continue returns true if patch is required else false
function is_patch_continue() {
    local deploy_name=$1
    local res_name=$2
    local ns=$3
    local selector_version=$(kubectl get $res_name $deploy_name -n $ns \
         -o jsonpath='{.spec.selector.matchLabels.openebs\.io/version}')
    rc=$?; if [ $rc -ne 0 ]; then
        echo "Failed to get selector version from $deploy_name deployment name | Exit code: $rc"
        exit 1
    fi
    if [ -z "$selector_version" ]; then
        echo "false"
    else
        echo "true"
    fi
}

if [ "$#" -ne 1 ]; then
    usage
fi

ns=$1

## Remove openebs.io/version from maya-apiserver
## Get maya-apiserver deployment name
maya_deploy_name=$(kubectl get deploy \
                   -l name=maya-apiserver -n "$ns"\
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get maya apiserver deployment \
name | Exit code: $rc"; exit 1; fi

is_continue=$(is_patch_continue "$maya_deploy_name" "deployment" "$ns")
if [ "$is_continue" == "true" ]; then
    kubectl patch deploy "$maya_deploy_name" -p "$(cat deploy-patch.json)" -n "$ns"
    rc=$?; if [ $rc -ne 0 ]; then echo -n "Failed to patch deployment $maya_deploy_name | Exit code: $rc"; exit 1; fi
fi

### admission-server has label selector in deployment file so no need to patch

## Remove openebs.io/version from openebs-provisioner
## Get openebs-provisioner deployment name
provisioner_deploy_name=$(kubectl get deploy \
                   -l name=openebs-provisioner -n "$ns"\
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get provisioner deployment name | Exit code: $rc"; exit 1; fi

is_continue=$(is_patch_continue "$provisioner_deploy_name" "deployment" "$ns")
if [ "$is_continue" == "true" ]; then
    kubectl patch deploy "$provisioner_deploy_name" \
            -p "$(cat deploy-patch.json)" -n "$ns"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch deployment $provisioner_deploy_name | Exit code: $rc"; exit 1; fi
fi

## Remove openebs.io/version from snapshot-provisioner
## Get snapshot-provisioner deployment name
snapshot_deploy_name=$(kubectl get deploy \
                   -l name=openebs-snapshot-operator -n "$ns"\
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get snapshot deployment name \
| Exit code: $rc"; exit 1; fi

is_continue=$(is_patch_continue "$snapshot_deploy_name" "deployment" "$ns")
if [ "$is_continue" == "true" ]; then
    kubectl patch deploy "$snapshot_deploy_name" -p "$(cat deploy-patch.json)" -n "$ns"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch deployment $snapshot_deploy_name | Exit code: $rc"; exit 1; fi
fi

## Remove openebs.io/version from local-pvprovisioner
## Get localpv-provisioner deployment name
localpv_provisioner_deploy_name=$(kubectl get deploy \
                   -l name=openebs-localpv-provisioner -n "$ns"\
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get localpv provisioner \
deployment name | Exit code: $rc"; exit 1; fi

is_continue=$(is_patch_continue "$localpv_provisioner_deploy_name" "deployment" "$ns")
if [ "$is_continue" == "true" ]; then
    kubectl patch deploy "$localpv_provisioner_deploy_name" \
            -p "$(cat deploy-patch.json)" -n "$ns"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch deployment $local_pvprovisioner_deploy_name | Exit code: $rc"; exit 1; fi
fi

daemonset_name=$(kubectl get daemonset \
                   -l name=openebs-ndm,openebs.io/component-name=ndm -n "$ns" \
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get ndm daemonset name \
| Exit code: $rc"; exit 1; fi

is_continue=$(is_patch_continue "$daemonset_name" "daemonset" "$ns")
if [ "$is_continue" == "true" ]; then
    kubectl patch daemonset "$daemonset_name" -p "$(cat deploy-patch.json)" -n "$ns"
    rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch daemonset $daemonset_name | Exit code: $rc"; exit 1; fi
fi
echo "Successfully removed label selectors from openebs deployments"
exit 0
