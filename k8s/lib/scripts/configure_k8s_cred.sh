#!/bin/bash

function setup_k8s_cred() {
    sudo cp /etc/kubernetes/admin.conf $HOME/
    sudo chown $(id -u):$(id -g) $HOME/admin.conf
    export KUBECONFIG=$HOME/admin.conf
}

#Copy the k8s credentials to $HOME
echo Copy the k8s credentials to $HOME
setup_k8s_cred
echo "export KUBECONFIG=$HOME/admin.conf" >> $HOME/.profile
