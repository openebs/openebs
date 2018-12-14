#!/bin/bash

################################################################
# STEP: Verify if upgrade needs to be performed                #
#   Check the version of OpenEBS installed                     #
#   Check if default jiva storage pool or storage class can    #
#     conflict with the installed storage pool or class        #
#   Check if there are any PVs that need to be upgraded        #
#                                                              #
################################################################

function print_usage() {
    echo 
    echo "Usage:"
    echo 
    echo "$0 <openebs-namespace>"
    echo 
    echo "  <openebs-namepsace> Namespace where openebs control"
    echo "    plane pods like maya-apiserver are installed.    "
    exit 1
}

if [ "$#" -ne 1 ]; then
    print_usage
fi


oens=$1


echo
VERSION_INSTALLED=`kubectl get deploy -n $oens -o yaml \
 | grep m-apiserver | grep image: \
 | awk -F ':' '{print $3}'`


echo "Installed Version: $VERSION_INSTALLED" 
if [ -z $VERSION_INSTALLED ] || [ $VERSION_INSTALLED = "0*" ]; then 
    echo "Unable to determine installed openebs version"
    print_usage
elif test `echo $VERSION_INSTALLED | grep -c 0.6.` -eq 0; then
    echo "Upgrade is supported only from 0.6.0"
    exit 1
fi


echo
kubectl get sp default 2>/dev/null
rc=$? 
if [ $rc -eq 0 ]; then 
   POOL_PATH=`kubectl get sp default -o jsonpath='{.spec.path}'`
   if [ $POOL_PATH = "/var/openebs" ]; then
     echo "Found Jiva StoragePool named 'default' with path as /var/openebs"
   else
     echo "Found Jiva StoragePool named 'default' with cutomized path"
     echo " After upgrading to 0.7.0, you will need to re-apply your StoragePool"
     echo " or consider renaming the pool." 
     exit 1
   fi
else
   echo "Jiva StoragePool named 'default' was not found"
fi

echo
OLDER_PVS=`kubectl get pods --all-namespaces -l openebs/controller | wc -l`
if [ -z $OLDER_PVS ] || [ $OLDER_PVS -lt 2 ]; then 
    echo "There are no PVs that need to be upgraded to 0.7.0"
else
    echo "Found PVs that need to be upgraded to 0.7.0"
fi

echo
exit 0


