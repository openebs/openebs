#!/bin/bash

#Variables:
machineip=
hostname=`hostname`

#Functions:
function install_kubernetes(){
    echo Running the Kubernetes installer...

    # Update apt and get dependencies
    sudo apt-get update
    sudo apt-get install -y unzip curl wget

    # Install docker and K8s
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - 
    sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF >/dev/null
    deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    sudo apt-get update
    # Install docker if you don't have it already.
    sudo apt-get install -y docker.io
    sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

    #Install JSON Parser for patching kube-proxy
    sudo apt-get install -y jq
}

function get_machine_ip(){
    ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | sort | tail -n 1 | head -n 1
}

function setup_k8s_master(){
    sudo kubeadm init --api-advertise-addresses=$machineip
    kubectl create -f https://git.io/weave-kube
}

function update_hosts(){
    sudo sed -i "/$hostname/ s/.*/$machineip\t$hostname/g" /etc/hosts
}

function patch_kube_proxy(){
    kubectl -n kube-system get ds -l 'component=kube-proxy' -o json | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' | kubectl apply -f - && kubectl -n kube-system delete pods -l 'component=kube-proxy'
}

function download_specs(){

    specurl="https://api.github.com/repos/openebs/openebs/contents/k8s/demo/specs"
    mapfile -t downloadurls < <(curl -sS $specurl | grep "download_url" | awk '{print $2}' | tr -d '",')
    
    #Create demo directory and download specs
    mkdir -p /home/ubuntu/demo/k8s/spec
    cd /home/ubuntu/demo/k8s/spec    
    
    length=${#downloadurls[@]}
    for ((i = 0; i != length; i++)); do
        if [ -z "${downloadurls[i]##*yaml*}" ] ;then
            wget "${downloadurls[i]}"
        fi
    done
    
}

#Code
#Get the ip of the machine
machineip=`get_machine_ip`

#Install Kubernetes components
echo Installing Kubernetes on Master...
install_kubernetes

#Update the host file of the master.
echo Updating the host file...
update_hosts

#Create the Cluster
echo Setting up the Master using IPAddress: $machineip
setup_k8s_master

#Patching kube-proxy to run with --proxy-mode=userspace
echo Patching the kube-proxy for CNI Networks...
patch_kube_proxy

#Download the specs for the demo
echo Downloading samples for demo...
download_specs
