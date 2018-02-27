#!/bin/bash
kubeversion=${1:-"1.7.5"}
distribution=${2:-"ubuntu"}
docker=${3:-"docker-cs"}

if [ "$distribution" = "ubuntu" ]; then
   #Update the repository index
   apt-get update && apt-get install -y apt-transport-https ca-certificates software-properties-common \
   socat ebtables

   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

   if [ "$docker" = "docker-ce" ]; then

      echo  "Installing Docker CE..."
                
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
      add-apt-repository \
      "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      $(lsb_release -cs) \
      stable"
                
      apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce \
      | grep 17.03 | head -1 | awk '{print $3}')      
   else
      apt-get update
      # Install docker if you don't have it already.
      apt-get install -y docker.io      
   fi

systemctl enable docker && systemctl start docker

cd /vagrant/workdir/debpkgs

sudo dpkg -i {kubernetes-cni*.deb,kubelet_${kubeversion}-00*.deb,kubectl_${kubeversion}-00*.deb,kubeadm_${kubeversion}-00*.deb}

else

sudo setenforce 0

sudo tee -a /etc/yum.repos.d/kubernetes.repo <<EOF >/dev/null
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo tee -a /etc/sysctl.d/k8s.conf <<EOF > /dev/null
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

echo  "Installing Docker CE..."
                
sudo yum install -y yum-utils \
device-mapper-persistent-data \
lvm2 socat ebtables

sudo yum-config-manager \
--add-repo \
https://download.docker.com/linux/centos/docker-ce.repo

sudo yum deplist docker-ce-17.03.2.ce-1.el7.centos | awk '/provider:/ {print $2}' \
| sort -u | sudo xargs yum -y install
                
sudo yum install -y docker-ce-17.03.2.ce-1.el7.centos

sudo systemctl enable docker && sudo systemctl start docker


cd /vagrant/workdir/rpmpkgs

sudo rpm -i {*kubernetes-cni*.rpm,*kubelet-${kubeversion}-0*.rpm,*kubectl-${kubeversion}-0*.rpm,*kubeadm-${kubeversion}-0*.rpm}

sudo sed -i -E 's/--cgroup-driver=systemd/--cgroup-driver=cgroupfs/' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

fi
sudo systemctl enable kubelet && sudo systemctl start kubelet