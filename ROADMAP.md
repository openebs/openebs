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
| One installer | Unified Helm installer for all engines, deprecates operator yaml | All | v4.0 (Q1 2024) | Completed |
| One documentation | Unified and restructured documentation website, deprecates mayastor.gitbook.io | All | v4.0 (Q1 2024) | Completed |
| Legacy engines deprecation | Deprecated, archived and removed support for legacy engines and components eg. CStor, Jiva, NFS, NDM | All | v4.0 (Q1 2024) | Completed |
| Volume resize | Able to increase volume size and overlaying filesystem size with I/O continuity | Replicated PV Mayastor | v4.0 (Q1 2024) | Completed |
| Multi-replica volume snapshot and restore | Able to take consistent snapshots across all available replicas of a volume and restore to a given snapshot | Replicated PV Mayastor | v4.1 (Q3 2024) | Completed |
| Local PV CI | CI hardening and enhancements, helm chart support and more tests | Local PV (LVM, ZFS, Hostpath) | v4.2 (Q4 2024) | In progress |
| Local PV E2E | E2E hardening, umbrella chart testing, conversion of Ansible to Ginkgo-based BDDs | Local PV (LVM, ZFS, Hostpath) | v4.2 (Q4 2024) | In progress |
| Replica topology | Replica distribution based on pool and node topologies | Replicated PV Mayastor | v4.2 (Q4 2024) | In progress |
| NVMe-oF over RDMA support | Support for NVMe-oF over RDMA as transport | Replicated PV Mayastor | v4.2 (Q4 2024) | In progress |
| DiskPool resize | Able to increase pool capacity by expansion of underlying disk pool device(s) with I/O continuity | Replicated PV  Mayastor | v4.3 (Q1 2025) | In progress |
| At-rest encryption | Provision encrypted data-at-rest volumes | Replicated PV Mayastor | v4.3 (Q1 2025) | In progress |
| Snapshot rebuilding | Rebuilding snapshot data during replica rebuilds | Replicated PV Mayastor | 2025 | In progress |
| NVMe zoning support | Support for Western Digital ZNS devices | Replicated PV Mayastor | 2025 | In progress |
| DiskPool Aggregate media mgmt SPDK mode       | Able to create, expand & manage virtual SPDK disks that are aggregates of multiple physical media devices      | Pri 2 /  Rel: (TBD)    |
| DiskPool storage media mgmt xVM mode          | New DiskPool type (xVM Mediastore) - Backend media devices are managed under LVM & ZFS kernel layers           | Pri 2 /  Rel: (TBD)    |
| DiskPool Choosable Replication mode           | New DiskPool enables user to select Replicated/Non-Replicated persona for any volume type (SPDK, LVM, ZFS)     | Pri 2 /  Rel: (TBD)    |
| DiskPool Chosable Data Protection mode        | New DiskPool enables RAID Levels 0,1,4,5,6,10 & Z,Z2,Z3 via DiskPool modes LVM & ZFS integrations              | Pri 2 /  Rel: (TBD)    |
| DiskPool Erasure Coded Data Protection mode   | New DiskPool enables Distributed Erasure Coding Data Protection as an alternative to RAID architecture         | Pri 3 /  Rel: (TBD)    |
| Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK managed storage      | Pri 3 /  Rel: (TBD)   |
| Local-PV Hostpath integrated + enabled        | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Hostpath addressed storage  | Pri 2 /  Rel: (TBD)   |
| Local-PV RawFile Soft Luns enabled            | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Soft Filesystem lun addressed storage    | Pri 3 /  Rel: (2025)  |
| Local-PV RawFile Multi-F/S support            | Multi filesystems support for Local-PV RawFile Soft luns : ext3, ext4, XFS, BTRFS, f2fs, SSDFS, ZNS                    | Pri 3 /  Rel: (2025)   |
| HyperLocal-PV Data-Engine                     | Dynamically provision a non-replicated PV of Local-PV type via SPDK blobstor LVol as storage + NVMe target device |  Pri 2 /  Rel: (2025)   |
| HyperLocal-PV : UBlock mode                   | Non-replicated PV of Local-PV type via UBlock kernel integration to SPDK blobstor LVol as storage                  |  Pri 2 /  Rel: (2025)   |
| HyperLocal-PV : PCIe mode                     | Non-replicated PV of Local-PV type via PCIe-based NVMe kernel integration to SPDK blobstor LVol as storage         |  Pri 2 /  Rel: (2025)*   |
| Health & Supportability metrics + Dashboard   | Deep health diagnostics view of all elements OpenEBS manages - enable Metric inclusion in Support Bundle uploads |  Pri 2 /  Rel: (TBD)  |
| E2E Storage UNMAP reclaim integration         | Support Discard: LINUX / UNMAP: SCSI / Deallocate: NVMe issued from filesystem down to SPDK Blobstor elements    | Pri 3 /  Rel: (TBD)    |
| Thin provisioning phase-2                     | Thin Provision awareness and integrations with DiskPool metrics, pre-emptive intelligence actions                   | Pri 3 /  Rel: (TBD)    |
| Replicated Hostpath                           | Replication over hostpath volumes                                                                                | Pri 2 /  Rel: (2025)  |
<BR>

These repositories are critically required for the **current** roadmap.<BR>
### Mayastor Source repositories
  - https://github.com/openebs/mayastor
  - https://github.com/openebs/mayastor-control-plane
  - https://github.com/openebs/mayastor-api
  - https://github.com/openebs/mayastor-extensions
  - https://github.com/openebs/mayastor-docs

### Dynamic Local PVs repos
  - https://github.com/openebs/dynamic-localpv-provisioner
  - https://github.com/openebs/zfs-localpv
  - https://github.com/openebs/lvm-localpv
  - https://github.com/openebs/rawfile-localpv

### Others
  - https://github.com/openebs/charts
  - https://github.com/openebs/openebsctl
  - https://github.com/openebs/monitoring
  - https://github.com/openebs/website

# Getting involved with Contributions

We are always looking for more contributions. If you see anything above that you would love to work on, we welcome you to become a contributor and maintainer of the areas that you love. You can get started by commenting on the related issue or by creating a new issue. Also you can reach out to us by:

- [Joining OpenEBS contributor community on Kubernetes Slack](https://kubernetes.slack.com)
	- Already signed up? Head to our discussions at [#openebs-dev](https://kubernetes.slack.com/messages/openebs-dev/)
- [Joining our Community meetings](https://github.com/openebs/openebs/tree/master/community)

