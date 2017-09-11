#!/bin/bash

#Variables:
machineip=
hostname=`hostname`
kubeversion="v1.7.5"

function get_machine_ip(){
    ifconfig | \
    grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" \
    | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | sort |\
     tail -n 1 | head -n 1
}

function setup_k8s_master() {
    sudo kubeadm init --apiserver-advertise-address=$machineip \
    --kubernetes-version=$kubeversion
}

function update_hosts(){
    sudo sed -i "/$hostname/ s/.*/$machineip\t$hostname/g" /etc/hosts
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
