---
oep-number: CStor Backup and Restore REV2
title: Non incremental scheduled backups for cstor volume
authors:
  - "@mynktl"
owners:
  - "@kmova"
  - "@mittachaitu"
  - "@mynktl"
editor: "@mynktl"
creation-date: 2021-06-22
last-updated: 2021-06-22
status: provisional
---

# Non incremental scheduled backup for cstor

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Summary](#summary)
- [Goals](#goals)
- [Proposal](#proposal)
  - [User Stories](#user-stories)
    - [Create a scheduled non-incremental backup for CStorVolumes](#create-a-scheduled-non-incremental-backup-for-cstorvolumes)
    - [Create a restore from scheduled backup for CStorVolumes](#create-a-restore-from-scheduled-backup-for-cstorvolumes)
  - [Proposed Implementation](#proposed-implementation)
  - [High Level Design](#high-level-design)
  - [Low Level Design](#low-level-design)
    - [Backup design changes](#backup-design-changes)
    - [Restore design changes](#restore-design-changes)
  - [Upgrade](#upgrade)



## Summary
This design is to implement non incremental scheduled backups for cstor volumes. This design covers changes to be made in velero-plugin and cstor-operator to support this feature. Existing design creates incremental snapshot for scheduled backup where base backup will be full backup of cstor volume and subsequent incremental backup will include only changes from previous backup. This proposal is to extend this behavior and support non-incremental backup for backup schedules.

## Goals
Create velero scheduled to backup cstor volume periodically.

## Proposal
### User Stories
#### Create a scheduled non-incremental backup for CStorVolumes
I should be able to create scheduled backup to backup cstor volume periodically.

#### Create a restore from scheduled backup for CStorVolumes
I should be able to restore the backup created using the backup schedule.

### Proposed Implementation
For non-incremental backups using schedule
On scheduled backup creation,velero-plugin will send request to cstor-operator to create backup with full backup flag set
Cstor-operator will create a CstorBackup resource with empty PrevSnapName
For restore of non-incremental scheduled backup
To restore non-incremental scheduled backup, `restoreAllIncrementalSnapshots` needs to be set to false. `autoSetTargetIP` can be set to `true` to automatically set the targe-tip in CVR

### High Level Design
User will create a volumesnapshotlocation with `disableIncrementalBackups` set to true. Default value for this parameter will be set to false.

```yaml
apiVersion: velero.io/v1
kind: VolumeSnapshotLocation
metadata:
  name: location_1
  namespace: velero
spec:
  provider: openebs.io/cstor-blockstore
  config:
    bucket: test
    provider: gcp
    restoreAllIncrementalSnapshots: "false"
    autoSetTargetIP: “true”
    disableIncrementalBackups: “true”
```

User will create the schedule using above volumesnapshotlocation

### Low Level Design
#### Backup design changes
1. Velero-plugin create backup
To create backup, the velero server executes `CreateSnapshot` api of velero-plugin with backup information. `CreateSnapshot` will execute following steps:

Backup the PVC to cloud storage
Execute the REST API(POST `/latest/backups`) of cstor-operator with CstorBackup resource with `disableIncrementalBackups` set to `true`
Check backup upload status using `checkBackupStatus`
On backup completion, `cleanupCompletedBackup` will delete the snapshot created by backup

Modify existing CstorBackup schema to add new parameter `DisableIncrementalBackups` under `CStorBackupSpec`.

Modified CstorBackup schema will be as below:

```go
// CStorBackup describes a cstor backup resource created as a custom resource
type CStorBackup struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`
    Spec              CStorBackupSpec   `json:"spec"`
    Status            CStorBackupStatus `json:"status"`
}

// CStorBackupSpec is the spec for a CStorBackup resource
type CStorBackupSpec struct {
    // BackupName is a name of the backup or scheduled backup
    BackupName string `json:"backupName"`

    // VolumeName is a name of the volume for which this backup is destined
    VolumeName string `json:"volumeName"`

    // SnapName is a name of the current backup snapshot
    SnapName string `json:"snapName"`

    // PrevSnapName is the last completed-backup's snapshot name
    PrevSnapName string `json:"prevSnapName"`

    // BackupDest is the remote address for backup transfer
    BackupDest string `json:"backupDest"`

    // LocalSnap is flag to enable local snapshot only
    LocalSnap bool `json:"localSnap"`

    // DisableIncrementalBackups is flag to disable incremental backup
     DisableIncrementalBackups bool `json:”disableIncrementalBackups”`
}
```

2. Cstor-operator backup request handling
`/latest/backups` API endpoint handles the backup request. Execution steps for `/latest/backups` endpoint will be as follow:
Create a snapshot for cstor volume
Find the healthy CVR to upload the snapshot
If `DisableIncrementalBackups` is set to true then create a CstorBackup resource with `PrevSnapName` set to empty
 
#### Restore design changes
1. Velero create restore
To create a restore, the velero server executes `CreateVolumeFromSnapshot` api of velero-plugin with backup information. To restore non-incremental backup, created using schedule, `restoreAllIncrementalSnapshots` needs to be set to `false`. 

Sample volumesnapshotlocation config is as below to restore non-incremental scheduled backups.

```yaml
apiVersion: velero.io/v1
kind: VolumeSnapshotLocation
metadata:
  name: location_1
  namespace: velero
spec:
  provider: openebs.io/cstor-blockstore
  config:
    bucket: test
    provider: gcp
    restoreAllIncrementalSnapshots: "false"
    autoSetTargetIP: “true”
    disableIncrementalBackups: “true”
```

### Upgrade
This proposal adds changes to `CstorBackup` resource which is being used by velero-plugin and cstor-operator. This requires the cstor-operator and velero-plugin to be at the same version to support this feature.

Since we are adding new parameters in `CstorBackup` and volumesnapshotlocation config, the older version of velero-plugin and cstor-operator doesn’t require any special handling during upgrade.

