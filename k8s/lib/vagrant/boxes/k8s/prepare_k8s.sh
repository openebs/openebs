#!/bin/bash
# Get the specs from github.
specurl="https://api.github.com/repos/openebs/openebs/contents\
/k8s/demo/specs"

# Get the scripts from github.
scripturl="https://api.github.com/repos/openebs/openebs/contents\
/k8s/lib/scripts"

# Get the plugin from github
pluginurl="https://raw.githubusercontent.com/openebs/openebs/master\
/k8s/lib/plugin/flexvolume/openebs-iscsi"

# Download and install needed packages.
sudo apt-get update
sudo apt-get install -y unzip curl wget

#Install JSON Parser for patching kube-proxy
sudo apt-get install -y jq

# Create the demo directory and download scripts
mapfile -t scriptdownloadurls < <(curl -sS $scripturl \
| grep "download_url" | awk '{print $2}' \
| tr -d '",')

mkdir -p /home/ubuntu/setup/k8s
cd /home/ubuntu/setup/k8s

scriptlength=${#scriptdownloadurls[@]}
for ((i = 0; i != scriptlength; i++)); do
    if [ -z "${scriptdownloadurls[i]##*configure_k8s_master.sh*}" -o \
         -z "${scriptdownloadurls[i]##*configure_k8s_cred.sh*}" -o \
         -z "${scriptdownloadurls[i]##*configure_k8s_weave.sh*}" -o \
         -z "${scriptdownloadurls[i]##*configure_k8s_host.sh*}" ] ;then
        wget "${scriptdownloadurls[i]}"
    fi
done
    
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

K8S_VOL_PLUGINDIR="/usr/libexec/kubernetes/kubelet-plugins/volume/exec/"
sudo mkdir -p ${K8S_VOL_PLUGINDIR}

## Install the plugin for dedicated openebs-iscsi storage
sudo mkdir -p ${K8S_VOL_PLUGINDIR}/openebs~openebs-iscsi
wget $pluginurl 
chmod +x openebs-iscsi 
sudo mv openebs-iscsi ${K8S_VOL_PLUGINDIR}/openebs~openebs-iscsi/

