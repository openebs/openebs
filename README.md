# OpenEBS

[![Build Status](https://travis-ci.org/openebs/jiva.svg?branch=master)](https://travis-ci.org/openebs/jiva)
[![Docker Pulls](https://img.shields.io/docker/pulls/openebs/jiva.svg)](https://hub.docker.com/r/openebs/jiva/)
[![Slack](https://img.shields.io/badge/chat !!!-slack-ff1493.svg)]( https://openebsslacksignup.herokuapp.com/)

http://www.openebs.io/

OpenEBS is a Software Defined Storage (SDS) platform, written in GoLang, that provides the block storage containers called `Virtual Storage Machines` or VSMs. A VSM is a fully isolated block storage container, has it's own iSCSI stack, full set of storage management APIs and can back up the application consistent data to another VSM or an S3 compatible storage.

OpenEBS can scale to millions of VSMs seamlessly as it manages the metadata of the block storage system at a file level. The block storage for each VSM is managed as one single file or directory. The IO to this file is managed through large size chunks rather than the typical small size blocks. This enables to OpenEBS to provide higher performance for each VSM and to easilyh scale to very large number of VSMs. 

## Quick demo of OpenEBS 

[![OpenEBS Demo](https://s7.postimg.org/adw357irf/openebs_demo_png.png)](https://www.youtube.com/watch?v=jeeWIFiC5LQ)

## Installation and Getting Started

OpenEBS can be setup in few easy steps either on Physical Machines or VMs. 
Please follow our [Getting Started](docs/getting-started.md) documentation 

## Source Code

This is a meta-repository for OpenEBS. The actual source code is located in other repositories 
under openebs organization. One may refer to the pinned repositories to begin with.

## Contributing

OpenEBS is completely Open Source and is built by making use of other Open Source projects (listed below). 
The project is in the early stages of the development and we welcome your feedback and contributions in any 
form possible.

- Join the discussions at [signup](https://openebsslacksignup.herokuapp.com/)
  - Already signed up ? Head to [openebs-users](https://openebs-community.slack.com/messages/openebs-users/)
- Want to raise an issue ?
  - If it is a generic (or `not really sure`), you can still raise it at [issues](https://github.com/openebs/openebs/issues)
  - Project specific issues can be raised at individual project level.
- Want to help with fixes and features:
  - Have a look at [open issues](https://github.com/issues?q=user%3Aopenebs+is%3Aopen)

## Credits

- VSMs are containers running on `Docker` (https://github.com/docker/docker)
- Persistent Storage and Replication for OpenEBS VSMs from forked Rancher's `Longhorn` (https://github.com/openebs/longhorn)
- iSCSI Frontent for OpenEBS VSMs from forked gostor's `gotgt` (https://github.com/openebs/gotgt)
- VSMs are managed and scheduled via HashiCorp's `Nomad` (https://github.com/hashicorp/nomad)
- Configuration Information is stored in HashiCorp's `Consul` (https://github.com/hashicorp/consul)

## License

OpenEBS is developed under Apache 2.0 License at the project level. 
Some components of the project are derived from other opensource projects like Nomad, Longhorn 
and are distributed under their respective licenses. 
