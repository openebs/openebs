#!/bin/bash

#Update the repository index
apt-get update && apt-get install -y apt-transport-https 

# Install docker if you don't have it already.
apt-get install -y docker.io socat ebtables

sudo dpkg -i /vagrant/workdir/dpkgs/kubernetes-cni*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubelet*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubectl*.deb
sudo dpkg -i /vagrant/workdir/dpkgs/kubeadm*.deb
