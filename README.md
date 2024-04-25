# Welcome to OpenEBS
<BR>
We are an ultra-modern Block Mode storage platform, a Hyper-Converged software Storage System and an Enterprise Grade virtual NVMe-oF SAN (vSAN) Fabric that is natively & very tightly integrated into Kubernetes.<BR>
<BR>

> [!IMPORTANT]
> **OpenEBS provides**... <BR>
> - Stateful persistent Dynamically provisioned storage volumes for Kubernetes
> - High Performance NVMe-oF storage access optimized for All-Flash Solid State storage media
> - is a 100% Cloud-Native storage platform
> - Delivers a Kubernetes cluster-wide vSAN fabric that provides containers/Pods with resilient access to storage across the entire cluster.
> - Enterprise Grade data management capabilities such as **snapshots, clones, replicated volumes, DiskGroups, Volume Groups, Aggregates, RAID** <BR>
<BR>


### Multiple Storage Engines
OpenEBS is a Kubernetes provides Persistent Stateful Storage Platform that has **5 core Data-Engines**<BR>
Each Storage engine provides different Capabilities, Flexibility, Resilience, Data Protections, and Performance features. <BR>

| ID  | Data-Eegines       | Where to create your issues                            |
| :---: | :---             | :---                                                   |
|     | ```Replicated PV```          | ```Replicated storage and data volumes```     |
|  1  | [Replicated PV Mayastor](https://github.com/openebs/mayastor)      | Distributed vSAN Fabric attached volumes that are replicated   | 
| &nbsp;                        |    |
|     | ```Local PV```          | ```Non-replicated node local storage and volumes```   |                                                            |
|  2. |  [Local PV HostPath](https://github.com/openebs/dynamic-localpv-provisioner)     | Dynamically provisioned Node-local volumes with **```Hostpath```** resident backend data |
|  3. |  [Local PV ZFS](https://github.com/openebs/zfs-localpv)      | Dynamically provisioned Node-local volumes with an integrated **```ZFS```** storage backend |
|  4. |  [Local PV LVM](https://github.com/openebs/lvm-localpv)      | Dynamically provisioned Node-local volumes with an integrated **```LVM```** storage backend |
|  5. |  [Local PV Raw-device-File](https://github.com/openebs/rawfile-localpv) | Dynamically provisioned Node-local volumes via **```soft-lun RAW Device files```** on ```Hostpath``` resident backend filesystem  |
<BR>
<BR>

> **OpenEBS is very popular** : Live OpenEBS systems actively report back product metrics every day, to our Global Anaytics metrics engine (unless disabled by the user).
> Here are our key project popularity metrics as of: 01 Feb 2024 <BR>
>
> :rocket: &nbsp; OpenEBS is the #1 deployed Storage Platform for Kubernetes <BR>
> :star: &nbsp; We are the [#1 GitHub Star ranked](https://github.com/openebs/website/blob/main/website/public/images/png/github_star-history-2024_Feb_1.png) K8s Data Storage platform <BR>
> :floppy_disk: &nbsp; We have +49 Million Volumes deployed globally <BR>
> :tv: &nbsp; We have +8 Million Global installations <BR>
> :zap: &nbsp; 1 Million OpenEBS K8s Containers are spawned per week <BR>
> :sunglasses: &nbsp; 1.1 Million global users <BR>

<BR>

We have a very large [active community](https://github.com/openebs/community), and many storage users [contribute to our product](https://github.com/openebs/community/blob/develop/CONTRIBUTING.md) with discussions, ideas, Issues, Feature requests and even code contribnutions.  

There are many ways to get in touch with our team.
- **EMAIL us**:  cncf-openebs-maintainers@lists.cncf.io <BR>
- **Contact the Maintainers** : The up to date Maintainers list [is here](/openebs/MAINTAINERS.md)
> Reach out via GitHuib to the OpenEBS core leadership team. <BR>
> :rocket: &nbsp; Ed Robinson | @edrob999 <BR>
> :star: &nbsp; David Brace | @orville-wright <BR>
> :zap: &nbsp; Vishnu Attur | @avishnu <BR>
> :sunglasses: &nbsp; Tiago Castro | @tiagolobocastro <BR>

| [<img src="https://github.com/openebs/community/blob/develop/images/slack_icon_small.png" width="100">](https://kubernetes.slack.com/messages/openebs)  | **Try our Slack channel** <BR>If you have questions about using OpenEBS, please use the CNCF Kubernetes **OpenEBS slack channel**, it is open for [anyone to ask a question](https://kubernetes.slack.com/messages/openebs/) <BR> |
| :---         | :---      |

<BR>

---

# Current status

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

## Activity dashbaord
![Alt](https://repobeats.axiom.co/api/embed/1e565d4d1fdfeacd2cf810f10bcb6cde7368c9ea.svg "Repobeats analytics image")

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
[🇰🇷](translations/README.ko.md)
**[other languages](translations/#readme).**

**OpenEBS** is the most widely deployed and easy to use open-source storage solution for Kubernetes.

**OpenEBS** is the leading open-source example of a category of cloud native storage solutions sometimes called [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** is listed as an open-source example in the [CNCF Storage White Paper](https://github.com/cncf/tag-storage/blob/master/CNCF%20Storage%20Whitepaper%20V2.pdf) under the hyperconverged storage solutions.

Some key aspects that make OpenEBS different compared to other traditional storage solutions:
- Built using the micro-services architecture like the applications it serves. OpenEBS is itself deployed as a set of containers on Kubernetes worker nodes. Uses Kubernetes itself to orchestrate and manage OpenEBS components.
- Built completely in userspace making it highly portable to run across any OS/platform.
- Completely intent-driven, inheriting the same principles that drive the ease of use with Kubernetes.
- OpenEBS supports a range of storage engines so that developers can deploy the storage technology appropriate to their application design objectives. Distributed applications like Cassandra can use the LocalPV engine for lowest latency writes. Monolithic applications like MySQL and PostgreSQL can use the ZFS engine (cStor) for resilience. Streaming applications like Kafka can use the NVMe engine [Mayastor](https://github.com/openebs/Mayastor) for best performance in edge environments. Across engine types, OpenEBS provides a consistent framework for high availability, snapshots, clones and manageability.

# Deployment
OpenEBS itself is deployed as just another container on your host and enables storage services that can be designated on a per pod, application, cluster or container level, including:
- Automate the management of storage attached to the Kubernetes worker nodes and allow the storage to be used for Dynamically provisioning OpenEBS Replicated or Local PVs.
- Data persistence across nodes, dramatically reducing time spent rebuilding Cassandra rings for example.
- Synchronous replication of volume data across availability zones improving availability and decreasing attach/detach times for example.
- A common layer so whether you are running on AKS, or your bare metal, or GKE, or AWS - your wiring and developer experience for storage services is as similar as possible.
- Backup and Restore of volume data to and from S3 and other targets.

An added advantage of being a completely Kubernetes native solution is that administrators and developers can interact and manage OpenEBS using all the wonderful tooling that is available for Kubernetes like kubectl, Helm, Prometheus, Grafana, Weave Scope, etc.

**Our vision** is simple: let storage and storage services for persistent workloads be fully integrated into the environment so that each team and workload benefits from the granularity of control and Kubernetes native behaviour.

## Roadmap (as of Jan 2024)
OpenEBS is 100% open source software. 
The project source code is spread across multiple repos and covers multiple projects: 
<BR>
<BR>
Our main Roadmap is focused exclusively on the modern (STANDARD Edition) Data-Engine **Mayastor**. It does not define any net-new features or capabilities for any LEGACY projects or projects that are tagged & defined as DEPRECATED or ARCHIVED. Currently those projects are defined as the follows (see references above for the details on the projects DEPRECATED and ARCHIVAL strategy)...
- Jiva
- cStor
- NFS-Provisioner
<BR>

**MayaStor Roadmap
[2024 Roadmap](https://github.com/openebs/openebs/blob/main/ROADMAP.md) 


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
[![CNCF logo](https://github.com/openebs/community/raw/develop/images/CNCF_member-silver-color.svg)](https://www.datacore.com/)
OpenEBS is a CNCF project and DataCore, Inc is a CNCF Silver member. DataCore support's CNCF extensively and has funded OpenEBS participating in every KubeCon event since 2020. Our project team is managed under the CNCF Storage Landscape and we contribute to the CNCF CSI and TAG Storage project initiatives. We proudly support CNCF Cloud Native Community Groups initatives.<BR>
<BR>
<img  alt="Container Storage Interface group" src="https://github.com/openebs/community/raw/develop/images/CNCF_csi-horizontal-color.png" width="300"> <img alt="Storage Technical Advisory Group" src="https://github.com/openebs/community/raw/develop/images/CNCF_tag-storage-horizontal-color.png" width="300">  <img alt="Cloud Native Community Groups" src="https://github.com/openebs/community/raw/develop/images/CNCF_cncg-icon-color.png" width="120">

 
<BR>
Thanks for dropping by.

## Commercial Offerings

This is a list of third-party companies and individuals who provide products or services related to OpenEBS. OpenEBS is a CNCF project which does not endorse any company. The list is provided in alphabetical order.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [DataCore](https://www.datacore.com/support/openebs/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
