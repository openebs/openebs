---
oep-number: OEP 3904
title: Add Volume Group Snapshot Feature to OpenEBS LVM
authors:
  - "@tiagolobocastro"
owners:
  - "@tiagolobocastro"
editor: TBD
creation-date: 06/04/2025
last-updated: 06/04/2025
status: provisional
---

# Add Volume Group Snapshot Feature to OpenEBS LVM

## Summary

This OEP proposes adding a Volume Group Snapshot feature to OpenEBS LVM.
This feature would enable users to create consistent snapshots of multiple volumes in a single operation.
It is designed to improve data consistency across related volumes, particularly for stateful applications with interdependent datasets.

## Motivation

Currently, OpenEBS LVM supports snapshots at the individual volume level. However, applications with multiple dependent volumes, such as distributed databases or clustered services, require simultaneous snapshots to ensure data consistency.
This limitation presents challenges for backup and disaster recovery workflows.

### Goals

- Enable users to create consistent snapshots of multiple volumes in a single operation.
- Provide compatibility with existing snapshot and backup workflows.

### Non-Goals

- Changes to the underlying storage engine beyond snapshot-related features.
- Adding Snapshot Restore workflow as part of this OEP.

## Proposal

As per the K8s docs, to implement the volume group snapshot feature, a CSI driver must:

- Implement a new group controller service.
- Implement group controller RPCs: CreateVolumeGroupSnapshot, DeleteVolumeGroupSnapshot, and GetVolumeGroupSnapshot.
- Add group controller capability CREATE_DELETE_GET_VOLUME_GROUP_SNAPSHOT.

See the [CSI spec](https://github.com/container-storage-interface/spec/blob/master/spec.md) and the [Kubernetes-CSI Driver Developer Guide](https://kubernetes-csi.github.io/docs/) for more details.

As such, I propose adding a new "Volume Group Snapshot" Custom Resource Definition (CRD) to LVM.
It may also be required to add a new field "group_id" to the existing Snapshot CRD.

### User Stories [optional]

#### Story 1

As a user, I want to take a write consistent volume group snapshot across all my application volumes.

#### Story 2

As a user, I want to delete the volume group snapshot when I don't need it.

### Implementation Details/Notes/Constraints [optional]

TODO

### Risks and Mitigations

LVM does not yet have the snapshot restore workflow implemented, that should be implemented in order to really make this feature usable without any manual LVM specific steps.

## Graduation Criteria

TODO

## Implementation History

TODO

## Drawbacks [optional]

Adds extra complexity by adding a new api and extra snapshot metadata information.

## Alternatives [optional]

User must take each snapshot individually, whilst ensuring write consistency across all volumes.
