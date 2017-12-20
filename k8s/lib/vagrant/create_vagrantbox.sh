#!/bin/bash

kubeversion=${1:-"1.7.5"}

packageurl="https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages"

function fetch_k8s_scripts(){
    mkdir -p workdir/scripts/k8s/    
    cp ../scripts/configure_k8s_master.sh workdir/scripts/k8s/
    sed -i "s/.*kubeversion=.*/kubeversion=v${kubeversion}/g" workdir/scripts/k8s/configure_k8s_master.sh


    cp ../scripts/configure_k8s_host.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_weave.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_cred.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_dashboard.sh workdir/scripts/k8s/
}

function fetch_specs(){
    mkdir -p workdir/specs
    cp ../../demo/specs/demo-vdbench-openebs.yaml workdir/specs/
    cp ../../demo/specs/demo-fio-openebs.yaml workdir/specs/
}

function fetch_k8s_dpkgs(){
    mkdir -p workdir/dpkgs
    
    mapfile -t packagedownloadurls < <(curl -sS $packageurl \
    | grep _$kubeversion | awk '{print $2}' \
    | cut -d '/' -f2)

    length=${#packagedownloadurls[@]}
    for ((i = 0; i != length; i++)); do    
        wget "https://packages.cloud.google.com/apt/pool/${packagedownloadurls[i]}" -P workdir/dpkgs    
    done

    wget https://packages.cloud.google.com/apt/pool/kubernetes-cni_0.5.1-00_amd64_08cbe5c42366ec3184cc91a4353f6e066f2d7325b4db1cb4f87c7dcc8c0eb620.deb \
    -P workdir/dpkgs
}

function cleanup(){
    rm -rf workdir
}

echo Download Kubernetes Packages
fetch_k8s_dpkgs

echo Gathering all the K8s configure scripts to be package
fetch_k8s_scripts

echo Gathering sample k8s specs
fetch_specs

echo Launch VM
KUBE_VERSION=${kubeversion} vagrant up
vagrant package --output workdir/kubernetes-${kubeversion}.box


echo Test the new box
vagrant box add --name openebs/k8s-test-box --force workdir/kubernetes-${kubeversion}.box 
mkdir workdir/test 
currdir=`pwd`
cp test/k8s/Vagrantfile workdir/test/
cd workdir/test; 
vagrant up
#vagrant destroy -f
#vagrant box remove openebs/k8s-test-box
#cd $currdir

echo Destroy the default vm
#vagrant destroy default

echo Clear working directory
#cleanup


