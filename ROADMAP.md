# Roadmap

This Roadmap defines OpenEBS features and capabilities that are in current development and may be incldued in upcoming releases.<BR>
<BR>
Community and contributor involvement is vital for successfully implementing all desired items for each release. We hope that the items listed below will inspire further engagement from the community to keep OpenEBS progressing and shipping exciting and valuable features.

OpenEBS follows a lean project management approach by splitting the development items into current, near term and future categories.


## Active Master roadmap
This table holds a list of the most active roadmap items. These are the features that are currently getting the most active focus and attention within the project.

## Current
These are backlog items that are prioritized and planned to be completed within the next major release. While many are planned items, higher priority is given to usability, stability, resilence, Data integrity issues reported by the community.


_Note_: OpenEBS follows an agressive release cadence with a new minor release every 2 months. For the most current plan and status check out the [release project trackers](https://github.com/orgs/openebs/projects?type=classic). This document is reviewed and updated by the maintainers after each major release.


## Mayastor Roadmap : 2024 Phase-2
- Forward facing planned release date, Release version numbers and feature priorities are subject to change as the project Maintainers/Leadership/community continuously update and adjust the **Release Feature bundling Strategy** to react to K8s industry movements, trends and our community influence.

|  ID  | Feature name                   | Description and user stpory                                            | Release, links, tracking issue, GitHub repo                                                   |
| :--- | :----------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| 1    | Multi-replica volume snapshot and CSI cloning | Able to take consistent snapshots across all available replicas of a volume                                     | Pri 1 /  Rel: (Q1 2024)    |
| 2    | Volume resize                                 | Able to increase volume size and overlaying filesystem size with I/O continuity                                | Pri 1 /  Rel: (Q1 2024)    |
| 3    | DiskPool resize                               | Able to increase pool capacity by expansion of underlying disk pool device(s) with I/O continuity               | Pri 1 /  Rel: (Q1 2024)    |
| 4    | DiskPool media aggregation mgmt               | Able to create, expand & manage virtual disks that are aggregated from multiple physical disks                 | Pri 1 /  Rel: (Q2 2024)    |
| 6    | Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK blobstor for storage  | Pri 1 /  Rel: (Q1 2024)    |
| 6    | Local-PV Data-Engine integrated + enabled     | Dynamically provision a persistent volume of LocalPV (non-replicated) type using non-SPDK blobstor for storage  | Pri 1 /  Rel: (Q1 2024)    |
| 6.1  | Local-PV Hostpath enabled                     | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Hostpath addressed storage  | Pri 2 /  Rel: (Q2 2024)    |
| 6.2  | Local-PV Device enabled                       | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Device addressed storage    | Pri 2 /  Rel: (Q2 2024)    |
| 6.3  | Local-PV RawFile Soft Luns enabled            | Able to provision a persistent volume of Local-PV (non-replicated) using type : K8s Soft Filesystem lun addressed storage    | Pri 3 /  Rel: (Q3 2024)  |
| 6.4  | Local-PV RawFile Multi-Filesystem support     | Multi filesystems support for Local-PV RawFile Soft luns : ext3, ext4, XFS, BTRFS, f2fs, SSDFS, ZNS                    | Pri 3 /  Rel: (Q3 2024)   |
| 6.5  | NDM integrated + enabled                      | NDM support for all Local-PV dependant services                                                                 | Pri 2 /  Rel: (Q2 2024)   |
| 7    | HyperLocal-PV Data-Engine                     | Dynamically provision a non-replicated PV of Local-PV type via SPDK blobstor LVol as storage + NVMe target device |  Pri 2 /  Rel: (Q2 2024)   |
| 7.1  | HyperLocal-PV : UBlock mode                   | Non-replicated PV of Local-PV type via UBlock kernel integration to SPDK blobstor LVol as storage                  |  Pri 2 /  Rel: (Q2 2024)   |
| 7.2  | HyperLocal-PV : PCIe mode                     | Non-replicated PV of Local-PV type via PCIe-based NVMe kernel integration to SPDK blobstor LVol as storage         |  Pri 2.5 /  Rel: (Q2 2024)*   |
| 8    | GUI Mgmt Portal & Dashboard                   | Provision, manage, monitor Mayastor deployments with a RESTful GUI interface - @ parity with Shell & kubectl cmds | Pri 3 /  Rel: (Q3 2024)    |
| 8.1  | GUI Mgmt Portal & Dashboard : On-Prem         | Mgmt portal & Dashboard deployed privately on-prem for air-gapped architectures                                     | Pri 3 /  Rel: (Q3 2024)    |
| 8.2  | GUI Mgmt Portal & Dashboard : In-Cloud SaaS   | Mgmt portal & Dashbord deployed as SaaS privately in-cloud for cloud enabled architetcures                        | Pri 3 /  Rel: (Q3 2024)    |
| 8.3  | GUI Mgmt Portal & Dashboard : Global view     | Mgmt portal aggregated Global world view of all k8s clusters configured to contribute anonymized global stats     | Pri 3 /  Rel: (Q3 2024)    |
| 9    | Storgae Encryption                            | Provision Encrypted data-at-rest volume via SPDK LVol layer - multi File system suppoort (ext3, ext4, XFS, BRFS, SSDFS)  | Pri 3 /  Rel: (Q3 2024)    |
| 10   | Health & Supportability metrics + Dashboard   | Deep health diagnostics view of all elements OpenEBS manages - enable Metric inclusion in Support Bundle upoloads |  Pri 2.5 /  Rel: (Q2 2024*)   |
| 11   | E2E Storage UNMAP reclaim integration          | Support Discard: LINUX / UNMAP: SCSI / Deallocate: NVMe issued from filesystem down to SPDK Blobstor elements    | Pri 3 /  Rel: (Q4 2024)    |
| 12   | Thin provisioning phase-2                     | Thin Provision awareness and integrations with DiskPool metrics, pre-emptive intelligence actions                   | Pri 3 /  Rel: (Q4 2024)    |
| 13   | Native Object Store                           | An S3-compliant fast object store   integrated with SPDK LVstore/LVols Blobstor & HyperLocal-PV vols               | Pri 3 /  Rel: (Q4 2024)    |
| 14   | Zoned-SSD support                             | Integrated Western Digital Team's Mayastor ZNS feature for very high performance vols                             | Pri 2.5 /  Rel: (Q2 2024)   |
<BR>

## Excluded from the roadmap
The Roadmap is focused exclusively on the modern **Mayastor* Data-Engines in the **STANDARD** edition. 
<BR>
It does not define any net-new features or capabilities for any OpenEBS **LEGACY** projects or projects that are tagged & defined as DEPRECATED or ARCHIVED. (Currently those projects are as follows):<BR>
| ID  | Data-Engines      | Embedded tech stack  | Status                           |
|-----|-------------------|----------------------|--------------------------------------------|
|  1  |  Jiva             | iSCSI                | We plan to ARCHIVE & sunset LEGACY in 2024 |
|  2  |  cStor            | Open ZFS             | We plan to ARCHIVE & sunset LEGACY in 2024 |
|  2  |  NFS Provisioner  | NFS userspace server | We plan to ARCHIVE & sunset LEGACY in 2024 |
<BR>

## Mayastor Source repositories
These repos are critically requried for the **current** roadmap.<BR>
  - https://github.com/openebs/mayastor
  - https://github.com/openebs/mayastor-control-plane
  - https://github.com/openebs/mayastor-api
  - https://github.com/openebs/mayastor-extensions
  - https://github.com/openebs/mayastor-docs

### Dynamic Local PVs repos
- (These repos are integrating into Mayastor to be included as part of the Mayastor STANDARD edition - Q1 2024)
  - https://github.com/openebs/dynamic-localpv-provisioner
  - https://github.com/openebs/zfs-localpv
  - https://github.com/openebs/lvm-localpv
  - https://github.com/openebs/rawfile-localpv
  - https://github.com/openebs/device-localpv
  - https://github.com/openebs/node-disk-manager

- Backlogs
  - Shared VG for LVM Local PV.
  
## Backlogs in-progress (under active development
  - New set of items to be updated Feb 2024

## Backlogs (near-term)
  - Support for hot upgrade, business continuity with no downtime.
  - Support for volume groups, i.e. Mayastor replica placement should be topology aware for statefulsets zonal (or HA) distribution.

### Others
  - https://github.com/openebs/charts
  - https://github.com/openebs/openebsctl
  - https://github.com/openebs/monitoring
  - https://github.com/openebs/website
  - https://github.com/openebs/m-exporter
  - https://github.com/openebs/dynamic-nfs-provisioner
- Backlogs


## Repos to be DEPRECATED and ARCHIVED
### Jiva
- Source repositories
  - https://github.com/openebs/jiva
  - https://github.com/openebs/jiva-operator
- Backlogs
  - None
 
  
### cStor
- Source repositories
  - https://github.com/openebs/libcstor
  - https://github.com/openebs/node-disk-manager
  - https://github.com/openebs/istgt
  - https://github.com/openebs/cstor-csi
  - https://github.com/openebs/cstor-operators
  - https://github.com/openebs/velero-plugin
  - https://github.com/openebs/api
  - https://github.com/openebs/upgrade
- Backlogs
  - Upstream uZFS changes and start using them instead of a local fork


## Old items (needs tidy-up)

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

