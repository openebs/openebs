#!/bin/bash
distribution=${1:-"ubuntu"}

# Location of the k8s configure scripts
scriptloc="/vagrant/workdir/scripts/k8s"

# Location of the sample k8s spec files
specloc="/vagrant/workdir/specs"

# Download and install needed packages.
# Install JSON Parser (jq) for patching kube-proxy
if [ "$distribution" = "ubuntu" ]; then
   
   apt-get update
   apt-get install -y unzip curl wget jq

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
else   
   
   yum install -y unzip curl wget
   
   wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
   chmod +x ./jq
   sudo mv jq /usr/bin
   
   yum install -y iscsi-initiator-utils
   systemctl enable iscsid && systemctl start iscsid

   mkdir -p /home/vagrant/setup/k8s
   cd /home/vagrant/setup/k8s

   cp ${scriptloc}/configure_k8s_master.sh .
   cp ${scriptloc}/configure_k8s_cred.sh .
   cp ${scriptloc}/configure_k8s_weave.sh .
   cp ${scriptloc}/configure_k8s_host.sh .
   cp ${scriptloc}/configure_k8s_dashboard.sh .

   mkdir -p /home/vagrant/demo/    
   cd /home/vagrant/demo/
   cp ${specloc}/demo-vdbench-openebs.yaml .
   cp ${specloc}/demo-fio-openebs.yaml .
fi