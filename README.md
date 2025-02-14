## OpenEBS - Cloud Native Storage

[![CNCF Status](https://img.shields.io/badge/cncf%20status-sandbox-blue.svg)](https://www.cncf.io/projects/openebs/)
[![LICENSE](https://img.shields.io/github/license/openebs/openebs.svg)](./LICENSE)
[![FOSSA Status](https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs.svg?type=shield&issueType=license)](https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield&issueType=license)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/1754/badge)](https://www.bestpractices.dev/projects/1754)
[![CLOMonitor](https://img.shields.io/endpoint?url=https://clomonitor.io/api/projects/cncf/openebs/badge)](https://clomonitor.io/projects/cncf/openebs)
[![Slack](https://img.shields.io/badge/chat-slack-ff1493.svg?style=flat-square)](https://kubernetes.slack.com/messages/openebs)
[![Community Meetings](https://img.shields.io/badge/Community-Meetings-blue)](https://us05web.zoom.us/j/87535654586?pwd=CigbXigJPn38USc6Vuzt7qSVFoO79X.1)
[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/openebs)](https://artifacthub.io/packages/helm/openebs/openebs)
[![Release Charts](https://github.com/openebs/openebs/actions/workflows/chart-release.yml/badge.svg)](https://github.com/openebs/openebs/actions/workflows/chart-release.yml)

## Overview

OpenEBS is an open-source Container Native Storage solution that provides persistent storage for Kubernetes workloads. It enables dynamic provisioning of storage resources using containerized storage controllers, making it highly flexible and cloud-native. OpenEBS supports various storage engines, including LocalPVs for direct node storage and Replicated PV advanced data replication and resilience. It is designed to integrate seamlessly with Kubernetes, offering benefits like storage policies, resize, thin-provisioning, snapshots, and restore capabilities, making it an ideal choice for stateful applications.

OpenEBS offers two primary storage approaches for Kubernetes workloads: Local Storage and Replicated Storage. Below is a comparative overview:

| Feature                     | Local Storage                                                                 | Replicated Storage                                                                 |
|-----------------------------|-------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| **Data Availability**       | Limited to the node where the volume is provisioned; not suitable for high-availability requirements.| Synchronously replicates data across multiple nodes, ensuring high availability and durability. |
| **Use Cases**               | Ideal for applications managing their own replication and availability, such as distributed databases like MongoDB and Cassandra. | Suitable for stateful workloads requiring storage-level replication and high availability, like Percona/ Standalone DBs, and GitLab. |
| **Performance**             | Provides near-disk performance with minimal overhead. | Designed for high performance, leveraging NVMe-oF semantics for low-latency access. |
| **Limitations**             | Not highly available; node failure leads to data unavailability. | Requires sufficient resources (CPU, RAM, NVMe) for optimal performance. |
| **Snapshot and Cloning**    | Supported when backed by advanced filesystems like LVM or ZFS. | Supported, providing enterprise storage capabilities. |
| **Backup and Restore**      | Supported via Velero, using Restic for local volumes. | Supported via Velero, ensuring data protection and recovery.|

In summary, **Local Storage** is a good choice when your application can manage its own replication and high availability, and **Replicated Storage** when you require storage-level replication, enhanced data durability and network-based storage access.

Below are the sub-projects or the major storage solutions under the OpenEBS Umbrella. Visit the individual repositories to learn more about their usage and architecture.

| Sub-Project | [Local PV Hostpath](https://github.com/openebs/dynamic-localpv-provisioner) | [Local PV ZFS](https://github.com/openebs/zfs-localpv) | [Local PV LVM](https://github.com/openebs/lvm-localpv)  | [Local PV Rawfile (_**Experimental**_)](https://github.com/openebs/rawfile-localpv) | [Mayastor](https://github.com/openebs/mayastor) |
| :---:  | :---              | :---         | :---         | :---:            | :---:                  |
| Type   | Single-node       | Single-node  | Single-node  |  Single-node     | Multi-node             |
| What is it for?   | Replacement for in-Tree Kubernetes CSI Hostpath       | Storage engine for ZFS managed backend storage  | Storage engine for LVM2 managed backend storage  |  Experimental engine for using an extent file as block storage     | General purpose replicated enterprise storage           |
| Designed for | Developers or DevOps | ZFS users and production deployments | LVM2 users and production deployments | Developers | Enterprises and production deployments |
| Features | Everything in Kubernetes Hostpath, plus: - Dynamic provisioning, Zero configuration, No CSI driver | Provision ZFS datasets, Provision ZFS volumes, Dynamic provisioning, ZFS resilience, ZFS RAID protection, CSI driver | Provision LVM2 volumes, Dynamic provisioning, LVM2 RAID protection, CSI driver | Provision file system from local files as persistent volumes, CSI driver | Replicated storage NVMe / RDMA, Snapshots, Clones, High availability, CSI driver|
| Status | Stable, deployable in PROD  | Stable, deployable in PROD  | Stable, deployable in PROD  | Beta, undergoing evaluation & integration | Stable, deployable in PROD  |
| Current Version | [![Releases](https://img.shields.io/github/release/openebs/dynamic-localpv-provisioner/all.svg?style=flat-square)]() | ![Releases](https://img.shields.io/github/release/openebs/zfs-localpv/all.svg?style=flat-square) | [![Releases](https://img.shields.io/github/release/openebs/lvm-localpv/all.svg?style=flat-square)]() | [release v0.80](https://github.com/openebs/rawfile-localpv/releases/tag/0.8.0) | [![Releases](https://img.shields.io/github/release/openebs/Mayastor/all.svg?style=flat-square)]() |

### Why OpenEBS?

OpenEBS offers several compelling advantages for managing storage in Kubernetes environments:

- <b>Cloud-Native Architecture</b>: Designed as a cloud-native solution, OpenEBS integrates seamlessly with Kubernetes, most of the storage engines are CSI compliant.
- <b>Solutions for wide range of workloads</b>: Solutions for both workloads which need or may not need replication.
- <b>Avoidance of Cloud Lock-In</b>: By abstracting storage management, OpenEBS facilitates the movement of data across various Kubernetes environments, whether on-premises or in the cloud, thereby reducing dependency on a single cloud provider.
- <b>Cost Efficiency</b>: With features like thin provisioning OpenEBS enables dynamic allocation of storage resources, potentially reducing storage by preventing overprovisioning and allowing for on-the-fly storage expansion.
- <b>High Availability with Lower Blast Radius</b>: OpenEBS enhances application resilience by synchronously replicating data across multiple nodes, ensuring high availability. In the event of a node failure, only the data on that specific node is affected, minimizing the impact on the overall system.

These features make OpenEBS a robust and flexible solution for managing persistent storage in Kubernetes environments.

### Documents

- [Official Documentation](https://openebs.io/docs)
- [Governance Documentation](https://github.com/openebs/community/blob/develop/GOVERNANCE.md)
- [Contributing to OpenEBS](https://github.com/openebs/community/blob/develop/CONTRIBUTING.md)
- [OpenEBS Security Guidelines](https://github.com/openebs/community/blob/develop/SECURITY.md)
- [Release Process](./RELEASE.md)
- [Roadmap Tracker](https://github.com/orgs/openebs/projects/78)

### Community

- Homepage: [openebs.io](https://openebs.io/)
- Maintainers' email: openebs-team@googlegroups.com
- Slack:
  - [#openebs](https://kubernetes.slack.com/messages/openebs)
  - [#openebs-dev](https://kubernetes.slack.com/messages/openebs-dev)
- Twitter: [@openebs](https://twitter.com/intent/follow?screen_name=openebs)
- Community Meeting: OpenEBS holds a monthly [community meeting](https://us05web.zoom.us/j/87535654586?pwd=CigbXigJPn38USc6Vuzt7qSVFoO79X.1) via Zoom on the last Thursday of the month, at 14:00 UTC.
  - [Google Calendar](https://calendar.google.com/calendar/event?action=TEMPLATE&tmeid=ZDhqbDB0YjZtNmpvanJjN2Y2bWw3NnY0ajRfMjAyNTAyMjdUMTQwMDAwWiBvcGVuZWJzLnRlYW1AbQ&tmsrc=openebs.team%40gmail.com&scp=ALL)
  - [Other Calendars](https://openebs.github.io/community/community_meeting.ics)
- Community Meeting Recordings: [Youtube](https://www.youtube.com/@openebscommunity6021)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=openebs/openebs&type=Date)](https://star-history.com/#openebs/openebs&Date)

## Activity dashboard

![Alt](https://repobeats.axiom.co/api/embed/27af71ce20c687fd31105fff04146a50826e2852.svg "Repobeats analytics image")

## License Compliance

[![FOSSA Status](https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs.svg?type=large&issueType=license)](https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fopenebs?ref=badge_large&issueType=license)

## OpenEBS is a [CNCF Sandbox Project](https://www.cncf.io/projects/openebs)

![OpenEBS is a CNCF Sandbox Project](https://github.com/cncf/artwork/blob/main/other/cncf/horizontal/color/cncf-color.png)
