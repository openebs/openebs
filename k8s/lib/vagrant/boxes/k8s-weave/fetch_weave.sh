#!/bin/bash

sudo docker -- pull weaveworks/weave-kube:2.0.4
sudo docker -- pull weaveworks/weave-npc:2.0.4

mkdir -p /home/ubuntu/setup/weave
cp /vagrant/boxes/k8s-weave/external/weave-daemonset-k8s-1.6.yaml /home/ubuntu/setup/weave/
