#!/bin/bash

function fetch_k8s_scripts(){
    mkdir -p workdir/scripts/k8s/    
    cp ../scripts/configure_k8s_master.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_host.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_weave.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_cred.sh workdir/scripts/k8s/
}

function fetch_specs(){
    mkdir -p workdir/specs
    cp ../../demo/specs/demo-vdbench-openebs.yaml workdir/specs/
    cp ../../demo/specs/demo-fio-openebs.yaml workdir/specs/
}

function cleanup(){
    rm -rf workdir
}

echo Gathering all the K8s configure scripts to be package
fetch_k8s_scripts

echo Gathering sample k8s specs
fetch_specs

echo Launch VM

echo Clear working directory
cleanup
