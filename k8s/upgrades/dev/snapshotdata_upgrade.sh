run_snapshotdata_upgrades()
{
    if [ $# -eq 1 ]; then
        pv=$1
    else
        echo "please pass persistentVolume name got pv: $pv"
        exit 1
    fi
    # Get the list of volumesnapshotdata related to given PV
    volumesnapshotdata_list=$(kubectl get volumesnapshotdata\
                               -o jsonpath="{range .items[?(@.spec.persistentVolumeRef.name=='$pv')]}{@.metadata.name}:{end}")
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "failed to get snapshotdata name list"
        exit 1
    fi

    if [ ! -z $volumesnapshotdata_list ]; then

        pv_size=""
        pv_size=$(kubectl get pv $pv -o jsonpath='{.spec.capacity.storage}')
        rc=$?
        if [ $rc -ne 0 ]; then
            echo "failed to get pv: $pv size"
            exit 1
        fi

        ## update volumesnapshotdata-patch.tpl.json with pv size
        sed "s|@size@|$pv_size|g" volumesnapshotdata-patch.tpl.json > volumesnapshotdata-patch.json
        for snapdata_name in `echo $volumesnapshotdata_list | tr ":" " "`; do
            ## patch volumesnapshotdata cr ###
            kubectl patch volumesnapshotdata $snapdata_name -p "$(cat volumesnapshotdata-patch.json)" --type=merge
            rc=$?; if [ $rc -ne 0 ]; then echo "Error occurred while upgrading volumesnapshotdata name: $snapdata_name Exit Code: $rc"; exit; fi
        done
        ## Removes temporary file
        rm volumesnapshotdata-patch.json
    fi
}
