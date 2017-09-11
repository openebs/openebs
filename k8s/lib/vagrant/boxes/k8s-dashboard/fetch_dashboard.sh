#!/bin/bash

sudo docker -- pull gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3

mkdir -p /home/ubuntu/setup/dashboard
cp /vagrant/boxes/k8s-dashboard/external/kubernetes-dashboard-1.6.3.yaml /home/ubuntu/setup/dashboard/
