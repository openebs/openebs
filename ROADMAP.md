# Roadmap

This Roadmap defines OpenEBS features and capabilities that are in current development and may be included in upcoming releases.<BR>
<BR>
Community and contributor involvement is vital for successfully implementing all desired items for each release. We hope that the items listed below will inspire further engagement from the community to keep OpenEBS progressing and shipping exciting and valuable features.

OpenEBS follows a lean project management approach by splitting the development items into current, near term and future categories.

## Near-term and long-term roadmap (2024 onwards)
This table contains a list of both near-term and long-term backlog items. Near-term features are currently getting the most active focus and attention within the project. These are prioritized and planned to be completed within the next major release where higher priority is given to usability, stability, resilience, data integrity issues reported by the community. The long-term features require significant design and development efforts, and will be scoped in the future.

OpenEBS follows a release cadence with a new minor release every 3-4 months.

_Note_: The planned release timelines, version numbers and feature priorities are subject to change as the project maintainers/leadership/community continuously update and adjust in response to K8s industry movements, trends and our community influence.

_Note 2_: The table contains the high-level backlog items. For a comprehensive list of features and issues, please refer to https://github.com/openebs/openebs/releases.

| Feature | Description | Local or Replicated | Release timeline | Status |
| :------ | :---------- | :------------------ | :--------------- | :----- |
| Unified installer | Unified Helm installer for all engines, deprecates operator yaml | All | v4.0 (Q1 2024) | Completed |
| Unified documentation | Unified and restructured documentation website, deprecates mayastor.gitbook.io | All | v4.0 (Q1 2024) | Completed |
| Legacy engines deprecation | Deprecated, archived and removed support for legacy engines and components eg. CStor, Jiva, NFS, NDM | All | v4.0 (Q1 2024) | Completed |
| Volume resize | Able to increase volume size and overlaying filesystem size with I/O continuity | Replicated PV Mayastor | v4.0 (Q1 2024) | Completed |
| Multi-replica volume snapshot and cloning | Able to take consistent snapshots across all available replicas of a volume and restore to a given snapshot | Replicated PV Mayastor | v4.1 (Q3 2024) | Completed |
| Local PV CI | CI hardening and enhancements, helm chart support and more tests | Local PV (LVM, ZFS, Hostpath) | v4.2 (Q4 2024) | In progress |
| Local PV E2E | E2E hardening, umbrella chart testing, conversion of Ansible to Ginkgo-based BDDs | Local PV (LVM, ZFS, Hostpath) | v4.2 (Q4 2024) | In progress |
| Replica topology | Replica distribution based on pool and node topologies | Replicated PV Mayastor | v4.2 (Q4 2024) | In progress |
| NVMe-oF over RDMA support | Support for NVMe-oF over RDMA as transport | Replicated PV Mayastor | v4.2 (Q4 2024) | In progress |
| Unified kubectl plugin | Unified kubectl plugin to manage all OpenEBS components | All | v4.2 (Q4 2024) | In progress |
| Local PV LVM cloning | Able to do K8s restore of Local PV LVM snapshot | Local PV LVM | v4.3 (Q1 2025) | |
| DiskPool resize | Able to increase pool capacity by expansion of underlying disk pool device(s) with I/O continuity | Replicated PV  Mayastor | v4.3 (Q1 2025) | In progress |
| At-rest encryption | Provision encrypted data-at-rest volumes | Replicated PV Mayastor | v4.3 (Q1 2025) | In progress |
| Data protection | Able to backup and restore OpenEBS volume data to/from an S3 end-point | All | v4.3 (Q1 2025) | In progress |
| Observability enhancements/fixes | Logging, monitoring and alerting | All | v4.3 (Q1 2025) | In progress |
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

