# Setting up OpenEBS Cluster on Ubuntu 16.04

This is the getting started guide for Ubuntu 16.04. 

To configure OpenEBS Cluster, you’ll need one machine to act as a OpenEBS Maya Master (omm node), and one or more hosts to act as OpenEBS Storage Hosts (osh nodes). The kubernetes minion nodes should be able to communicate with the OpenEBS Maya Master, for initiating provisioning of VSMs and have access to the OpenEBS Storage Hosts to access the VSM block storage. 

This guide assumes that you already have a kubernetes cluster setup. If not, please follow the instructions provided at the [Kuberentes Ubuntu Guide](https://kubernetes.io/docs/getting-started-guides/ubuntu/).

In this guide, we will walk you through the following:
- Setup OpenEBS Maya Master on Ubuntu 16.04
- Setup OpenEBS Storage Host on Ubuntu 16.04
- Install the FlexVolume OpenEBS Driver (openebs-iscsi) on Kubernetes Minions
- Start MySQL Container on OpenEBS Storage

## Prerequisites

Identify 3 Ubuntu 16.04 machines (either Virtual Machines or Physical Machines) which will be used for OpenEBS Cluster. In the examples below, we will assume the following hostnames and IP address. Please replace this with your machine details. 

```
master-01 ( 172.28.128.4)
host-01   ( 172.28.128.5)
host-02   ( 172.28.128.6)
```

We will configure *master-01* as OpenEBS Maya Master and use *host-01* and *host-02* as OpenEBS Storage Hosts. 

Make sure each of the nodes have access to the internet and can communicate with the Kubernetes Minion Nodes.

OpenEBS Maya CLI helps you to easily setup OpenEBS Maya Master or OpenEBS Storage Host services on a given machine, by downloading and installing the required dependencies. OpenEBS Maya CLI is available for download from https://github.com/openebs/maya/releases. We will download and install OpenEBS 0.2 Maya CLI. 

## Setup OpenEBS Maya Master

### Prepare for installation

Login via SSH to *master-01* and install the required packages. 

```
sudo apt-get update
sudo apt-get install -y wget unzip
```

### Download and install Maya

```
RELEASE_TAG=0.2
wget https://github.com/openebs/maya/releases/download/${RELEASE_TAG}/maya-linux_amd64.zip
unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip
maya version
```

### Install and Start OpenEBS Maya Master

Note down the IP address on which you would like to have your maya master services to bind. We will use 172.28.128.4 in this example. 

```
maya setup-omm -self-ip=172.28.128.4
source ~/.profile	
maya omm-status
```

The last command should show you the following information:

```
Name           Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
omm-01.global  172.28.128.4  4648  alive   true    2         0.5.5  dc1         global

m-apiserver listening at http://172.28.128.4:5656
```

## Setup OpenEBS Storage Host

### Prepare for installation

Login via SSH to *host-01* and install the required binaries. 

```
sudo apt-get update
sudo apt-get install -y wget unzip
```

### Download and install Maya

```
RELEASE_TAG=0.2
wget https://github.com/openebs/maya/releases/download/${RELEASE_TAG}/maya-linux_amd64.zip
unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip
maya version
```

### Install and Start OpenEBS Storage Host

Note down the IP address on which you would like to have your maya master services to bind. We will use 172.28.128.5 in this example. 

```
maya setup-osh -self-ip=172.28.128.4 -omm-ips=172.28.128.4
source ~/.profile	
maya osh-status
```

The last command should show you the following information:

```
ID        DC   Name     Class   Drain  Status
dc7fd9b9  dc1  host-01  <none>  false  ready
```

Repeat the above steps for *host-02*. After setting up *host-02* as OpenEBS Storage Host, you should see the following output for *maya osh-status*

```
ID        DC   Name     Class   Drain  Status
cbceb3d2  dc1  host-02  <none>  false  ready
dc7fd9b9  dc1  host-01  <none>  false  ready

```

## Install Kubernetes FlexVolume - OpenEBS Driver

Login to all the kubernetes minion nodes and install the driver with the following steps:

```
sudo wget https://raw.githubusercontent.com/openebs/openebs/v0.2/k8s/lib/plugin/flexvolume/openebs-iscsi
sudo chmod +x openebs-iscsi
sudo mkdir -p /usr/libexec/kubernetes/kubelet-plugins/volume/exec/openebs~openebs-iscsi/
sudo cp openebs-iscsi /usr/libexec/kubernetes/kubelet-plugins/volume/exec/openebs~openebs-iscsi/openebs-iscsi
sudo systemctl restart kubelet
```

## Configure the MySQL K8s Pod to use the OpenEBS Volume

You can start consuming OpenEBS Storge by modifying the Application intent files to point to the FlexVolume OpenEBS Driver (openebs-iscsi). In this guide we will run MySQL on OpenEBS Storage. A sample spec is available for download from [openebs project](https://github.com/openebs/openebs/blob/master/k8s/demo/specs/demo-mysql-openebs-plugin.yaml). 

### Configure the Application Pod to consume OpenEBS Storage

Login to your Kuberentes Master or machine from where you can send the kubectl commands to the kubernetes master. 

```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/specs/demo-mysql-openebs-plugin.yaml
cat demo-mysql-openebs-plugin.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: mysql
  labels:
    name: mysql
spec:
  containers:
  - resources:
      limits:
        cpu: 0.5
    name: mysql
    image: mysql
    env:
      - name: MYSQL_ROOT_PASSWORD
        value: k8sDem0
    ports:
      - containerPort: 3306
        name: mysql
    volumeMounts:
    - mountPath: /var/lib/mysql
      name: demo-vsm1-vol1
  volumes:
  - name: demo-vsm1-vol1
    flexVolume:
      driver: "openebs/openebs-iscsi"
      options:
        name: "demo-vsm1-vol1"
        openebsApiUrl: "http://172.28.128.4:5656/latest"
        size: "5G"
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```
**Note:** The yaml ships with an default address for the openebsApiUrl. Modify this with the correct address, noted in the previous step.

### Start the MySQL pod
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl create -f demo-mysql-openebs-plugin.yaml
pod "mysql" created
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl get pods
NAME      READY     STATUS              RESTARTS   AGE
mysql     0/1       ContainerCreating   0          54s
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

Once the volume is mounted and database is initialized, the pod status turns to running. 

```
ubuntu@kubemaster-01:~$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
mysql     1/1       Running   4          11m
ubuntu@kubemaster-01:~$ 
```
