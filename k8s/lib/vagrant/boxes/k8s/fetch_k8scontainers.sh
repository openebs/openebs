#!/bin/bash

kubeversion=${1:-"1.7.5"}
kuberegex_cni='^1[.][6-8][.][0-9][0-9]?$'

# Get kubernetes containers from gcr.io
gcrUrlKube="gcr.io/google_containers/"
KUBEPACKAGES=(\
kube-scheduler-amd64:v${kubeversion} \
kube-apiserver-amd64:v${kubeversion} \
kube-controller-manager-amd64:v${kubeversion} \
kube-proxy-amd64:v${kubeversion} \
)

[[ $kubeversion =~ $kuberegex_cni ]]

if [[ $? -eq 1 ]]; then

gcrUrlExtra="gcr.io/google_containers/"
EXTRAPACKAGES=(\
pause-amd64:3.0 \
etcd-amd64:3.1.11 \
k8s-dns-kube-dns-amd64:1.14.7 \
k8s-dns-sidecar-amd64:1.14.7 \
k8s-dns-dnsmasq-nanny-amd64:1.14.7 \
)

else

gcrUrlExtra="gcr.io/google_containers/"
EXTRAPACKAGES=(\
pause-amd64:3.0 \
etcd-amd64:3.0.17 \
k8s-dns-kube-dns-amd64:1.14.4 \
k8s-dns-sidecar-amd64:1.14.4 \
k8s-dns-dnsmasq-nanny-amd64:1.14.4 \
)
fi

# Pull kubernetes container images.
for i in "${!KUBEPACKAGES[@]}"; do
    sudo docker pull $gcrUrlKube${KUBEPACKAGES[i]}
done

# Pull kubernetes container images.
for i in "${!EXTRAPACKAGES[@]}"; do
    sudo docker pull $gcrUrlExtra${EXTRAPACKAGES[i]}
done

