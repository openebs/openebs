---
oep-number: CStor Pool Migration
title: Migrating of CStor Pools from one node to other by migrating underlying disks
authors:
  - "@mittachaitu"
owners:
  - "@kmova"
  - "@sonasingh46"
editor: "@mittachaitu"
creation-date: 2020-08-26
last-updated: 2020-08-26
status: provisional
---

# CStor Pool Migration

## Table of Contents

- [CStor Pool Migration](#cstor-pool-migration)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
      - [Node name changes upon terminating/rebooting the node](#node-name-changes-upon-terminatingrebooting-the-node)
      - [Existing node is replcaed with new node in the cluster](#existing-node-is-replcaed-with-new-node-in-the-cluster)
      - [Scaling down the nodes in the cluster to 0 and scaling up the nodes in cluster](#scaling-down-the-nodes-in-the-cluster-to-0-and-scaling-up-the-nodes-in-cluster)
    - [Proposed Implementation](#proposed-implementation)
      - [CSPC-Operator](#cspc-operator)
    - [Steps to perform user stories](#steps-to-perform-user-stories)
    - [Low Level Design](#low-level-design)
    - [Schema changes](#schema-changes)

## Summary

This proposal brings out the design details to implement pool migration
from one node to other node.

*NOTE: Before pool migration all the disks participating in the cStor pools should be attached to newer node.*

## Motivation

- CStor pool migration should be supported when the disks were dettached and attached to different node. Following are the use cases:
  1. Scaling down the nodes in cluster to 0 and scaling up nodes in should work by updating the node selectors on CSPC(Use case in cloud environment).
  2. Dettaching and attaching underlying disks to different nodes.


### Goals

- Migrate the CStorPools from one node to another node when the underlying disks are moved to different node.

### Non-Goals

- Moving pools automatically to different node where ever disks are attached without any trigger from user.
- User has to take care of moving all the disks participating in pool to different node.
- High level operator to manage all these operation automatically.

## Proposal

### User Stories

#### Node name changes upon terminating/rebooting the node
As an OpenEBS user, I should be able to migrate pools from terminated node to new node.

#### Existing node is replcaed with new node in the cluster
As an OpenEBS user, I should be able to migrate pools to replaced node.

#### Scaling down the nodes in the cluster to 0 and scaling up the nodes in cluster
As an OpenEBS user, I should be able to scaledown the cluster to 0 and scale back the cluster should import the pool by changing the node selectors on CSPC.

### Proposed Implementation

#### CSPC-Operator

Currently to provision the cStorPoolInstances(cStor pools) user will create CSPC API. Once the CSPC is created watcher in CSPC-Operator will get an event and process CSPC for provisioning cStorPoolInstances. Not only create event even any updates made to CSPC watcher will get notified and proceess the changes accordingly. CSPC-Operator currently supports only adding blockdevices, replacing the blockdevices and changing the pool configurations like resource limits, tolerations, priority class. To support this use case CSPC-Operator should handle the node selector changes also.

**NOTE**: To know more information about the CSPC click [here](https://github.com/openebs/cstor-operators#operators-overview).

### Steps to perform user stories

1. Update the node selectors on the CSPC spec with new node details whereever blockdevices were attached.

**Consider following example for mirror pool migration**
This CSPC corresponds to a mirror pool on node `node1` and `node2`.
```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
    - nodeSelector:
        kubernetes.io/hostname: node1
      dataRaidGroups:
      - blockDevices:
          - blockDeviceName: "blockdevice-disk1"
          - blockDeviceName: "blockdevice-disk2"
      poolConfig:
        dataRaidGroupType: "mirror"
    - nodeSelector:
        kubernetes.io/hostname: node2
      dataRaidGroups:
      - blockDevices:
          - blockDeviceName: "blockdevice-disk3"
          - blockDeviceName: "blockdevice-disk4"
      poolConfig:
        dataRaidGroupType: "mirror"
```

Update the nodeSelector values to point to new node -- the spec will look following:

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
    - nodeSelector:
        kubernetes.io/hostname: node3
      dataRaidGroups:
      - blockDevices:
          - blockDeviceName: "blockdevice-disk1"
          - blockDeviceName: "blockdevice-disk2"
      poolConfig:
        dataRaidGroupType: "mirror"
    - nodeSelector:
        kubernetes.io/hostname: node2
      dataRaidGroups:
      - blockDevices:
          - blockDeviceName: "blockdevice-disk3"
          - blockDeviceName: "blockdevice-disk4"
      poolConfig:
        dataRaidGroupType: "mirror"
```

In the above CSPC spec `node1` nodeselector is updated with `node3` nodeselector.

### Low Level Design

When users updates the nodeSelector value with watcher in CSPC-Operator will get an event and process in the following manner. Usually CSPC-Operator will identify provisioned CStorPoolInstances of corresponding CSPC pool specs via nodeSelector but with this feature nodeSelector also will be modified. So to mitigate this CSPC-Operator will identify the CStorPoolInstances in following mannaer:
- First by verifying CSPC poolSpec nodeSelector and CSPI spec nodeSelector. If nodeSelector mismatches then it will identify using data raidgroup blockdevices.

- Scenario1: What happens when pool migration and horizontal pools scale(scale down and scaleup as well) operations(by adding pool spec) triggered at same time? CSPC-Operator will identify the changes and provision the cStorPoolInstance on new node later it will identify that nodeSelector has been updated for existing CStorPoolInstance then updates the pool-manager and CStorPoolInstance nodeSelector according to the new nodeSelector.

- Scenario2: What happens when disk replacement/pool expansion are performed on the migration spec? CSPC-Operator will identify the nodeSelector changes and then perform blockdevice replacement/pool expansion accordingly.


### Schema changes

No schema changes are required.
