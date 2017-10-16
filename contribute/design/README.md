# Overview

OpenEBS is a open source storage platform delivering containerized block storage for containers. 

Yes! The storage controller functionality is itself, delivered as containers. An OpenEBS Volume comprises of one or more containers working as a clustered microservice, providing block storage to other containers. This micro-services based architecture for storage controller functionality - where each Volume data is being served by its own set of containers, as opposed to a single monolothic storage controller software serving multiples volumes is what differentiates OpenEBS from traditional storage appliances.

OpenEBS Storage Controller functionality comprises of serveral micro-services (or containers) that can be classified into two broad categories: OpenEBS Data Plane - that serves the data to the applications and OpenEBS Control Plane - that manages the OpenEBS Volume Containers. If you notice this classification, closely resembling that of a typical Container Orchestrator, it is because OpenEBS Volumes are delivered through containers and these containers are better managed by Container Orchestrators! So OpenEBS Control Plane services work in conjunction with the CO - schedulers, apiserver, etc., 
 
## OpenEBS Volume Container (aka jiva, aka data plane)

*openebs/jiva* containers are at the heart of the OpenEBS Volume's storage functionality. OpenEBS Volumes are fully isolated user space storage engines that present the block storage via iSCSI and persist the data onto the storage attached to Nodes (aka Docker Hosts). The storage attached to the docker hosts can either be directly attached disks or cloud volumes (like EBS, GPD, etc.,) depending on where the Container Cluster is deployed. 

![OpenEBS Data Plane](../../documentation/source/_static/OpenEBS-Data-Plane.png)

OpenEBS Volumes provide persistent storage for containers, with resliency against system failures, faster access to the storage, snapshot and backup capabilities. In addition, provides mechanism for monitoring the usage and enforcing QoS policies. 

The Disks where the data is peristed are called as *Storage Backends*, which can be either host directories, attached block devices or remote disks. Each OpenEBS Volume comprises of an iSCSI Target Container (represented as openebs-vol1 in the above diagram) and one or more Replica Containers (openebs-vol1-R1 and openebs-vol1-R2).

The application pods will access the storage via the iSCSI Target Container, whicn will replicate the data to all its replica's. In the event of the node failure, the iSCSI Target Container is started on one of the remaining online nodes, and will serve the data by connecting to the available Replica container(s).

### Source Code

- [openebs/jiva](https://github.com/openebs/jiva) Storage Controller functionality which includes the replication logic 
- [openebs/gotgt](https://github.com/openebs/gotgt) iSCSI Target functionality, which is used by *openebs/jiva*.



## OpenEBS Control Plane (aka OpenEBS Storage Orchestration, aka maya)

OpenEBS Control Plane - auguments the functionality provided by the Container Orchestrator, with storage specific orchestration capabilities, via a set of services. OpenEBS control plane can hook into any of the container orchestrators like Kubernetes, Docker Swarm, Nomad, etc., making it possible to run OpenEBS hyper-coverged with Container Orchestrators. 

![OpenEBS Control Plane](../../documentation/source/_static/OpenEBS-Control-Plane.png)

OpenEBS Control Plane is also delivered as micro-services that can be further divided as follows:
- Services : Each service will encapsulate a specific functionality like maya-apiserver, maya-agent, maya-mulebot, etc., that are either installed as binary services or container services. These will be either be running as Cluster Services (like the maya-apiserver), or on every docker host or node (like maya-agent) or can be completely out-of-band like (storage-analytics in the cloud, represented as *maya cloud*). You can learn more about these services under the following repo - [openebs/maya](https://github.com/openebs/maya).

- Plugins : Maya allows the OpenEBS storage to be run along side any orchestration engine like kubernetes, docker swarm, nomad etc., This is made possible by the maya orchestration engine plugins. For example, one of the ways in which Kubernetes can consume OpenEBS Storage is via the K8s Dynamic Provisioners - [openebs-provisioner](https://github.com/openebs/external-storage/tree/master/openebs). 

- Tools : CLI/UI tools that will help with installation or management of tasks. One of the first tools under heavy development is [mayactl](https://github.com/openebs/maya/tree/master/cmd/mayactl), that aims at simplying the management of OpenEBS Volumes. 

In the current release, OpenEBS Control supports integration with Kubenetes. OpenEBS control plane represents the volume containes as Deployments and Services similar to other Applications deployed on Kubernetes. Since these Volumes can be expressed, as YAML files, OpenEBS allows to make storage infrastructure programmable. 

Maya builds on top of the container orchestration engine capabilities in terms of runtime, scheduling, monitoring etc., and extends the capabilities to orchestrate and simplify the management of storage. Maya will learn and provide storage metrics to the container schedulers for better placements of pods as well as storage migration between hosts within/across cluster(s).


*Note: In future, OpenEBS can also be deployed as a storage service (non hyperconverged) like the traditional software defined storage, and can be connected via the storage plugins.*
