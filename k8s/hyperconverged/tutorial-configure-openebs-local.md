# Using OpenEBS with Kubernetes on local machine

This tutorial, provides detailed instructions on how to setup and use OpenEBS on local machine.
Follow the steps given below:

## Step 1: Install vagrant box

To run the kubernetes cluster on local machine you need Vagrant box. If you do not have vagrant box then follow steps given [here.](https://github.com/openebs/openebs/tree/master/k8s/lib/vagrant/test/k8s/1.6#installing-kubernetes-16-and-openebs-clusters-on-ubuntu-1604)

## Step 2. Download OpenEBS Vagrantfile

```
git clone https://github.com/openebs/openebs
```

## Step 3: Bring k8s cluster up

```
cd openebs/k8s/vagrant/1.9.4/ubuntu/
vagrant up
```

It will bring up one kubemaster and two kubeminions

## Step 4: ssh to kubemaster

```
ubuntu-1604@ubuntu1604-virtual-machine:~/openebs/k8s/vagrant/1.9.4/ubuntu$ vagrant ssh kubemaster-01

```

## Step 5: Run OpenEBS operator

Download the latest OpenEBS Operator Files inside kubemaster-01.
```
ubuntu@kubemaster-01:~/openebs/k8s$ git clone https://github.com/openebs/openebs
ubuntu@kubemaster-01:~/openebs/k8s$
```

Run OpenEBS Operator:

```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-operator.yaml
namespace "openebs" created
serviceaccount "openebs-maya-operator" created
clusterrole "openebs-maya-operator" created
clusterrolebinding "openebs-maya-operator" created
deployment "maya-apiserver" created
service "maya-apiserver-service" created
deployment "openebs-provisioner" created
deployment "openebs-snapshot-controller" created
customresourcedefinition "storagepoolclaims.openebs.io" created
customresourcedefinition "storagepools.openebs.io" created
storageclass "openebs-standard" created
storageclass "snapshot-promoter" created
customresourcedefinition "volumepolicies.openebs.io" created
```
Check OpenEBS Pods status
```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl get pods -n openebs
NAME                                           READY     STATUS    RESTARTS   AGE
maya-apiserver-84fd4f776d-n564g                1/1       Running   0          5m
openebs-provisioner-74cb999586-jlglb           1/1       Running   0          5m
openebs-snapshot-controller-6449b4cdbb-bl72s   2/2       Running   0          5m
```

Add OpenEBS related Storage Classes, that can then be used by developers/apps.

```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-storageclasses.yaml
storageclass "openebs-standalone" created
storageclass "openebs-percona" created
storageclass "openebs-jupyter" created
storageclass "openebs-mongodb" created
storageclass "openebs-cassandra" created
storageclass "openebs-redis" created
storageclass "openebs-kafka" created
storageclass "openebs-zk" created
storageclass "openebs-es-data-sc" created
```

## Step 6 : Running Stateful workloads with OpenEBS Storage.

All you need to do, to use OpenEBS as persistent storage for your Stateful workloads, is to set the Storage Class in the PVC to the OpenEBS Storage Class.

Get the list of storage classes using the below command. Choose the storage class that best suits your application. 

```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl get sc
NAME                 PROVISIONER                                                AGE
openebs-cassandra    openebs.io/provisioner-iscsi                               27s
openebs-es-data-sc   openebs.io/provisioner-iscsi                               27s
openebs-jupyter      openebs.io/provisioner-iscsi                               27s
openebs-kafka        openebs.io/provisioner-iscsi                               27s
openebs-mongodb      openebs.io/provisioner-iscsi                               27s
openebs-percona      openebs.io/provisioner-iscsi                               27s
openebs-redis        openebs.io/provisioner-iscsi                               27s
openebs-standalone   openebs.io/provisioner-iscsi                               27s
openebs-standard     openebs.io/provisioner-iscsi                               7m
openebs-zk           openebs.io/provisioner-iscsi                               27s
snapshot-promoter    volumesnapshot.external-storage.k8s.io/snapshot-promoter   7m
```

Some sample yaml files for stateful workoads using OpenEBS are provided in the [openebs/k8s/demo](https://github.com/openebs/openebs/tree/master/k8s/demo)

```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml
deployment "jupyter-server" created
persistentvolumeclaim "jupyter-data-vol-claim" created
service "jupyter-service" created
```

The above command will create the following, which can be verified using the corresponding kubectl commands:

- Launch a Jupyter Server, with the specified notebook file from github
  ```
  ubuntu@kubemaster-01:~/openebs/k8s$ kubectl get deployments
  NAME                                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
  jupyter-server                                  1         1         1            0           2m
  pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db-ctrl   1         1         1            1           2m
  pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db-rep    3         3         3            1           2m
  ```
- Create an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data)
  ```
  ubuntu@kubemaster-01:~/openebs/k8s$ kubectl get pvc
  NAME                     STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
  jupyter-data-vol-claim   Bound     pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db   5G         RWO            openebs-jupyter   2m
  
  ubuntu@kubemaster-01:~/openebs/k8s$ kubectl get pv
  NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                   STORAGECLASS      REASON    AGE
  pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db   5G         RWO            Delete           Bound     default/jupyter-data-vol-claim           openebs-jupyter             2m
  
  ubuntu@kubemaster-01:~/openebs/k8s$ kubectl get pods
  NAME                                                             READY     STATUS              RESTARTS   AGE
  jupyter-server-68d4ddc48-tb2jj                                   1/1       Running             0          4m
  pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db-ctrl-7888fc7f89-q7blg   2/2       Running             0          4m
  pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db-rep-6d8d4965c6-9hrj7    1/1       Running             0          3m
  pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db-rep-6d8d4965c6-dj7sr    1/1       Running             0          3m
  pvc-e3b4c8bc-7859-11e8-9472-02b983f0a4db-rep-6d8d4965c6-kkpt7    0/1       Pending             0          3m
  ```
- Expose the Jupyter Server to external world via the http://NodeIP:8888 (NodeIP is any of the minion nodes external IP)
  (kubectl get nodes -o wide)
