# Installing Kubernetes and OpenEBS Clusters on Ubuntu 16.04

This tutorial, provides detailed instructions on how to setup a Kubernetes and OpenEBS Cluster using the Vagrantfile provided in this folder.
The following types of VMs can be launched:
- Kubernetes Master
- Kubernetes Minion
- OpenEBS Maya Master
- OpenEBS Storage Host

Depending on your need, you can also use this Vagrantfile, to only setup a Kubernetes Cluster or just OpenEBS Cluster or both. The number of nodes under each category is also configurable.

The Kubernetes cluster is setup, in this Vagrantfile using "kubeadm".

## Running the setup on Ubuntu 16.04

The following instructions have been verified on :
- Laptop installed with Ubuntu 16.04
- Laptop installed Windows 10 and Ubuntu 16.04 VM (created using VMWare Player 12)

### Prerequisites

Verify that you have the required software installed, with at least minimum specified version.

```
1.Vagrant (>=1.9.1)
2.VirtualBox 5.1
3.Git
```

#### Verify
```
ubuntu-host:~/$ vagrant version
Installed Version: 1.9.1
Latest Version: 1.9.1

You're running an up-to-date version of Vagrant!
ubuntu-host:~/$ vboxmanage --version
5.1.14r112924
ubuntu-hos:~/$ git version
git version 2.7.4
ubuntu-host:~/$

```

### Download

Setup your local directory, where the demo code will be downloaded. Let us call this as $demo-folder

```
mkdir $demo-folder
cd $demo-folder
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/demo
ls $demo-folder/openebs/k8s/demo/Vagrantfile
```

#### Verify

```
ubuntu-host:~/$ cd $demo-folder/openebs/k8s/demo/
ubuntu-host:~/demo-folder/openebs/k8s/demo$ vagrant status
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

### Changing Number of Nodes

By default, 5 VMs will be created as shown above. To create these VMs, you will need around 10GB RAM and 6 CPU. Depending on your system configuration, you can edit the Vagrantfile to create lesser or more nodes. Please check the customization instructions [here](./customizing-demo-vagrant-setup.md)


### Working with Slow Internet

If you are installing for the first time on the host, the vagrant will need to download the virtualbox images. If you are running on a low speed internet, the download can take considerable time. We recommend that you perform the following two steps, prior to issuing the "vagrant up" command below. Both the images put together will require around 1500MB.

```
cd $demo-folder/openebs/k8s/demo
vagrant box add openebs/k8s-1.5.5
vagrant box add openebs/openebs-0.2
```

#### Verify

```
ubuntu-host:~/demo-folder/openebs/k8s/demo$ vagrant box list | grep openebs
openebs/k8s-1.5.5      (virtualbox, 2017033101)
openebs/openebs-0.2    (virtualbox, 2017033102)
ubuntu-host:~/demo-folder/openebs/k8s/demo$
```
It is possible that, you may have a later versions downloaded. That's ok!

### Install Kubernetes and OpenEBS Cluster

```
cd $demo-folder/openebs/k8s/demo
vagrant up
```
This step, can take few minutes depending on your network speed. The required vagrant plugins are installed (for caching the vagrant boxes), the ubuntu-xenial box is download and the required software packages for each of the node are downloaded and installed.

#### Verify the VM installation

```
ubuntu-host:~/demo-folder/openebs/k8s/demo$ vagrant status
Current machine states:

kubemaster-01             running (virtualbox)
kubeminion-01             running (virtualbox)
omm-01                    running (virtualbox)
osh-01                    running (virtualbox)
osh-02                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ubuntu-host:~/demo-folder/openebs/k8s/demo$
```

Note: The network slowness can abort the process of installation, since a default timeout of 300 seconds is specified for the VMs to be launched. This can be modified by editing the Vagrantfile ( vmCfg.vm.boot_timeout ) value. If the installation aborts in between, make sure to clean-up before starting with the installation again.
```
cd $demo-folder/openebs/k8s/demo
vagrant destroy
```

#### Verify the Kubernetes Cluster Status

Use the kubectl from within the Kubernetes master to get the current status.

```
ubuntu-host:~/demo-folder/openebs/k8s/demo$ vagrant ssh kubemaster-01
... snipped ...
ubuntu@kubemaster-01:~$ kubectl get nodes
NAME            STATUS         AGE
kubemaster-01   Ready,master   1h
kubeminion-01   Ready          57m
ubuntu@kubemaster-01:~$
```

Check the status of the system pods.

```
ubuntu@kubemaster-01:~$ kubectl get pods --all-namespaces
```
The above command will output the status of the pods created:
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

For more usage options of ```kubectl``` refer to:
```
https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/
```


#### Verify the OpenEBS Cluster Status

Use the mayactl from within the OpenEBS Maya Master to get the current status.

```
ubuntu-host:~/demo-folder/openebs/k8s/demo$ vagrant ssh omm-01
... snipped ...
ubuntu@omm-01:~$
ubuntu@omm-01:~$ maya omm-status
Name           Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
omm-01.global  172.28.128.4  4648  alive   true    2         0.5.5  dc1         global

m-apiserver listening at http://172.28.128.4:5656

```

Use the below command to check the openebs storage host status
```
ubuntu@omm-01:~$
ubuntu@omm-01:~$ maya osh-status
ID        DC   Name    Class   Drain  Status
e57020e9  dc1  osh-02  <none>  false  ready
b6789013  dc1  osh-01  <none>  false  ready
ubuntu@omm-01:~$
```



## Next Steps
- [Run VDBench Tests on OpenEBS Storage](./running-vdbench-tests-with-openebs.md)
- [Run MySQL Pod with OpenEBS Storage](./run-mysql-openebs.md)

### Known Issues

Check out the issues section for known issues and possible workarounds for some of the common glitches while setting up kubernetes clusters on Ubunut/VirtualBox.

https://github.com/openebs/openebs/issues?utf8=%E2%9C%93&q=label%3Ademo%2Fk8s%20

Some of the issues observed:
- Unable to upgrade to VirtualBox 5.1
- weave pod, is stuck in CrashLoop
