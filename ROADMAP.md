# Roadmap

This Roadmap defines OpenEBS features and capabilities that are in current development and may be included in upcoming releases.<BR>
<BR>
Community and contributor involvement is vital for successfully implementing all desired items for each release. We hope that the items listed below will inspire further engagement from the community to keep OpenEBS progressing and shipping exciting and valuable features.

OpenEBS follows a lean project management approach by splitting the development items into current, near term and future categories.


## Active Master roadmap
This table holds a list of the most active roadmap items. These are the features that are currently getting the most active focus and attention within the project.

## Current
These are backlog items that are prioritized and planned to be completed within the next major release. While many are planned items, higher priority is given to usability, stability, resilience, data integrity issues reported by the community.

_Note_: OpenEBS follows a release cadence with a new minor release every 2-3 months.

- Forward facing planned release date, Release version numbers and feature priorities are subject to change as the project Maintainers/Leadership/community continuously update and adjust the **Release Feature bundling Strategy** to react to K8s industry movements, trends and our community influence.

|  ID  | Feature name                   | Description and user story                                            | Release, links, tracking issue, GitHub repo                                                   |
| :--- | :----------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| 1    | Multi-replica volume snapshot and CSI cloning | Able to take consistent snapshots across all available replicas of a volume                                    | Pri 1 /  Rel: (Q3 2024) / Completed in v4.1  |
| 2    | Volume resize                                 | Able to increase volume size and overlaying filesystem size with I/O continuity                                | Pri 1 /  Rel: (Q1 2024) / Completed in v4.0   |
| 3    | DiskPool resize                               | Able to increase pool capacity by expansion of underlying disk pool device(s) with I/O continuity              | Pri 1 /  Rel: (Q4 2024) / In progress for v4.2   |
| 4    | DiskPool Aggregate media mgmt SPDK mode       | Able to create, expand & manage virtual SPDK disks that are aggregates of multiple physical media devices      | Pri 2 /  Rel: (TBD)    |
| 4.1  | DiskPool storage media mgmt xVM mode          | New DiskPool type (xVM Mediastore) - Backend media devices are managed under LVM & ZFS kernel layers           | Pri 2 /  Rel: (TBD)    |
| 4.2  | DiskPool Choosable Replication mode           | New DiskPool enables user to select Replicated/Non-Replicated persona for any volume type (SPDK, LVM, ZFS)     | Pri 2 /  Rel: (TBD)    |
| 4.3  | DiskPool Chosable Data Protection mode        | New DiskPool enables RAID Levels 0,1,4,5,6,10 & Z,Z2,Z3 via DiskPool modes LVM & ZFS integrations              | Pri 2 /  Rel: (TBD)    |
| 5    | DiskPool Erasure Coded Data Protection mode   | New DiskPool enables Distributed Erasure Coding Data Protection as an alternative to RAID architecture         | Pri 3 /  Rel: (TBD)    |
| 6    | Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK managed storage      | Pri 3 /  Rel: (TBD)   |
| 6.1  | Local-PV Hostpath integrated + enabled        | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Hostpath addressed storage  | Pri 2 /  Rel: (TBD)   |
| 6.2  | Local-PV Device enabled                       | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Device addressed storage    | Pri 3 /  Rel: (Dropped, Archived)   |
| 6.3  | Local-PV RawFile Soft Luns enabled            | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Soft Filesystem lun addressed storage    | Pri 3 /  Rel: (2025)  |
| 6.4  | Local-PV RawFile Multi-F/S support            | Multi filesystems support for Local-PV RawFile Soft luns : ext3, ext4, XFS, BTRFS, f2fs, SSDFS, ZNS                    | Pri 3 /  Rel: (2025)   |
| 6.5  | NDM enabled                                   | NDM support for all Local-PV dependant services                                                                 | Pri 2 /  Rel: (Dropped, Archived)   |
| 7    | HyperLocal-PV Data-Engine                     | Dynamically provision a non-replicated PV of Local-PV type via SPDK blobstor LVol as storage + NVMe target device |  Pri 2 /  Rel: (2025)   |
| 7.1  | HyperLocal-PV : UBlock mode                   | Non-replicated PV of Local-PV type via UBlock kernel integration to SPDK blobstor LVol as storage                  |  Pri 2 /  Rel: (2025)   |
| 7.2  | HyperLocal-PV : PCIe mode                     | Non-replicated PV of Local-PV type via PCIe-based NVMe kernel integration to SPDK blobstor LVol as storage         |  Pri 2 /  Rel: (2025)*   |
| 8    | GUI Mgmt Portal & Dashboard                   | Provision, manage, monitor Mayastor deployments with a RESTful GUI interface - @ parity with Shell & kubectl cmds | Pri 3 /  Rel: (Out-of-scope)    |
| 8.1  | GUI Mgmt Portal & Dashboard : On-Prem         | Mgmt portal & Dashboard deployed privately on-prem for air-gapped architectures                                     | Pri 3 /  Rel: (Out-of-scope)    |
| 8.2  | GUI Mgmt Portal & Dashboard : In-Cloud SaaS   | Mgmt portal & Dashboard deployed as SaaS privately in-cloud for cloud enabled architectures                        | Pri 3 /  Rel: (Out-of-scope)    |
| 8.3  | GUI Mgmt Portal & Dashboard : Global view     | Mgmt portal aggregated Global world view of all k8s clusters configured to contribute anonymized global stats     | Pri 3 /  Rel: (Out-of-scope)    |
| 9    | Storage Encryption                            | Provision Encrypted data-at-rest volume via SPDK LVol layer                                                       | Pri 1 /  Rel: (Q4 2024) / In progress for v4.2   |
| 10   | Health & Supportability metrics + Dashboard   | Deep health diagnostics view of all elements OpenEBS manages - enable Metric inclusion in Support Bundle uploads |  Pri 2 /  Rel: (TBD)  |
| 11   | E2E Storage UNMAP reclaim integration         | Support Discard: LINUX / UNMAP: SCSI / Deallocate: NVMe issued from filesystem down to SPDK Blobstor elements    | Pri 3 /  Rel: (TBD)    |
| 12   | Thin provisioning phase-2                     | Thin Provision awareness and integrations with DiskPool metrics, pre-emptive intelligence actions                   | Pri 3 /  Rel: (TBD)    |
| 13   | Native Object Store                           | An S3-compliant fast object store   integrated with SPDK LVstore/LVols Blobstor & HyperLocal-PV vols               | Pri 3 /  Rel: (Out-of-scope)    |
| 14   | Replica topology                              | Replica distribution based on pool and node topologies                                                            | Pri 1 /  Rel: (Q3 2024) / In progress for v4.2  |
| 15   | Zoned-SSD support                             | Integrated Western Digital Team's Mayastor ZNS feature for very high performance vols                             | Pri 3 /  Rel: (Q4 2024) / In progress for v4.2  |
| 16   | NVMe-oF over RDMA support                     | Support for NVMe-oF over RDMA as transport for higher performance                                                | Pri 1 /  Rel: (Q4 2024) / In progress for v4.2  |
| 17   | Local PV CI and E2E hardening                 | Enhancing CI and E2E of Local PV engines with more tests                                                         | Pri 1 /  Rel: (Q4 2024) / In progress for v4.2  |
| 18   | Replicated Hostpath                           | Replication over hostpath volumes                                                                                | Pri 2 /  Rel: (2025)  |
| 19   | Snapshot rebuilding                           | Rebuilding snapshot data during replica rebuilds                                                                 | Pri 2 /  Rel: (2025) / In progress  |
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

## Previous roadmap items (mostly completed, need tidying-up)

Typically the items under this category fall under next major release.
- Support for pluggable storage backend for Mayastor (example: replace blobstore with lvm)
- Support for specifying multiple hostpaths to be used with Local PV hostpath
- Update user documentation with reference stacks of running various workloads using OpenEBS volumes
- Auto provisioning of block devices (on the external storage systems) that can be used with OpenEBS storage engines
- Automate the workflows around handling scenarios like complete cluster failures that currently require some manual steps
- Custom Kubernetes storage schedulers to address auto-rebalancing of the data placed on the nodes to help with scale up/down of Kubernetes nodes
- Support for restoring a volume (in-place) for supporting blue/green stateful deployments
- Partial rebuild for the Mayastor replicas (similar to zfs resilvering)
- Support Bulk BDC requests to claim multiple block devices that satisfy affinity or anti-affinity rules of applications. Example: two block devices from same node or two block devices from different nodes.
- Support for device configuration tasks like partitioning, mounting or unmounting devices by adding new services via NDM gRPC API layer.

## Future

As the name suggests this bucket contains items that are planned for future. Sometimes the items are related to adapting to the changes coming in the Kubernetes repo or other related projects. Github milestone called [future backlog](https://github.com/openebs/openebs/milestone/11) is used to track these requests.

# Getting involved with Contributions

We are always looking for more contributions. If you see anything above that you would love to work on, we welcome you to become a contributor and maintainer of the areas that you love. You can get started by commenting on the related issue or by creating a new issue. Also you can reach out to us by:

- [Joining OpenEBS contributor community on Kubernetes Slack](https://kubernetes.slack.com)
	- Already signed up? Head to our discussions at [#openebs-dev](https://kubernetes.slack.com/messages/openebs-dev/)
- [Joining our Community meetings](https://github.com/openebs/openebs/tree/master/community)

