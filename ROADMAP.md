# Roadmap

This Roadmap defines OpenEBS features and capabilities that are in current development and may be included in upcoming releases.<BR>
<BR>
Community and contributor involvement is vital for successfully implementing all desired items for each release. We hope that the items listed below will inspire further engagement from the community to keep OpenEBS progressing and shipping exciting and valuable features.

OpenEBS is a cloud-native persistent storage solution-provider for Kubernetes stateful workloads. OpenEBS offers 4 Local PV engines (Local PV Hostpath, Local PV ZFS, Local PV LVM and Local PV Rawfile), and 1 Replicated PV engine (Mayastor). The following roadmap includes features and enhancements for all the above engines.
_NOTE_: Local PV Rawfile is currently experimental. OpenEBS maintainers are seeking help from community to define the roadmap and take the sub-project forward.

## Near-term and long-term roadmap (2024 onwards)
Below table contains a list of both near-term and long-term backlog items. Near-term features are prioritized and planned to be completed within the next major release where precedence is given to usability, stability, resilience, data integrity issues reported by the community. The long-term features require significant design and development efforts, and will be scoped in the future.

OpenEBS follows a release cadence with a new minor release every 3-4 months.

_Note_: This document should not be construed as a binding commitment to delivery. Rather, its primary purpose is to provide insight into the project's intended objectives and strategic direction. The planned release timelines, version numbers and feature priorities are subject to change as the project maintainers/leadership/community continuously update and adjust in response to Kubernetes industry movements, trends and our community influence.

Please refer the GitHub project [OpenEBS Roadmap Tracking](https://github.com/orgs/openebs/projects/78) for the execution status of the roadmap items. The project also provides the release mapping and timelines for the issues and enhancement requests raised by the community.

| Feature | Description | Local or Replicated | Release timeline | Status |
| :------ | :---------- | :------------------ | :--------------- | :----- |
| Unified installer | Unified Helm installer for all engines, deprecates operator yaml | All | v4.0 (Q1 2024) | Completed |
| Unified documentation | Unified and restructured documentation website, deprecates mayastor.gitbook.io | All | v4.0 (Q1 2024) | Completed |
| Legacy engines deprecation | Deprecated, archived and removed support for legacy engines and components eg. CStor, Jiva, NFS, NDM | All | v4.0 (Q1 2024) | Completed |
| Volume resize | Able to increase volume size and overlaying filesystem size with I/O continuity | Replicated PV Mayastor | v4.0 (Q1 2024) | Completed |
| Multi-replica volume snapshot and cloning | Able to take consistent snapshots across all available replicas of a volume and restore to a given snapshot | Replicated PV Mayastor | v4.1 (Q3 2024) | Completed |
| Local PV CI | CI hardening and enhancements, helm chart support and more tests | Local PV (LVM, ZFS, Hostpath) | v4.2 (Q1 2025) | Completed |
| Local PV E2E | E2E hardening, umbrella chart testing, conversion of Ansible to Ginkgo-based BDDs | Local PV (LVM, ZFS, Hostpath) | v4.2 (Q1 2025) | Completed |
| Replica topology | Replica distribution based on pool and node topologies | Replicated PV Mayastor | v4.2 (Q1 2025) | Completed |
| NVMe-oF over RDMA support | Support for NVMe-oF over RDMA as transport | Replicated PV Mayastor | v4.2 (Q1 2025) | Completed |
| Data protection | Able to backup and restore OpenEBS volume data to/from an S3 end-point | All | v4.2 (Q1 2025) | Completed |
| Unified kubectl plugin | Unified kubectl plugin to manage all OpenEBS components | All | v4.3 (Q2 2025) | In progress |
| Local PV LVM cloning | Able to do K8s restore of Local PV LVM snapshot | Local PV LVM | v4.3 (Q2 2025) | |
| DiskPool resize | Able to increase pool capacity by expansion of underlying disk pool device(s) with I/O continuity | Replicated PV Mayastor | v4.3 (Q2 2025) | In progress |
| At-rest encryption | Provision encrypted data-at-rest volumes | Replicated PV Mayastor | v4.3 (Q2 2025) | In progress |
| Observability enhancements/fixes | Logging, monitoring and alerting | All | v4.3 (Q2 2025) | In progress |
| Handle Pool media transfer | Support for handling scenarios where pool block device is disconnected from one node and reconnected to a different node | All | 2025 | |
| Snapshot rebuilding | Rebuilding snapshot data during replica rebuilds | Replicated PV Mayastor | 2025 | In progress |
| NVMe zoning support | Support for Western Digital ZNS devices | Replicated PV Mayastor | 2025 | In progress |
| DiskPool over multiple devices | Able to create and expand DiskPools that are aggregates of multiple block devices | Replicated PV Mayastor | 2025 | |
| DiskPool of ZFS/LVM type | DiskPool over LVM VG & ZFS ZPool | Replicated PV Mayastor | 2025 | In progress |
| Replicated Hostpath | Replication over hostpath volumes | Local PV Hostpath | 2025 | |
| Local PV RawFile graduation | Steps to graduate localpv-rawfile from beta to stable | Local PV Rawfile | 2025 | |
| Unified Local PV CSI driver | Single CSI driver for all Local PV engines | Local PV (LVM, ZFS, Hostpath) | TBD | |
| Unmap support | Support discard/unmap/trim operations for NVMe volumes | Replicated PV Mayastor | TBD | |

<BR>

# Getting involved with contributions

We are always looking for more contributions. If you see anything above that you would love to work on, we welcome you to become a contributor and maintainer of the areas that you love. You can get started by commenting on the related issue or by creating a new issue. Also you can reach out to us by:

- [Joining OpenEBS contributor community on Kubernetes Slack](https://kubernetes.slack.com)
	- Already signed up? Head to our discussions at [#openebs-dev](https://kubernetes.slack.com/messages/openebs-dev/)
- [Joining our Community meetings](https://github.com/openebs/openebs/tree/develop/community)

