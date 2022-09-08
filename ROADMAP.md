# Roadmap

This document provides information on OpenEBS development in current and upcoming releases. Community and contributor involvement is vital for successfully implementing all desired items for each release. We hope that the items listed below will inspire further engagement from the community to keep OpenEBS progressing and shipping exciting and valuable features.

OpenEBS follows a lean project management approach by splitting the development items into current, near term and future categories.


## Current

These are some of the backlogs that are prioritized and planned to be completed within the next major release (e.g. OpenEBS 4.0). While the following are planned items, higher priority is given to usability and stability issues reported by the community. The completion of these items also depends on the availability of contributors.

Note: OpenEBS follows a quarterly release cadence with a new minor release around the end of each quarter. For the most current plan and status check out the [release project trackers](https://github.com/orgs/openebs/projects?type=classic). This document is reviewed and updated by the maintainers after each major release.

### Mayastor
- Source repositories
  - https://github.com/openebs/mayastor
  - https://github.com/openebs/mayastor-control-plane
  - https://github.com/openebs/mayastor-api
  - https://github.com/openebs/mayastor-extensions
  - https://github.com/openebs/mayastor-docs
- Backlogs in-progress (under active development)
  - Ease of installation by having a unified Helm chart for installing Mayastor in a Kubernetes cluster.
  - Generic naming of all Mayastor Kubernetes API resources. For eg. MayastorStoragePool will be changed to DiskPool.
  - Enhance supportability by ingesting Mayastor component logs and creating a bundle through kubectl plug-in. 
  - Mayastor should expose metrics that meet the needs of the SRE persona, to track utilization at pool and volume levels.
  - Removal of iSCSI support from Mayastor, NVMe is the only supported protocol.
  - On manual deletion of a Mayastor PV having Reclaim policy set to "Retain", the related Mayastor resources need to be cleaned up.
  - Support for Mayastor installation on AWS/EKS clusters.
  - Support for Mayastor installation on SuSE Rancher clusters.
  - Support for Mayastor installation on RHEL-based Kubernetes clusters.
  - High availability support for Mayastor nexus (target), ability to spin up on-demand replacement target for a Mayastor volume.
  - Ability to cordon, drain and delete Mayastor nodes.
  - Basic upgrade framework for updating Mayastor releases.
  - Support for thin-provisioned Mayastor volumes.
  - Faster rebuild of volume replicas using log-based technique.
  - Call home analytics.
- Backlogs (near-term)
  - Support for hot upgrade, business continuity with no downtime.
  - Support for volume groups, i.e. Mayastor replica placement should be topology aware for statefulsets zonal (or HA) distribution.
  - Support for Mayastor volume resize.
  - Support for volume snapshots.

### Dynamic Local PVs
- Source repositories
  - https://github.com/openebs/dynamic-localpv-provisioner
  - https://github.com/openebs/zfs-localpv
  - https://github.com/openebs/lvm-localpv
  - https://github.com/openebs/rawfile-localpv
  - https://github.com/openebs/device-localpv
  - https://github.com/openebs/node-disk-manager
- Backlogs
  - Shared VG for LVM Local PV. 
  - Data populator for moving Local PVs across nodes. 

### Jiva
- Source repositories
  - https://github.com/openebs/jiva
  - https://github.com/openebs/jiva-operator
- Backlogs
  - Deprecate the v1alpha1 CRDs in favor of the v1 CRDs introduced from 3.1
 
  
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

### NDM 
- Source repositories
  - https://github.com/openebs/node-disk-manager
- Backlogs
  - None


### Others
- Source repositories
  - https://github.com/openebs/charts
  - https://github.com/openebs/openebsctl
  - https://github.com/openebs/monitoring
  - https://github.com/openebs/website
  - https://github.com/openebs/m-exporter
  - https://github.com/openebs/dynamic-nfs-provisioner
  - https://github.com/openebs/openebs-k8s-provisioner (deprecated)
  - https://github.com/openebs/openebs-docs (deprecated)
  - https://github.com/openebs/maya (deprecated)
- Backlogs
  - Enhancements to OpenEBS CLI (openebsctl) for better troubleshooting OpenEBS components and fixing the errors
  - User-friendly installation & configuration command-line tool (analogy to linkerd CLI for linkerd)
  - Migrate the CI to CNCF infrastructure from vendor infrastructure

## Near Term

Typically the items under this category fall under next major release (after the current. e.g 4.0). At a high level, the focus is towards moving the beta engines towards stable by adding more automated e2e tests and updating the corresponding user and contributor documents. To name a few backlogs (not in any particular order) on the near-term radar, where we are looking for additional help: 


- Support for Mayastor Volume resize
- Support for pluggable storage backend for Mayastor (example: replace blobstore with lvm)
- Support for specifying multiple hostpaths to be used with Local PV hostpath
- Update user documentation with reference stacks of running various workloads using OpenEBS volumes 
- Auto provisioning of block devices (on the external storage systems) that can be used with OpenEBS storage engines
- Setup E2e pipelines for ARM Clusters
- Automate the workflows around handling scenarios like complete cluster failures that currently require some manual steps
- Custom Kubernetes storage schedulers to address auto-rebalancing of the data placed on the nodes to help with scale up/down of Kubernetes nodes
- Allow Mayastor Pools to incorporate more than one capacity contributing disk device
- Auto-scaling up and down of cStor pools as the new nodes are added and removed
- Auto-upgrade of cStor Pools and Volumes when user upgrades control plane
- Asynchronous or DR replica for cStor and Mayastor volumes
- Support for restoring a volume (in-place) for supporting blue/green stateful deployments
- Multi-arch builds for all Mayastor components
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

