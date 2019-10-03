#!/bin/bash

# Insert the patch instructions here

# Patch 01 - Copy the latest configure_k8s_weave.sh 
# Location of the k8s configure scripts
scriptloc="/vagrant/workdir/scripts/k8s"
cd /home/ubuntu/setup/k8s
cp ${scriptloc}/configure_k8s_weave.sh .
# END Patch 01


# DONOT MODIFY BELOW THIS LINE
# Cleaning up apt and bash history before packaging the box. 
sudo mkdir -p /etc/systemd/system/apt-daily.timer.d/
cat <<EOF | sudo tee -a /etc/systemd/system/apt-daily.timer.d/apt-daily.timer.conf > /dev/null
[Timer]
Persistent=false
EOF

sudo apt-get clean
cat /dev/null > ~/.bash_history && history -c && exit
