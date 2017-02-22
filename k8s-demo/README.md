# Kubernetes Cluster Setup with OpenEBS for Ubuntu 16.04

This document explains the construction of a basic kubernetes cluster setup that uses OpenEBS for persistance:

1. Kubernetes  - 1 Master and 1 Minion Node
2. OpenEBS Maya  - 1 Master and 1 Host Node

## Getting Started

Setting up Kubernetes was a complicated task until the recent release of Kubernetes 1.4. Kubernetes 1.4+ includes a tool called kubeadm which eases the process of setting up a cluster between the nodes.We are going to setup this cluster using the Kubernetes binaries instead of cloning from the repository.

We will create a Vagrantfile which will use the kubeadm tool to create the nodes and form a cluster between them.

We will be downloading the OpenEBS Maya binaries from the OpenEBS Maya releases.
### Prerequisites

To get started with the process, we would initially need the following be installed on the Ubuntu box:
```
1.Vagrant (>=1.9.1)
2.VirtualBox 5.1
3.Git 
```

### Installing

We will setup the prerequisites required for the environment as below:
#### Vagrant:
##### Update the packages info from repositories
```
sudo apt-get update
```
##### Check the Vagrant package info (optional)
```
apt-cache show vagrant
```
The output should be similar to:
```
Package: vagrant
Priority: optional
Section: universe/admin
Installed-Size: 2466
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Original-Maintainer: Antonio Terceiro <terceiro@debian.org>
Architecture: all
Version: 1.8.1+dfsg-1
Depends: bsdtar, bundler, curl, openssh-client, ruby-childprocess (>= 0.3.7), ruby-erubis (>= 2.7.0), ruby-i18n (>= 0.6.0), ruby-listen, ruby-log4r (>= 1.1.9), ruby-net-scp (>= 1.1.0), ruby-net-sftp, ruby-net-ssh (>= 1:2.6.6), ruby-rest-client, ruby-nokogiri, ruby-rb-inotify, ruby
Suggests: virtualbox (>= 4.0)
Filename: pool/universe/v/vagrant/vagrant_1.8.1+dfsg-1_all.deb
...
```
##### Install Vagrant
```
sudo apt-get install vagrant
```
#### VirtualBox
##### Remove an existing copy of VirtualBox if you have one
```
sudo apt remove virtualbox
```
##### Open the /etc/apt/sources.list file:
```
sudo nano -w /etc/apt/sources.list
```
##### Append the following line to the file
```
deb http://download.virtualbox.org/virtualbox/debian xenial contrib
```
##### Press Ctrl+O to save the file. Then press Ctrl+X to close the file.

##### Get the Oracle GPG public key and import it into Ubuntu 16.04
```
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
```
##### Run the following commands to install VirtualBox
```
sudo apt update

sudo apt install virtualbox-5.1
```
#### Git
```
sudo apt-get install git
```
## Vagrantfile
We will using a Vagrantfile for setting up these nodes. We define the way the nodes have to be setup and form a cluster. 

### Running the Vagrant file
1. Launch the Terminal.
2. Get the K8s demo project by cloning it from the repository
```
git clone https://github.com/openebs/openebs.git
```

Change directory to the location where the Vagrantfile has been placed.The Vagrantfile is split into the following sections:

1. Define the characteristics of the Nodes.
2. Specify the plugins needed by Vagrant to build the Nodes.
3. Scripts to install binaries for Kubernetes nodes and setting up a K8s cluster.
4. Scripts to install binaries for OpenEBS Maya nodes and setting up a cluster.


### Define the characteristics of the Nodes
```
#Recommended minimum configuration
# Kube Master node Memory & CPUs
KM_MEM = ENV['KM_MEM'] || 2048
KM_CPUS = ENV['KM_CPUS'] || 2

# Master node Memory & CPUs
M_MEM = ENV['M_MEM'] || 1024
M_CPUS = ENV['M_CPUS'] || 1

# Minion Host Memory & CPUs
H_MEM = ENV['H_MEM'] || 1024
H_CPUS = ENV['H_CPUS'] || 1
```
### Required plugins for Vagrant
```
required_plugins = %w(vagrant-cachier vagrant-triggers)

required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end
```
### Install scripts for Kubernetes.
```
$kubeinstaller = <<SCRIPT
#!/bin/bash
echo Will run the common installer script ...
# Update apt and get dependencies
sudo apt-get update
sudo apt-get install -y unzip curl wget
# Install docker and K8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
# Install docker if you don't have it already.
apt-get install -y docker.io
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
SCRIPT

#Will be called during the VM creation
vmCfg.vm.provision "shell", inline: $kubeinstaller, privileged: true

```
### Master Node Setup
```
$kubeadminit = <<SCRIPT
#!/bin/bash
echo Will run the kubeadm init script ...
kubeadm init --api-advertise-addresses=$1
kubectl create -f https://git.io/weave-kube
SCRIPT

#Will be called when setting up the Master Node
vmCfg.vm.provision :shell, inline: $kubeadminit, :args => "`#{master_ip_address}` #{token}", privileged: true
```

### Minion Nodes Setup - uses vagrant-triggers
```
       vmCfg.vm.provision :trigger, :force => true, :stdout => true, :stderr => true do |trigger|
         trigger.fire do
            info"Getting the Master IP to join the cluster..."
            master_hostname = "kubemaster-01"
            get_ip_address = %Q(vagrant ssh #{master_hostname}  -c 'ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 3 | head -n 1')            
            master_ip_address = `#{get_ip_address}`            
            if master_ip_address == ""
               info"The Kubernetes Master is down, bring it up and manually run:"
               info"kubeadm join --token=<token> <master_ip_address>"
               info"in order to join the cluster."
               info"The Token can be obtained by running the following command on the Master Node:"
               info"kubectl -n kube-system get secret clusterinfo -o yaml | grep token-map | cut -d \":\" -f2 | cut -d \" \" -f2 | base64 -d | sed \"s|{||g;s|}||g\" | sed \"s|:|.|g\" | xargs echo"
            else                           
               get_token = %Q(vagrant ssh #{master_hostname} -c 'kubectl -n kube-system get secret clusterinfo -o yaml | grep token-map | cut -d ":" -f2 | cut -d " " -f2 | base64 -d | sed "s|{||g;s|}||g" | sed "s|:|.|g" | xargs echo')
               token = `#{get_token}`
               get_ip_address = %Q(vagrant ssh #{hostname}  -c 'ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1')      
               host_ip_address = `#{get_ip_address}`
               @machine.communicate.sudo("echo \"#{master_ip_address.strip} #{master_hostname}\" >> /etc/hosts")
               append_to_hosts = %Q(vagrant ssh #{master_hostname} -c 'echo #{host_ip_address.strip} #{hostname} | sudo tee -a /etc/hosts')               
               `#{append_to_hosts}`
               info"Setting up the Minion using IPAddress: #{master_ip_address}"
               info"Setting up the Minion using Token: #{token}"
               if token != ""
                  get_cluster_ip = %Q(vagrant ssh #{master_hostname} -c 'kubectl get svc -o yaml | grep clusterIP | cut -d ":" -f2 | cut -d " " -f2')
                  cluster_ip = `#{get_cluster_ip}`
                  @machine.communicate.sudo("kubeadm join --token=#{token.strip} #{master_ip_address.strip}")
                  info"Joining the CNI Network..."
                  @machine.communicate.sudo("route add #{cluster_ip.strip} gw #{master_ip_address.strip}")
               else
                  info"Token cannot be empty. SSH into the Master and run the below command to get the token:"
                  info"kubectl -n kube-system get secret clusterinfo -o yaml | grep token-map | cut -d \":\" -f2 | cut -d \" \" -f2 | base64 -d | sed \"s|{||g;s|}||g\" | sed \"s|:|.|g\" | xargs echo"
               end
            end  
         end
      end
```
### Install scripts for OpenEBS.
```
$mayainstaller = <<SCRIPT
#!/bin/bash

echo Running the Maya installer...

# Update apt and get dependencies
sudo apt-get update
sudo apt-get install -y unzip curl wget

# Install Maya binaries
wget https://github.com/openebs/maya/releases/download/$1/maya-linux_amd64.zip
unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip

SCRIPT

#Will be called during the VM creation
vmCfg.vm.provision :shell, inline: $mayainstaller, :args => "#{RELEASE_TAG}", privileged: true

```
### Master Node Setup - uses vagrant-triggers
```
#Will be called when setting up the Master Node
vmCfg.vm.provision :trigger, :force => true, :stdout => true, :stderr => true do |trigger|
    trigger.fire do
      info"Getting the Master IP to join the cluster..."            
      get_ip_address = %Q(vagrant ssh #{hostname}  -c 'ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1')            
      master_ip_address = `#{get_ip_address}`            
      if master_ip_address == ""
          info"The Maya Master is down, bring it up and manually run:"
          info"maya setup-omm -self-ip=<master_ip_address>"
          info"in order to join the cluster."               
      else               
    info"Setting up the node using IPAddress: #{master_ip_address.strip}"                                             
          @machine.communicate.sudo("maya setup-omm -self-ip=#{master_ip_address.strip}")
          @machine.communicate.sudo("echo 'export NOMAD_ADDR=http://#{master_ip_address.strip}:4646' >> /home/ubuntu/.profile")               
      end  
    end
end
```

### Host Nodes Setup - uses vagrant-triggers
```
      vmCfg.vm.provision :trigger, :force => true, :stdout => true, :stderr => true do |trigger|
         trigger.fire do
            info"Getting the Master IP to join the cluster..."
            master_hostname = "mayamaster-01"            
            get_ip_address = %Q(vagrant ssh #{master_hostname}  -c 'ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1')            
            master_ip_address = `#{get_ip_address}`            
            if master_ip_address == ""
               info"The Maya Master is down, bring it up and manually run:"
               info"maya setup-osh -self-ip=<host_ip_address> -omm-ips=<master_ip_address>"
               info"in order to join the cluster."               
            else               
               get_ip_address = %Q(vagrant ssh #{hostname}  -c 'ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1')      
               host_ip_address = `#{get_ip_address}`	       
               info"Setting up the node using IPAddress: #{host_ip_address.strip}"                              
               @machine.communicate.sudo("maya setup-osh -self-ip=#{host_ip_address.strip} -omm-ips=#{master_ip_address.strip}")
               @machine.communicate.sudo("echo 'export NOMAD_ADDR=http://#{master_ip_address.strip}:4646' >> /home/ubuntu/.profile")                              
            end  
         end
      end
```

### Running the Vagrant file
1. Launch the Terminal.
2. Run the following command.

```
vagrant up
```

### Verify the configuration
Once the nodes have been setup:

#### SSH into the Kubernetes Master Node and run the following command.
```
sudo kubectl get nodes
```
The command should output the number of nodes in the cluster and their current state.
```
NAME        STATUS         AGE
kubeminion-01   Ready          43m
kubemaster-01   Ready,master   1h

```
#### SSH into the OpenEBS Master Node and run the following commands
```
sudo maya omm-status
```
The command should output the status of the master node.
```
Name                  Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
mayamaster-01.global  172.28.128.6  4648  alive   true    2         0.5.0  dc1         global
```

```
sudo maya osh-status
```
The command should output the status of the host nodes.
```
ID        DC   Name         Class   Drain  Status
f3ca046e  dc1  mayahost-01  <none>  false  ready
```
