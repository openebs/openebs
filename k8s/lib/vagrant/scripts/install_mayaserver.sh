#!/bin/bash

set -e

MAPI_VERSION="0.2-RC2"
CURDIR=`pwd`

if [[ $(which m-apiserver >/dev/null && m-apiserver version | head -n 1 | cut -d ' ' -f 2 | sed 's/dev//' | cut -d "'" -f 2) == "$MAPI_VERSION" ]]; then    
    echo "Maya-API Server v$MAPI_VERSION already installed; Skipping"
    exit
fi

cd /tmp/

if [ ! -f "./m-apiserver_${MAPI_VERSION}.zip" ]; then
echo "Fetching Maya-API Server ${MAPI_VERSION} ..."
curl -sSL https://github.com/openebs/mayaserver/releases/download/${MAPI_VERSION}/m-apiserver-linux_amd64.zip -o m-apiserver_$MAPI_VERSION.zip
fi

echo "Installing Maya-API Server ${MAPI_VERSION} ..."
unzip m-apiserver_$MAPI_VERSION.zip
sudo chmod +x m-apiserver
sudo mv m-apiserver /usr/bin/

# Setup INI config directory for m-apiserver
sudo mkdir -p /etc/mayaserver/orchprovider
sudo chmod a+w /etc/mayaserver/orchprovider

cd ${CURDIR}
