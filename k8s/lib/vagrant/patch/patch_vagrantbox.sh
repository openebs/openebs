#!/bin/bash

kubeversion="1.7.5"

function fetch_k8s_scripts(){
    mkdir -p workdir/scripts/k8s/    
    cp ../../scripts/configure_k8s_master.sh workdir/scripts/k8s/
    cp ../../scripts/configure_k8s_host.sh workdir/scripts/k8s/
    cp ../../scripts/configure_k8s_weave.sh workdir/scripts/k8s/
    cp ../../scripts/configure_k8s_cred.sh workdir/scripts/k8s/
    cp ../../scripts/configure_k8s_dashboard.sh workdir/scripts/k8s/
}

function fetch_specs(){
    mkdir -p workdir/specs
    cp ../../../demo/specs/demo-vdbench-openebs.yaml workdir/specs/
    cp ../../../demo/specs/demo-fio-openebs.yaml workdir/specs/
}

function cleanup(){
    rm -rf workdir
}

#echo Gathering all the K8s configure scripts to be package
fetch_k8s_scripts

#echo Gathering sample k8s specs
fetch_specs

#echo Launch VM
vagrant up
vagrant package --output workdir/kubernetes-${kubeversion}.box

#echo Test the new box
mkdir -p workdir/test 
vagrant box add --name openebs/k8s-test-box --force workdir/kubernetes-${kubeversion}.box 
currdir=`pwd`
echo Launch Test VM
cp ../test/k8s/Vagrantfile workdir/test/
cd workdir/test; 
vagrant up
#vagrant destroy -f
#vagrant box remove openebs/k8s-test-box
#cd $currdir

echo Destroy the default vm
#vagrant destroy default

echo Clear working directory
#cleanup


