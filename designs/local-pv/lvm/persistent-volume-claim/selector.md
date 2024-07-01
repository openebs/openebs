---
title: Volume Selector
authors:
  - "k8s sig-storage authors"
owners:
  - "k8s sig-storage authors"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# Volume Selector

## Table of Contents
- [Volume Selector](#volume-selector)
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

This proposal points out workflow details to support the selector field in PersistentVolumeClaim.

## Proposal

### Implementation Details

Detailed information about use cases and workflow is available [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/volume-selectors.md#abstract).

**Note**: If Selector field is specified request will not be sent to CSI driver.

### Usage Details

- Users can reclaim pre provisioned/retained volumes by specifying label selectors as shown below
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: csi-lvmpv
spec:
  storageClassName: openebs-lvmpv
  ## Specify selector matching to available PVs label, K8s will bound to any of available PV matches to specified labels
  selector:
    matchLabels:
      openebs.io/lvm-volume: reuse
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 4Gi   ## Capacity should be less than or equal to available PV capacities
```

### Test Plan

- Provision a volume by specifying match labels matching to available/pre-provisioned
  volumes and verify that PVC should get bound.
- Provision a volume by specifying labels that don't exist on any of the available
  volumes and verify that PVC should not get bound to volume.
- Provision a volume with a capacity greater than available volumes and verify that
  PVC should not get bound to volume.
- Provision a volume with selectors by specifying different storageclass name from
  available volumes and verify that PVC should not get bound to volume.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
