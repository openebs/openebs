#!/bin/bash

#Variables:
machineip=
hostname=`hostname`
kubeversion="v1.7.5"
kuberegex='^v1.[0-7].[0-9][0-9]?$'
kubecniregex='^v1[.][0-8][.][0-9][0-9]?$'

function get_machine_ip(){
    ip addr show | \
    grep -oP "inet \\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" \
    | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | sort |\
     tail -n 1 | head -n 1
}

function setup_k8s_master() {

    # HEPTIO Pro Tip
    # Flush iptables for any residue left behind by kubeadm reset
    sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

    # Releases the port 10251, which causes the pre-flight checks to fail.
    # Kubeadm init, will start the kubelet if it is not running.
    sudo systemctl stop kubelet

    [[ $kubeversion =~ $kubecniregex ]]

    if [[ $? -eq 1 ]]; then
        # Use Kuberouter Pod Network for now for version 1.9.0 and above    
        sudo kubeadm init --apiserver-advertise-address=$machineip \
        --kubernetes-version=$kubeversion --pod-network-cidr 10.1.0.0/16
    else
        sudo kubeadm init --apiserver-advertise-address=$machineip \
        --kubernetes-version=$kubeversion
    fi
}

function update_hosts(){
    sudo sed -i "/$hostname/ s/.*/$machineip\t$hostname/g" /etc/hosts
}

function disable_swap()
{    
    sudo swapoff -a

    sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    
    cat <<EOF | sudo tee -a /etc/systemd/system/kubelet.service.d/90-local-extras.conf > /dev/null
    Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
}

#Code
#Get the ip of the machine
machineip=`get_machine_ip`

#Update the host file of the master.
echo Updating the host file...
update_hosts

[[ $kubeversion =~ $kuberegex ]]
# For versions 1.8 and above, swap needs to be disabled
if [[ $? -eq 1 ]]; then
    #Disable swap for Kubernetes 1.8 and above
    echo Disable swap
    disable_swap
fi

#Create the Cluster
echo Setting up the Master using IPAddress: $machineip
setup_k8s_master
