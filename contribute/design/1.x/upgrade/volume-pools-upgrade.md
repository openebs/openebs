---
oep-number: draft Upgrade 20190710
title: Upgrade via Kubernetes Job
authors:
  - "@kmova"
owners:
  - "@amitkumardas"
  - "@vishnuitta"
editor: "@kmova"
creation-date: 2019-07-10
last-updated: 2019-07-10
status: provisional
see-also:
  - NA
replaces:
  - current upgrade steps with scripts
superseded-by:
  - NA
---

# Upgrade via Kubernetes Job

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
    * [Design Constraints](#design-constraints)
    * [Proposed Implementation](#proposed-implementation)
    * [High Level Design](#high-level-design)
      * [CStorVolumeConfigClass -- new custom resource](#cstorvolumeconfigclass----new-custom-resource)
      * [CStorVolumeClaim -- new custom resource](#cstorvolumeclaim----new-custom-resource)
      * [ConfigInjector -- new custom resource](#configinjector----new-custom-resource)
      * [CStorVolume -- existing custom resource](#cstorvolume----existing-custom-resource)
      * [CStorVolumeReplica -- existing custom resource](#cstorvolumereplica----existing-custom-resource)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This proposal charts out the design details to perform pool and
volume upgrades via a Kubernetes Job. 

## Motivation

Once the OpenEBS control plane is upgraded, user has to manually 
upgrade the pools and volumes one at a time using the upgrade 
scripts. While this may work for smaller clusters and when upgrades 
are infrequent, the dependency on a manual intervention for upgrades
becomes a bottleneck on Ops team when running thousands of clusters
across different geographic locations.

In addition to the scalability limitation, in some environments, 
additional steps may be required like running the upgrades from 
an external shell - that has access to the cluster and has 
live connection to the cluster in the process of upgrade.

Cluster administrators would like to automate the process of upgrade, 
with push-button access for upgrades and/or flexibility on which 
pools and volumes are upgraded. 

This design provides the necessary abstractions to perform upgrades
of pools and volumes via Kubernetes Job. 

### Goals

- Ability to upgrade jiva volume or cstor pool/volume via `kubectl`
- Support for upgrading only a single cStor Pool from an SPC

### Non-Goals

- Scheduling of upgrades
- Support for upgrading all the volumes or pools at once. 

## Proposal

### User Stories

- As an cluster administrator - I want to automate the upgrades of 
  OpenEBS on thousands of Edge Clusters that are running in my 
  organization. 
- As an developer of managed kubernetes platform - I want to provide 
  an option for my end-user (cluster administrator) an user-interface 
  to easily select the volumes and pools and schedule an upgrade. 
  

### Design Constraints

This design builds on top of the initial implementation of upgrade 
supported via kubectl for upgrading from [0.8.2 to 0.9](https://github.com/openebs/openebs/tree/master/k8s/upgrades/0.8.2-0.9.0). 


The implementation made use of the CAS Template feature and comprised 
of the following: 
- Each type of upgrade - like jiva volume upgrade, cstor pool upgrade, 
  were converted from shell to an CAS Template, with a series of  
  upgrade tasks (aka runtasks) to be executed. 
- A custom resource called upgraderesults was defined to capture
  the results while executing the run tasks.
- An upgrade agent, that can read the upgrade CAS Template and 
  execute the run tasks on a given volume or pool.
- Administrator will have to create a Kubernetes Job out of the
  upgrade agent - by passing the upgrade cas template and the object
  details via a config map. 

While the above approach was good enough to be automated via `kubectl`, 
the steps that can be executed as part of upgrade were limited
by the features or constructs available within the CAST/RunTasks. 

Another short-comming of the CAST/RunTasks is the lack of developer
friendly constructs for rapidly writing new CAST/RunTasks. This was
severely impacting the time taken to push out new releases. 

### Proposed Implementation

Since the upgrades using the scripts have been well tested and tried 
out on several test and production developments, we decided to re-use
the shell scripts to perform the upgrade tasks. 

The upgrade scripts will be packaged into upgrade container, with an 
entrypoint script that will invoke the right scripts depending on 
the object being upgraded. 

A custom resource called `UpgradeTask` will be defined with the 
details of the object being upgraded, and will in trun be updated
with the status of the upgrade by the upgrade-container scripts.  

OpenEBS team will release an openebs-upgrade-tools container 
that contains all the upgrade scripts supported by openebs. 

The workflow followed by administrator is as follows:
- Define the Custom Resource and a Service account
- Create a UpgradeTask CR for the object being upgraded 
- Create a Kubernetes Job with upgrade-container and passing the 
  UpgradeTask details. 
- Administrator can query the UpgradeTask to check the status 
  and result of the upgrade.


### High Level Design

### Risks and Mitigations

## Graduation Criteria

## Implementation History

- Owner acceptance of `Summary` and `Motivation` sections - YYYYMMDD
- Agreement on `Proposal` section - YYYYMMDD
- Date implementation started - YYYYMMDD
- First OpenEBS release where an initial version of this OEP was available - YYYYMMDD
- Version of OpenEBS where this OEP graduated to general availability - YYYYMMDD
- If this OEP was retired or superseded - YYYYMMDD

## Drawbacks

NA

## Alternatives

NA

## Infrastructure Needed

