#!/bin/bash

set -e

NOMAD_VERSION="0.5.0"
CURDIR=`pwd`

if [[ $(which nomad >/dev/null && nomad version | head -n 1 | cut -d ' ' -f 2 | sed 's/dev//' | cut -d "'" -f 2) == "v$NOMAD_VERSION" ]]; then    
    echo "Nomad v$NOMAD_VERSION already installed; Skipping"
    exit
fi

# Remove if already present
# NOTE: this is install only script
echo "Cleaning old Nomad installation if any"
sudo rm -rf /usr/bin/nomad
sudo rm -rf /etc/nomad.d/
sudo rm -rf /opt/nomad/
sudo rm -rf /var/log/nomad

cd /tmp/

if [ ! -f "./nomad_${NOMAD_VERSION}.zip" ]; then
  echo "Fetching Nomad ${NOMAD_VERSION} ..."
  curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad_${NOMAD_VERSION}.zip
fi

echo "Installing Nomad ${NOMAD_VERSION} ..."
unzip nomad_${NOMAD_VERSION}.zip
sudo chmod +x nomad
sudo mv nomad /usr/bin/nomad

# Setup config directory for Nomad
sudo mkdir -p /etc/nomad.d/server
sudo mkdir -p /etc/nomad.d/client

sudo chmod a+w /etc/nomad.d/
sudo chmod a+w /etc/nomad.d/server
sudo chmod a+w /etc/nomad.d/client

# Setup data directory for Nomad
sudo mkdir -p /opt/nomad/data
sudo chmod a+w /opt/nomad/data

# Setup log directory for Nomad
sudo mkdir -p /var/log/nomad
sudo chmod a+w /var/log/nomad

cd ${CURDIR}
