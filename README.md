# Welcome to OpenEBS
<BR>
We are an ultra-modern storage target platform, a Hyper-Converged storage software system and a modern Storage Data Fabric natively & tighty integrated into a Kubernetes platform.<BR>
<BR>
OpenEBS provides... <BR>
<BR>

- Stateful persistent storage voluems for Kubernetes
- is a 100% Cloud-Native storage solution
- Delivers a Kubernetes cluster-wide storage fabric that provides containers with access to storage across the entire Kubernetes cluster.
- Enterprise Grade data management capabilities such as **snapshots, clones and replicated volumes** <BR>
<BR>

OpenEBS is completely free and open source software. There are also commercial options available for organizations seeking enterprise support and management capabilities. These are provided by third-party vendors. For more information, see https://openebs.io <BR>
<BR>
In 2022, OpenEBS introduced the MayaStor storage Data-Engine which is based on the Ultra High-Performance SPDK NVMe Stack, UIO-Ring Technology & Linux NVMEe drivers. This delivers higher performance than was previously possible in any Kubernetes storage product.<BR>
<BR>
The OpeneBS project consists of multiple Data-Engines projects that are grouped into 2 EDITIONs.
- The older storage engines are refered to as **LEGACY Edition**
- The ultra modern Mayastor Data-Engine is classifed as **STANDARD Edition**, which also includes...
    - LVM LocalPV
    - ZFS LocalPV
    - Device LocalPV
    - RawFile LocalPV
    - LocalPV-HostPath
    - LocalPV-Device

<BR>
The project plans to migrate, sunset and archive all LEGACY Data-Engines by June 2024. <BR>
<BR>


All **LEGACY** Data-Engines will me tagged as DEPRECATED and will be moved to ARCHIVE status by June 2024. These Data-Engines are:
  - Jiva  - Users should migrate to MayaStor Data-Engine
  - cStor - Users should migrate to MayaStor Data-Engine
  - NFS Provisioner  - Deprecated. No RWX services or features will be supported
 
New Roadmap features are planned for **STANDARD** that provide a strong pathway for **LEGACY** users to migrate to **STANDARD**. <BR>
<BR>
We hope you find OpenEBS useful. We welcome all contributions to the project. If you’d like to get in touch, please email us hello@openebs.io 

# Current status

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
The project source code is spread across multiple repos: 
<BR>
<BR>
The Roamap is focused exclusively on the modern Data-Engine **Mayastor**. It does not define any net-new features or capabilities for any OpenEBS LEGACY projects or projects that are tagged & deifned as DEPRERCATED or ARCHIVED. Currently those proejcts are defined as the follows (see refernces above for the details on thje projects DEPRECATED and ARCHIVAL strategy)...
- Jiva
- cStor
- NFS-Provisioner
<BR>

**MayaStor Roadmap : 2024 Phase-2**
- Forward facing planned release date, Release version numbers and feature priotiries re subject to chage as the project Maintainers/Leadership/community continiously update and adjust the **Release Feature bundling Strategy** to react to K8s industry movements, trends and our community influence.

|  ID  | Feature name                   | Description and user stpory                                            | Release, links, tracking issue, GitHub repo                                                   |
| :--- | :----------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| 1    | Multi-replica volume snapshot and CSI cloning | Able to take consistent snapshots across all available replicas of a volume                                     | Pri 1 /  Rel: (Q1 2024)    |
| 2    | Volume resize                                 | Able to increase volume size and overlaying file-system size with I/O continuity                                | Pri 1 /  Rel: (Q1 2024)    |
| 3    | DiskPool resize                               | Able to increase pool capacity by expansion of underlying disk pool device(s) with I/O continuity               | Pri 1 /  Rel: (Q1 2024)    |
| 4    | DiskPool media aggregation mgmt               | Able to create, expand & mannage virtual disks that are aggregated from multiple physical disks                 | Pri 1 /  Rel: (Q2 2024)    |
| 6    | Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK blobstor for storage  | Pri 1 /  Rel: (Q1 2024)    |
| 6    | Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK blobstor for storage  | Pri 1 /  Rel: (Q1 2024)    |
| 6.1  | Local-PV Hostpath enabled                     | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Hostpath addressed storage  | Pri 2 /  Rel: (Q2 2024)    |
| 6.2  | Local-PV Device enabled                       | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Device addressed storage    | Pri 2 /  Rel: (Q2 2024)    |
| 6.3  | Local-PV RawFile Soft Luns enabled            | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Soft Fileystem lun addressed storage    | Pri 3 /  Rel: (Q3 2024)  |
| 6.4  | Local-PV RawFile Multi-Filesystem support     | Multi filesystems support for Local-PV RawFile Soft luns : ext3, ext4, XFS, BTRFS, f2fs, ZNS                    | Pri 3 /  Rel: (Q3 2024)   |
| 6.5  | NDM integrated + enabled                      | NDM supoort for all Local-PV dependant services                                                                 | Pri 2 /  Rel: (Q2 2024)   |
| 7    | HyperLocal-PV Data-Engine                     | Dynamically provision a non-replicated PV of Local-PV type via SPDK blobstor LVol as storage + NVMe target device |  Pri 2 /  Rel: (Q2 2024)   |
| 7.1  | HyperLocal-PV : UBlock mode                   | Non-replicated PV of Local-PV type via UBlock kernel intgartion to SPDK blobstor LVol as storage                  |  Pri 2 /  Rel: (Q2 2024)   |
| 7.2  | HyperLocal-PV : PCIe mode                     | Non-replicated PV of Local-PV type via PCIe-based NVMe kernel intgartion to SPDK blobstor LVol as storage         |  Pri 2.5 /  Rel: (Q2 2024)*   |
| 8    | GUI Mgmt Portal & Dashboard                   | Provision, manage, monitor Mayastor deployments with a RESTful GUI interface - @ parity with Shell & kubectl cmds | Pri 3 /  Rel: (Q3 2024)    |
| 8.1  | GUI Mgmt Portal & Dashboard : On-Prem         | Mgmt portal & Dashbord deployed privately on-prem for air-gaped architetcures                                     | Pri 3 /  Rel: (Q3 2024)    |
| 8.2  | GUI Mgmt Portal & Dashboard : In-Cloud SaaS   | Mgmt portal & Dashbord deployed as SaaS privately in-cloud for cloud enabled architetcures                        | Pri 3 /  Rel: (Q3 2024)    |
| 8.3  | GUI Mgmt Portal & Dashboard : Global view     | Mgmt portal aggregated Global world  view of all k8s clusters configred to contribute anonymized global stats     | Pri 3 /  Rel: (Q3 2024)    |
| 9    | Storgae Encryption                            | Provision Encrypted data-at-rest volume via SPDK LVol layer - multi File system suppoort (ext3, ext4, XFS, BRFS)  | Pri 3 /  Rel: (Q3 2024)    |
| 10   | Health & Supportability metrics + Dashboard   | Deep health diagnostics view of all elemets OpenEBS manages - enable Metric inclusion in Suppoort Bundle upoloads |  Pri 2.5 /  Rel: (Q2 2024*)   |
| 11   | E2E Storage UNMAP reclaim integation          | Support Discard: LINUX / UNMAP: SCSI / Deallocate: NVMe issued from file-system down to SPDK Blobstor elements    | Pri 3 /  Rel: (Q4 2024)    |
| 12   | Thin provisioning phase-2                     | Thin Provision awarness and integarions with DiskPool metrics, pre-emptive intelligence actions                   | Pri 3 /  Rel: (Q4 2024)    |
| 13   | Native Object Store                           | An S3-compliant fast object store   inteatted with SPDK LVstore/LVols Blobstor & HyperLoca-PVl vols               | Pri 3 /  Rel: (Q4 2024)    |
| 14   | Zoned-SSD support                             | Integrated Western Digital Team's Mayastor ZNS feature for very high performance vols                             | Pri 2.5 /  Rel: (Q2 2024)   |



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
