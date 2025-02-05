---
title: VolumeMode
authors:
  - "k8s sig-storage authors"
owners:
  - "k8s sig-storage authors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# Persistent Volume Claim Volume Mode

## Table of Contents
- [Persistent Volume Claim Volume Mode](#persistent-volume-claim-volume-mode)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
    - [Implementation Details](#implementation-details)
    - [Usage details](#usage-details)
    - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)

## Summary

This proposal points out workflow details of PersistentVolumeClaim Volume Mode.

### Implementation Details

Kubernetes supports two kinds of volume modes one is filesystem mode and another one is
raw block mode. For more detailed information about raw block mode click [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/raw-block-pv.md#raw-block-consumption-in-kubernetes).

- During application mount time Kubelet will send volume capabilities as a payload for
  `NodePublishVolume` gRPC request. Driver will perform following operations based on
  volume access type
  - If access type is mount(which is filesystem mode) then driver will format(if not
    formatted) and mount the volume at given target path.
  - If access type is block(which is raw block mode) then driver will create a file in
    given target path and bind mount the device at target path.
- Once the operation is succeeded then driver will return success response to gRPC request.

### Usage details

1. User/Admin can configure desired mode under `Spec.VolumeMode`
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: csi-lvmpv
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: openebs-lvm
  volumeMode: Filesystem     ## Specifies in which mode volume should be attached to pod
  resources:
    requests:
      storage: 4Gi
```

### Test Plan
- Provision and application on volume with filesystem volume mode
  and verify that volume should get formatted with user specified filesystem.
- Provision volume with raw block volume and verify block volume accessibility
  from inside the application pod.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
