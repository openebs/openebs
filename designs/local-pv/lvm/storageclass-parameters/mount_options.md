---
title: LocalPV-LVM Mount Options
authors:
  - "@pawanpraka1"
owners:
  - "@kmova"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# LocalPV-LVM Mount Options

## Table of Contents
- [LocalPV-LVM Mount Options](#lvm-localpv-mount-options)
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

- As a user, I need storage to be mounted inside the applications with specific options.

### Non-Goals

- Supporting mount options that are natively don't support by filesystem(s).

## Proposal

### Implementaion Details


LVMLocalPV Node CSI driver is responsible for mounting LVM Volumes on application
specific paths during [NodePublishVolume](https://github.com/container-storage-interface/spec/blob/master/spec.md#nodepublishvolume) request gRPC. At a high level, Kubelet will perform the following operations when pod schedules on node
- Kubelet will identify CSI-Driver responsible for mounting volume and issues
  `NodePublishVolume` request for mounting volume into application specific path. Along
  with the request, Kubelet also sends the payload which contains mount specific information(which
  are gathered from multiple places ex: mount options & fsType are read from storageclass, volume
  information like capabilities are read from PV resource).
- Now, after receiving the request CSI-Driver reads following information from NodePublishVolume
  request
  - Filesystem information
  - Target path(application specific path) i.e mount path
  - Volume attributes(Which got populated to PV during volume creation time)
  - Volume Capabilities(Block mode/Filesystem mode)
  - Mount Options
  and perform mount operation using K8s [mount-utils](https://github.com/kubernetes/mount-utils#purpose) library.


**Note**:
- How kubelet gets event on pod scheduling and what it does after receiving a successful
  response from NodePublishVolume request is out of scope in this workflow.
- For more information about mount options are available [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/mount-options.md#mount-options-for-mountable-volume-types).
- There won't be any validations on mount options either from K8s side (or) from LocalPV-LVM
  side. If user doesn't specify invalid values mount operation will be errored and the reason
  can be seen in describe of the application pod.

### Usage details

1. User/Admin can specify mount options in StorageClass under `mountOptions` field

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvmpv-xfs
provisioner: local.csi.openebs.io
allowVolumeExpansion: true
parameters:
  storage: "lvm"
  vgpattern: "^lvmvg$"
  fsType: ext4
mountOptions:
- barrier=0
- commit=10
- data=journal
```

### Test Plan
A test plan will include following test cases:
- Provision application without specifying mount options and verify that
  application should be able to consume a volume.
- Provision application with various mount options according to user chosen
  filesystem(ext[3|4], xfs, btrfs) and verify whether mount options behavior
  from the application.
- Provision application with invalid mount options and verify that application
  should remain in the containerCreating state.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
