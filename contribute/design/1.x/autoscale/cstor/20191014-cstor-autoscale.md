---
oep-number: CStor ClusterAutoscale REV1
title: CStor ClusterAutoscale
authors:
  - "@vishnuitta"
owners:
  - "@kmova"
  - "@amitkumardas"
  - "@mynktl"
  - "@pawanpraka1"
editor: "@vishnuitta"
creation-date: 2019-10-14
last-updated: 2019-10-14
status: provisional
---

# CStor ClusterAutoscale

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Add new pool to existing CSPC](#add-new-pool-to-existing-cspc)
      * [Remove pool from existing CSPC ensuring data safety](#remove-pool-from-existing-cspc-ensuring-data-safety)
      * [Move pool from one node to another](#move-pool-from-one-node-to-another)
    * [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
    * [Proposed Implementation](#proposed-implementation)
      * [CA related information](#ca-related-information)
      * [Adding new node to existing CSPC](#adding-new-node-to-existing-cspc)
      * [Informing that a pool has been cordoned to the system](#informing-that-a-pool-has-been-cordoned-to-the-system)
      * [Draining the cordoned pool](#draining-the-cordoned-pool)
      * [Movement of pools on remote disks from one node to another](#movement-of-pools-on-remote-disks-from-one-node-to-another)
    * [Steps to perform user stories](#steps-to-perform-user-stories)
      * [Adding new pool to existing CSPC](#adding-new-pool-to-existing-cspc)
      * [Removing pool from existing CSPC ensuring data safety](#removing-pool-from-existing-cspc-ensuring-data-safety)
      * [Moving pool from one node to another](#moving-pool-from-one-node-to-another)
    * [High Level Design](#high-level-design)
      * [More OEPs](#more-oeps)
      * [Components Interaction](#components-interaction)
    * [Testcases](#testcases)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This proposal includes high level design for building blocks of cStor which can
be triggered by an administrator or by an operator
- to add a pool to existing cStor pool cluster
- to remove a pool from cStor pool cluster with data consistency
either when CA adds/wants-to-remove a node (or)
admin adds/wants-to-remove a node.
- move pool across nodes

## Motivation

User wants OpenEBS to work natively with K8S cluster autoscaler. This minimizes
operational cost.
More usescases are available at:
https://docs.google.com/document/d/1z_HdF7p_BNYO1MJnfJqFAHBrXEbqCjistyRXTpLbnFg/edit?usp=sharing

### Goals

- Adding a pool to existing cStor pool cluster
- Removing a pool from existing cStor pool cluster with data consistency
- Movement of pools on remote disks from one node to another

### Non-Goals

- Integrating with CA to automatically add/remove a pool from cluster
- Movement of pools on physical disks from one node to another

## Proposal

### User Stories

#### Add new pool to existing CSPC
As an OpenEBS user, I should be able to add a pool to existing cStor pool
cluster.

#### Remove pool from existing CSPC ensuring data safety
As an OpenEBS user, I should be able to remove pool from cluster by moving any
replicas on old pool to pools on other nodes.

#### Move pool from one node to another
As an OpenEBS user, I should be able to move pool across nodes in the cluster.

### Implementation Details/Notes/Constraints

Currently, CSPC is having concept of creating/maintaining cStor pools on the
nodes. Design and other details of CSPC are available at:
https://github.com/openebs/openebs/blob/master/contribute/design/1.x/cstor-operator/doc.md

Sample CSPC yaml looks like:
```
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostname: gke-cstor-it-default-pool-1
    raidGroups:
    - type: mirror
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: pool-1-bd-1

      - blockDeviceName: pool-1-bd-2

    - type: mirror
      name: group-2
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: pool-1-bd-3

      - blockDeviceName: pool-1-bd-4

    poolConfig:
      cacheFile: var/openebs/disk-img-0
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: lz

  - nodeSelector:
      kubernetes.io/hostname: gke-cstor-it-default-pool-2
    raidGroups:

    - type: mirror
      blockDevices:
      - blockDeviceName: pool-2-bd-1

      - blockDeviceName: pool-2-bd-2

    - type: mirror
      name: group-2
      blockDevices:
      - blockDeviceName: pool-2-bd-3

      - blockDeviceName: pool-2-bd-4

    poolConfig:
      cacheFile: var/openebs/disk-img-2
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: off
```

cspc-operator reads the above yaml and creates CSPI CR, CSPI-MGMT deployments.
It also creates BlockDeviceClaims for BlockDevices mentioned in yaml.
cspc-operator looks for changes in above yaml and accordingly updates CSPI CR.

If a node-selector entry is added to above yaml, it creates new CSPI CR,
CSPI-MGMT deployment for newly added entry, BDCs etc.

If any entry related to nodeSelector is removed, it triggers the deletion of
deployment, CSPI CR and associated BDCs.
More details of cspc-operator and above yaml are available at above mentioned
link.

Provisioning of cStor volumes are done on a CSPC by CVC controller. As part of
volume provisioning, it creates target related CR i.e., CV, target deployment
and replica related CRs i.e., CVRs.

CVRs are created by CVC by selecting RF (replication factor) number of CSPIs of
CSPC, and makes each CVR point to one CSPI.

### Proposed Implementation

#### CA related information

CA can scale down the node on which cStor pool pods are running. This causes
data unavailability or data loss. So, nodes on which cStor pool pods are running
should not be scaled down.
This information can be passed to CA by setting
`"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"` as annotation on
cStor pool related pods.

#### Adding new node to existing CSPC

Either admin (or) operator which recognizes the need to add new pool to
existing CSPC adds a `node entry` to above yaml.
cspc-operator then takes care of creating required resources to add new pool to
existing pool cluster.

#### Informing that a pool has been `cordoned` to the system

This is required to stop provisioning new replicas on a pool that eventually
gets deleted from pool cluster.

A new field will be added to CSPI which can be read by CVC controller during
the phase of volume provision.
This being related to provision, field for this in CSPI is:
`provision.status`. This can take `ONLINE` and `CORDONED` as possible values.

`ONLINE` means CVC can pick the CSPI for volume provisioning.

`CORDONED` means CVC SHOULD NOT pick the CSPI for any further volume
provisioning.

There is NO reconciliation happens for this, but, this acts as a config
parameter.

This is not added to `spec` of CSPI as `spec` is shared with CSPC controller
also.

#### Draining the `cordoned` pool

Admin (or) operator drains a pool (DP) by moving replicas which are on DP to
another pool in the same cluster. This can be in two modes.

One is - by adding new replica and deleting old one

Second is - by moving replica from old one to new replica

Admin (or) operator need to identify the list of replicas i.e., CVRs on pool DP.
For each identified CVR (CVR1), follow either the first mode or second.

__Add a new replica and remove old one__ way:
- Identify new pool (NP) other than DP which can take the replica
- Perform replica scaleup steps
  - create a new CVR (CVR2) on NP
  - Increase the desired replication factor by 1 in CV CR related to this volume.
- Once the CVR2 becomes healthy, perform replica scaledown steps
  - remove CVR1 related details, and, reduce DRF on CV CR
  - delete CVR1

Above steps to add new replica are given in
https://github.com/openebs/openebs/blob/master/contribute/design/1.x/replica_scaleup/dataplane/20190910-replica-scaleup.md

Steps to perform replica scale down can change as its implementation starts.

__Move old replica to new one__ way:
- Identify new pool (NP) other than DP which can take the replica
- Delete CVR1 which is on old pool
- Create new CVR (CVR2) on new pool with status as 'Recreate' and
`spec.ReplicaID` same as that of CVR1

Above steps to move replica are also available at
https://github.com/openebs/openebs/blob/master/contribute/design/1.x/replica_scaleup/dataplane/20190910-replica-scaleup.md

#### Movement of pools on remote disks from one node to another

This scenario is about moving pools on remote disks from old node to another,
instead of distributing replicas on pool of old node to other pools.

Steps to perform are as follows:
- Identify the node N1 on which replicas of old pool doesn't exists
- Delete CSPI-mgmt deployment of old pool
- Patch CSPI CR with the new node information
- Detach disks from old node and attach them to new node
- Create CSPI-mgmt deployment on new node N1

Another approach for the same would be:
Let cStor pool pod i.e., CSPI-mgmt deployment consume disks using PVC instead
of BDC. Then, steps to follow would be:
- Identify the node N1 on which replicas of old pool doesn't exists
- Delete CSPI-mgmt deployment of old pool
- Create CSPI-mgmt deployment on new node N1

### Steps to perform user stories

#### Adding new pool to existing CSPC
- User will add new node entry to existing CSPC yaml

#### Removing pool from existing CSPC with data safety
- Trigger operator to perform steps that cordon the node
- Trigger operator to perform steps to drain the node

#### Moving pool on remote disks from one node to another
- Trigger operator with old and new node information along with CSPC details

### High Level Design

In CSPI spec, `provision.status` field will be added to let CVC controller to
know the provisioning status of CSPI.
It excludes the CSPIs whose provision.status is NOT ONLINE for provisioning
replicas.

#### More OEPs:
- For cStor volume's replica scale down scenario, separate OEP need to be raised
or existing OEP on replica scaleup need to be updated.
- OEP for operator that cordons and drains the node need to be raised

#### Components interaction:

```
Operator ---> [CSPI CR] ---> CVC-CONTROllER ---> [CVR CRs]
```

In *phase 1*, first two user stories will be targeted.

First user story is already covered in 1.2 release.
For second user story, building block of doing replica scale up is available in
1.3 release.

In *phase 2*, pool movement across nodes will be targeted.

### Testcases:

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

NA
