# Overview

OpenEBS is the most widely deployed open source example of a category of storage solutions sometimes called [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). OpenEBS is itself deployed as a set of containers on Kubernetes worker nodes. This document describes the high level architecture of OpenEBS and the links to the Source Code and its Dependencies. 

Some key aspects that make OpenEBS different compared to other traditional storage solutions:
* Built using the micro-services architecture like the applications it serves. Use Kubernetes itself to orchestrate and manage the OpenEBS components 
* Built completely in userspace making it highly portable to run across any OS / Platform
* Completely intent driven, inheriting the same principles that drive the ease of use with Kubernetes

# Architecture 

The architecture of OpenEBS is container native and horizontally scalable. OpenEBS is a collection of different microservices that can be grouped into 3 major areas (or planes):

## Data Engines or the Data Plane

The data engines are the containers responsible for interfacing with the underlying storage devices such as host filesystem, rotational drives, SSDs and NVMe devices. The data engines provide volumes with required capabilities like high availability, snapshots, clones, etc. Volume capabilities can be optimized based on the workload they serve. Depending on the capabilities requested, OpenEBS selects different data engines like cStor ( a CoW based) or Jiva or even Local PVs for a given volume. 

The high availability is achieved by abstracting the access to the volume into the target container - which in turn does the synchronous replication to multiple different replica containers. The replica containers save the data to the underlying storage devices. If a node serving the application container and the target container fails, the application and target are rescheduled to a new node. The target connects with the other available replicas and will start serving the IO.

## Storage Management or Control Plane

The Storage Management or Control Plane is responsible for interfacing between Kubernetes (Volume/CSI interface) and managing the volumes created using the OpenEBS Data Engines. The Storage Management Plane is implemented using a set of containers that are either running at the cluster level or the node level. Some of the storage management options are also provided by containers running as side-cars to the data engine containers. 

The storage management containers are responsible for providing APIs for gathering details about the volumes. The APIs can be used by Kubernetes Provisioners for managing volumes, snapshots, backups, so forth; used by Prometheus to collect metrics of volumes; used by custom programs like CLI or UI to provide insights into the OpenEBS Storage status or management.

## Storage Device Management Plane

While this plane is an integral part of the OpenEBS Storage Management Plane, the containers and custom resources under this plane can be used by other projects that require a Kubernetes native way of managing the Storage Devices (rotational drives, SSDs and NVMe, etc.) attached to Kubernetes nodes.

Storage Device Management Plane can be viewed as an Inventory Management tool, that discovers devices and keeps track of their usage via device claims (akin to PV/PVC concept). All the operations like device listing, identifying the topology or details of a specific device can be accessed via kubectl and Kubernetes Custom Resources.

# Source Code and Dependencies 

OpenEBS source code is spread across multiple repositories, organized either by the storage engine or management layer. This section describes the various actively maintained repositories. 

## Local PVs

- [openebs/zfs-localpv](https://github.com/openebs/zfs-localpv) contains the CSI driver for provisioning Kubernetes Local Volumes on ZFS installed on the nodes. 
- [openebs/lvm-localpv](https://github.com/openebs/lvm-localpv) contains the CSI driver for provisioning Kubernetes Local Volumes on LVM installed on the nodes. 
- [openebs/dynamic-localpv-provisioner](https://github.com/openebs/dynamic-localpv-provisioner) contains the CSI driver for provisioning Kubernetes hostpath Local Volumes. 

## Replicated PVs

- [openebs/mayastor](https://github.com/openebs/mayastor) contains the mayastor data plane. 
- [openebs/mayastor-control-plane](https://github.com/openebs/mayastor-control-plane) contains the mayastor control plane and CSI driver. 
- [openebs/mayastor-extensions](https://github.com/openebs/mayastor-extensions) contains the mayastor helm installer, upgrade operator and the kubectl plugin. 
- [openebs/mayastor-dependencies](https://github.com/openebs/mayastor-dependencies) common set of dependencies used by both control-plane and data-plane components.
- [openebs/spdk](https://github.com/openebs/spdk) is a forked repository of [spdk/spdk](https://github.com/spdk/spdk) (License: BSD) for managing the upstream changes. 
- [openebs/spdk-rs](https://github.com/openebs/spdk-rs) provides a higher-level bindings and wrappers around SPDK library to enable building safer SPDK-based Rust applications.

## Common or Generic 

- [openebs/openebs](https://github.com/openebs/openebs) is OpenEBS meta repository that contains design documents, project management, community and contributor documents, deployment and workload examples. 
- [openebs/website](https://github.com/openebs/website) contains the source code for OpenEBS portal (https://openebs.io) implemented using Gatsby framework and other libraries listed in [package.json](https://github.com/openebs/website/blob/refactor-to-ghost-and-gatsby/package.json).
- [openebs/velero-plugin](https://github.com/openebs/velero-plugin) has the plugin code to perform cStor and ZFS Local PV based Backup and Restore using Velero. 
- [openebs/linux-utils](https://github.com/openebs/linux-utils) is a general purpose alpine container used to launch some management jobs by OpenEBS Operators. 
- [openebs/openebsctl](https://github.com/openebs/openebsctl) contains the OpenEBS CLI that can be run as kubectl plugin. This functionality is being split from the mono-repo [openebs/maya](https://github.com/openebs/maya) into its own repository. (Currently in Alpha). 

## Experimental repos  

- [openebs/performance-benchmark](https://github.com/openebs/performance-benchmark) contains tools/scripts for running performance benchmarks on Kubernetes volumes.  This is an experimental repo. The work in this repo can move to other repos like e2e-tests. 
- [openebs/rawfile-localpv](https://github.com/openebs/rawfile-localpv) contains the CSI driver for provisioning Kubernetes Local Volumes on Hostpath by creating sparse files. (Currently in Alpha). 

# Additional details

- Design Documents for various components and features are listed here([local-pv](./local-pv/), [replicated-pv](./replicated-pv/))
- Find the template for creating the design proposal [here](./oep-template.md)
- Find the process of the OEP [here](./oep-template.md)

# Getting involved with Contributions

There is always something more that is required, to make it easier to suit your use-cases. Feel free to join the discussion on new features or raise a PR with your proposed change. 

- [Join OpenEBS contributor community on Kubernetes Slack](https://kubernetes.slack.com)
	- Already signed up? Head to our discussions at [#openebs-dev](https://kubernetes.slack.com/messages/openebs-dev/)
- [Join our Community meetings](https://github.com/openebs/community/blob/develop/CONTRIBUTING.md#regular-community-meeting)
- Pick an issue of your choice to work on from any of the repositories listed above. Here are some contribution ideas to start looking at:
  - [Good first issues](https://github.com/search?q=org%3Aopenebs+is%3Aissue+label%3A%22good+first+issue%22).
  - [Slightly more involved issues](https://github.com/search?q=org%3Aopenebs+is%3Aissue+label%3A%22help+wanted%22).
  - Help with backlogs from the [roadmap](../ROADMAP.md) by discussing requirements and design.
