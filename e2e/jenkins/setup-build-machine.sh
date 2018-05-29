#!/bin/bash

set -e

# Install ansible to run the setup playbooks
echo Installing Prerequisites...
sudo apt-get update
sudo apt-get install -y python-pip libffi-dev python-dev libssl-dev sshpass

echo Installing Ansible...
sudo -H pip install ansible==2.3.0

echo Installing Nginx...
sudo apt-get install -y nginx

echo Installing Java...
sudo apt-get install -y openjdk-8-jdk

echo Installing Jenkins...
# Add Jenkins to trusted keys and source list
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y jenkins

IS_VAGRANT_INSTALLED=$(which vagrant >> /dev/null 2>&1; echo $?)
if [[ $IS_VAGRANT_INSTALLED -eq 0 ]]; then
    echo "vagrant is installed; Skipping"
    sleep 2
else
    wget https://releases.hashicorp.com/vagrant/1.9.1/vagrant_1.9.1_x86_64.deb
    sudo dpkg -i vagrant_1.9.1_x86_64.deb
    vagrant version
fi

IS_VIRTUALBOX_INSTALLED=$(which vboxmanage >> /dev/null 2>&1; echo $?)
if [[ $IS_VIRTUALBOX_INSTALLED -eq 0 ]]; then
    echo "virtualbox is installed; Skipping"
    sleep 2
else
    sudo sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list.d/virtualbox.list'
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install -y virtualbox-5.1
fi

# Add jenkins user to sudo group
echo "jenkins ALL=(ALL:ALL) ALL" | sudo tee --append /etc/sudoers > /dev/null
sudo chpasswd <<<"jenkins:jenkins"

#Create a .profile file for the jenkins user
sudo touch /var/lib/jenkins/.profile
sudo chown jenkins:jenkins /var/lib/jenkins/.profile
