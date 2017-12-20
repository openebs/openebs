#!/bin/bash
kubeversion=${1:-"1.7.5"}

#Update the repository index
apt-get update && apt-get install -y apt-transport-https

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
# Install docker if you don't have it already.
apt-get install -y docker-engine socat ebtables

sudo dpkg -i /vagrant/workdir/dpkgs/kubernetes-cni*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubelet_${kubeversion}-00*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubectl_${kubeversion}-00*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubeadm_${kubeversion}-00*.deb
