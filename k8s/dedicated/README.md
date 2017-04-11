# Deploying dedicated OpenEBS Cluster for Kubernetes

OpenEBS provides Storage via Containers (called as VSMs). The VSMs are launched on Docker via container orchestration engine. Thus the deployment of the OpenEBS Cluster (as show in the diagram below) closely resembles that of a Container Orchestrator like Kubernetes. 

![Dedicated Deployment Image](https://github.com/openebs/openebs/blob/master/documentation/source/_static/dedicated-with-podsv0.2.png)

Just as you would see your apps/containers running in Docker on the Kubernetes minion nodes, the storage required for your stateful apps/containers will be provided by VSMs (Storage Containers) running in Docker on the OpenEBS Storage hosts 

An dedicated OpenEBS Cluster comprises of three parts:

(a) **OpenEBS Maya Master ( omm )**, contains the functionality of the control plane ( like Kubernetes Master), participating in the provisioning and monitoring of the VSMs. Since VSMs are storage containers, albeit containers, the OMM defers the actual scheduling and launching of the containers to the container orchestration engines, and focuses on providing storage aware inputs only. OpenEBS 0.2 uses Nomad as a container scheduler, thus requiring the following components to be installed on OMM:
- Maya CLI
- Maya API Server 
- Nomad Server and Consul Server

(b) **OpenEBS Storage Hosts (osh)**, are where the VSM containers are launched. These are the nodes, where data is persisted onto the local disks or remote disks. The VSM software (containerized) takes care of replicating the data to peer container in another osh node for data persistence and high availability. The osh nodes, primarily comprise of:
- Maya CLI
- Docker
- Nomad Agent and Consul Agent

OpenEBS 0.2 supports host-based networking for the containers. 

(c) **Kubernetes FlexVolume - OpenEBS Driver (openebs-iscsi)**, is the one that helps in dynamically provisioning and connecting to the block storage offered by the VSMs. This driver needs to be installed on all the Kubernetes minion nodes.

## Install Options

You can manually setup the OpenEBS Cluster on your machines.
- [Setup OpenEBS Cluster on Ubuntu 16.04](https://github.com/openebs/openebs/blob/master/k8s/dedicated/tutorial-ubuntu-1604-baremetal.md)

## Getting Started using Vagrant

To help you quickly get started, we have setup an Vagrantfile that will launch 5 Ubuntu VMs, for creating a single node Kubernetes Cluster and a two node OpenEBS Cluster. If this is your first time with Vagrant, you can follow through our [Step-by-step Installation Tutorial for Ubuntu 16.04](./tutorial-ubuntu1604-vagrant.md).

If you are an user of Vagrant and VirtualBox on Ubuntu, just follow these simple instructions to setup an Amazon EBS like Storage Service for Kubernetes Cluster using the following simple steps:

```
mkdir demo
cd demo
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/demo
vagrant up
```

**Note** *vagrant up* may take few minutes depending on your network speed - When vagrant up is issued for the first time, the required vagrant plugins are installed (for caching the vagrant boxes) and kubernetes and openebs 2.0 virtualboxes are downloaded and configured.

The demo setup will provide you with the following machines:
- Kubernetes Master (kubemaster-01)
- Kubernetes Minion (kubeminion-01)
- OpenEBS Maya Master (omm-01)
- OpenEBS Storage Host (osh-01)
- OpenEBS Storage Host (osh-02)


## Next Steps
- [Create MySQL container on OpenEBS Storage](./run-mysql-openebs.md)
- [Start vdbench tests on OpenEBS storage](./running-vdbench-tests-with-openebs.md)
- [Start fio tests on OpenEBS storage](./running-fio-tests-with-openebs.md)
