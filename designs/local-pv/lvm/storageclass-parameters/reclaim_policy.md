---
title: ReclaimPolicy
authors:
  - "k8s storage contributors"
owners:
  - "k8s storage contributors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

## StorageClass Volume Reclaim Policy

## Table of Contents
- [StorageClass Volume Reclaim Policy](#storageclass-volume-reclaim-policy)
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

This proposal points out workflow details of volume reclaim policies.

## Motivation

### Goals

- As a user, I should be able to retain underlying LVM Volume even after deleting PVC.
- As a user, I should be able to delete LVM volume after deleting PVC.

## Proposal

### Implementation Details

LocalPV-LVM doesn't have any direct dependency over volume reclaim policies moreover
these are is a standard Kubernetes storageclass option. Kubernetes supports two kind
of volume policies that are `Retain` & `Delete`. By the name `Retain` states underlying
volume should exist even after deleting PVC whereas `Delete` states underlying volume
should be deleted and space should be reclaimed to serve a different purpose.

- If reclaim policy is `Delete` then external-provisioner will make `DeleteVolume` gRPC
  request to CSI-Driver.
- If reclaim policy is `Retain` then external-provisioner will not issue any gRPC request to CSI-Driver.

**Note**: If ReclaimPolicy is unspecified then defaults of `Delete` policy.

### Usage Details

- User/Admin can specify the type of Reclaim policy under StorageClass options.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvm
provisioner: local.csi.openebs.io
parameters:
  storage: "lvm"
  vgpattern: "lvmvg.*"
reclaimPolicy: Delete          ## Reclaim policy can be specified here. It also accepts Retain
```

### Test Plan

- Provision and de-provision volume with `Delete` reclaim policy and
  verify that PV & LVMVolume resources should get deleted.
- Provision volume with `Retain` reclaim policy and trigger deletion
  of volume and verify that underlying volume should retain.
- Provision & de-provision volume with `Retain` reclaim policy then
  try to claim retained volume by creating PVC referencing to retained
  volume and verify that volume should get provisioned.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
 
