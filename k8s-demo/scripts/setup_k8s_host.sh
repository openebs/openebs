#!/bin/bash

#Note:This script assumes the user has the permission to ssh into the master machine.
#Variables:
user=""
masterhostname=""
machineip="0.0.0.0"
masterip=""
clusterip="0.0.0.0"
token=""
hostname=`hostname`
usage="Usage : $(basename "$0") -u Remote_User -i Master_IPAddress"

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
}

#Block comment
:<<'END'
function setupspec(){
    #Copy any pod yaml files if available
    mkdir -p /home/ubuntu/demo/k8s/spec
    cd /vagrant/
    cp -u demo*.yaml /home/ubuntu/demo/k8s/spec 2>/dev/null || :
}
END

function get_machine_ip(){
    ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1
}

function get_master_hostname(){
    ssh $user@$masterip 'echo `hostname`'
}

function get_master_ip(){
    ssh $user@$masterhostname ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 3 | head -n 1
}

function update_hosts(){
    sudo sed -i "/$hostname/ s/.*/$machineip\t$hostname/g" /etc/hosts
    echo $masterip $masterhostname | sudo tee -a /etc/hosts >/dev/null
    echo $machineip $hostname | ssh $user@$masterip sudo tee -a /etc/hosts >/dev/null
}

function get_token(){
    ssh $user@$masterip kubectl -n kube-system get secret clusterinfo -o yaml | grep token-map | cut -d ":" -f2 | cut -d " " -f2 | base64 -d | sed "s|{||g;s|}||g" | sed "s|:|.|g" | xargs echo
}

function setup_k8s_minion(){
    sudo kubeadm join --token=$token $masterip
}
function get_cluster_ip(){
    ssh $user@$masterip kubectl get svc -o yaml | grep clusterIP | cut -d ":" -f2 | cut -d " " -f2
}

function join_cni_network(){
    sudo route add $clusterip gw $masterip
}

#Code:
#Check whether we recieved the User and Master hostnames else Show usage
# Reset if getopts was used previously
OPTIND=1 
if (($# == 0)); then
    echo $usage
    exit 2
fi

while getopts ":u:i:" options; do
    case $options in
        u)  user=$OPTARG         
            ;;    
        i)  masterip=$OPTARG        
            ;;    
        \?) echo $usage
            exit 1;;
        *)  echo $usage
            exit 1;;
    esac
done

if [ "x" != "x$user" ]; then
    if [ "x" == "x$masterip" ]; then
        echo "-u [option] requires -i [option]"
        echo $usage
        exit
    fi
fi
if [ "x" != "x$masterip" ]; then
    if [ "x" == "x$user" ]; then
        echo "-i [option] requires -u [option]"
        echo $usage
        exit
    fi
fi

#Get the machine ip, master ip, cluster ip and the token from the master
machineip=`get_machine_ip`
masterhostname=`get_master_hostname`
clusterip=`get_cluster_ip`
token=`get_token`

#Install Kubernetes components
echo Installing Kubernetes on Minion...
install_kubernetes

#Update the host files of the master and minion.
echo Updating the host files...
update_hosts

#Join the cluster
echo Setting up the Minion using IPAddress: $machineip
echo Setting up the Minion using Token: $token 
setup_k8s_minion

#Add route to the minion ip to the cluster ip
echo Joining the CNI Network...
join_cni_network