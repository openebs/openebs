#!/bin/bash

###############################################################################
# STEP: Get Storage Classes                                                   #
###############################################################################

# Get the list of storageclasses, delimited by ':'
sc_list=`kubectl get sc \
 -o jsonpath="{range .items[*]}{@.metadata.name}:{end}"`
rc=$?;
if [ $rc -ne 0 ]; 
then 
  echo "ERROR: $rc"; 
  echo "Please ensure `kubectl` is installed and can access your cluster."; 
  exit; 
fi

echo "Check if openebs storage class parameters are moved to config annotation"
for sc in `echo $sc_list | tr ":" " "`; do
    pt="";pt=`kubectl get sc $sc -o jsonpath="{.provisioner}"`
    if [ "openebs.io/provisioner-iscsi"  == "$pt" ];
    then
       uc="";uc=`kubectl get sc $sc -o jsonpath="{.metadata.labels.openebs\.io/cas-type}"`
       if [ ! -z $uc ]; then 
         echo "SC $sc already upgraded";
         continue
       fi

       echo "Upgrading SC $sc";

       replicas=`kubectl get sc $sc -o jsonpath="{.parameters.openebs\.io/jiva-replica-count}"`
       pool=`kubectl get sc $sc -o jsonpath="{.parameters.openebs\.io/storage-pool}"`
       monitoring=`kubectl get sc $sc -o jsonpath="{.parameters.openebs\.io/volume-monitor}"`
       fstype=`kubectl get sc $sc -o jsonpath="{.parameters.openebs\.io/fstype}"`

       if [ -z $replicas ]; then replicas="3"; fi
       sed "s/@jiva-replica-count[^ \"]*/$replicas/g" sc.patch.tpl.yaml > sc.patch.tpl.yaml.0

       if [ -z $pool ]; then pool="default"; fi
       sed "s/@storage-pool[^ \"]*/$pool/g" sc.patch.tpl.yaml.0 > sc.patch.tpl.yaml.1

       if [ -z $monitoring ]; then monitoring="true"; fi
       sed "s/@volume-monitor[^ \"]*/$monitoring/g" sc.patch.tpl.yaml.1 > sc.patch.tpl.yaml.2

       if [ -z $fstype ]; then fstype="ext4"; fi
       sed "s/@fstype[^ \"]*/$fstype/g" sc.patch.tpl.yaml.2 > sc.patch.yaml

       echo " openebs.io/jiva-replica-count -> ReplicaCount : $replicas"
       echo " openebs.io/storage-pool -> StoragePool : $pool"
       echo " openebs.io/volume-monitor -> VolumeMonitor : $monitoring"
       echo " openebs.io/fstype -> FSType : $fstype"

       kubectl patch sc $sc -p "$(cat sc.patch.yaml)"
       rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: $rc"; exit; fi

       rm -rf sc.patch.tpl.yaml.0
       rm -rf sc.patch.tpl.yaml.1
       rm -rf sc.patch.tpl.yaml.2
       rm -rf sc.patch.yaml

       #TODO
       # Check if SC has other parameters and warn the user about patching them manually.
       # or contact openebs dev.

       echo "Successfully upgraded $sc to 0.8.1"
    fi
done


