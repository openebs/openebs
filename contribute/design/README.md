# OpenEBS Design and Architecture

## Overview

OpenEBS is a open source storage platform delivering containerized block storage for containers. OpenEBS aims at making storage instrastructure programmable, easy-to-use, consumed by applications via self-service. OpenEBS takes storage software upgrade seriously.

The storage is containerized through concept called VSM or "Virtual Storage Machine". VSMs are fully isolated user space storage engines that present the block storage at the front end through iSCSI, NBD or TCMU protocol and consume raw storage from a local OpenEBS host or remote storage. OpenEBS uses maya, a storage orchestration engine that helps in managing local and remote storage, integrate into the container orchestrators like Kubernetes, Docker Swarm, Nomad etc., manages QoS policies for VSMs.

## Architecture

In the following diagram, we use Kubernetes as an example, but the concepts applies to other orchestration engines as well. 
![OpenEBS Deployment](../../documentation/source/_static/architecture-overview-hc.png)

OpenEBS, being container native, seamlessely integrates easily into the container orchestartors via OpenEBS VSM and OpenEBS Maya. 

### VSM ( aka storage containers or storage pods )

VSMs are the heart of the OpenEBS - enterprise storage functionality delivered in containers. VSMs provide persistent storage for containers, with resliency against system failures via a distrubuted architecture, faster access to the storage, snapshot and backup capabilities. In addition, provides mechanism for monitoring the usage and enforcing QoS policies. 

VSMs are scheduled onto the container hosts using Orchestration Engines. VSMs consume the disk storage from the local host or  remote storage using volume plugins (k8s flexvolumes). VSMs are described in yaml files, just like application pods. The VSMs can be deployed through K8s Pods, Deployments, Services, StatefulSets etc., 

Further details on the VSM can be found under the following two repositories - [openebs/longhorn](https://github.com/openebs/longhorn), the golang block storage functionality and [openeb/jiva](https://github.com/openebs/jiva) contains the packaging and ci functionality. 

### Maya ( aka storage orchestrator )

Maya makes the storage infrastructure programmable via yaml files that the DevOps can define and commit, just like the container clusters or containerized applications. Maya builds on top of the container orchestration engine capabilities in terms of runtime, scheduling, monitoring etc., and extends the capabilities to orchestrate and simplify the management of storage. Maya will learn and provide storage metrics to the container schedulers for better placements of pods as well as storage migration between hosts within/across cluster(s).

Maya is a set of components that can be further divided as follows:
- Services : These encapsulate a specific functionality like api-server, storage-manager, storage-analytics, sml-engine (storage machine learning engine), that are either installed as binary services are container services. These will be either be running on the Container Control Plane (like the [api-server](https://github.com/openebs/mayaserver)), or on Container-Runtime/Minion hosts ( like storage-manager ) or can be completely out-of-band (storage-analytics). Each of these services are developed under their own repository under the OpenEBS organization. 

- Plugins : Maya allows the OpenEBS storage to be run along side any orchestration engine like kubernetes, docker swarm, nomad etc., This is made possible by the maya orchestration engine plugins. For example, one of the ways in which Kubernetes can consume OpenEBS Storage is via the K8s FlexVolume Plugin - [openebs-iscsi](https://github.com/openebs/openebs/tree/master/k8s/lib/plugin/flexvolume). The plugin's are also used extensively in the hyperconverged mode to integrated into the various orchestration capabilities. The plugin libraries are developed under the main openebs/openebs repository, under the respective container orchestrator directory. 

- Tools : CLI/UI tools that will help with installation or management of tasks. One of the first tools under heavy development is [maya] (https://github.com/openebs/maya), that aims the simplying the installation of OpenEBS components or plugins. 


*Note: OpenEBS can also be deployed in the dedicated environment like the traditional software defined storage, and can be connected via the storage plugins.*
