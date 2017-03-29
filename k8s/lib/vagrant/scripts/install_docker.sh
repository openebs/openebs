#!/bin/bash

set -e

echo "Installing Docker ..."

sudo apt-get install -y apt-transport-https ca-certificates

echo deb https://apt.dockerproject.org/repo ubuntu-`lsb_release -c \
  | awk '{print $2}'` main | sudo tee /etc/apt/sources.list.d/docker.list

# TODO - These values should be coming from maya cli
sudo apt-key adv \
  --keyserver hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

sudo apt-get update

# Install recommended packages
# This allows the use of aufs storage driver
#sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual

# Display the version of docker that will be installed
# NOTE: The default version that is set is marked with ***
sudo apt-cache policy docker-engine

# Install docker
sudo apt-get install -y docker-engine

# Restart docker to make sure we get the latest version of the daemon
# if there is an upgrade
sudo service docker restart

# Make sure we can actually use docker as the current user without using sudo
# Add current user to docker group
# NOTE: The docker group is equivalent to the root user
# NOTE: By default that Unix socket is owned by the user root and other users
# can only access it using sudo. The docker daemon always runs as the root user.
sudo usermod -aG docker $USER

# Verify the env variable
env | grep DOCKER_HOST || echo "NOTE: DOCKER_HOST is not set"
