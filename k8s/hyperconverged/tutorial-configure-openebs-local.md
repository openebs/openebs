# Using OpenEBS with Kubernetes on local machine

This tutorial, provides detailed instructions on how to setup and use OpenEBS on local machine.
Follow the steps given below:

## Step 1: Install vagrant box

To run the kubernetes cluster on local machine you need Vagrant box. If you do not have vagrant box then follow steps given [here.](https://github.com/openebs/openebs/tree/master/k8s/lib/vagrant/test/k8s/1.6#installing-kubernetes-16-and-openebs-clusters-on-ubuntu-1604)

## Step 2. Download OpenEBS Vagrantfile

```
$ wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/lib/vagrant/test/k8s/1.6/Vagrantfile
```

## Step 3: Bring k8s cluster up

```
openebs@openebs:~$ cd openebs/k8s/lib/vagrant/test/k8s/1.6
openebs@openebs:~/openebs/k8s/lib/vagrant/test/k8s/1.6$ vagrant up
```

It will bring up one kubemaster and two kubeminions

## Step 4: ssh to kubemaster

```
openebs@openebs:~/openebs/k8s/lib/vagrant/test/k8s/1.6$ vagrant ssh kubemaster-01

```

## Step 5: Run OpenEBS operator

Download the latest OpenEBS Operator Files inside kubemaster-01.
```
ubuntu@kubemaster-01:~$ git clone https://github.com/openebs/openebs
ubuntu@kubemaster-01:~$ cd openebs/k8s
```

Run OpenEBS Operator:

```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-operator.yaml
```

Add OpenEBS related Storage Classes, that can then be used by developers/apps.

```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-storageclasses.yaml
```

## Step 6 : Running Stateful workloads with OpenEBS Storage.

All you need to do, to use OpenEBS as persistent storage for your Stateful workloads, is to set the Storage Class in the PVC to the OpenEBS Storage Class.

Get the list of storage classes using the below command. Choose the storage class that best suits your application. 

```
ubuntu@kubemaster-01:~$ kubectl get sc
```

Some sample yaml files for stateful workoads using OpenEBS are provided in the [openebs/k8s/demo](https://github.com/openebs/openebs/tree/master/k8s/demo)

```
ubuntu@kubemaster-01:~$ kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml
```

The above command will create the following, which can be verified using the corresponding kubectl commands:

- Launch a Jupyter Server, with the specified notebook file from github
  (kubectl get deployments)
- Create an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data)
  (kubectl get pvc)
  (kubectl get pv)
  (kubectl get pods)
- Expose the Jupyter Server to external world via the `http://NodeIP:8888` (NodeIP is any of the minion nodes external IP)
  (kubectl get pods)
