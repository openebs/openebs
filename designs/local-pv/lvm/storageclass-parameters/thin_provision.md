---
title: LocalPV-LVM Thin Provision
authors:
  - "@pawanpraka1"
owners:
  - "@kmova"
creation-date: 2021-06-16
last-updated: 2021-06-16
status: Implemented
---

# LocalPV-LVM Thin Provisioning

## Table of Contents
- [LocalPV-LVM Thin Provisioning](#lvm-localpv-thin-provisioning)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non Goals](#non-goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
    - [Implementation Details](#implementation-details)
    - [Usage details](#usage-details)
    - [Test Plan](#test-plan)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)


## Summary

This proposal charts out the workflow details to support creation of thin provisioned volumes.

## Motivation

### Goals

- Able to provision thin volume in user specified VolumeGroup.

### Non Goals

- Reclaiming a space from VolumeGroup if thin pool doesn't contain volumes.

## Proposal

### User Stories

- Thin provisioned volume will occupy storage only on demand and it will help a lot save cost on storage.

### Implementation Details

- User/Admin has to set `thinProvision` parameter to "yes" under storageclass parameters
  which informs driver to create thin provisioned volume.
- During volume provisioning time external-provisioner will read all key-value pairs
  that are specified under referenced storageclass and pass information to CSI
  driver as payload for `CreateVolume` gRPC request.
- After receiving the `CreateVolume` request CSI driver will pick appropriate node based
  on scheduling attributes(like topology information, matching VG name and available capacity)
  and creates LVM volume resource by setting `Spec.ThinProvision` to yes along with other properties.
- Once the LVMVolume resource is created corresponding node LVM volume controller reconcile
  LVM volume resource in the following way:
  - LVM controller will check `Spec.ThinProvision` field, if the field is set then controller
    will perform following operations:
    - Fetch information about existence of thin pool matching with volume group(`<vgname>_thinpool`).
      - If no such pool found then controller will create new pool with
        min(volume_request_size, VG_available_size) size along with thin volume.
        Command used to create thin pool & volume: `lvcreate -L <min_pool_size> -T lvmvg/lvmvg_thinpool  -V <volume_size> -n <volume_name> -y`.
      - If there is a thin pool with <vg_name>_thinpool name then controller will create thin volume.
        Command used to create thin volume: `lvcreate -T lvmvg/lvmvg_thinpool -V <volume_size> -n <volume_name> -y`
    - If thin volume creation is successfull then controller will LVM volume resource as `Ready`.
- After watching `Ready` status CSI driver will return success response to `CreateVolume` gRPC
  request.

### Usage details

1. User/Admin can configure `thinProvision` value to `yes` under storageclass parameter.
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvm
provisioner: local.csi.openebs.io
parameters:
  storage: "lvm"
  volgroup: "lvmvg"
  thinProvision: "yes"
```

### Test Plan
- Provision an application on thin volume with a capacity less than
  underlying VG size and verify volume accessibility from application.
- Provision an application on thin volume with a capacity greater than
  underlying VG size and verify volume accessibility from application.
- Provision multiple thin volumes with capacities greater than underlying
  VG size and verify volume accessibility from applications.
- Deprovision thin volume and verify that space should be reclaimed from thin pool.
 
## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks
NA

## Alternatives

The current implementation will create a new thin pool if there doesn't
exist pool with name `<vg_name>_thinpool` in specified VolumeGroup(VG). 
This approach requires additional parameters to reclaim the space when there
are no volumes exist on the pool and also adds complexities for day-2-operations 
like thin volume expansions(case where pool doesn't have enough space).

To mitigate above limitations we can hand over thin pool creation to the administrator
(or) user. Once admin/user creates a thin pool user can specify pool name (or) regex of name
in storage class(new parameter). Below is an example of a storage class with thin pool
parameter
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-thin-lvm
provisioner: local.csi.openebs.io
parameters:
  storage: "lvm"
  volgroup: "lvmvg"
  thinPool: "$lvm.*pool$"
```

- Once the user provisions a PVC by referring to the above storage class, external provisioner
  will send CreateVolume request to the CSI driver. Now, CSI driver will figure out
  nodes based on the requirement and creates LVMVolume on it.
- Corresponding LVM controller will get an event and creates a thin volume on user specified pool.

Since we are not the creator of thin pool, so it is not necessary to support all features on it.

**Limitations**:
- This approach will increase manual steps for day-1 operations, like creating a thin pool by
  figuring out an appropriate volume group(assume in larger environments it is not possible).
- User has to manually reclaim the space by deleting a thin pool(if pool doesn't contain any volumes).
- Application teams has to request admin for creation of multiple storage classes to provision thin volumes.

**Conclusion**
    Since alternative approach requires more steps to perform day1 operations it was
    decided to continue with current approach.

