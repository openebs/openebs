# OpenEBS
[![Build Status](https://travis-ci.org/openebs/openebs.svg?branch=master)](https://travis-ci.org/openebs/openebs) [![Join the chat at https://gitter.im/openebs/Lobby](https://badges.gitter.im/openebs/Lobby.svg)](https://gitter.im/openebs/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Docker Pulls](https://img.shields.io/docker/pulls/openebs/jiva.svg?maxAge=604800)](https://hub.docker.com/r/openebs/jiva/)
=========

http://www.openebs.io/

OpenEBS is a Software Defined Storage (SDS) platform, written in GoLang, that provides the block storage containers called Virtual Storage Machines or VSMs. A VSM is a fully isolated block storage container, has it's own iSCSI stack, full set of storage management APIs and can back up the application consistent data to another VSM or an S3 compatible storage.

OpenEBS can scale to millions of VSMs seamlessly as it manages the metadata of the block storage system at a file level. The block storage for each VSM is managed as one single file or directory. The IO to this file is managed through large size chunks rather than the typical small size blocks. This enables to OpenEBS to provide higher performance for each VSM and to easilyh scale to very large number of VSMs. 


#Setting up your own OpenEBS Storage Cluster
It is very easy to install OpenEBS from binaries or source on your Ubuntu 16.04 VMs or Appliances and enable them to provide persistent distributed storage to your containers or VMs. All you require is access to Internet!
- [Install from Binaries](https://github.com/openebs/openebs/blob/master/docs/Installing-from-binaries.md)
- [Install from Sources](https://github.com/openebs/openebs/blob/master/docs/installing-from-source.md)


## Quick demo of OpenEBS 
[![OpenEBS Demo](https://s7.postimg.org/adw357irf/openebs_demo_png.png)](https://www.youtube.com/watch?v=jeeWIFiC5LQ)


#License
OpenEBS is developed under Apache 2.0 License at the project level. Some components of the project are derived from other opensource projects like Nomad, Longhorn and are distributed under their respective licenses. 

#Contributing
OpenEBS is completely Open Source and is built by making use of other Open Source projects (listed below). The project is in the early stages of the development and we welcome your feedback and contributions in any form possible.
- Join the Discussion at https://gitter.im/openebs/Lobby
- Raise an issue https://github.com/openebs/openebs/issues
- Discuss the enhancements/wip items - https://github.com/issues?q=user%3Aopenebs+label%3Aenhancement+is%3Aopen

#Credits
- Persistent Storage and Replication for OpenEBS VSMs provided implmented by forked Rancher Longhorn (https://github.com/openebs/longhorn)
- iSCSI Frontent for OpenEBS VSMs from forked gostor gotgt (https://github.com/openebs/gotgt)
- VSMs are managed and scheduled via HashiCorp Nomad (https://github.com/hashicorp/nomad)
- Configuration Information is stored in HashiCorp Consul (https://github.com/hashicorp/consul)
