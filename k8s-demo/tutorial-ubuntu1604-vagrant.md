# Installting Kubernetes and OpenEBS Clusters on Ubuntu 16.04

This tutorial, provides detailed instructions on how to setup a Kubernetes and OpenEBS Cluster using the Vagrantfile provided in this folder.
The following types of VMs can be launched:
- Kubernetes Master (kubemaster-xx)
- Kubernetes Minion (kubeminion-xx)
- OpenEBS Maya Master (omm-xx)
- OpenEBS Storage Host (osh-xx)

Depending on your need, you can also use this Vagrantfile, to only setup a Kubernetes Cluster or just OpenEBS Cluster or both. The number of nodes under each category is also configurable. 

The Kubernetes cluster is setup, in this Vagrantfile using "kubeadm". 

## Running the setup on Ubuntu 16.04

The following instructions have been verified on : 
- Laptop installed with Ubuntu 16.04
- Laptop installed Windows 10 and Ubuntu 16.04 VM (created using VMWare Player 12)

### Prerequisites

Verify that you have the following software installed, with atleast at the minimum version mentioned next to them.

```
1.Vagrant (>=1.9.1)
2.VirtualBox 5.1
3.Git 
```

#### Verify
```
ubuntu-hos:~/t$ vagrant version
Installed Version: 1.9.1
Latest Version: 1.9.1
 
You're running an up-to-date version of Vagrant!
ubuntu-host$ vboxmanage --version
5.1.14r112924
ubuntu-hos:~/$ git version
git version 2.7.4
ubuntu-hos:~/$ 

```

### Download

Setup your local directory, where the demo code will be downloaded. Let us call this as $demo-folder

```
mkdir $demo-folder
cd $demo-folder
git clone https://github.com/openebs/openebs.git
cd openebs/k8s-demo
ls $demo-folder/openebs/k8s-demo/Vagrantfile
```

#### Verify

```
ubuntu-hos:~/$ cd $demo-folder/openebs/k8s-demo/
ubuntu-hos:~/demo-folder/openebs/k8s-demo$ vagrant status
Current machine states:

kubemaster-01             not created (virtualbox)
kubeminion-01             not created (virtualbox)
omm-01                    not created (virtualbox)
osh-01                    not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

### Configure Nodes

By default, 4 VMs will be created with the following CPU/Memory configuration. 

Kubernetes Master requires 2G RAM and 2 CPU
Kubernetes Minion, OpenEBS Master and OpenEBS Host are configured with 1GB RAM and 1 CPU. 

Depending on your system configuration, you can edit the Vagrantfile or pass the modified files as environment files to specify:
(a) Number of Nodes under each category:
- Kubernetes Minion hosts ( KH_NODES) 
- OpenEBS Maya Master ( MM_NODES )
- OpenEBS Storage Host ( MH_NODES )

A value of 0 for the above variables will skip the installation of that type. For example, to install only Kubernetes you can run the following command:

```
ubuntu-hos:~/demo-folder/openebs/k8s-demo$ MH_NODES=0 MM_NODES=0 vagrant status
Current machine states:

kubemaster-01             not created (virtualbox)
kubeminion-01             not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

(b) RAM and CPU for Kubernetes Master ( KM_MEM and KM_CPUS)

(c) RAM and CPU for OpenEBS Maya Master ( M_MEM and M_CPUS)

(c) RAM and CPU for OpenEBS Storage Host or Kubernetes Minion ( H_MEM and H_CPUS)


### Install Kubernetes and OpenEBS Cluster

```
cd $demo-folder/openebs/k8s-demo
vagrant up
```
This step, can take few minutes depending on your network speed. The required vagrant plugins are installed (for caching the vagrant boxes), the ubuntu-xenial box is download and the required software packages for each of the node are downloaded and installed. 

#### Verify the VM installation

```
ubuntu-hos:~/demo-folder/openebs/k8s-demo$ vagrant status
Current machine states:

kubemaster-01             running (virtualbox)
kubeminion-01             running (virtualbox)
omm-01                    running (virtualbox)
osh-01                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ubuntu-hos:~/demo-folder/openebs/k8s-demo$ 
```

Note: The network slowness can abort the process of installation, since a default timeout of 300 seconds is specified for the VMs to be launched. This can be modified by editing the Vagrantfile ( vmCfg.vm.boot_timeout ) value. If the installation aborts in between, make sure to clean-up before starting with the installation again.
```
cd $demo-folder/openebs/k8s-demo
vagrant destroy
```

#### Verify the Kubernetes Cluster Status

Use the kubectl from within the Kubernetes master to get the current status. 

```
ubuntu-hos:~/demo-folder/openebs/k8s-demo$ vagrant ssh kubemaster-01
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

For more usage options of ```kubectl``` refer to:
```
https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/
```


#### Verify the OpenEBS Cluster Status

Use the mayactl from within the OpenEBS Maya Master to get the current status. 

```
ubuntu-hos:~/demo-folder/openebs/k8s-demo$ vagrant ssh omm-01
... snipped ...
ubuntu@omm-01:~$ 
ubuntu@omm-01:~$ maya omm-status
Name           Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
omm-01.global  172.28.128.5  4648  alive   true    2         0.5.0  dc1         global
```

Use the below command to check the openebs storage host status
```
ubuntu@omm-01:~$
ubuntu@omm-01:~$ maya osh-status
ID        DC   Name    Class   Drain  Status
3f56a738  dc1  osh-01  <none>  false  ready
ubuntu@omm-01:~$
```


### Known Issues

Check out the issues section for known issues and possible workarounds for some of the commom glitches while setting up kubernetes clusters on Ubunut/VirtualBox. 

https://github.com/openebs/openebs/issues?utf8=%E2%9C%93&q=label%3Ademo%2Fk8s%20

Some of the issues observed:
- Unable to upgrade to VirtualBox 5.1
- weave pod, is stuck in CrashLoop
