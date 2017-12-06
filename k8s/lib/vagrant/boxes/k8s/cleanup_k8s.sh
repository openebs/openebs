#!/bin/bash

kubeversion=${1:-"1.7.5"}
kuberegex='^1.[0-7].[0-9][0-9]?$'

# Cleaning up apt and bash history before packaing the box. 
sudo mkdir -p /etc/systemd/system/apt-daily.timer.d/
cat <<EOF | sudo tee -a /etc/systemd/system/apt-daily.timer.d/apt-daily.timer.conf > /dev/null
[Timer]
Persistent=false
EOF

[[ $1 =~ $kuberegex ]]

# For versions 1.8 and above, swap needs to be disabled
if [[ $? -eq 1 ]]; then
    cat <<EOF | sudo tee -a /etc/systemd/system/kubelet.service.d/90-local-extras.conf > /dev/null
    Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
fi

# To fix the '/var/lib/kubelet not empty' error
sudo kubeadm reset

# Remove the deb packages from the /vagrant/ folder.
rm -rf /vagrant/workdir/dpkgs

sudo apt-get clean
cat /dev/null > ~/.bash_history && history -c && exit