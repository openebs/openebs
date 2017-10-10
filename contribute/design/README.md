# Overview

OpenEBS is a open source storage platform delivering containerized block storage for containers. OpenEBS aims at making storage instrastructure programmable, easy-to-use, consumed by applications via self-service. OpenEBS takes storage software upgrade seriously.

The storage controller functionality is delivered as containers - openebs/jiva. An OpenEBS Volume comprises of one or more containers working as a clustered microservice, providing block storage to other containers. OpenEBS Volumes are fully isolated user space storage engines that present the block storage via iSCSI and persist the data onto the storage attached to Nodes (aka Docker Hosts). The storage attached to the docker hosts can either be directly attached disks or cloud volumes depending on where the Container Cluster is deployed. OpenEBS uses *Maya*, a storage orchestration engine that helps in managing local and remote storage, integrate into the container orchestrators like Kubernetes, Docker Swarm, Nomad etc., manages QoS policies for OpenEBS Volumes.

OpenEBS, being container native, seamlessely integrates easily into the container orchestartors via OpenEBS Maya and OpenEBS Volume containers. 

## OpenEBS Volume Containers (aka jiva)

*openebs/jiva* containers are the heart of the OpenEBS Volume's storage functionality. OpenEBS Volumes provide persistent storage for containers, with resliency against system failures via a distrubuted architecture, faster access to the storage, snapshot and backup capabilities. In addition, provides mechanism for monitoring the usage and enforcing QoS policies. 

OpenEBS Volume (or Jiva) Containes are scheduled onto the container hosts using Orchestration Engines. Jiva containers consume the disk storage from the local host or remote storage using volume plugins (like k8s persistent volumes). OpenEBS Volumes are described in yaml files, just like your application pods, are deployed through objects like Pods, Deployments, Services, StatefulSets etc., 

Further details on the OpenEBS Volume Container - jiva can be found under the following repo - [openeb/jiva](https://github.com/openebs/jiva)

## OpenEBS Storage Orchestration (aka maya)

Maya makes the storage infrastructure programmable via yaml files that the DevOps can define and commit, just like the container clusters or containerized applications. Maya builds on top of the container orchestration engine capabilities in terms of runtime, scheduling, monitoring etc., and extends the capabilities to orchestrate and simplify the management of storage. Maya will learn and provide storage metrics to the container schedulers for better placements of pods as well as storage migration between hosts within/across cluster(s).

Maya is a set of components that can be further divided as follows:
- Services : These encapsulate a specific functionality like maya-apiserver, maya-agent, maya-mulebot, etc., that are either installed as binary services or container services. These will be either be running as Cluster Services (like the maya-apiserver), or on every docker host or node (like maya-agent) or can be completely out-of-band like (storage-analytics in the cloud). You can learn more about these services under the following repo - [openebs/maya](https://github.com/openebs/maya).

- Plugins : Maya allows the OpenEBS storage to be run along side any orchestration engine like kubernetes, docker swarm, nomad etc., This is made possible by the maya orchestration engine plugins. For example, one of the ways in which Kubernetes can consume OpenEBS Storage is via the K8s Dynamic Provisioners - [openebs-provisioner](https://github.com/openebs/external-storage/tree/master/openebs). 

- Tools : CLI/UI tools that will help with installation or management of tasks. One of the first tools under heavy development is [mayactl](https://github.com/openebs/maya/tree/master/cmd/mayactl), that aims at simplying the management of OpenEBS Volumes. 


*Note: In future, OpenEBS can also be deployed as a storage service (non hyperconverged) like the traditional software defined storage, and can be connected via the storage plugins.*
