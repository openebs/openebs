#!/bin/bash
# Get the mode for installing - Master or Host.
vm=$1

# Get the specs from github.
specurl="https://api.github.com/repos/openebs/openebs/contents\
/k8s/demo/specs"

# Get the scripts from github.
scripturl="https://api.github.com/repos/openebs/openebs/contents\
/k8s/demo/scripts"

# Get the plugin from github
pluginurl="https://raw.githubusercontent.com/openebs/openebs/master\
/k8s/lib/plugin/flexvolume/openebs-iscsi"
# Get kubernetes containers from gcr.io
gcrUrl="gcr.io/google_containers/"
PACKAGES=(\
pause-amd64:3.0 \
kube-scheduler-amd64:v1.5.5 \
kube-apiserver-amd64:v1.5.5 \
kube-controller-manager-amd64:v1.5.5 \
etcd-amd64:3.0.14-kubeadm \
kube-discovery-amd64:1.0 \
kube-proxy-amd64:v1.5.5 \
kubedns-amd64:1.9 \
kube-dnsmasq-amd64:1.4 \
dnsmasq-metrics-amd64:1.0 \
exechealthz-amd64:1.2 \
)

# For ubuntu/xenial64 only
useradd vagrant --password vagrant --home /home/vagrant --create-home -s /bin/bash
echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
mkdir -p /home/vagrant/.ssh
wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
chmod 0700 /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh


# Download and install needed packages.
sudo apt-get update
sudo apt-get install -y unzip curl wget

# Install docker and K8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
| sudo apt-key add - 
sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF >/dev/null
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update

# Install docker if you don't have it already.
sudo apt-get install -y docker.io
sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

#Install JSON Parser for patching kube-proxy
sudo apt-get install -y jq

# Pull kubernetes container images.
for i in "${!PACKAGES[@]}"; do
    sudo docker -- pull $gcrUrl${PACKAGES[i]}
done

sudo docker -- pull weaveworks/weave-kube:1.9.4
sudo docker -- pull weaveworks/weave-npc:1.9.4

# Create the demo directory and download scripts
mapfile -t scriptdownloadurls < <(curl -sS $scripturl \
| grep "download_url" | awk '{print $2}' \
| tr -d '",')

mkdir -p /home/ubuntu/demo/k8s/scripts
cd /home/ubuntu/demo/k8s/scripts

scriptlength=${#scriptdownloadurls[@]}
for ((i = 0; i != scriptlength; i++)); do
    if [ -z "${scriptdownloadurls[i]##*configure_k8s_master.sh*}" -o \
         -z "${scriptdownloadurls[i]##*configure_k8s_host.sh*}" ] ;then
        wget "${scriptdownloadurls[i]}"
    fi
done


if [ $vm -eq 0 ]; then
    
    mapfile -t downloadurls < <(curl -sS $specurl \
    | grep "download_url" | awk '{print $2}' \
    | tr -d '",')

    #Create demo directory and download specs
    mkdir -p /home/ubuntu/demo/k8s/spec
    cd /home/ubuntu/demo/k8s/spec    

    length=${#downloadurls[@]}
    for ((i = 0; i != length; i++)); do
        if [ -z "${downloadurls[i]##*yaml*}" ] ;then
            wget "${downloadurls[i]}"
        fi
    done

else

    K8S_VOL_PLUGINDIR="/usr/libexec/kubernetes/kubelet-plugins/volume/exec/"
    sudo mkdir -p ${K8S_VOL_PLUGINDIR}

    ## Install the plugin for dedicated openebs-iscsi storage
    sudo mkdir -p ${K8S_VOL_PLUGINDIR}/openebs~openebs-iscsi
    wget "https://raw.githubusercontent.com/openebs/openebs/master/k8s/lib/plugin/flexvolume/openebs-iscsi" 
    chmod +x openebs-iscsi 
    sudo mv openebs-iscsi ${K8S_VOL_PLUGINDIR}/openebs~openebs-iscsi/

    ## Restart the kubelet for the new volume plugins to take effect
    sudo systemctl restart kubelet.service

fi
