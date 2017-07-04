#!/bin/bash

function setup_k8s_cred() {
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    export KUBECONFIG=$HOME/.kube/config
}

#Copy the k8s credentials to $HOME
echo Copy the k8s credentials to $HOME
setup_k8s_cred
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.profile
