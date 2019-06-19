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
name | Exit code: $rc"; exit; fi

kubectl patch deploy "$maya_deploy_name" -p "$(cat deploy-patch.json)" -n "$ns"
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch deployment $maya_deploy_name \
| Exit code: $rc"; exit; fi

### admission-server has label selector in deployment file so no need to patch

## Remove openebs.io/version from openebs-provisioner
## Get openebs-provisioner deployment name
provisioner_deploy_name=$(kubectl get deploy \
                   -l name=openebs-provisioner -n "$ns"\
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get provisioner deployment name \
| Exit code: $rc"; exit; fi

kubectl patch deploy "$provisioner_deploy_name" \
        -p "$(cat deploy-patch.json)" -n "$ns"
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch deployment \
$provisioner_deploy_name | Exit code: $rc"; exit; fi

## Remove openebs.io/version from snapshot-provisioner
## Get snapshot-provisioner deployment name
snapshot_deploy_name=$(kubectl get deploy \
                   -l name=openebs-snapshot-operator -n "$ns"\
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get snapshot deployment name \
| Exit code: $rc"; exit; fi

kubectl patch deploy "$snapshot_deploy_name" -p "$(cat deploy-patch.json)" -n "$ns"
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch deployment \
$snapshot_deploy_name | Exit code: $rc"; exit; fi

## Remove openebs.io/version from local-pvprovisioner
## Get local-pvprovisioner deployment name
local_pvprovisioner_deploy_name=$(kubectl get deploy \
                   -l name=openebs-localpv-provisioner -n "$ns"\
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get localpv provisioner \
deployment name | Exit code: $rc"; exit; fi

kubectl patch deploy "$local_pvprovisioner_deploy_name" \
        -p "$(cat deploy-patch.json)" -n "$ns"
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch deployment \
$local_pvprovisioner_deploy_name | Exit code: $rc"; exit; fi

daemonset_name=$(kubectl get daemonset \
                   -l name=openebs-ndm,openebs.io/component-name=ndm -n "$ns" \
                   -o jsonpath='{.items[0].metadata.name}')
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to get ndm daemonset name \
| Exit code: $rc"; exit; fi

kubectl patch daemonset "$daemonset_name" -p "$(cat deploy-patch.json)" -n "$ns"
rc=$?; if [ $rc -ne 0 ]; then echo "Failed to patch daemonset $daemonset_name \
| Exit code: $rc"; exit; fi

echo "Successfully removed label selectors from openebs deployments"
exit 0
