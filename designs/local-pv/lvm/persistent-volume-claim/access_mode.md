---
title: Volume Access Modes
authors:
  - "k8s sig-storage authors"
owners:
  - "k8s sig-storage authors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# Persistent Volume Claim Access Modes

## Table of Contents
- [Persistent Volume Claim Access Modes](#persistent-volume-claim-access-modes)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Proposal](#proposal)
    - [Implementation Details](#implementation-details)
    - [Usage Details](#usage-details)
    - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)

## Summary

This proposal points out workflow details to add support of various volume access
modes which help to state the behavior of volume(SingleNodeReadWriter, MultiNodeReader
and MultiNodeReaderWrtier).

## Proposal

### Implementation Details

- Kubernetes has support of various AccessModes those are ReadWriteOnce, ReadWriteMany
  & ReadOnlyMany access modes but among those LVM-Local PV supports only ReadWriteOnce
  access mode.
  - ReadWriteOnce access mode states LVM volume can be available at most only on
    one node at any given time.
  - ReadWriteMany access mode states LVM volume could be available more than one node at any given time.
  - ReadOnlyMany access mode states LVM volume can be available as ReadOnly volume at a given time.
- During volume provisioning time external-provisioner sends user defined access modes as a paylod
  of `CreateVolume` gRPC request.
- CSI driver receives the `CreateVolume` gRPC request and reads the payload information which contains
  access modes. After reading the access modes driver will validate against supported access modes, 
  if there are any unsupported modes then CSI driver will return an error response to gRPC request else
  the driver continues with provisioning.

### Usage Details

- User can specify storage provider supported access modes under `spec.accessModes` according to their use case.

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: csi-lvmpv
spec:
  accessModes:
    - ReadWriteOnce        ## Specify ReadWriteOnce(RWO) access modes
  storageClassName: openebs-lvm
  resources:
    requests:
      storage: 4Gi
```

### Test Plan

- Provision an application with LocalPV-LVM supported access mode and verify accessibility of volume from application.
- Provision an application with unsupported access modes and verify that volume should not get provisioned.
- Provision multiple applications on the same volume and verify that only one application instance should be in running state.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
