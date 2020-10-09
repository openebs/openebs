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

## Common or Generic 

- [openebs/openebs](https://github.com/openebs/openebs) is OpenEBS meta repository that contains design documents, project management, community and contributor documents, deployment and workload examples. 
- [openebs/openebs-docs](https://github.com/openebs/openebs-docs) contains the source code for OpenEBS Documentation portal (https://docs.openebs.io) implemented using Docusaurus framework and other libraries listed in [package.json](https://github.com/openebs/openebs-docs/blob/staging/website/package.json).
- [openebs/website](https://github.com/openebs/website) contains the source code for OpenEBS portal (https://openebs.io) implemented using Gatsby framework and other libraries listed in [package.json](https://github.com/openebs/website/blob/refactor-to-ghost-and-gatsby/package.json).
- [openebs/charts](https://github.com/openebs/charts) contains the Helm chart source code for OpenEBS and also hosts a gh-pages website for install artifacts and Helm packages. 
- [openebs/maya](https://github.com/openebs/maya) contains OpenEBS Storage Management components that help with managing cStor, Jiva and Local Volumes. This repository contains the non-CSI drivers. The code is being moved from this repository to engine specific CSI drivers. Detailed dependency list can be found in: [go.mod](https://github.com/openebs/maya/blob/master/go.mod). OpenEBS also maintains a forked copy of the Kubernetes external-storage repository to support the external-provisioners for cStor and Jiva volumes. 
  - [openebs/external-storage](https://github.com/openebs/external-storage) contains OpenEBS extensions for Kubernetes External Dynamic Provisioners. These provisioners will be deprecated in the near term in favor of the CSI drivers that are under beta and alpha stage at the moment. This is a forked repository from [kubernetes-incubator/external-storage](https://github.com/kubernetes-retired/external-storage).
- [openebs/velero-plugin](https://github.com/openebs/velero-plugin) has the plugin code to perform cStor and ZFS Local PV based Backup and Restore using Velero. 
- [openebs/linux-utils](https://github.com/openebs/linux-utils) is a general purpose alpine container used to launch some management jobs by OpenEBS Operators. 
- [openebs/api](https://github.com/openebs/api) contains the OpenEBS related Kubernetes custom resource specifications and the related Go-client API to manage those resources. This functionality is being split from the mono-repo [openebs/maya](https://github.com/openebs/maya) into its own repository.
- [openebs/upgrade](https://github.com/openebs/upgrade) contains management tools for upgrading and migrating OpenEBS volumes and pools. This funtionality is being split from the mono-repo [openebs/maya](https://github.com/openebs/maya) into its own repository. Go dependencies are listed [here](https://github.com/openebs/upgrade/blob/master/go.mod).
- [openebs/e2e-tests](https://github.com/openebs/e2e-tests) contains the Litmus based e2e tests that are executed on GitLab pipelines. Contains tests for Jiva, cStor and Local PV.

## Experimental repos  

- [openebs/openebsctl](https://github.com/openebs/openebsctl) contains the OpenEBS CLI that can be run as kubectl plugin. This functionality is being split from the mono-repo [openebs/maya](https://github.com/openebs/maya) into its own repository. (Currently in Alpha). 
- [openebs/performance-benchmark](https://github.com/openebs/performance-benchmark) contains tools/scripts for running performance benchmarks on Kubernetes volumes.  This is an experimental repo. The work in this repo can move to other repos like e2e-tests. 
- [openebs/monitor-pv](https://github.com/openebs/monitor-pv) is a prometheus exporter for sending capacity usage statistics using `du` from hostpath volumes. 
- [openebs/helm-operator](https://github.com/openebs/helm-operator) is wrapper around OpenEBS Helm to allow installation the [Operator Hub](https://operatorhub.io/). 



## Node Disk Manager (aka Storage Device Management plane)

- [openebs/node-disk-manager](https://github.com/openebs/node-disk-manager) contains Kubernetes native Device Inventory Management functionality. A detailed dependency list can be found in [go.mod](https://github.com/openebs/node-disk-manager/blob/master/go.mod). Along with being dependent on Kubernetes and Operator SDK for managing the Kubernetes custom resources, NDM also optionally depends on the following. 
  - [openSeaChest](https://github.com/Seagate/openSeaChest) (License: MPL 2.0) for discovering device attributes. OpenEBS maintains forked repositories of openSeaChest to fix/upstream the issues found in this libarary.

## Jiva
- [openebs/jiva](https://github.com/openebs/jiva) is one of the data engines supported by OpenEBS which was forked from Rancher Longhorn engine and has diverged from the way Jiva volumes are managed within Kubernetes. At the time of the fork, Longhorn was focused towards Docker and OpenEBS was focused on supporting Kubernetes. Jiva engine depends on the following:
  - A fork of Longhorn engine is maintained in OpenEBS to upstream the common changes from Jiva to Longhorn. 
  - [gostor/gotgt](https://github.com/openebs/gotgt) for providing user space iSCSI Target support implemented in Go. A fork of the project is maintained in OpenEBS to keep the dependencies in sync and upstream the changes. 
  - [longhorn/sparse-tools](https://github.com/openebs/sparse-tools) fork is also maintained by OpenEBS to manage the differences between Jiva way of writing into the sparse files.
  - [go.mod](https://github.com/openebs/jiva/blob/master/go.mod) provides a complete list of dependencies used by the Jiva project. 
- [openebs/jiva-csi](https://github.com/openebs/jiva-csi) contains the CSI Driver for Jiva Volumes. Currently in alpha. Dependencies are in: [go.mod](https://github.com/openebs/jiva-csi/blob/master/go.mod).
- [openebs/jiva-operator](https://github.com/openebs/jiva-operator) contains Kubernetes custom resources and operators to manage Jiva volumes. Currently in alpha used by Jiva CSI Driver. This will replace the volume management functionality offered by OpenEBS API Server. Dependencies are in: [go.mod](https://github.com/openebs/jiva-operator/blob/master/go.mod).
  
## cStor

- [openebs/libcstor](https://github.com/openebs/libcstor) contains the cStor Replica functionality that makes use of uZFS - userspace ZFS to store the data on devices. 
  - [openebs/cstor](https://github.com/openebs/cstor) is a fork of [openzfs/zfs](https://github.com/openzfs/zfs) (License: CDDL). This fork contains the code that modifies ZFS to run in user space. 
- [openebs/istgt](https://github.com/openebs/istgt) contains the iSCSI Target functionality used by cStor volumes. This work is derived from earlier work available as FreeBSD port at http://www.peach.ne.jp/archives/istgt/ (archive link: https://web.archive.org/web/20190622064711/peach.ne.jp/archives/istgt/). The original work was licensed under BSD license.
- [openebs/cstor-csi](https://github.com/openebs/cstor-csi) is the CSI Driver for cStor Volumes. This will deprecate the external provisioners. Currently in beta. Dependencies are in: [go.mod](https://github.com/openebs/cstor-csi/blob/master/go.mod).
- [openebs/cstor-operators](https://github.com/openebs/cstor-operators) contain the Kubernetes custom resources and operators to manage cStor Pools volumes. Currently in beta and used by cStor CSI Driver. This will replace the volume management functionality offered by OpenEBS API Server. Dependencies are in: [go.mod](https://github.com/openebs/cstor-operators/blob/master/go.mod).

## Mayastor

- [openebs/Mayastor](https://github.com/openebs/Mayastor) contains the Mayastor data engine, CSI driver and management utilitities. 
  - [openebs/spdk](https://github.com/openebs/spdk) is a forked repository of [spdk/spdk](https://github.com/spdk/spdk) (License: BSD) for managing the upstream changes. 
  - [openebs/spdk-sys](https://github.com/openebs/spdk-sys) (License: MIT) contains Rust bindings for SPDK. 
  - [openebs/partition-identity](https://github.com/openebs/partition-identity) is forked from [pop-os/partition-identity](https://github.com/pop-os/partition-identity) (License: MIT) for managing the upstream changes. 
  - [openebs/blkid](https://github.com/openebs/blkid) is forked from [pop-os/blkid](https://github.com/pop-os/blkid) (License: MIT) for managing the upstream changes.
  - [openebs/proc-mounts](https://github.com/openebs/proc-mounts/) is forked from [pop-os/proc-mounts](https://github.com/pop-os/proc-mounts) (License: MIT) for managing upstream changes.
  - [openebs/sys-mount](https://github.com/openebs/sys-mount/) is forked from [pop-os/sys-mount](https://github.com/pop-os/sys-mount) (License: MIT) for managing upstream changes.
  - [openebs/blkid-sys](https://github.com/openebs/blkid-sys/) is forked from [cholcombe973/blkid-sys](https://github.com/cholcombe973/blkid-sys) (License: MIT) for managing upstream changes.



## Dynamic Local PVs

- [openebs/zfs-localpv](https://github.com/openebs/zfs-localpv) contains the CSI driver for provisioning Kubernetes Local Volumes on ZFS installed on the nodes. 
- [openebs/rawfile-localpv](https://github.com/openebs/rawfile-localpv) contains the CSI driver for provisioning Kubernetes Local Volumes on Hostpath by creating sparse files. (Currently in Alpha). 



# Additional details

- Architectural overview on how each of the Data engines operate are provided in this [Presentation](https://docs.google.com/presentation/d/1mjOkAQppyd23sw7PIryxu5kSrex352bT6bINzw6mUFY/edit?usp=sharing)
- Design Documents for various components and features are listed [here](./)

# Getting involved with Contributions

There is always something more that is required, to make it easier to suit your use-cases. Feel free to join the discussion on new features or raise a PR with your proposed change. 

- [Join OpenEBS contributor community on Kubernetes Slack](https://kubernetes.slack.com)
	- Already signed up? Head to our discussions at [#openebs-dev](https://kubernetes.slack.com/messages/openebs-dev/)
- [Join our Community meetings](https://github.com/openebs/openebs/tree/master/community)
- Pick an issue of your choice to work on from any of the repositories listed above. Here are some contribution ideas to start looking at:
  - [Good first issues](https://github.com/search?q=org%3Aopenebs+is%3Aissue+label%3A%22good+first+issue%22).
  - [Slightly more involved issues](https://github.com/search?q=org%3Aopenebs+is%3Aissue+label%3A%22help+wanted%22).
  - Help with backlogs from the [roadmap](../../ROADMAP.md) by discussing requirements and design.
