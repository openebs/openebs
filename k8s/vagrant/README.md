# Installing Kubernetes Clusters on Ubuntu 16.04 using Vagrant

OpenEBS provides vagrant boxes with prepackaged kuberentes images. There are different vagrant boxes created depending on the kubernetes release. The Vagrantfiles are organized here based on the kubernetes version used by the box. A deployer can choose the Vagrantfile, based on his choice of kubernetes version. 

This Vagrantfile can be used on laptop or Baremetal server installed with Ubuntu 16.04 and Virtualization Enabled


## Prerequisites

Verify that you have the following required software installed on your Ubuntu 16.04 machine:
```
1.Vagrant (>=1.9.1)
2.VirtualBox 5.1
3.curl or wget or git, etc., to download the Vagrant file. 
```

## Download and Verify 

Dowload the required Vagrantfile. You can use wget to download a specific vagrant file, like shown below - or you can just close the repository locally. 

```
mkdir k8s-demo
cd k8s-demo
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/vagrant/1.6/Vagrantfile
vagrant status
```

### Verify

You should see output similar to this:
```
ubuntu-host:~/k8s-demo$ vagrant status
Current machine states:

kubemaster-01             not created (virtualbox)
kubeminion-01             not created (virtualbox)
kubeminion-02             not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

## Bringing up K8s Cluster

Just use *vagrant up* to bring up the cluster. 

```
ubuntu-host:~/k8s-demo$ vagrant up
```


