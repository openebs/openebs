# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**Read this in**
[🇩🇪](translations/README.de.md)	
[🇷🇺](translations/README.ru.md)	
[🇹🇷](translations/README.tr.md)	
[🇺🇦](translations/README.ua.md)	
[🇨🇳](translations/README.zh.md)	
[🇫🇷](translations/README.fr.md)
[🇧🇷](translations/README.pt-BR.md)
[🇪🇸](translations/README.es.md)
[🇵🇱](translations/README.pl.md)
**[other languages](translations/#readme).**

**OpenEBS** is the most widely deployed and easy to use open-source storage solution for Kubernetes.

**OpenEBS** is the leading open-source example of a category of cloud native storage solutions sometimes called [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** is listed as an open-source example in the [CNCF Storage White Paper](https://github.com/cncf/tag-storage/blob/master/CNCF%20Storage%20Whitepaper%20V2.pdf) under the hyperconverged storage solutions.

Some key aspects that make OpenEBS different compared to other traditional storage solutions:
- Built using the micro-services architecture like the applications it serves. OpenEBS is itself deployed as a set of containers on Kubernetes worker nodes. Uses Kubernetes itself to orchestrate and manage OpenEBS components.
- Built completely in userspace making it highly portable to run across any OS/platform.
- Completely intent-driven, inheriting the same principles that drive the ease of use with Kubernetes.
- OpenEBS supports a range of storage engines so that developers can deploy the storage technology appropriate to their application design objectives. Distributed applications like Cassandra can use the LocalPV engine for lowest latency writes. Monolithic applications like MySQL and PostgreSQL can use the ZFS engine (cStor) for resilience. Streaming applications like Kafka can use the NVMe engine [Mayastor](https://github.com/openebs/Mayastor) for best performance in edge environments. Across engine types, OpenEBS provides a consistent framework for high availability, snapshots, clones and manageability.

OpenEBS itself is deployed as just another container on your host and enables storage services that can be designated on a per pod, application, cluster or container level, including:
- Automate the management of storage attached to the Kubernetes worker nodes and allow the storage to be used for Dynamically provisioning OpenEBS Replicated or Local PVs.
- Data persistence across nodes, dramatically reducing time spent rebuilding Cassandra rings for example.
- Synchronous replication of volume data across availability zones improving availability and decreasing attach/detach times for example.
- A common layer so whether you are running on AKS, or your bare metal, or GKE, or AWS - your wiring and developer experience for storage services is as similar as possible.
- Backup and Restore of volume data to and from S3 and other targets.

An added advantage of being a completely Kubernetes native solution is that administrators and developers can interact and manage OpenEBS using all the wonderful tooling that is available for Kubernetes like kubectl, Helm, Prometheus, Grafana, Weave Scope, etc.

**Our vision** is simple: let storage and storage services for persistent workloads be fully integrated into the environment so that each team and workload benefits from the granularity of control and Kubernetes native behaviour.

## Roadmap
OpenEBS is 100% open source software. 
The project source code is spread across multiple repos: 
<BR>
<BR>
The Roamap is focused exclusively on the modern Data-Engn *Mayastor* and does not define any net-new features or capabilities for any OpenEBS LEGACY projects or projects that are tagged & deifned as DEPRICTAED or ARCHIVED. Whihc are currentl defined as the follows (see refernces above for the details on thje projects DEPRECIATED and ARCHIVAL strategy)...
- Jiva
- cStor
- NFS-Provisioner
<BR>
<BR>

**MayaStor Roadmap : 2024 Phase-2**
- Forward facing release version numbers are subject to chage as the project Maintainers/Leadership continiously update the **Release Feature bundling Strategy** to react to industry movements, trends and our community influence.   

|  ID  | Feature name                   | Description and user stpory                                            | Notes, links, tracking issue, GitHub repo                                                   |
| :--- | :----------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| 1    | Multi-replica volume snapshot and CSI cloning | Able to take consistent snapshots across all available replicas of a volume                         | Pri : 1         |
| 2    | Volume resize                                 | Able to increase volume size and overlaying file-system size with I/O continuity                    | Pri : 1         |
| 3    | DiskPool resize                               | Able to increase pool capacity by expansion of underlying disk pool device(s) with I/O continuity   | Pri : 1         |
| 4    | DiskPool media aggregation mgmt               | Able to create, expand & mannage virtual disks that are aggregated from multiple physical disks     | Pri : 1         |
| 6    | Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK blobstor for storage |  Pri : 1 |
| 6    | Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK blobstor for storage |  Pri : 1 |
| 6.1  | Local-PV Hostpath enabled                     | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Hostpath addressed storage  |  Pri : 1 |
| 6.2  | Local-PV Device enabled                       | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Device addressed storage    |  Pri : 2 |
| 6.3  | Local-PV RawFile Soft Luns enabled            | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Soft Fileystem lun addressed storage    |  Pri : 2 |
| 6.4  | Local-PV RawFile Multi-Filesystem support     | Multi filesystems support for Local-PV RawFile Soft luns : ext3, ext4, XFS, BTRFS, f2fs, ZNS    |  Pri : 2 |
| 6.5  | NDM integrated + enabled                      | NDM supoort for all Local-PV dependant services |  Pri : 2 |
| 7    | HyperLocal-PV Data-Engine                     | Dynamically provision a persistent volume of Local-PV (non-replicated) type using SPDK blobstor LVols as storage + NVMe target device |  Pri : 2 |
| 8    | GUI Mgmt Portal & Dashboard                   | Provision, manage and monitor OpenEBS / Mayastor deployments with a RESTful GUI interface - @ parity with Shell & kubectl cmds |  Pri : 2 |
| 8.1  | GUI Mgmt Portal & Dashboard : On-Prem         | Mgmt portal & Dashbord deployed privately on-prem for air-gaped architetcures |  Pri : 2 |
| 8.2  | GUI Mgmt Portal & Dashboard : In-Cloud SaaS   | Mgmt portal & Dashbord deployed as SaaS privately in-cloud for cloud enabled architetcures |  Pri : 2 |
| 8.3  | GUI Mgmt Portal & Dashboard : Global view     | Mgmt portal aggregated Global world stats view of all k8s clusters configred to contribute anonymized global stats |  Pri : 3 |
| 9    | Storgae Encryption                            | Provision Volume that Encrypts data-at-rest at the SPDK LVol block layer - with multi File system suppoort (ext3, ext4, XFS, BRFS) |  Pri : 3 |
| 10   | Health & Supportability metrics + Dashboard   | Comprehensive health diagnostics & view for the all elemets OpenEBS is managing & enable Metric inclusion in Suppoort Bundle upoloads |  Pri : 2 |


## Scalability

OpenEBS can scale to include an arbitrarily large number of containerized storage controllers. Kubernetes is used to provide fundamental pieces such as using etcd for inventory. OpenEBS scales to the extent your Kubernetes scales.

## Installation and Getting Started

OpenEBS can be set up in a few easy steps. You can get going on your choice of Kubernetes cluster by having open-iscsi installed on the Kubernetes nodes and running the openebs-operator using kubectl.

**Start the OpenEBS Services using operator**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Start the OpenEBS Services using helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

You could also follow our [QuickStart Guide](https://openebs.io/docs).

OpenEBS can be deployed on any Kubernetes cluster - either in the cloud, on-premise or developer laptop (minikube). Note that there are no changes to the underlying kernel that are required as OpenEBS operates in userspace.  Please follow our [OpenEBS Setup](https://openebs.io/docs/user-guides/quickstart) documentation.

## Status

OpenEBS is one of the most widely used and tested Kubernetes storage infrastructures in the industry. A CNCF Sandbox project since May 2019, OpenEBS is the first and only storage system to provide a consistent set of software-defined storage capabilities on multiple backends (local, nfs, zfs, nvme) across both on-premise and cloud systems, and was the first to open source its own Chaos Engineering Framework for Stateful Workloads, the [Litmus Project](https://litmuschaos.io), which the community relies on to automatically readiness assess the monthly cadence of OpenEBS versions. Enterprise customers have been using OpenEBS in production since 2018. 

The status of various storage engines that power the OpenEBS Persistent Volumes are provided below. The key difference between the statuses are summarized below:
- **alpha:** The API may change in incompatible ways in a later software release without notice, recommended for use only in short-lived testing clusters, due to increased risk of bugs and lack of long-term support.
- **beta**: Support for the overall features will not be dropped, though details may change. Support for upgrading or migrating between versions will be provided, either through automation or manual steps.
- **stable**: Features will appear in released software for many subsequent versions and support for upgrading between versions will be provided with software automation in the vast majority of scenarios.


| Storage Engine | Status | Details |
|---|---|---|
| Jiva | stable | Best suited for running Replicated Block Storage on nodes that make use of ephemeral storage on the Kubernetes worker nodes |
| cStor | stable | A preferred option for running on nodes that have Block Devices. Recommended option if Snapshot and Clones are required |
| Local Volumes | stable | Best suited for Distributed Application that need low latency storage - direct-attached storage from the Kubernetes nodes. |
| Mayastor | stable | Persistent storage solution for Kubernetes, with near-native NVMe performance and advanced data services. |

For more details, please refer to [OpenEBS Documentation](https://openebs.io/docs/).

## Contributing

OpenEBS welcomes your feedback and contributions in any form possible.

- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
  - Already signed up? Head to our discussions at [#openebs](https://kubernetes.slack.com/messages/openebs/)
- Want to raise an issue or help with fixes and features?
  - See [open issues](https://github.com/openebs/openebs/issues)
  - See [contributing guide](./CONTRIBUTING.md)
  - Want to join our contributor community meetings, [check this out](./community/README.md).
- Join our OpenEBS CNCF Mailing lists
  - For OpenEBS project updates, subscribe to [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
  - For interacting with other OpenEBS users, subscribe to [OpenEBS Users](https://lists.cncf.io/g/cncf-openebs-users)

## Show me the Code

This is a meta-repository for OpenEBS. Please start with the pinned repositories or with [OpenEBS Architecture](./contribute/design/README.md) document. 

## License

OpenEBS is developed under [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) license at the project level. Some components of the project are derived from other open source projects and are distributed under their respective licenses.

OpenEBS is part of the CNCF Projects.

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## Commercial Offerings

This is a list of third-party companies and individuals who provide products or services related to OpenEBS. OpenEBS is a CNCF project which does not endorse any company. The list is provided in alphabetical order.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [DataCore](https://www.datacore.com/support/openebs/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
