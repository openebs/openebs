#!/bin/bash

kubeversion=${1:-"1.7.5"}
distribution=${2:-"ubuntu"}

# To fix the '/var/lib/kubelet not empty' error
sudo kubeadm reset

if [ "$distribution" = "ubuntu" ]; then

# Remove the deb packages from the /vagrant/ folder.
rm -rf /vagrant/workdir/debpkgs
# Cleaning up apt and bash history before packaging the box. 
sudo mkdir -p /etc/systemd/system/apt-daily.timer.d/
cat <<EOF | sudo tee -a /etc/systemd/system/apt-daily.timer.d/apt-daily.timer.conf > /dev/null
[Timer]
Persistent=false
EOF

sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer

cat <<EOF | sudo tee -a /etc/apt/apt.conf.d/02periodic > /dev/null
APT::Periodic::Enable "0";
EOF

sudo apt-get clean
cat /dev/null > ~/.bash_history && history -c && exit
else
# Remove the rpm packages from the /vagrant/ folder.
rm -rf /vagrant/workdir/rpmpkgs

cat /dev/null > ~/.bash_history && history -c && exit

fi