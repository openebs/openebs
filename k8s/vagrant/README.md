# Installing Kubernetes Clusters on Ubuntu 16.04 using Vagrant

OpenEBS provides vagrant boxes with prepackaged Kuberentes images. There are different vagrant boxes created depending on the Kubernetes release. The Vagrantfiles are organized here based on the Kubernetes version used by the box. 

This Vagrantfile can be used on any machine with Virtualization *Enabled*, like a laptop or bare metal server. 

Procedures listed in this section will help you -
- Verify prerequisites
- Download Vagrantfile
- Setup Kubernetes Cluster
- Install kubectl on the host 
- Setup access to Kubernetes UI/Dashboard (Vagrantfile version 1.7.5 onwards)
- Setup OpenEBS
- Launch demo pod

*Note: The instructions are from an Ubuntu 16.06 host.*

## Prerequisites:

Verify that you have the following software installed on your Ubuntu 16.04 machine:
```
1.Vagrant (>=1.9.1)
2.VirtualBox 5.1
```

## Download and Verify 

Download the required Vagrantfile. Use curl, wget, git and so on, to download the required Vagrantfile. This example uses wget.

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

kubemaster-01             not created (VirtualBox)
kubeminion-01             not created (VirtualBox)
kubeminion-02             not created (VirtualBox)

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

The output displayed will be similar to the following:
```
kiran@kmaya:~/k8s-demo$ vagrant status
Current machine states:

kubemaster-01             running (VirtualBox)
kubeminion-01             running (VirtualBox)
kubeminion-02             running (VirtualBox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
kiran@kmaya:~/k8s-demo$ 
```

## Install kubectl on the Host

Follow the procedures for [installing kubectl from binary](https://Kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl).

```
curl -LO https://storage.googleapis.com/Kubernetes-release/release/$(curl -s https://storage.googleapis.com/Kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
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

The connection error is expected. The next step will configure the kubectl to contact the Kubernetes cluster. 

## Configure kube-config from the Installed Cluster

```
vagrant ssh kubemaster-01 -c "cat ~/.kube/config" > demo-kube-config
```

*Note: If you have a single Kubernetes cluster on your host, you could copy the demo-kube-config to ~/.kube/config, and avoid specifying the parameter --kubeconfig in the kubectl commands*

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

Launch the URL `http://127.0.0.1:8001/ui`

**Your local Kubernetes cluster with the dashboard is ready. The below steps are required only if you would like to run stateful applications with OpenEBS**

## Setup OpenEBS

Fetch the latest *openebs-operator.yaml* and *openebs-storageclasses.yaml* [github - openebs/openebs](../)

```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml
```

Load the OpenEBS operator and storage classes onto your Kubernetes cluster

```
kubectl --kubeconfig ./demo-kube-config apply -f openebs-operator.yaml
kubectl --kubeconfig ./demo-kube-config apply -f openebs-storageclasses.yaml
```

### Verify

On successful run of the above commands, you will see output like below:

```
kiran@kmaya:~/k8s-demo$ kubectl --kubeconfig ./demo-kube-config apply -f openebs-operator.yaml
serviceaccount "openebs-maya-operator" created
clusterrole "openebs-maya-operator" created
clusterrolebinding "openebs-maya-operator" created
deployment "maya-apiserver" created
service "maya-apiserver-service" created
deployment "openebs-provisioner" created
kiran@kmaya:~/k8s-demo$ kubectl --kubeconfig ./demo-kube-config apply -f openebs-storageclasses.yaml 
storageclass "openebs-standard" created
storageclass "openebs-percona" created
storageclass "openebs-jupyter" created
kiran@kmaya:~/k8s-demo$ 
```

