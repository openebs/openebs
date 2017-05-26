# Installing Kubernetes 1.6 and OpenEBS Clusters on Ubuntu 16.04

This Vagrantfile helps in setting up VirtualBox VMs with the following configuration: 
- Kubernetes 1.6 Cluster with Master and Minion nodes using kubeadm
- OpenEBS Cluster ( on dedicated VMs) 

This Vagrantfile can be used on laptop or Baremetal server installed with Ubuntu 16.04 and Virtualization Enabled


## Prerequisites

Verify that you have the following required software installed on your Ubuntu 16.04 machine:
```
1.Vagrant (>=1.9.1)
2.VirtualBox 5.1
3.curl or wget or git, etc., to download the Vagrant file. 
```

## Download and Verify 

Setup your local directory, where the demo code will be downloaded. Let us call this as $demo-folder

```
mkdir k8s-demo
cd k8s-demo
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/lib/vagrant/test/k8s/1.6/Vagrantfile
vagrant status
```

### Verify

You should see output similar to this:
```
ubuntu-host:~/k8s-demo$ vagrant status
Current machine states:

kubemaster-01             not created (virtualbox)
kubeminion-01             not created (virtualbox)
omm-01                    not created (virtualbox)
osh-01                    not created (virtualbox)
osh-02                    not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

## Bringing up K8s Cluster

Just use *vagrant up* to bring up the cluster. 

```
ubuntu-host:~/k8s-demo$ vagrant up
```
