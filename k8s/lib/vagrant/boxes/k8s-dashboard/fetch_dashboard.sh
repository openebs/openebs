#!/bin/bash
distribution=${1:-"ubuntu"}

sudo docker pull gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3

if [ "$distribution" = "ubuntu" ]; then
   mkdir -p /home/ubuntu/setup/dashboard
   cp /vagrant/boxes/k8s-dashboard/external/kubernetes-dashboard-1.6.3.yaml /home/ubuntu/setup/dashboard/
else
   mkdir -p /home/vagrant/setup/dashboard
   cp /vagrant/boxes/k8s-dashboard/external/kubernetes-dashboard-1.6.3.yaml /home/vagrant/setup/dashboard/
fi