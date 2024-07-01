---
title: LocalPV-LVM Shared Volume
authors:
  - "@pawanpraka1"
owners:
  - "@kmova"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# LocalPV-LVM Shared Volume

## Table of Contents
- [LocalPV-LVM Shared Volume](#lvm-localpv-shared-volume)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [Implementation Details](#implementation-details)
      - [How can be volume shared between multiple instances](#how-can-be-volume-shared-between-multiple-instances)
    - [Usage details](#usage-details)
    - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)


## Summary

This proposal charts out the workflow details to support sharing of LVM volume
between different instances of applications on the same node.

## Motivation

### Goals

- Able to access the LVM volume from multiple application instances on the same node.

### Non-Goals

- Accessing LVM volume from different nodes other than where LVM is accessible.

## Proposal

### Implementation Details

- User/Admin has to set `shared` parameter to "yes" under storageclass parameters
  to make volume to be available in more than one application instance.
- During volume provisioning time external-provisioner will read all key-value pairs
  that are specified under referenced storageclass and pass information to CSI
  driver as payload for `CreateVolume` gRPC request.
- After receiving the `CreateVolume` request CSI driver will pick the appropriate node based
  on scheduling attributes(like topology information, matching VG name, available capacity)
  and creates LVM volume resource with node information as well as other attributes like
  VG name, desired capacity information, and also property of volume that states whether
  it can be accessed between multiple instances or not.
- After creation of LVM volume resource corresponding LVM volume controller gets an event and
  create LVM volume on desired volume group and marks LVM volume resource status as `Ready`.
- After watching `Ready` status CSI driver will return success response to `CreateVolume` gRPC
  request.

#### How can be volume shared between multiple instances

- During application mount time i.e `NodePublishVolume` request CSI driver will verify whether
  underlying LVM volume is already mounted or not. If volume is already mounted then driver will
  verify whether target path is same as mounted path if both are different then driver will allow
  mounting of volume only when `spec.shared` is set else an error will be returned. In case if the
  target path and mounted path same then success response will be returned.

```go
// VolumeInfo defines LVM info
type VolumeInfo struct {

	// OwnerNodeID is the Node ID where the volume group is present which is where
	// the volume has been provisioned.
	// OwnerNodeID can not be edited after the volume has been provisioned.
	OwnerNodeID string `json:"ownerNodeID"`

	// VolGroup specifies the name of the volume group where the volume has been created.
	VolGroup string `json:"volGroup"`

	// VgPattern specifies the regex to choose volume groups where volume
	// needs to be created.
	VgPattern string `json:"vgPattern"`

	// Capacity of the volume
	Capacity string `json:"capacity"`

	// Shared specifies whether the volume can be shared among multiple pods.
	// If it is not set to "yes", then the LVM LocalPV Driver will not allow
	// the volumes to be mounted by more than one pods.
	Shared string `json:"shared,omitempty"`

	// ThinProvision specifies whether logical volumes can be thinly provisioned.
	// If it is set to "yes", then the LVM LocalPV Driver will create
	// thinProvision i.e. logical volumes that are larger than the available extents.
	ThinProvision string `json:"thinProvision,omitempty"`
}
```
In above structure, Shared value controls shared property of volume.

### Usage details

1. User/Admin can configure shared value to `yes` under storageclass parameter.
```yaml
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: nvme-lvmsc
  allowVolumeExpansion: true
  provisioner: local.csi.openebs.io
  parameters:
    volgroup: "lvmvg"
    shared: "yes"
```
**Note**: If a shared field is unspecified then defaults to `No` that means volume
          can't be shared among multiple instances.

### Test Plan
- Provision multiple application instances by setting a shared property to `yes` and
  verify that all application instances should get into a running state.
- Provision multiple application instances by setting a shared property to `No`
  and verify that among multiple instances, only one should be in running state.
- Provision single application instance without specifying any shared property and
  verify that application should be able to access the volume.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
