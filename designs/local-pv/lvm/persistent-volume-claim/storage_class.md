---
title: StorageClass
authors:
  - "k8s sig-storage authors"
owners:
  - "k8s sig-storage authors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# Persistent Volume Claim StorageClass Reference

## Table of Contents
- [Persistent Volume Claim StorageClass Reference](#persistent-volume-claim-storageclass-reference)
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

This proposal points out workflow details to support dynamic provisioning of volumes.

## Proposal

### Implementation Details

Kubernetes introduced StorageClass filed to support dynamic provisioning. More detailed
information on how storageclass is involved in provisioning is described [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/container-storage-interface.md#provisioning-and-deleting).

**Note**: Kubernetes will not perform any validation given StorgeClass.
          If StorageClass is not available PVC will remains in pending.

### Usage Details

- User can specify pre-defined storageclass for provisioning dynamic volumes
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: csi-lvmpv
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: openebs-lvm    ## It must be OpenEBS LVM storageclass for provisioning LVM volumes
  resources:
    requests:
      storage: 4Gi
```

### Test Plan

- Provision a volume with a valid StorageClass name and verify that
  volume should get provisioned.
- Provision a volume with an invalid StorageClass name and verify that
  volume should never get provisioned(PVC will remain in a pending state).
- Provision a volume without StorageClass and verify that creation call should get errored out.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
