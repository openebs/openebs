---
title: LocalPV-LVM fsType
authors:
  - "@pawanpraka1"
owners:
  - "@kmova"
creation-date: 2021-06-17
last-updated: 2021-06-17
status: Implemented
---

# LocalPV-LVM fsType Parameter

## Table of Contents
- [LocalPV-LVM fsType Parameter](#lvm-localpv-fstype-parameter)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
- [Proposal](#proposal)
    - [Implementaion Details](#implementaion-details)
    - [Usage details](#usage-details)
  - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)


## Summary

This proposal charts out the workflow details to support mount options for various filesystems.

## Motivation

### Goals

- As a user, I should be able to format the volume with desired filesystem and make volume to be
  availabe as a file.

### Non-Goals

- Installing prerequisites to support user specified filesystem

# Proposal

### Implementaion Details

Kubernetes provides a placeholder in StorageClasss to specify driver & Storage Provider
supported key-value pairs under the parameters section. K8s registered a key called `fsType`
to specify filesystem.

- Filesystem information is propagated to LocalPV-LVM CSI Driver during as payload during
  `NodePublishVolume` gRPC request.
- During `NodePublishVolume` gRPC request CSI driver reads required information(fsType,
  volume mode, mount options, and so on) if volume mode is filesystem then driver will
  formats the volume with user specified filesystem and mount the volume in given target
  path by using K8s [mount-utils](https://github.com/kubernetes/mount-utils).
- Once the mount operation is succeeded driver will return a success response to `NodePublishVolume`
  gRPC request.

**Note**: 
- User can specify filesystem type with two different keys one is `fsType` and another
  key is `csi.storage.k8s.io/fstype`. If unspecified then defaults to ext4.
- There won't be any validations on filesystem type either from K8s or from CSI driver side.
- Supported filesystem types are ext[2|3|4], xfs and btrfs.

 ### Usage details

1. User/Admin can specify filesystem type in StorageClass under parameters.
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvm
allowVolumeExpansion: true
provisioner: local.csi.openebs.io
parameters:
  storage: "lvm"
  vgpattern: "lvmvg.*"
  fsType: xfs 
```

## Test Plan
- Provision applications with all supported filesystem types and verify
  that volume should formatted with user specified filesystem.
- Provision an application without specifying any filesystem type under
  parameters and verify that application should be able to consume the volume.
- Provision an application and restart the CSI node driver during application
  mounting time and verify that application should get into running state after
  ejecting the chaos.


## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
