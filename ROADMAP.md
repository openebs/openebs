# Roadmap

This document provides information on OpenEBS development in current and upcoming releases. Community and contributor involvement is vital for successfully implementing all desired items for each release. We hope that the items listed below will inspire further engagement from the community to keep OpenEBS progressing and shipping exciting and valuable features.

## OpenEBS Lean Roadmap

OpenEBS follows a lean project management approach by splitting the development items into current, near term and future categories. We use GitHub [Projects](https://github.com/orgs/openebs/projects) and [Milestones](https://github.com/openebs/openebs/milestones) for tracking the feature development. This document is reviewed and updated based on the [monthly community call](https://github.com/openebs/openebs/tree/master/community#regular-monthly-product-meetings). 

## Current

These are some of the areas under active development planned to be completed within three releases. OpenEBS follows a monthly release cadence with a new release on the 15th of every month. 

While the following are planned items, a higher priority is given to usability and stability issues reported by the community. For the most current issue plan and status check out the [release milestones](https://github.com/openebs/openebs/milestones). 

* [Jiva](https://github.com/orgs/openebs/projects/1)
  * Optimizations to the replica rebuild process
  * CSI Driver
* [cStor](https://github.com/orgs/openebs/projects/9) 
  * Support for local snapshot and clone via Velero
  * New cStor API schema with automated Day 2 operations. 
  * CSI Driver
  * Support migration from SPC (older schema) to CSPC (new schema)
* [OpenEBS Local PV - hostpath and device](https://github.com/orgs/openebs/projects/11)
  * Generating Metrics 
  * Capacity based scheduling 
* [OpenEBS ZFS Local PV](https://github.com/orgs/openebs/projects/10)
  * Generating metrics
  * Integration and end-to-end tests
  * Automated install and upgrades  
* [NDM Enhancements](https://github.com/orgs/openebs/projects/2)
  * Enhance the discovery probes to support partitions, lvms and so forth
  * Support Prometheus exporter on block device metrics
  * Add gRPC API layer around NDM capabilities
* [Mayastor](https://github.com/openebs/Mayastor)
  * Replication across multiple nodes
  * Integration and end-to-end tests
  * Setup CI
* ARM based builds for OpenEBS [#1295](https://github.com/openebs/openebs/issues/1295)

## Near Term

Typically the items under this category fall under 3 to 6 months roadmap. 

There are several enhancements planned under each of the storage engines tracked under the respective GitHub Projects. The high level goals for each storage engine are as follows:
* cStor with new schema (stable). [Project Tracker](https://github.com/orgs/openebs/projects/9)
* NDM (stable). [Project Tracker](https://github.com/orgs/openebs/projects/2)
* OpenEBS ZFS Local PV (stable). [Project Tracker](https://github.com/orgs/openebs/projects/10)
* OpenEBS Local PV - hostpath and device (stable). [Project Tracker](https://github.com/orgs/openebs/projects/11)
* Mayastor (beta)

## Future

As the name suggests this bucket contains items that are planned for future. Some times the items are related to adapting to the changes coming in the Kubernetes or other related projects. Some of the items currently planned include: 
* Mayastor (stable)
* Support for working with multiple network interfaces. 

For a full list of issues, check out the [future backlog](https://github.com/openebs/openebs/milestone/11). 

