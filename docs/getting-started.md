
#Get Started

This quick start guide helps you to setup a simple OpenEBS Cluster with three machines, VMs or Servers. OpenEBS is both a scale-out and scale-up solution. The OpenEBS cluster created using this guide can be taken into production and can be scaled later, to meet changing storage demands, by adding additional machines to the cluster.

*The clients (docker-hosts) can be configured to consume the OpenEBS storage either via Network(iSCSI) or using TCMU. This guide will show connecting to storage using iSCSI.*

OpenEBS is delivered through container architecture called VSM (Virtual Storage Machine), to provide storage. A VSM can be considered as Storage Pod,a set of containers - a frontend-container and one or more storage-containers. 

<< Block Diagram of frontend and backend containers of a VSM >>

The frontend container takes care of providing access to the block storage, example iscsi, and handles the data input/output operations and data management functions like - snapshots, replication, caching, metering etc., 

The storage container(s) are configured with a persistent backend storage using local disks or remote disks. The controller will replicate the data inot the storage-containers and the storage containers also participate in building new backends for a VSM, restoring the data from snapshots, transferring snapshots to clouds, etc., Storage-containers can be added/removed dynamically to an VSM. 

The VSM/Storage Pod - containers provisioning, scheduling and monitoring is taken care by OpenEBS Maya Master (omm), the storage orchestration layer. The VSM storage-containers will be running on the OpenEBS Storage Hosts (osh), which typically would either have hard disks/SSDs or mounted file/block/s3 storage.

To get started, let us use three machines, referred here as: master-01 used as OpenEBS Maya Master (omm) and host-01 and host-02 used as OpenEBS Storage Host (osh). 

*If you are trying to use VirtualBox VMs, you can bring up the machines using the following Vagrantfile*

<< Connectivity Diagram showing the three machines >>

##Prepare the machines for installation. 

Since OpenEBS is delivered through containers, the OpenEBS hosts can be run on any operating system with container engine (say docker, etc.,). We will use Ubuntu 16.04 in this example. 

### Prepare Software
OpenEBS is a software-only solution that can be installed using the released binaries or built and installed directly from source. In this guide we will *Ubuntu 16.04* as the underlying operating system. 

To download and install, you will require *wget* and *unzip* to be present on the operating system. 

```
apt-get update wget unzip
```

### Prepare Network
Typically, the storage is accessed via a different network (with high bandwidth 10G or 40G et.,) than management on 1G. In case you don't have an high bandwidth network in your setup, you can try this example with a single network as well.

### Prepare Disk Storage
You can use *maya* to manage the local and remote disks. Optionally create RAID and filesystem layer ontop of the raw disks, etc., 

In this guide for sake of simplicity, we will use the following directory /opt/openebs/. Ensure that the directory is writeable. Note that you add new replication stores at runtime and attach to VSMs. So when you move this node into production, you can move the content from local directories to local/remote disk based storage. 

