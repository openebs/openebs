#!/bin/bash
distribution=${1:-"ubuntu"}

sudo docker pull weaveworks/weave-kube:2.0.4
sudo docker pull weaveworks/weave-npc:2.0.4

if [ "$distribution" = "ubuntu" ]; then
   mkdir -p /home/ubuntu/setup/cni/weave
   cp /vagrant/boxes/k8s-weave/external/weave-daemonset-k8s-1.6.yaml /home/ubuntu/setup/cni/weave/
else
   mkdir -p /home/vagrant/setup/cni/weave
   cp /vagrant/boxes/k8s-weave/external/weave-daemonset-k8s-1.6.yaml /home/vagrant/setup/cni/weave/
fi