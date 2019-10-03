#!/bin/bash

# Cleaning up apt and bash history before packaging the box.
sudo mkdir -p /etc/systemd/system/apt-daily.timer.d/
cat <<EOF | sudo tee -a /etc/systemd/system/apt-daily.timer.d/apt-daily.timer.conf > /dev/null
[Timer]
Persistent=false
EOF

sudo apt-get clean
cat /dev/null > ~/.bash_history && history -c && exit