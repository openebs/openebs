#!/bin/bash

function setup_k8s_weave() {
    kubectl apply -f $HOME/setup/weave/weave-daemonset-k8s-1.6.yaml
}


echo Configure Pod Network with Weave
setup_k8s_weave

