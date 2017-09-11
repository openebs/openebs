#!/bin/bash

# Location of the k8s configure scripts
scriptloc="/vagrant/workdir/scripts/k8s"

# Location of the sample k8s spec files
specloc="/vagrant/workdir/specs"

# Download and install needed packages.
# Install JSON Parser (jq) for patching kube-proxy
sudo apt-get update
sudo apt-get install -y unzip curl wget jq

mkdir -p /home/ubuntu/setup/k8s
cd /home/ubuntu/setup/k8s

cp ${scriptloc}/configure_k8s_master.sh .
cp ${scriptloc}/configure_k8s_cred.sh .
cp ${scriptloc}/configure_k8s_weave.sh .
cp ${scriptloc}/configure_k8s_host.sh .
cp ${scriptloc}/configure_k8s_dashboard.sh .

mkdir -p /home/ubuntu/demo/    
cd /home/ubuntu/demo/
cp ${specloc}/demo-vdbench-openebs.yaml .
cp ${specloc}/demo-fio-openebs.yaml .

