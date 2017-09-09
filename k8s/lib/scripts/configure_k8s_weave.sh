#!/bin/bash

function patch_kube_proxy(){
    kubectl -n kube-system get ds -l 'k8s-app=kube-proxy' -o json \
    | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
    | kubectl apply -f - \
    && kubectl -n kube-system delete pods -l 'k8s-app=kube-proxy'
}

function setup_k8s_weave() {
    kubectl apply -f $HOME/setup/weave/weave-daemonset-k8s-1.7.yaml
}


#Patching kube-proxy to run with --proxy-mode=userspace
echo Patching the kube-proxy for CNI Networks...
patch_kube_proxy

echo Configure Pod Network with Weave
setup_k8s_weave

