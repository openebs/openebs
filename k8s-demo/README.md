# Using OpenEBS Storage with Kubernetes

In this document, we will use Vagrant and Virtualbox to automate the process of setting up Kubernetes and OpenEBS Cluster. The Vagrantfile automates the process of setting up the Kubernetes and OpenEBS Clusters. 

The following types of VMs can be launched:
- Kubernetes Master (kubemaster-xx)
- Kubernetes Minion (kubeminion-xx)
- OpenEBS Maya Master (omm-xx)
- OpenEBS Storage Host (osh-xx)

Depending on your need, you can also use this Vagrantfile, to only setup a Kubernetes Cluster or just OpenEBS Cluster or both. The number of nodes under each category is also configurable. 

The Kubernetes cluster is setup, in this Vagrantfile using "kubeadm". 

## Running the setup on Ubuntu 16.04

The following instructions have been verified on : 
(a) Laptop installed with Ubuntu 16.04
(b) Windows with Ubuntu 16.04 VM

### Prerequisites

Verify that you have the following software installed, with atleast at the minimum version mentioned next to them.

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
sudo apt-get remove --purge virtualbox
sudo rm ~/"VirtualBox VMs" -Rf
sudo rm ~/.config/VirtualBox/ -Rf
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
We will using a Vagrantfile for setting up these nodes. 

### Running the Vagrant file
1. Launch the Terminal.
2. Get the K8s demo project by cloning it from the repository
```
git clone https://github.com/openebs/openebs.git
```
3. Change directory to the location where the Vagrantfile has been placed.
4. Run the following command.

```
vagrant up
```

### Verify the configuration
Once the nodes have been setup:

#### SSH into the Kubernetes Master Node and run the following command.
```
kubectl get nodes
```
The command should output the number of nodes in the cluster and their current state.
```
NAME        STATUS         AGE
kubeminion-01   Ready          43m
kubemaster-01   Ready,master   1h

```
```
ubuntu@kubemaster-01:~$ kubectl get pods --all-namespaces
```
The above command will ouput the status of the pods created:
```
NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE
kube-system   dummy-2088944543-1t7hc                  1/1       Running   0          22m
kube-system   etcd-kubemaster-01                      1/1       Running   0          21m
kube-system   kube-apiserver-kubemaster-01            1/1       Running   0          22m
kube-system   kube-controller-manager-kubemaster-01   1/1       Running   0          21m
kube-system   kube-discovery-1769846148-nzbd1         1/1       Running   0          22m
kube-system   kube-dns-2924299975-jt7wz               4/4       Running   0          20m
kube-system   kube-proxy-5wrcp                        1/1       Running   0          15m
kube-system   kube-proxy-p2n9v                        1/1       Running   0          20m
kube-system   kube-scheduler-kubemaster-01            1/1       Running   0          21m
kube-system   weave-net-6t9pz                         2/2       Running   0          15m
kube-system   weave-net-frt55                         2/2       Running   0          20m
```

Note: The below issue has been identified to cause problems for POD creation. 
```
https://github.com/openebs/openebs/issues/26
```
The issue also contains the solution where a couple of steps have to be manually performed before any pods are created.

For more usages of ```kubectl``` refer to:
```
https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/
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
