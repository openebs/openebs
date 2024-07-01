---
title: AllowedTopologies
authors:
  - "k8s storage contributors"
owners:
  - "k8s storage contributors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Summary](#summary)
- [Motivation](#motivation)
  - [Goals](#goals)
- [Proposal](#proposal)
  - [Implementation Details](#implementation-details)
  - [Usage Details](#usage-details)
  - [Test Plan](#test-plan)


## Summary

This proposal points out workflow details to support allowed topologies.

## Motivation

### Goals

- As a user, I should be able to schedule a volume based on some custom labels available on the node.

## Proposal


### Implementation Details

This feature is natively driven by Kubernetes(for more information about workflow click [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/volume-topology-scheduling.md#volume-topology-aware-scheduling)) and LocalPV-LVM CSI-Driver is a consumer of topology
feature.

- During volume provisioning time external-provisioner will read topology information specified
  over referenced StorageClass and pass that information as a payload for CreateVolume
  gRPC request to CSI-Driver.
- After receiving CreateVolume request CSI-Driver will read topology information available under
  `accessible_topology` field and fetch nodes that satisfies given topology. 
    - Now, It picks the node that is capable of provisioning volume and creates a LVMVolume resource
      with required details(like volume group, desired size and type of volume[thick/thin]).
    -  LVMVolume controller which is a reconcilier for LVM volume triggers `lvcreate` command to
       create LVM volume on user specified VolumeGroup.
    - Once the LVMVolume resource status is updated to `Ready` then controller will return success
      response to CreateVolume gRPC request.

**Note**: If topologies are not specified then it creates volume on the best fit volume group.

### Usage Details

- Below is an example to specify topology information under storageclass.
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
 name: lvm-sc
allowVolumeExpansion: true
parameters:
  volgroup: "lvmvg"
provisioner: local.csi.openebs.io
allowedTopologies:
- matchLabelExpressions:
 - key: openebs.io/nodename
   values:
     - node-1
     - node-2
```

### Test Plan

- Provision a volume without specifying any topology information and
  verify that volume should get provisioned.
- Provision a volume with valid topology and immediate binding mode and
  verify that volume should get provisioned.
- Provision a volume with invalid topology information and verify that
  volume should not get provisioned(PVC will remain pending state).
- Provision a volume with topology information that is not available
  currently but it will available in near future and verify that volume should
  get provisioned after making topology available.
- Provision a volume with valid topology and delayed binding mode and verify
  that volume should get provisioned only after deploying application on delayed
  binding volume.
- Provision a volume by specifying the topology of node where required storage
  is not available and verify that volume should not get provisioned(PVC will
  remains pending state).
