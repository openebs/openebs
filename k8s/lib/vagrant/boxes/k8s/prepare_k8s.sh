#!/bin/bash

# Location of the k8s configure scripts
scriptloc="/vagrant/workdir/scripts/k8s/"

# Location of the sample k8s spec files
scriptloc="/vagrant/workdir/specs/"

# Download and install needed packages.
sudo apt-get update
sudo apt-get install -y unzip curl wget

#Install JSON Parser for patching kube-proxy
sudo apt-get install -y jq

mkdir -p /home/ubuntu/setup/k8s
cd /home/ubuntu/setup/k8s

cp ${scriptloc}/configure_k8s_master.sh .
cp ${scriptloc}/configure_k8s_cred.sh .
cp ${scriptloc}/configure_k8s_weave.sh .
cp ${scriptloc}/configure_k8s_host.sh .

cd /home/ubuntu/demo/k8s/spec    
cp ${scriptloc}/demo-vdbench-openebs.sh .
cp ${scriptloc}/demo-fio-openebs.sh .

