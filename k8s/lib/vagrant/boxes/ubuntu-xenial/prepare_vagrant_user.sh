#!/bin/bash

# For ubuntu/xenial64 only
# TODO: why is this only for ubuntu/xenial64

useradd vagrant --password vagrant \
  --home /home/vagrant \
  --create-home -s /bin/bash

echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
mkdir -p /home/vagrant/.ssh
wget --no-check-certificate \
   https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub \
   -O /home/vagrant/.ssh/authorized_keys

chmod 0700 /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

