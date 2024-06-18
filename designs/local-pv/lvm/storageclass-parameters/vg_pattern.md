---
title: LocalPV-LVM VG Pattern
authors:
  - "@pawanpraka1"
owners:
  - "@kmova"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# LocalPV-LVM Support of VG Pattern

## Table of Contents
- [LocalPV-LVM Support of VG Pattern](#lvm-localpv-support-of-vg-pattern)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
    - [Implementation Details](#implementation-details)
    - [Usage details](#usage-details)
    - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)


## Summary

This proposal charts out the workflow details to support volume group(VG)
pattern to provision LVM volume.

## Motivation

### Goals

- Able to provision LVM volume on VG name that matches to user specified pattern.

## Proposal

### User Stories

- In a multinode cluster environment, there might be a large number of VolumeGroups available
  and it is a hectic job for admin to create StorageClass per volume group. So adding support
  to specify patterns will be more helpful.

### Implementation Details

- User/Admin has to specify value of `vgpattern` in StorageClass parameters that helps in
  provisioning volume.
- During volume provisioning time external-provisioner will read key value pairs
  specified under referenced storageclass and pass information to CSI
  driver as payload for `CreateVolume` gRPC request.
- After receiving the `CreateVolume` request CSI driver will pick appropriate node based
  on scheduling attributes(like topology information, matching VG pattern name, available capacity)
  and creates LVM volume resource with node information as well as other attributes like
  VG pattern name, desired capacity information and so on.
- Once the LVMVolume resource is created corresponding node LVM volume controller reconcile
  LVM volume resource in following way:
    - LVM controller will verify existence of `Spec.VolGroup` filed,
      - If `Spec.VolGroup` field is set then LVM controller will try to create LVM volume on `spec.VolGroup`
        volume group using following command `lvcreate -L 4294967296b -n <volume-name> <volume_group_name>`.
        If LVM volume creation is successful then LVM Volume resource status is updated
        to `Ready` else it is updated to `Failed`.
      - If `Spec.VgPattern` filed is set then the LVM controller will find the best fit volume group(that matches
        to a given pattern as well as least amount of free space available that fits to serve request) and update
        VG name on LVM volume resource and then it creates a volume. After successful creation of volume LVM
        volume resource status is updated to `Ready`.
- After watching `Ready` status CSI driver will return a success response to `CreateVolume` gRPC
  request.

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

### Usage details

1. User/Admin can configure vgpattern under storageclass parameter.
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvm
provisioner: local.csi.openebs.io
parameters:
  storage: "lvm"
  vgpattern: "lvmvg.*"
```

### Test Plan
- Provision volume by specifying unavailable volume group pattern and
  verify that volume should not get provisioned.
- Provision volume by specifying valid volume group name pattern and verify
  that volume should get provisioned.
- Provision volume and trigger deletion of a corresponding volume group and verify
  that volume should remain in pending state.
- Provision volume with capacity more than available capacity of volume group.
  Once PVC remains in pending state expanding volume group and verify that
  volume should get provisioned.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives
NA
