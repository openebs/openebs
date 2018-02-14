#!/bin/bash

function patch_kube_proxy(){
    kubectl -n kube-system get ds -l 'k8s-app=kube-proxy' -o json \
    | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
    | kubectl apply -f - \
    && kubectl -n kube-system delete pods -l 'k8s-app=kube-proxy'
}

function setup_k8s_weave() {
    export kubever=$(kubectl version | base64 | tr -d '\n')
    kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$kubever
}


#Patching kube-proxy to run with --proxy-mode=userspace
echo Patching the kube-proxy for CNI Networks...
patch_kube_proxy

echo Configure Pod Network with Weave
setup_k8s_weave

