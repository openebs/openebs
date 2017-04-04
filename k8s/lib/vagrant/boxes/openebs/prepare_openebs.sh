#!/bin/bash

# Get the mode for installing - Master or Host.
releasetag=$1

# Get the releases from github.
releaseurl="https://api.github.com/repos/openebs/maya/releases"

# Get the specs from github.
specurl="https://api.github.com/repos/openebs/openebs/contents\
/k8s/demo/specs"

# Get the scripts from github.
scripturl="https://api.github.com/repos/openebs/openebs/contents\
/k8s/lib/scripts" 

# Get the bootstrap scripts from github.
bootstrapurl="https://raw.githubusercontent.com/openebs/maya/master\
/scripts/install_bootstrap.sh"

# For ubuntu/xenial64 only
useradd vagrant --password vagrant --home /home/vagrant --create-home -s /bin/bash
echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
mkdir -p /home/vagrant/.ssh
wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
chmod 0700 /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Update apt and get dependencies
sudo apt-get update
sudo apt-get install -y unzip curl wget

# Install Maya binaries
if [ -z "$releasetag" ]; then

wget $(curl -sS $releaseurl | grep "browser_download_url" \
| awk '{print $2}' | tr -d '"' | head -n 2 | tail -n 1)

else    

wget "https://github.com/openebs/maya/releases/download/\
$releasetag/maya-linux_amd64.zip"

fi

unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip

mapfile -t scriptdownloadurls < <(curl -sS $scripturl \
| grep "download_url" | awk '{print $2}' \
| tr -d '",')

mkdir -p /home/ubuntu/demo/maya/scripts
cd /home/ubuntu/demo/maya/scripts

scriptlength=${#scriptdownloadurls[@]}
for ((i = 0; i != scriptlength; i++)); do
    if [ -z "${scriptdownloadurls[i]##*configure_omm.sh*}" -o \
    -z "${scriptdownloadurls[i]##*configure_osh.sh*}" ] ;then
        wget "${scriptdownloadurls[i]}"
    fi
done

wget $bootstrapurl

mapfile -t specdownloadurls < <(curl -sS $specurl \
| grep "download_url" | awk '{print $2}' \
| tr -d '",')

#Create demo directory and download specs
mkdir -p /home/ubuntu/demo/maya/spec
cd /home/ubuntu/demo/maya/spec    

speclength=${#specdownloadurls[@]}
for ((i = 0; i != speclength; i++)); do
    if [ -z "${specdownloadurls[i]##*hcl*}" ] ;then
        wget "${specdownloadurls[i]}"
    fi
done

