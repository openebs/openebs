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

#### Verify
```
ubuntu-host$ vagrant version
Installed Version: 1.9.1
Latest Version: 1.9.1
 
You're running an up-to-date version of Vagrant!
ubuntu-host$ vboxmanage --version
5.1.14r112924
ubuntu-host$ git version
git version 2.7.4
kiran@kmaya:~/github/openebs/openebs/k8s-demo$ 

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

You should see that Vagrantfile is available on your machine now. 

### Configure Nodes

By default, 4 VMs will be created with the following CPU/Memory configuration. 


### Launch Kubernetes and OpenEBS Cluster

```
cd $demo-folder/openebs/k8s-demo
vagrant up
```

#### Verify the installation
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
