#!/bin/bash
set -e
distribution=${1:-"ubuntu"}

sudo docker pull quay.io/coreos/flannel:v0.9.1-amd64

if [ "$distribution" = "ubuntu" ]; then
   mkdir -p /home/ubuntu/setup/cni/flannel
   cp /vagrant/boxes/k8s-flannel/external/kube-flannel.yml /home/ubuntu/setup/cni/flannel/
else
   mkdir -p /home/vagrant/setup/cni/flannel
   cp /vagrant/boxes/k8s-flannel/external/kube-flannel.yml /home/vagrant/setup/cni/flannel/
fi