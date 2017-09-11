#!/bin/bash

function setup_k8s_dashboard() {
    kubectl apply -n kube-system -f $HOME/setup/dashboard/kubernetes-dashboard-1.6.3.yaml
}


echo Configure Kubernetes Dashboard
setup_k8s_dashboard

