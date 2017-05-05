#!/bin/bash

#Variables:
machineip=
hostname=`hostname`

function get_machine_ip(){
    ifconfig | \
    grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" \
    | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | sort |\
     tail -n 1 | head -n 1
}

function setup_k8s_master() {
    sudo kubeadm init --apiserver-advertise-address=$machineip \
    --kubernetes-version=v1.6.2        
}

function update_hosts(){
    sudo sed -i "/$hostname/ s/.*/$machineip\t$hostname/g" /etc/hosts
}

function patch_kube_proxy(){
    kubectl -n kube-system get ds -l \
    'component=kube-proxy' -o json | jq \
    '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
    | kubectl apply -f - && kubectl -n \
    kube-system delete pods -l 'component=kube-proxy'
}

#Code
#Get the ip of the machine
machineip=`get_machine_ip`

#Update the host file of the master.
echo Updating the host file...
update_hosts

#Create the Cluster
echo Setting up the Master using IPAddress: $machineip
setup_k8s_master

#Patching kube-proxy to run with --proxy-mode=userspace
#echo Patching the kube-proxy for CNI Networks...
#patch_kube_proxy
