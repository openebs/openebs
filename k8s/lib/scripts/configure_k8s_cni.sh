#!/bin/bash
kubeversion=`kubectl version --short | grep 'Server Version' | awk {'print $3'}`
kuberegex='^v1[.][0-8][.][0-9][0-9]?$'

function patch_kube_proxy(){
    kubectl -n kube-system get ds -l 'k8s-app=kube-proxy' -o json \
    | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
    | kubectl apply -f - \
    && kubectl -n kube-system delete pods -l 'k8s-app=kube-proxy'
}

function setup_k8s_weave() {
    kubectl apply -f $HOME/setup/cni/weave/weave-daemonset-k8s-1.6.yaml 

    if [[ $? -ne 0 ]]; then

       kubectl delete -f $HOME/setup/cni/weave/weave-daemonset-k8s-1.6.yaml
       
       export kubever=$(kubectl version | base64 | tr -d '\n')
       kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

       if [[ $? -ne 0 ]]; then
          echo "Unable to apply the Pod Network. SSH into the master and apply a Pod Network for your Cluster."
       fi

    fi
}

function setup_k8s_kuberouter(){
    kubectl apply -f $HOME/setup/cni/kuberouter/kubeadm-kuberouter.yaml

    if [[ $? -ne 0 ]]; then

       kubectl delete -f $HOME/setup/cni/kuberouter/kubeadm-kuberouter.yaml
       
       kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml

       if [[ $? -ne 0 ]]; then
          echo "Unable to apply the Pod Network. SSH into the master and apply a Pod Network for your Cluster."
       fi
    fi
} 

#Patching kube-proxy to run with --proxy-mode=userspace
echo Patching the kube-proxy for CNI Networks...
patch_kube_proxy

[[ $kubeversion =~ $kuberegex ]]

if [[ $? -eq 1 ]]; then
    echo Configure Pod Network with Kuberouter
    setup_k8s_kuberouter
else
    echo Configure Pod Network with Weave
   setup_k8s_weave
fi
