---
title: Capacity Resource Request
authors:
  - "k8s sig-storage authors"
owners:
  - "k8s sig-storage authors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# Persistent Volume Claim Resource Request

## Table of Contents
- [Persistent Volume Claim Resource Request](#persistent-volume-claim-resource-request)
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

This proposal charts out workflow details to provision dynamic volumes with requested capacity.

## Proposal

### Implementation Details

- CSI External-Provisioner receives PVC creation events and sends volume name, size, and
  other volume attributes as a payload of `CreateVolume` gRPC request to CSI driver.
- Once CSI driver receives `CreateVolume` gRPC request driver reads the payload information
  and creates a LVM volume resource with best fit VolumeGroup.
  - Corresponding LVM controller creates LVM volume on matching VolumeGroup and updates the status
    of LVM volume resource to `Ready`.
- After wathing `Ready` status on LVM volume resource CSI driver will retrun success response to
  gRPC request.

**Note**: If matching VolumeGroups doesn't have enough available space then PVC will remains Pending.

### Usage Details

- User can specify desired capacity under `Spec.Resources.Requests.Storage` field.
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: csi-lvmpv
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: openebs-lvm
  resources:
    requests:
      storage: 4Gi       ## Specify required storage for an application
```

### Test Plan
- Provision volume with valid capacity i.e less than available capacity of
  corresponding VolumeGroup and verify that volume should get provisioned.
- Provision volume with a capacity larger than available VolumeGroup capacity,
  later make capacity to be available to the volume group(via vgextend) and verify that
  volume should get provisioned after increasing capacity.
- Deprovision bounded volume and verify that space should be reclaimed from
  underlying VolumeGroup.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA

