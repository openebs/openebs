#OpenEBS Design and Architecture

##Overview

OpenEBS is a open source storage platform delivering containerized block storage for containers. OpenEBS aims at making storage instrastructure programmable, easy-to-use, consumed by applications via self-service. OpenEBS takes upgrades of storage software seriously. 

The storage is containerized through concept called VSM or "Virtual Storage Machine". VSMs are fully isolated user space storage engines that present the block storage at the front end through iSCSI, NBD or TCMU protocol and consume raw storage from a local OpenEBS host or remote storage. OpenEBS uses maya, a storage orchestration engine that helps in managing local and remote storage, integrate into the container orchestrators like Kubernetes, Docker Swarm, Nomad etc., manages QoS policies for VSMs.

##Architecture


##Detailed Design Documents

The following tables contains the details about the OpenEBS components - their design, design status, implementation status, code repositories, etc., 

| Document | Status | Implementation Repository |
|----------|--------|---------------------------|
| [Jiva/VSM](./jiva.md) | WIP | [jiva](https://github.com/openebs/jiva) |
| [Maya Server](./maya-server.md) | WIP | [mayaserver](https://github.com/openebs/mayaserver) |
| [Maya CLI](./maya.md) | WIP |[maya](https://github.com/openebs/maya) |
