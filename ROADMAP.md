# Roadmap

This document provides information on OpenEBS development in current and upcoming releases. Community and contributor involvement is vital for successfully implementing all desired items for each release. We hope that the items listed below will inspire further engagement from the community to keep OpenEBS progressing and shipping exciting and valuable features.

OpenEBS follows a lean project management approach by splitting the development items into current, near term and future categories.


## Current

These are some of the backlogs that are prioritized and planned to be completed within the next major release (e.g. OpenEBS 3.0). While the following are planned items, higher priority is given to usability and stability issues reported by the community. The completion of these items also depends on the availability of contributors.

Note: OpenEBS follows a monthly release cadence with a new minor release on the 15th of every month.  For the most current plan and status check out the [release project trackers](https://github.com/orgs/openebs/projects) or the component specific trackers listed below. This document is reviewed and updated by the maintainers after each release. 

  
### Dynamic Local PVs
- Source repositories
  - https://github.com/openebs/dynamic-localpv-provisioner
  - https://github.com/openebs/zfs-localpv
  - https://github.com/openebs/lvm-localpv
  - https://github.com/openebs/rawfile-localpv
  - https://github.com/openebs/device-localpv
  - https://github.com/openebs/node-disk-manager
- Backlogs
  - [Done] Support for incremental and full Backups for ZFS Local PV
  - [Done] Split the Local Provisioner for hostpath and device from openebs/maya into its own repository
  - [Done] Support for specifying node affinity on Local Volumes using custom labels
  - [Done] Support for Dynamic Provisioning of Local PV backed by LVM
  - [Done] Support for Dynamic Provisioning of Local PV backed by Device Partitions
  - [Done] Capacity based scheduling for ZFS,LVM and Device Local PV. 
  - [Done] Support for setting IOPS limits for the LVM Local PV
  - [In-progress] Set quota on the hostpath volumes created on XFS filesystem
  - [In-progress] Expose prometheus metrics 
  - [In-progress] Add additional integration and end-to-end tests

### Mayastor
- Source repositories
  - https://github.com/openebs/Mayastor
  - https://github.com/openebs/moac
  - https://github.com/openebs/mayastor-control-plane
- Backlogs
  - [Done] User applications can continue to access volumes when the nexus hosting them fails (e.g. Mayastor container crashes or is otherwise rescheduled, or its host node is lost or disconnected)
  - [Done] It should be possible for Moac (and all other significant control plane components) to be rescheduled within a cluster  
  - [In-progress] Refactoring for better control plane and stability fixes
  - [In-progress] Add additional integration and end-to-end tests 
  - Mayastor Replica placement should be topology aware
  - Mayastor should expose metrics which meet the needs of the SRE persona, to trend review throughput, latency, capacity utilisation and errors
  - Multi-arch builds for all Mayastor components
  - Support for VolumeSnapshot

### Jiva
- Source repositories
  - https://github.com/openebs/jiva
  - https://github.com/openebs/jiva-operator
- Backlogs
  - [Done] Enhance Jiva Operator functionality to reduce manual steps around launching new replicas when node is completely removed from the cluster
  - [Done] Add additional integration tests to Jiva CSI Driver to move towards beta
  - [Done] Consolidate the CSI driver and Jiva control plane into single repo
  - [In-progress] Automate the migration of volumes from out-of-tree provisioners to CSI Driver
  - [In-progress] Add additional integration and end-to-end tests 
  
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
  - [Done] Move the Backup/Restore related API to v1
  - [Done] Automate the migration of volumes from out-of-tree provisioner to CSI Driver 
  - [In-progress] Additional integration and e2e tests to help move cStor towards stable

### NDM 
- Source repositories
  - https://github.com/openebs/node-disk-manager
- Backlogs
  - [Done] Enhance the discovery probes to identify virtual storage (without WWN) moving across nodes
  - [Done] Add gRPC API to list and re-scan block device
  - [Done] Enhance the discovery probes to detect if the device already has device mapper, zfs and so forth
  - [Done] Scan for device media errors and report them as prometheus metrics via ndm-exporter
  - [Done] Label the block devices so that they can be reserved for use by different StorageClasses
  - [In-progress] Auto-detecting capacity and mountpoint changes and updating the block device CR 
  - [In-progress] Additional integration and e2e tests
  - Support for using a custom node label to claim devices (instead of default kubernetes.io/hostname)
  - Support Bulk BDC requests to claim multiple block devices that satisfy affinity or anti-affinity rules of applications. Example: two block devices from same node or two block devices from different nodes. 
  - Support for device configuration tasks like partitioning, mounting or unmounting devices by adding new services via NDM gRPC API layer.


### Others
- Source repositories
  - https://github.com/openebs/charts
  - https://github.com/openebs/openebsctl
  - https://github.com/openebs/monitoring
  - https://github.com/openebs/website
  - https://github.com/openebs/openebs-docs
  - https://github.com/openebs/maya
  - https://github.com/openebs/m-exporter
  - https://github.com/openebs/openebs-k8s-provisioner
  - https://github.com/openebs/dynamic-nfs-provisioner
- Backlogs
  - [Done] Move towards GitHub actions based builds from Travis for all the repositories.
  - [Done] Enable multi-arch builds.
  - [Done] Add OpenAPI validations for the OpenEBS CRDs 
  - [Done] Building additional Grafana Dashboards for OpenEBS Components, Block Devices, Pools and Volumes, that can be used to monitor SLOs
  - [Done] Dashboard/UI for monitoring and managing cStor pools and volumes
  - [Done] Split the provisioners and/or operators from the mono-repos [openebs/maya](https://github.com/openebs/maya) and [openebs/external-storage](https://github.com/openebs/external-storage) into individual repos
  - [Done] Simplify the setup of NFS based Read-Write-Many volumes using OpenEBS RWO block volumes
  - [Done] Add the existing functionality available in [mayactl](https://github.com/openebs/maya/tree/master/cmd/mayactl) for volume management to openebsctl
  - [In-progress] Provide component level helm charts, that can then be used as dependent charts by the openebs chat
  - [In-progress] Refactor the website and user documentation to be built as a single website using Hugo, similar to other CNCF projects 
  - [In-progress] Add support for Kyverno, as a replacement for PSP
  - [In-progress] Integrate the content sites like - website and documentation into a single repo. 


## Near Term

Typically the items under this category fall under next major release (after the current. e.g 4.0). At a high level, the focus is towards moving the beta engines towards stable by adding more automated e2e tests and updating the corresponding user and contributor documents. To name a few backlogs (not in any particular order) on the near-term radar, where we are looking for additional help: 


- Support for specifying multiple hostpaths to be used with Local PV hostpath
- Ability to migrate the Local PVs to other nodes in the cluster to handle node upgrades
- Update user documentation with reference stacks of running various workloads using OpenEBS volumes 
- Auto provisioning of block devices (on the external storage systems) that can be used with OpenEBS storage engines
- Enhancements to OpenEBS CLI (openebsctl) for better troubleshooting OpenEBS components and fixing the errors
- Setup E2e pipelines for ARM Clusters
- Conform with the new enhancements coming in the newer Kubernetes releases around Capacity based provisioning, CSI, and so forth
- Automate the workflows around handling scenarios like complete cluster failures that currently require some manual steps
- Custom Kubernetes storage schedulers to address auto-rebalancing of the data placed on the nodes to help with scale up/down of Kubernetes nodes
- User-friendly installation & configuration command-line tool (analogy to linkerd CLI for linkerd)
- Allow Mayastor Pools to incorporate more than one capacity contributing disk device
- Failed replicas should be garbage collected (return capacity to Mayastor Pool)
- Allow a new replica to be created within the same Mayastor Pool as the failed replica it replaces
- Auto-scaling up and down of cStor pools as the new nodes are added and removed
- Auto-upgrade of cStor Pools and Volumes when user upgrades control plane
- Asynchronous or DR replica for cStor and Mayastor volumes
- Support for restoring a volume (in-place) for supporting blue/green stateful deployments
- Upstream uZFS changes and start using them instead of a local fork 


## Future

As the name suggests this bucket contains items that are planned for future. Sometimes the items are related to adapting to the changes coming in the Kubernetes repo or other related projects. Github milestone called [future backlog](https://github.com/openebs/openebs/milestone/11) is used to track these requests . 

# Getting involved with Contributions

We are always looking for more contributions. If you see anything above that you would love to work on, we welcome you to become a contributor and maintainer of the areas that you love. You can get started by commenting on the related issue or by creating a new issue. Also you can reach out to us by:

- [Joining OpenEBS contributor community on Kubernetes Slack](https://kubernetes.slack.com)
	- Already signed up? Head to our discussions at [#openebs-dev](https://kubernetes.slack.com/messages/openebs-dev/)
- [Joining our Community meetings](https://github.com/openebs/openebs/tree/master/community)
