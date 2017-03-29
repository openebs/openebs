#!/bin/bash

set -e

CURDIR=`pwd`

# Update the apt
sudo apt-get update

sudo apt-get install -y unzip

# Remove if already present
echo "Cleaning old maya boostrapping if any ..."
sudo rm -rf /etc/maya.d/

sudo mkdir -p /etc/maya.d/scripts
sudo mkdir -p /etc/maya.d/templates

sudo chmod a+w /etc/maya.d/
sudo chmod a+w /etc/maya.d/scripts
sudo chmod a+w /etc/maya.d/templates

# Fetch various install scripts
cd /etc/maya.d/scripts

echo "Fetching utility scripts ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/get_first_private_ip.sh -o get_first_private_ip.sh

echo "Fetching docker scripts ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/install_docker.sh -o install_docker.sh

echo "Fetching Mayaserver scripts ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/install_mayaserver.sh -o install_mayaserver.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/start_mayaserver.sh -o start_mayaserver.sh

echo "Fetching consul scripts ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/install_consul.sh -o install_consul.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/set_consul_as_server.sh -o set_consul_as_server.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/start_consul_server.sh -o start_consul_server.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/set_consul_as_client.sh -o set_consul_as_client.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/start_consul_client.sh -o start_consul_client.sh

echo "Fetching nomad scripts ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/install_nomad.sh -o install_nomad.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/set_nomad_as_server.sh -o set_nomad_as_server.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/start_nomad_server.sh -o start_nomad_server.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/set_nomad_as_client.sh -o set_nomad_as_client.sh
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/start_nomad_client.sh -o start_nomad_client.sh

echo "Fetching Flannel scripts ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/install_flannel.sh -o install_flannel.sh

#echo "Fetching etcd scripts ..."
#curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/install_etcd.sh -o install_etcd.sh
#curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/set_etcd.sh -o set_etcd.sh
#curl -sSL https://raw.githubusercontent.com/openebs/maya/master/scripts/start_etcd.sh -o start_etcd.sh

# Changing the ownership 
sudo chmod 0755 set_nomad_as_server.sh

# Fetch various templates
cd /etc/maya.d/templates

echo "Fetching mayaserver config templates ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/m-apiserver.service.tmpl -o m-apiserver.service.tmpl
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/nomad_global.INI.tmpl -o nomad_global.INI.tmpl

echo "Fetching consul config templates ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/consul-server.json.tmpl -o consul-server.json.tmpl
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/consul-server.service.tmpl -o consul-server.service.tmpl
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/consul-client.json.tmpl -o consul-client.json.tmpl
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/consul-client.service.tmpl -o consul-client.service.tmpl

echo "Fetching nomad config templates ..."
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/nomad-server.hcl.tmpl -o nomad-server.hcl.tmpl
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/nomad-server.service.tmpl -o nomad-server.service.tmpl
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/nomad-client.hcl.tmpl -o nomad-client.hcl.tmpl
curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/nomad-client.service.tmpl -o nomad-client.service.tmpl

#echo "Fetching etcd config templates ..."
#curl -sSL https://raw.githubusercontent.com/openebs/maya/master/templates/etcd.service.tmpl -o etcd.service.tmpl

cd ${CURDIR}
