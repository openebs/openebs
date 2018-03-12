#!/bin/bash
set -e
distribution=${1:-"ubuntu"}

sudo docker pull busybox:latest
sudo docker pull cloudnativelabs/kube-router:latest

if [ "$distribution" = "ubuntu" ]; then
   mkdir -p /home/ubuntu/setup/cni/kuberouter
   cp /vagrant/boxes/k8s-kuberouter/external/kubeadm-kuberouter.yaml /home/ubuntu/setup/cni/kuberouter/
else
   mkdir -p /home/vagrant/setup/cni/kuberouter
   cp /vagrant/boxes/k8s-kuberouter/external/kubeadm-kuberouter.yaml /home/vagrant/setup/cni/kuberouter/
fi
