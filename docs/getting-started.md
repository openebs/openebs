
#Get Started

This quick start guide helps you to setup a simple OpenEBS Cluster with three machines, VMs or Servers. OpenEBS is both a scale-out and scale-up solution. The OpenEBS cluster created using this guide can be taken into production and can be scaled later, to meet changing storage demands, by adding additional machines to the cluster.

*The clients (docker-hosts) can be configured to consume the OpenEBS storage either via Network(iSCSI) or using TCMU. This guide will show connecting to storage using iSCSI.*

In this guide, we will setup an simple OpenEBS cluster with three machines: 
- **master-01** used as OpenEBS Maya Master (omm) and 
- **host-01** and **host-02** used as OpenEBS Storage Host (osh). 

*If you are trying to use VirtualBox VMs, you can bring up the machines using the following Vagrantfile*

![Machine Connectivity Diagram](./images/OpenEBSNodes.png)

##Prepare the machines for installation. 

Since OpenEBS is delivered through containers, the OpenEBS hosts can be run on any operating system with container engine. This guide will use Ubuntu 16.04 and docker.

### Prepare Software
OpenEBS is a software-only solution that can be installed using the released binaries or built and installed directly from source. In this guide we will *Ubuntu 16.04* as the underlying operating system. 

To download and install, you will require *wget* and *unzip* to be present on the operating system. 

```
sudo apt-get update
sudo apt-get install -y wget unzip
```

### Prepare Network
Typically, the storage is accessed via a different network (with high bandwidth 10G or 40G et.,) than management on 1G. In case you don't have an high bandwidth network in your setup, you can try this example with a single network as well.

### Prepare Disk Storage
You can use *maya* to manage the local and remote disks. Optionally create RAID and filesystem layer ontop of the raw disks, etc., 

In this guide for sake of simplicity, we will use the following directory /opt/openebs/. Ensure that the directory is writeable. Note that you add new replication stores at runtime and attach to VSMs. So when you move this node into production, you can move the content from local directories to local/remote disk based storage. 

```
sudo mkdir -p /opt/openebs
sudo chown -R <docker-user> /opt/openebs
```

