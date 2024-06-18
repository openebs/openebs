---
title: Volume Name
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
    - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)

## Summary

This proposal points out workflow details to support volume name field in PersistentVolumeClaim.

## Proposal

### Implementation Details

When volume name is specified in claim request then Kubernetes will bind
claim to the volume only if volume satisfies all of the following criteria:
- StorageClass name should be same on the claim as well as on volume.
- Volume capacity should be equal to or greater than claim request.
- Volume should be in an available state.

**Note**: Among volume name and selector volume name takes more precedence.

### Test Plan

- Provision a volume by specifying available/pre-provisioned volume name and
  verify that PVC should get bound to volume.
- Provision a volume by specifying unavailable volume name and verify that
  PVC should remains in pending state.
- Provision a volume with capacity more than available volume capacity and verify
  that PVC should remains in pending state.
- Provision a volume with volume name by specifying different storageclass name
  from available volumes and verify that PVC should remains in pending state.

  
## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
