#!/bin/bash

echo "---------pre-upgrade logs----------" > log.txt

current_version="1.0.0"
updated_version="1.1.0"

# STEP 1: patch (rename) finalizer in all existing BDCs
#       "blockdeviceclaim.finalizer" -> "openebs.io/bdc-protection"
# STEP 2: add a new finalizer in all BDCs(both localPV and cstor)
# STEP 3: Add a new finalizer to existing SPCs

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$0 <openebs-namespace>"
    echo
    echo "  <openebs-namespace> Namespace in which openebs control plane components are installed"
    exit 1
}

# remove any finalizers on BDC if it exists
function remove_bdc_ndm_finalizer() {
    local bdc=$1
    local ns=$2

    currentFinalizer=$(kubectl get bdc ${bdc} -n ${ns} -o jsonpath='{.metadata.finalizers}')
    rc=$?; if [ $rc -ne 0 ]; then echo "Error getting finalizers on BDC: $bdc : $rc"; exit 1; fi
    if [ -n "$currentFinalizer" ]; then
        kubectl patch bdc ${bdc} -n ${ns} --type json -p "$(cat patch_remove_bdc_finalizer.json)"
        rc=$?; if [ $rc -ne 0 ]; then echo "Error removing finalizers on BDC: $bdc : $rc"; exit 1; fi
    fi
}
# Usage:
#       add_bdc_ndm_finalizer  <bdc-name> <namespace>
# This function adds the NDM finalizer in a `Bound` BDC
function add_bdc_ndm_finalizer() {
    local bdc=$1
    local ns=$2

    # phase of BDC
    phase=$(kubectl get bdc ${bdc} -n ${ns} -o jsonpath='{.status.phase}')

    # patch the BDC with NDM finalizer only if it is bound
    if [[ "$phase" == "Bound" ]]; then
        kubectl patch bdc ${bdc} -n ${ns} --type json -p "$(cat patch-add-bdc-finalizer.json)"
        rc=$?; if [ $rc -ne 0 ]; then echo "Error adding NDM finalizer in BDC: $bdc : $rc"; exit 1; fi
    fi
}

# Usage:
#       add_bdc_localPV_finalizer  <bdc-name> <namespace>
# This function adds a localPV finalizer to the BDC
function add_bdc_localPV_finalizer() {
    local bdc=$1
    local ns=$2

    kubectl patch bdc ${bdc} -n ${ns} --type json -p "$(cat patch-add-localpv-finalizer.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "Error adding localPV finalizer to BDC: $bdc : $rc"; exit 1; fi
}

# Usage:
#       add_bdc_spc_finalizer  <bdc-name> <namespace>
# This function adds a SPC finalizer to the BDC
function add_bdc_spc_finalizer() {
    local bdc=$1
    local ns=$2

    kubectl patch bdc ${bdc} -n ${ns} --type json -p "$(cat patch-add-spc-finalizer.json)"
    rc=$?; if [ $rc -ne 0 ]; then echo "Error adding SPC finalizer to BDC: $bdc : $rc"; exit 1; fi
}

# remove existing finalizer and
# add all required finalizer to a BDC
function add_finalizer() {
    local bdc=$1
    local ns=$2

    # remove finalizers on BDC
    remove_bdc_ndm_finalizer ${bdc} ${ns}

    # check if BDC is created by localPV or SPC
    val=$(kubectl get bdc ${bdc} -n ${ns} -o jsonpath='{.metadata.labels.openebs\.io/storage-pool-claim}')

    # if label does not exist, then the bdc is created by local PV provisioner
    if [[ -z "$val" ]]; then
        #localpv
        add_bdc_localPV_finalizer ${bdc} ${ns}
    else
        # if the label is present, then the bdc is created by cStor
        add_bdc_spc_finalizer ${bdc} ${ns}
    fi

    # add NDM finalizer on BDC
    add_bdc_ndm_finalizer ${bdc} ${ns}
}

if [ "$#" -ne 1 ]; then
    usage
fi

ns=$1

bdc_list=$(kubectl get bdc -n ${ns} -o jsonpath='{range .items[*]}{@.metadata.name}:{end}')
rc=$?; if [ $rc -ne 0 ]; then echo "Error listing BDCs : $rc"; exit 1; fi

echo "=======BDCs======" >> log.txt
echo $bdc_list | tr ":" "\n" >> log.txt

for bdc_name in `echo $bdc_list | tr ":" " "`; do
    add_finalizer ${bdc_name} ${ns}
done