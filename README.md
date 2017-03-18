# OpenEBS

[![Build Status](https://travis-ci.org/openebs/jiva.svg?branch=master)](https://travis-ci.org/openebs/jiva)
[![Docker Pulls](https://img.shields.io/docker/pulls/openebs/jiva.svg)](https://hub.docker.com/r/openebs/jiva/)
[![Slack](https://img.shields.io/badge/chat!!!-slack-ff1493.svg)]( https://openebsslacksignup.herokuapp.com/)

http://www.openebs.io/

OpenEBS is purpose built storage for containerized environments, written in GoLang, built upon block storage 
containers we call **Virtual Storage Machines** or `VSMs`. 

Some of the features provided by a single VSM are:

- is a set of fully isolated block storage containers,
- has it's own iSCSI stack, 
- full set of storage management APIs,
- can distribute application consistent data to another VSM or an S3 compatible storage.

## Performant Storage Delivered

OpenEBS can scale to an arbitrarily large number of VSMs as it manages the metadata of the block storage system at 
a file level. The block storage for each VSM is managed as one single file or directory. Further, the IO to this file
is managed through large size chunks rather than the typical small size blocks. This enables OpenEBS to 
deliver higher performance for each VSM and to  scale to a large number of VSMs. 

## Quick Demo of OpenEBS 

[![OpenEBS Demo](https://s7.postimg.org/adw357irf/openebs_demo_png.png)](https://www.youtube.com/watch?v=jeeWIFiC5LQ)

## Installation and Getting Started

OpenEBS can be setup in few easy steps either on Physical Machines or VMs. 
Please follow our [Getting Started](k8s/dedicated/README.md) documentation 

## Show me the Code

This is a meta-repository for OpenEBS. Here please find various documentation related artifacts and code related to integrating OpenEBS with popular orchestration engines like kubernetes, swarm, mesos, rancher, etc., The core storage and storage orchestration source code is distributed in other repositories under the OpenEBS organization. Please start with the pinned repositories or with [OpenEBS Architecture](./contribute/design/README.md) document. 

## Contributing

OpenEBS is completely Open Source and is makes use of other Open Source projects (listed below). 
The project is in the early stages of development and we welcome your feedback and contributions in any 
form possible.  If you have not already, **please make our day and star us above**.  

- Join us at [openebs-slack-signup](https://openebsslacksignup.herokuapp.com/)
  - Already signed up ? Head to our discussions at [openebs-users channel](https://openebs-community.slack.com/messages/openebs-users/)
- Want to raise an issue ?
  - If it is a generic (or `not really sure`), you can still raise it at [issues](https://github.com/openebs/openebs/issues)
  - Project specific issues can be raised at individual project level.
- Want to help with fixes and features:
  - Have a look at [open issues](https://github.com/issues?q=user%3Aopenebs+is%3Aopen)
  - Have a look at [contributing guide](./CONTRIBUTING.md)

## Credits

- A VSM is a bunch of containers
  - Currently `Docker` engine based container (https://github.com/docker/docker)
- Persistent Storage and Replication for OpenEBS VSMs from forked Rancher's `Longhorn` (https://github.com/openebs/longhorn)
- iSCSI Frontent for OpenEBS VSMs from forked gostor's `gotgt` (https://github.com/openebs/gotgt)
- VSMs are managed and scheduled via HashiCorp's `Nomad` (https://github.com/hashicorp/nomad)
- Configuration Information is stored in HashiCorp's `Consul` (https://github.com/hashicorp/consul)

## License

OpenEBS is developed under Apache 2.0 License at the project level. 
Some components of the project are derived from other opensource projects like Nomad, Longhorn 
and are distributed under their respective licenses. 
