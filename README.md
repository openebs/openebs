## OpenEBS - Cloud Native Storage
[![Release Charts](https://github.com/openebs/openebs/actions/workflows/chart-release.yml/badge.svg)](https://github.com/openebs/openebs/actions/workflows/chart-release.yml)
[![Slack](https://img.shields.io/badge/chat-slack-ff1493.svg?style=flat-square)](https://kubernetes.slack.com/messages/openebs)
[![Community Meetings](https://img.shields.io/badge/Community-Meetings-blue)](https://us05web.zoom.us/j/87535654586?pwd=CigbXigJPn38USc6Vuzt7qSVFoO79X.1)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/1754/badge)](https://www.bestpractices.dev/projects/1754)
[![FOSSA Status](https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs.svg?type=shield&issueType=license)](https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield&issueType=license)

## Project Purpose

OpenEBS is an open-source storage service for Kubernetes applications. OpenEBS manages the block storage and file systems based on the block storage for containers running in Kubernetes. Use OpenEBS for creating fast and resilient storage; with options for single-node, and replicated multi-node storage.<BR>

| [<img src="https://github.com/openebs/community/blob/develop/images/slack_icon_small.png" width="100">](https://kubernetes.slack.com/messages/openebs)  | **Try our Slack channel** <BR>If you have questions about using OpenEBS, please use the CNCF Kubernetes **OpenEBS slack channel**, it is open for [anyone to ask a question](https://kubernetes.slack.com/messages/openebs/) <BR> |
| :---         | :---      |

<BR>

## Monthly Community Meetings
OpenEBS holds a monthly community meeting via Zoom on the last Thursday of the month, at 14:00 UTC.
<br>
The next meeting is on: `Thursday 31 October, at 14:00 UTC`
<br>
Meeting Link: https://us05web.zoom.us/j/87535654586?pwd=CigbXigJPn38USc6Vuzt7qSVFoO79X.1
<br>
Starting in August 2024, the meetings will be recorded and posted on YouTube. [Check here](https://www.youtube.com/@openebscommunity6021)
<BR>

## Why OpenEBS?
OpenEBS provides enterprise-grade data management for Kubernetes clusters, with five storage engines (four single-node and one replicated) that meet a range of use cases for Kubernetes users. The five engines are summarized in the table below:
<BR>
> [!IMPORTANT]
> The OpenEBS platform, provides 2 types of K8s Storage Services. ```Replicated PV``` and ```Local PV```.
<BR>

| Engine | [Local PV HostPath](https://github.com/openebs/dynamic-localpv-provisioner) | [Local PV ZFS](https://github.com/openebs/zfs-localpv) | [Local PV LVM](https://github.com/openebs/lvm-localpv)  | [Local PV Rawfile](https://github.com/openebs/rawfile-localpv) | [Replicated PV Mayastor](https://github.com/openebs/mayastor) |
| :---:  | :---              | :---         | :---         | :---:            | :---:                  |
| Type   | Single-node       | Single-node  | Single-node  |  Single-node     | Multi-node             |
| What is it for?   | Replacement for in-Tree Kubernetes CSI HostPath       | Storage engine for ZFS managed backend storage  | Storage engine for LVM2 managed backend storage  |  Experimental engine for using an extent file as block storage     | General purpose replicated enterprise storage           |
| Designed for | Developers or DevOps | ZFS users and production deployments | LVM2 users and production deployments | Developers | Enterprises and production deployments |
| Features | Everything in Kubernetes HostPath, plus: - Dynamic provisioning, Zero configuration, No CSI driver | Provision ZFS datasets, Provision ZFS volumes, Dynamic provisioning, ZFS resilience, ZFS RAID protection, CSI driver | Provision LVM2 volumes, Dynamic provisioning, LVM2 RAID protection, CSI driver | Provision file system from local files as persistent volumes, CSI driver | Replicated storage NVMe / RDMA, Snapshots, Clones, High availability, CSI driver|
| Status | Stable, deployable in PROD  | Stable, deployable in PROD  | Stable, deployable in PROD  | Beta, undergoing evaluation & integration | Stable, deployable in PROD  |
| Current Version | [![Releases](https://img.shields.io/github/release/openebs/dynamic-localpv-provisioner/all.svg?style=flat-square)]() | ![Releases](https://img.shields.io/github/release/openebs/zfs-localpv/all.svg?style=flat-square) | [![Releases](https://img.shields.io/github/release/openebs/lvm-localpv/all.svg?style=flat-square)]() | ```release: v0.70``` | [![Releases](https://img.shields.io/github/release/openebs/Mayastor/all.svg?style=flat-square)]() |

<BR>

> [!IMPORTANT]
> **OpenEBS provides**... <BR>
> - Stateful persistent Dynamically provisioned storage volumes for Kubernetes
> - High-performance NVMe-oF & NVMe/RDMA storage transport optimized for All-Flash Solid State storage media
> - Block devices, LVM, ZFS, ext2/ext3/ext4, XFS, BTRFS...and more
> - 100% Cloud-Native K8s declarative storage platform
> - A cluster-wide vSAN block-mode fabric that provides containers/Pods with HA-resilient access to storage across the entire cluster.
> - Node local K8s PVs and n-way Replicated K8s PVs
> - Deployable On-premise & in-cloud: (AWS EC2/EKS, Google GCP/GKE, Azure VM/AKS, Oracle OCI, IBM/RedHat OpenShift, Civo Cloud, Hetzner Cloud... and more)
> - Enterprise Grade data management capabilities such as **snapshots, clones, replicated volumes, DiskGroups, Volume Groups, Aggregates, RAID** <BR>
<BR>

>
> :ballot_box_with_check: &nbsp; It uses the High performance [SPDK](https://spdk.io) storage stack - (SPDK is an open-source NVMe project initiated by INTEL) <BR>
> :ballot_box_with_check: &nbsp; The hyper-modern [IO_Uring](https://github.com/axboe/liburing) Linux Kernel Async polling-mode I/O Interface - (fastest kernel I/O mode possible) <BR>
> :ballot_box_with_check: &nbsp; Native abilities for RDMA and Zero-Copy I/O <BR>
> :ballot_box_with_check: &nbsp; NVMe-oF TCP Block storage Hyper-converged data fabric <BR>
> :ballot_box_with_check: &nbsp; Block layer volume replication <BR>
> :ballot_box_with_check: &nbsp; Logical volumes and Diskpool based data management <BR>
> :ballot_box_with_check: &nbsp; a Native high performance [Blobstore](https://spdk.io/doc/blob.html) <BR>
> :ballot_box_with_check: &nbsp; Native Block layer Thin provisioning <BR>
> :ballot_box_with_check: &nbsp; Native Block layer Snapshots and Clones <BR>

### Get in touch with our team.
|   |   |   |    |
| :--- | :--- | :--- | :--- |
| [Vishnu Attur](https://www.linkedin.com/in/vishnu-attur-5309a333/ "Senior Engineering, QA and Dev Manager")| :octocat: <kbd>**[@avishnu](https://github.com/avishnu "Vishnu Govind Attur")**</kbd> | ![](https://github.com/openebs/community/blob/develop/images/flags/de_je/in.png "I am based in Bengaluru, Karnataka, India (GMT+5:30) Timezone") | ```Maintainer``` |
| [Abhinandan Purkait](https://www.linkedin.com/in/abhinandan-purkait/ "Senior Engineer") | :sunglasses: <kbd>**[@Abhinandan-Purkait](https://github.com/Abhinandan-Purkait "Abhinandan Purkait")**</kbd> | ![](https://github.com/openebs/community/blob/develop/images/flags/de_je/in.png "I am based in Bengaluru, Karnataka, India (GMT+5:30) Timezone") | ```Maintainer``` |
| [Niladri Halder](https://www.linkedin.com/in/niladrih/ "Senior Engineer") | :rocket: <kbd>**[@niladrih](https://github.com/niladrih "Niladrih Halder")**</kbd> | ![](https://github.com/openebs/community/blob/develop/images/flags/de_je/in.png "I am based in Bengaluru, Karnataka, India (GMT+5:30) Timezone") | ```Maintainer``` |
| [Ed Robinson](https://www.linkedin.com/in/edrob/ "CNCF Head Liaison") | :dog: <kbd>**[@edrob999](https://github.com/edrob999 "Ed Robinson")**</kbd> | ![](https://github.com/openebs/community/blob/develop/images/flags/ni_tn/nz.png "I am based in San Francisco, USA (GMT-7) Timezone") &nbsp; ![](https://github.com/openebs/community/blob/develop/images/flags/to_zw/us.png "I am based in San Francisco, USA (GMT-7) Timezone") | <kbd>**CNCF Primary Liaison**</kbd><BR>```Special Maintainer``` |
| [Tiago Castro](https://www.linkedin.com/in/tiago-castro-3311453a/ "Chief Architect") | :zap: <kbd>**[@tiagolobocastro](https://github.com/tiagolobocastro "Tiago Castro")**</kbd> | ![](https://github.com/openebs/community/blob/develop/images/flags/ni_tn/pt.png "I am based in London, UK (GMT+1) Timezone") &nbsp; ![](https://github.com/openebs/community/blob/develop/images/flags/de_je/gb.png "I am based in London, UK (GMT+1) Timezone") | ```Maintainer``` |
| [David Brace](https://www.linkedin.com/in/dbrace/ "Head of Product Mgmt & Strategy") | :star: <kbd>**[@orville-wright](https://github.com/orville-wright "Dave Brace")**</kbd> | ![](https://github.com/openebs/community/blob/develop/images/flags/ni_tn/nz.png "I am based in San Francisco, USA (GMT-7) Timezone") &nbsp; ![](https://github.com/openebs/community/blob/develop/images/flags/de_je/hu.png "I am based in San Francisco, USA (GMT-7) Timezone") &nbsp; ![](https://github.com/openebs/community/blob/develop/images/flags/to_zw/us.png "I am based in San Francisco, USA (GMT-7) Timezone") | ```Maintainer``` |

---
## Activity dashboard
![Alt](https://repobeats.axiom.co/api/embed/1e565d4d1fdfeacd2cf810f10bcb6cde7368c9ea.svg "Repobeats analytics image")
---
## Current status
| <kbd>Release</kbd> | <kbd>Support</kbd> | <kbd>Twitter/X</kbd> | <kbd>Contrib</kbd> | <kbd>License status</kbd> | <kbd>CI Status</kbd> |
| :---: | :---: | :---: | :---: | :---: | :---: |
| [![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases) | [![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs) | [![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs) | [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md) | [![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield) | [![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754) |

---
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

## Deployment
- In-cloud: (AWS EC2/EKS, Google GCP/GKE, Azure VM/AKS, Oracle OCI, IBM/RedHat OpenShift, Civo Cloud, Hetzner Cloud... and more)
- On-Premise: Bare Metal, Virtualized Hypervisor infra using VMWare ESXi, KVM/QEMU (K8s KubeVirt), Proxmox
- Deployed as native K8s resources: ```Deployments```, ```Containers```, ```Services```, ```Stateful sets```, ```CRD's```, ```Sidecars```, ```Jobs``` and ```Binaries``` all on K8s worker nodes.
- Runs 100% in K8s userspace. So it's highly portable and runs across many OSs & platforms.

## Roadmap (as of June 2024)
- [OpenEBS Roadmap](https://github.com/openebs/openebs/blob/main/ROADMAP.md)
---

[![OpenEBS Welcome Banner](https://github.com/openebs/community/blob/develop/images/community_banner_retro_gamer_level-up-2024_transp.png)](https://www.openebs.io/)
## QUICKSTART : Installation <BR>
```NOTE: ``` Depending on which of the 5 storage engines you choose to deploy, pre-requisites must be met. [See detailed quickstart docs...](https://openebs.io/docs/)<BR>

<BR>

> 1. **Setup helm repository.**
```Erlang
# helm repo add openebs https://openebs.github.io/openebs
# helm repo update
```


> 2a. **Install the Full OpenEBS helm chart with default values.** <BR>
>    - This installs **ALL OpenEBS Storage Engines*** in the openebs namespace and chart name as <kbd>openebs</kbd>: <BR>
>    ```Local PV Hostpath```, ```Local PV LVM```, ```Local PV ZFS```, ```Replicated PV Mayastor```
```Erlang
# helm install openebs --namespace openebs openebs/openebs --create-namespace
```

> 2b. **To Install just the OpenEBS ```Local PV``` Storage Engines, use the following command**:
```Erlang
# helm install openebs --namespace openebs openebs/openebs --set engines.replicated.mayastor.enabled=false --create-namespace
```

> 3. **To view the chart**
```Erlang
# helm ls -n openebs

Output:
NAME     NAMESPACE   REVISION  UPDATED                                   STATUS     CHART           APP VERSION
openebs  openebs     1         2024-06-25 09:13:00.903321318 +0000 UTC   deployed   openebs-4.1.0   4.1.0
```

> 4. **Verify installation**
>    - List the pods in <openebs> namespace
>    - Verify StorageClasses
```Erlang
# kubectl get pods -n openebs

Example Ouput:
NAME                                              READY   STATUS    RESTARTS   AGE
openebs-agent-core-674f784df5-7szbm               2/2     Running   0          11m
openebs-agent-ha-node-nnkmv                       1/1     Running   0          11m
openebs-agent-ha-node-pvcrr                       1/1     Running   0          11m
openebs-agent-ha-node-rqkkk                       1/1     Running   0          11m
openebs-api-rest-79556897c8-b824j                 1/1     Running   0          11m
openebs-csi-controller-b5c47d49-5t5zd             6/6     Running   0          11m
openebs-csi-node-flq49                            2/2     Running   0          11m
openebs-csi-node-k8d7h                            2/2     Running   0          11m
openebs-csi-node-v7jfh                            2/2     Running   0          11m
openebs-etcd-0                                    1/1     Running   0          11m
openebs-etcd-1                                    1/1     Running   0          11m
openebs-etcd-2                                    1/1     Running   0          11m
...
```
```Erlang
# kubectl get sc

Example Output:
NAME                                              READY   STATUS    RESTARTS   AGE
openebs-localpv-provisioner-6ddf7c7978-jsstg      1/1     Running   0          3m9s
openebs-lvm-localpv-controller-7b6d6b4665-wfw64   5/5     Running   0          3m9s
openebs-lvm-localpv-node-62lnq                    2/2     Running   0          3m9s
openebs-lvm-localpv-node-lhndx                    2/2     Running   0          3m9s
openebs-lvm-localpv-node-tlcqv                    2/2     Running   0          3m9s
openebs-zfs-localpv-controller-f78f7467c-k7ldb    5/5     Running   0          3m9s
...
```
For more details, please refer to [OpenEBS Documentation](https://openebs.io/docs/).

[![CNCF logo](https://github.com/openebs/community/blob/develop/images/CNCF_member-silver-color.svg)](https://www.datacore.com/)
OpenEBS is a CNCF project and DataCore, Inc. is a CNCF Silver member. DataCore supports CNCF extensively and has funded OpenEBS participating in every KubeCon event since 2020. Our project team is managed under the CNCF Storage Landscape and we contribute to the CNCF CSI and TAG Storage project initiatives. We proudly support CNCF Cloud Native Community Groups initiatives.<BR>
> Project updates, subscribe to [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements) <BR>
> Interacting with other OpenEBS users, subscribe to [OpenEBS Users](https://lists.cncf.io/g/cncf-openebs-users)
<BR>

| [<img alt="Container Storage Interface group" src="https://github.com/openebs/community/blob/develop/images/CNCF_csi-horizontal-color_2024.png" width="320">](https://github.com/kubernetes/community/tree/master/sig-storage) | [<img alt="Storage Technical Advisory Group" src="https://github.com/openebs/community/blob/develop/images/CNCF_tag-storage-horizontal-color_2024.png" width="320">](https://github.com/cncf/tag-storage) | &emsp; &emsp; [<img alt="Cloud Native Community Groups" src="https://github.com/openebs/community/blob/develop/images/CNCF_cncg-icon-color_2024.png" width="200">](https://github.com/cncf/communitygroups)|
| :---         |     :---:      |          ---: |

## Commercial Offerings

Commercially supported deployments of OpenEBS are available via the companies below. (Some provide services, funding, technology, infra, and resources to the OpenEBS project).<BR>

- [DataCore Software, Inc.](https://www.datacore.com/support/openebs/)
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)

(OpenEBS OSS is a CNCF project. CNCF does not endorse any specific company).

## License Compliance
[![FOSSA Status](https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs.svg?type=large&issueType=license)](https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs?ref=badge_large&issueType=license)
