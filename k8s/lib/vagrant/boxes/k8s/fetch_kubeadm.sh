#!/bin/bash
kubeversion=${1:-"1.7.5"}
#Update the repository index
apt-get update && apt-get install -y apt-transport-https 

# Install docker if you don't have it already.
apt-get install -y docker.io socat ebtables

sudo dpkg -i /vagrant/workdir/dpkgs/kubernetes-cni*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubelet_${kubeversion}-00*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubectl_${kubeversion}-00*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubeadm_${kubeversion}-00*.deb
