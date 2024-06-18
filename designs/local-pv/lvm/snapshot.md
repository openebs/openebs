---
title: Snapshot Support for LocalPV-LVM
authors:
  - "@pawanpraka1"
owners:
  - "@kmova"
creation-date: 2021-06-21
last-updated: 2021-06-21
status: In Progress
---

# Snapshot Support for LocalPV-LVM

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
* [Implementation Details](#implementation-details)
* [Test Plan](#test-plan)
* [Graduation Criteria](#graduation-criteria)
* [Drawbacks](#drawbacks)

## Summary

LVM Snapshots are space efficient point in time copies of lvm volumes. It consumes the space only when changes are made to the source logical volume. This way it preserves all the data that was in the volume at the time the snapshot was created. This means that we can back up that volume without having to worry about data being changed while the backup is going on, and we don't have to take the database volume offline while the backup is taking place.

## Motivation

### Goals

- user should be able to take the snapshot
- user Should be able to reserve space for the snapshot
- user should be able to create thick and thin snapshots

### Non-Goals

- Creating clones from Snapshots
- restore of a snapshot
- expanding the snapshot
- making snapshot available to the source pod, there is a hack to make this possbile. Need to revisit this requirement for the community users.
- internals of csi-snapshotter and snapshot-controller


## Proposal

To create the k8s snapshot, we need to create a snapshot class similiar to storageclass :

```
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1
metadata:
  name: lvmpv-snapclass
  annotations:
    snapshot.storage.kubernetes.io/is-default-class: "true"
driver: local.csi.openebs.io
deletionPolicy: Delete

```

We need to create the volumesnaphot resource with the above snapshotclass. We also need to mention the pvc name in the source for which we want to create the snapshot

```
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: lvmpv-snap
spec:
  volumeSnapshotClassName: lvmpv-snapclass
  source:
    persistentVolumeClaimName: csi-lvmpvc
```

One the above resource is created, we can check the volumesnapshot CR and wait for readyToUse to be true. Once snapshot is ready, we can use this for backup or for any other purpose.

```
$ kubectl get volumesnapshot.snapshot
NAME         AGE
lvmpv-snap   2m8s
```

```
$ kubectl get volumesnapshot.snapshot lvmpv-snap -o yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"snapshot.storage.k8s.io/v1","kind":"VolumeSnapshot","metadata":{"annotations":{},"name":"lvmpv-snap","namespace":"default"},"spec":{"source":{"persistentVolumeClaimName":"csi-lvmpvc"},"volumeSnapshotClassName":"lvmpv-snapclass"}}
  creationTimestamp: "2020-02-25T08:25:51Z"
  finalizers:
  - snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
  - snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
  generation: 1
  name: lvmpv-snap
  namespace: default
  resourceVersion: "447494"
  selfLink: /apis/snapshot.storage.k8s.io/v1/namespaces/default/volumesnapshots/lvmpv-snap
  uid: 3cbd5e59-4c6f-4bd6-95ba-7f72c9f12fcd
spec:
  source:
    persistentVolumeClaimName: csi-lvmpvc
  volumeSnapshotClassName: lvmpv-snapclass
status:
  boundVolumeSnapshotContentName: snapcontent-3cbd5e59-4c6f-4bd6-95ba-7f72c9f12fcd
  creationTime: "2020-02-25T08:25:51Z"
  readyToUse: true
  restoreSize: "0" 
```

## Implementation Details

We need to implement CSI CreateSnapshot end point and also need to add CREATE_DELETE_SNAPSHOT as the supported capability to create the snapshot. Here is the entire CSI workflow

- snapshot-controller and csi-snapshotter both are sidecar in `openebs-lvm-controller` pod which watches for VolumeSnapshot object and call the CreateSnapshot grpc for the LVM driver to create the snapshot.
- once user creates the VolumeSnapshot object, the snapshotter calls the CreateSnapshot grpc in the controller to create the snapshot.
- In the CreateSnapshot, the Controller then creates a LVMSnapshot CR with the volume details for which we have to create the snapshot
- The driver's node agent daemonset will be watching for LVMSnapshot CR and will create the snapshot for the requested volume
- Once snapshot creation is successful, the controller will return successful to the CreateSnapshot call with ReadytoUse as true and then that snapshot can used for other purposes like backup or clone.

here is the high level Sequence Diagram explaining this workflow

![SnapShot Workflow](./images/snapshot.jpeg)


### Reservation

We can reserve the space for the snapshots using snapshotclass. We can mention snapSize in the parameters and specify how much space we want to reserve. We can mention size by percentage of the volume or we can also provide absolute value, the LVM Driver will reserved that much space for the snapshot.

```
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1
metadata:
  name: lvmpv-snapclass
  annotations:
    snapshot.storage.kubernetes.io/is-default-class: "true"
parameters:
  snapSize: 50%
driver: local.csi.openebs.io
deletionPolicy: Delete
```

### Thin and Thick snapshots

LVM allows us to create a thick or thin snapshots for thin provisioned volumes. For thick volume, we can only create thick snapshot. By default for thin volumes, the driver will create a thin snapshot and for thick volumes, it will create a thick snapshot. Using the `snapSize` parameter in the snapshotClass we can decide how thick a snapshot can be.

If we want to reserve the space for the snapshot created for thin volumes, we can use the snapSize parameter to decide how much space we want to reserve.


## Test Plan

- Create the snapshot for thick volumes and verify that volume group has the snapshot with size reserved same as volume size
- Create the snapshot for thick volumes when volume group is full and verify that snapshot is not successful
- Create the snapshot for thin volumes and verify that volume group has the snapshot with no size reserved for it
- Create the snapshot for thin volumes when volume group is full and verify that snapshot is created successfully
- Vefify the snapSize paramaeter with absolute value and check that correct size has been reserved for thick volumes
- Verify the snapSize paramaeter with absolute value and check that correct size has been reserved for thin volumes
- Verify the snapSize paramaeter with percentage value and check that correct size has been reserved for thick volumes
- Verify the snapSize paramaeter with percentage value and check that correct size has been reserved for thin volumes
- Verify the snapshot creation for non existing pvc and check that it fails
- Check the LVM behavior when we are exceeding the snapsize space for snapshots
- Check the perfromance of the volume after creating the snapshot
- Create multiple snapshots and verify that any modification in origianl volume gets stored in all the snapshots
- Verify original volume is working fine after creating the snapshot with and without snapsize parameter

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated

## Drawbacks

There is performance degradation when using the snapshots as it does copy on write of the modified blocks.
