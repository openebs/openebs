#!/bin/bash

# Get kubernetes containers from gcr.io
gcrUrl="gcr.io/google_containers/"
PACKAGES=(\
pause-amd64:3.0 \
etcd-amd64:3.0.17 \
kube-scheduler-amd64:v1.7.5 \
kube-apiserver-amd64:v1.7.5 \
kube-controller-manager-amd64:v1.7.5 \
kube-proxy-amd64:v1.7.5 \
k8s-dns-kube-dns-amd64:1.14.4 \
k8s-dns-sidecar-amd64:1.14.4 \
k8s-dns-dnsmasq-nanny-amd64:1.14.4 \
)

# Pull kubernetes container images.
for i in "${!PACKAGES[@]}"; do
    sudo docker -- pull $gcrUrl${PACKAGES[i]}
done

