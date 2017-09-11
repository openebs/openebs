# Installing Kubernetes Clusters on Ubuntu 16.04 using Vagrant

OpenEBS provides vagrant boxes with prepackaged kuberentes images. There are different vagrant boxes created depending on the kubernetes release. The Vagrantfiles are organized here based on the kubernetes version used by the box. 

This Vagrantfile can be used on any machine with Virtualization Enabled, like laptop or baremetal server. 

The below instructions will walk you through the following:
- Verify Prerequisites
- Download Vagrantfile
- Bringup K8s Cluster
- Install kubectl on the host 
- Setup access to Kubernetes UI/Dashboard (Starting from Vagrantfile 1.7.5)
- Setup OpenEBS
- Launch demo pod

*Note: The instructions are from an Ubuntu 16.06 host.*

## Prerequisites

Verify that you have the following required software installed on your Ubuntu 16.04 machine:
```
1.Vagrant (>=1.9.1)
2.VirtualBox 5.1
```

## Download and Verify 

Download the required Vagrantfile. Use curl or wget or git, etc., to download the required Vagrantfile. This example uses wget.

```
mkdir k8s-demo
cd k8s-demo
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/vagrant/1.7.5/Vagrantfile
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

### Verify

You should see output similar to this:
```
kiran@kmaya:~/k8s-demo$ vagrant status
Current machine states:

kubemaster-01             running (virtualbox)
kubeminion-01             running (virtualbox)
kubeminion-02             running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
kiran@kmaya:~/k8s-demo$ 
```

## Install kubectl on the host

Please follow the instructions for [install kubectl from binary](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl).

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

### Verify

```
kiran@kmaya:~/k8s-demo$ kubectl version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.5", GitCommit:"17d7182a7ccbb167074be7a87f0a68bd00d58d97", GitTreeState:"clean", BuildDate:"2017-08-31T09:14:02Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
The connection to the server localhost:8080 was refused - did you specify the right host or port?
kiran@kmaya:~/k8s-demo$ 
```

The connection error is expected. The next step will configure the kubectl to contact the kubernetes cluster. 

## Configure kube-config from the installed cluster

```
vagrant ssh kubemaster-01 -c "cat ~/.kube/config" > demo-kube-config
```

### Verify

```
kiran@kmaya:~/k8s-demo$ kubectl --kubeconfig ./demo-kube-config version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.5", GitCommit:"17d7182a7ccbb167074be7a87f0a68bd00d58d97", GitTreeState:"clean", BuildDate:"2017-08-31T09:14:02Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.5", GitCommit:"17d7182a7ccbb167074be7a87f0a68bd00d58d97", GitTreeState:"clean", BuildDate:"2017-08-31T08:56:23Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
kiran@kmaya:~/k8s-demo$ 
```

## Setup Access to Kubernetes UI

```
kiran@kmaya:~/k8s-demo$ kubectl --kubeconfig ./demo-kube-config proxy
Starting to serve on 127.0.0.1:8001
```

### Verify 

Launch the URL http://127.0.0.1:8001/ui



