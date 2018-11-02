# OpenEBS

[![Build Status](https://img.shields.io/travis/openebs/openebs/master.svg?style=flat-square)](https://travis-ci.org/openebs/jiva)
[![Docker Pulls](https://img.shields.io/docker/pulls/openebs/jiva.svg?style=flat-square)](https://hub.docker.com/r/openebs/jiva/)
[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack](https://img.shields.io/badge/chat!!!-slack-ff1493.svg?style=flat-square)]( https://openebsslacksignup.herokuapp.com/)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/openebs/openebs/blob/master/LICENSE)

https://www.openebs.io/
 
**OpenEBS** enables the use of containers for mission-critical, persistent workloads and for other stateful workloads such as logging or Prometheus for example. OpenEBS is containerized storage and related storage services.
 
**OpenEBS** allows you to treat your persistent workload containers, such as DBs on containers, just like other containers. OpenEBS itself is deployed as just another container on your host and enables storage services that can be designated on a per pod, application, cluster or container level, including:
- Data persistence across nodes, dramatically reducing time spent rebuilding Cassandra rings for example.
- Synchronization of data across availability zones and cloud providers improving availability and decreasing attach/detach times for example.
- A common layer so whether you are running on AKS, or your bare metal, or GKE, or AWS - your wiring and developer experience for storage services is as similar as possible.
- Integration with Kubernetes, so  developer and application intent flows into OpenEBS configurations automatically.
- Management of tiering to and from S3 and other targets.
  
**Our vision** is simple: let storage and storage services for persistent workloads be fully integrated into the environment so that each team and workload benefits from granularity of control and Kubernetes native behavior. 

## Scalability
 
OpenEBS can scale to include an arbitrarily large number of containerized storage controllers. Kubernetes is used to provide fundamental pieces such as using etcd for inventory. OpenEBS scales to the extent your Kubernetes scales.  

## Installation and Getting Started
 
OpenEBS can be set up in a few easy steps. You can get going on your choice of Kubernetes cluster by having open-iscsi installed on the Kubernetes nodes and running the openebs-operator using kubectl. 

**Start the OpenEBS Services using operator**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Apply OpenEBS StorageClasses**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-storageclasses.yaml
```

You could also follow our [QuickStart Guide](https://docs.openebs.io/docs/overview.html).

OpenEBS can be deployed on any Kubernetes cluster - either in cloud, on-premise or developer laptop (minikube). Note that there are no changes to the underlying kernel that are required as OpenEBS operates in userspace.  Please follow our [OpenEBS Setup](https://docs.openebs.io/docs/overview.html) documentation. Also, we have a Vagrant environment available that includes a sample Kubernetes deployment and synthetic load that you can use to simulate the performance of OpenEBS. You may also find interesting the related project called Litmus (https://www.openebs.io/litmus) which helps with chaos engineering for stateful workloads on Kubernetes.

## Status
We are approaching the beta stage with active development underway. See our [Project Tracker](https://github.com/openebs/openebs/wiki/Project-Tracker) for more details. Many users are running OpenEBS in production and early access commercial solutions were made available in September 2018 by our primary sponsor MayaData (https://www.mayadata.io).  
 
## Contributing
 
OpenEBS welcomes your feedback and contributions in any form possible.
 
- Join us at [Slack](https://openebsslacksignup.herokuapp.com/)
  - Already signed up? Head to our discussions at [#openebs-users](https://openebs-community.slack.com/messages/openebs-users/)
- Want to raise an issue?
  - If it is a generic (or `not really sure`), you can still raise it at [issues](https://github.com/openebs/openebs/issues)
  - Project (repository) specific issues also can be raised at [issues](https://github.com/openebs/openebs/issues) and tagged with the individual repository labels like *repo/maya*.
- Want to help with fixes and features?
  - See [open issues](https://github.com/openebs/openebs/labels)
  - See [contributing guide](./CONTRIBUTING.md)
  - Want to join our community, [check this out](./community/README.md). 

## Show me the Code

This is a meta-repository for OpenEBS. The source code is available at the following locations:
- The source code for the initial storage engine is under [openebs/jiva](https://github.com/openebs/jiva).
- The storage orchestration source code is under [openebs/maya](https://github.com/openebs/maya).
- While *jiva* and *maya* contain significant chunks of source code, some of the orchestration and automation code is also distributed in other repositories under the OpenEBS organization. 

Please start with the pinned repositories or with [OpenEBS Architecture](./contribute/design/README.md) document. 

## License

OpenEBS is developed under Apache 2.0 license at the project level. 
Some components of the project are derived from other open source projects and are distributed under their respective licenses. 
