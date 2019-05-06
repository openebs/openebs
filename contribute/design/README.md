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

| Component | Repo Link | License | Dependency and Notes
|---|---|---|---|
| Storage Management | https://github.com/openebs/maya | Apache 2.0  | Contains all the OpenEBS Storage Management components that help with managing multiple data engines. Dependencies are in: https://github.com/openebs/maya/blob/master/Gopkg.lock
| Storage Management - Dynamic Provisioners | https://github.com/openebs/external-storage | Apache 2.0  | Contains OpenEBS extensions for Kubernetes External Dynamic Provisioners. This will be replaced with CSI drivers under the above repo. 
| Data Engine - Jiva | https://github.com/openebs/jiva | Apache 2.0  | The first data engine supported by OpenEBS. Forked out from Rancher Longhorn engine. Dependencies are in: https://github.com/openebs/jiva/blob/master/vendor.conf
| Data Engine - cStor Replica | https://github.com/openebs/libcstor | Apache 2.0  | The second data engine supported by OpenEBS. cStor Data Engine makes use of (uZFS - userspace ZFS, aka cStor)[https://github.com/openebs/cstor].
| Data Engine - cStor Target | https://github.com/openebs/istgt | Apache 2.0  | Part of the cStor data engine that implements the iSCSI Target. 
| Storage Device Management | https://github.com/openebs/node-disk-manager | Apache 2.0  | Contains Kubernetes Device Inventory Management functionality. Dependencies are in https://github.com/openebs/node-disk-manager/blob/master/Gopkg.lock
| OpenEBS Documentation | https://github.com/openebs/openebs-docs | Apache 2.0  | Uses Docusaurus. Dependencies are in https://github.com/openebs/openebs-docs/blob/staging/website/package.json
| OpenEBS Examples | https://github.com/openebs/openebs | Apache 2.0  | Wrapper repo for examples and project management.|

# Further details

Additional details and how each of the Data engines operate are provided in this [Presentation](https://docs.google.com/presentation/d/1mjOkAQppyd23sw7PIryxu5kSrex352bT6bINzw6mUFY/edit?usp=sharing)
