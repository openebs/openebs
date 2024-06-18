---
title: VolumeBindingMode
authors:
  - "k8s sig-storage authors"
owners:
  - "k8s sig-storage authors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# StorageClass VolumeBindingMode

## Table of Contents
- [StorageClass VolumeBindingMode](#storageclass-volumebindingmode)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
  - [Proposal](#proposal)
    - [Implementation Details](#implementation-details)
    - [Usage Details](#usage-details)
    - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)


## Summary

This proposal points out workflow details to support volume binding modes.

## Motivation

### Goals

- As a user, I should be able to provision volume before deploying an application.
- As a user, I should be able to provision volume only when an application is requested.

## Proposal

### Implementation Details

LocalPV-LVM doesn't have any direct dependency over volumebinding modes moreover these are
standard Kubernetes storageclass option. For more information about workflow is
available [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/volume-topology-scheduling.md#delayed-volume-binding).

LocalPV-LVM honours both types of VolumeBindingModes `Immediate` & `WaitForFirstConsumer`.
- Configuring `Immediate` informs Kubernetes volume provisioning should be instantiated
  right after creation of PersistentVolumeClaim(PVC).
- Configuring `WaitForFirstConsumer` inform Kubernetes volume provisioning should be
  only after availability of consumer.

**Note**: If VolumeBindingMode is unspecified then defaults to `Immediate` mode.

### Usage Details

- User/Admin can specify type of binding mode according to their usecases:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvm
provisioner: local.csi.openebs.io
parameters:
  storage: "lvm"
  vgpattern: "lvmvg.*"
volumeBindingMode: WaitForFirstConsumer     ## It can also replaced by Immediate volume binding mode depends on use case.
```


### Test Plan

- Provision volume with immediate binding mode and verify that
  volume should get provisioned.
- Provision volume with delayed binding mode and verify that volume
  should remain in pending state till application deployed on volume.
- Provision application with delayed volume binding mode and verify whether
  pod is scheduled on a node where maximum capacity is available.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
