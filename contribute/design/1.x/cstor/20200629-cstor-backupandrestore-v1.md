---
oep-number: CStor Backup and Restore REV2
title: Migration of CStor Backup and Restore Resources to V1
authors:
  - "@mittachaitu"
  - "@sonasingh46"
owners:
  - "@kmova"
  - "@vishnuitta"
  - "@mynktl"
editor: "@mittachaitu"
creation-date: 2020-06-29
last-updated: 2020-06-29
status: provisional
---

# Migration of CStor Backup and Restore Resources to V1

## Table of Contents

- [Migration of CStor Backup and Restore Resources to V1](#migration-of-cstor-backup-and-restore-resources-to-v1)
	- [Table of Contents](#table-of-contents)
	- [Introduction](#introduction)
	- [Motivation](#motivation)
		- [Goals](#goals)
		- [Non-Goals](#non-goals)
	- [Proposal](#proposal)
		- [Proposed Approaches](#proposed-approaches)
		- [Steps to perform user stories](#steps-to-perform-user-stories)
		- [Low Level Design](#low-level-design)
			- [Work Flow](#work-flow)
				- [Current State of Schemas](#current-state-of-schemas)
				- [Proposed Schemas](#proposed-schemas)
				- [Migration Workflows](#migration-workflows)
					- [Approach1(With Backward compatibility)](#approach1with-backward-compatibility)
					- [Cons](#cons)

## Introduction

CStor Backup and Restore functionality is supported by a set of OpenEBS CRs and OpenEBS Velero plugin. On a high level, the backup and restore requests are initiated by Velero and there is an OpenEBS Velero plugin that intercepts the request and does a REST call to one of the OpenEBS components with a payload. The REST server finally provisions the required CRs by processing the information passed in the payload. Once the CRs are created/deleted, the controller components of the OpenEBS control plane converge to the intent specified in the CRs by making calls to the data layer.

The following are the CRs that facilitates Backup and Restore:
- CStorBackup			-- (Reconciled by Backup controller in pool manager)
- CStorRestore			-- (Reconciled by Restore controller in pool manger)
- CStorCompletedBackup	-- (Used to store last completed and second last completed backup information which is used for scheduled backups)

A detailed description on how cStor Backup and Restore works is out of the scope of this document. For more details to know how the cStor backup and restore works, please click [here](https://github.com/openebs/openebs/blob/master/contribute/design/1.x/cstor/20200511-cstor-backupandrestore.md)

## Motivation

- Promote backup and restore CRs to V1 version of cstor.openebs.io group which provides backup and restore support of cStor CSI volumes.

### Goals

- Freeze the schema of all the CRs related to cStor Backup and Restore.
- Move the CRs to the cstor.openebs.io  group from the existing openebs.io group.
- The CRs in  cstor.openebs.io will be in v1 version.
- Workflow for migration of existing Backup and Restore(i.e. openebs.io group and v1alpha1 API version ) to cstor.openebs.io group and v1 API version should be provided without any downtime and with backward compatibility.

### Non-Goals

- Non-CSI based volumes will not deal with a new version of backup and restore. It will continue with the existing version of backup and restore.

## Proposal

### Proposed Approaches

- Backward compatibility to support any version of backup and restore.

  Example:
  |   CVC-Operator Version    | Pool-Manager Version  |
  |  ------------------------ | --------------------  |
  |   1.11.0                  |  1.11.0               |
  |   >= 1.12.0               |  >= 1.12.0            |

*Note:*

_CVC-Operator and pool-manager version **< 1.11.0** will not support Backup and Restore_

### Steps to perform user stories

- User need to install or upgrade the CSPC based cStor pools to atleast 1.12.0
- SPC based cStor pools and Non-CSI volumes should migrate to 1.12.0 version of CSPC-Operater to get v1 version of Backup and Restore.

### Low Level Design

#### Work Flow

##### Current State of Schemas

Following is the existing CStorBackup schema in go struct:
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
}

// CStorBackupStatus is to hold status of backup
type CStorBackupStatus string
```

Following is the existing CStorRestore schema in go struct:
```go
// CStorRestore describes a cstor restore resource created as a custom resource
type CStorRestore struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"` // set name to restore name + volume name + something like csp tag
	Spec              CStorRestoreSpec            `json:"spec"`
	Status            CStorRestoreStatus          `json:"status"`
}

// CStorRestoreSpec is the spec for a CStorRestore resource
type CStorRestoreSpec struct {
	RestoreName   string            `json:"restoreName"` // set restore name
	VolumeName    string            `json:"volumeName"`
    // RestoreSrc can be ip:port in case of restore from remote or volumeName in case of local restore
	RestoreSrc    string            `json:"restoreSrc"`
	MaxRetryCount int               `json:"maxretrycount"`
	RetryCount    int               `json:"retrycount"`
	StorageClass  string            `json:"storageClass,omitempty"`
	Size          resource.Quantity `json:"size,omitempty"`
    // Local will be helpful to identify whether restore is from local (or) backup/snapshot
	Local         bool              `json:"localRestore,omitempty"`
}

// CStorRestoreStatus is to hold result of action.
type CStorRestoreStatus string
```

Following is the existing CStorCompletedBackup schema in go struct:
```go
// CStorCompletedBackup describes a cstor completed-backup resource created as custom resource
type CStorCompletedBackup struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`
    Spec              CStorBackupSpec `json:"spec"`
}
```

##### Proposed Schemas

Following is the proposed CStorBackup schema in go struct:
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
}

// CStorBackupStatus is to hold status of backup
type CStorBackupStatus string
```

Following is the proposed CStorRestore schema in go struct:
```go
// CStorRestore describes a cstor restore resource created as a custom resource
type CStorRestore struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"` // set name to restore name + volume name + something like csp tag
	Spec              CStorRestoreSpec            `json:"spec"`
	Status            CStorRestoreStatus          `json:"status"`
}

// CStorRestoreSpec is the spec for a CStorRestore resource
type CStorRestoreSpec struct {
	// RestoreName holds restore name
	RestoreName string `json:"restoreName"`
	// VolumeName is used to restore the data to corresponding volume
	VolumeName string `json:"volumeName"`
	// RestoreSrc can be ip:port in case of restore from remote or volumeName
	// in case of local restore
	RestoreSrc    string `json:"restoreSrc"`
	MaxRetryCount int    `json:"maxretrycount"`
	RetryCount    int    `json:"retrycount"`
	// StorageClass represents name of StorageClass of restore volume
	StorageClass string            `json:"storageClass,omitempty"`
	Size         resource.Quantity `json:"size,omitempty"`
	// Local defines whether restore is from local/remote
	Local bool `json:"localRestore,omitempty"` // if restore is from local backup/snapshot
}

// CStorRestoreStatus is to hold result of action.
type CStorRestoreStatus string
```

Following is the proposed CStorCompletedBackup schema in go struct:
```go
// CStorCompletedBackup describes a cstor completed-backup resource created as custom resource
type CStorCompletedBackup struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`
    Spec              CStorCompletedBackupSpec `json:"spec"`
}

// CStorCompletedBackupSpec is the spec for a CStorBackup resource
type CStorCompletedBackupSpec struct {
	// BackupName is a name of the backup or scheduled backup
	BackupName string `json:"backupName"`

	// VolumeName is a name of the volume for which this backup is destined
	VolumeName string `json:"volumeName"`

	// SecondLastSnapName is a name of the second last completed-backup's snapshot
	SecondLastSnapName string `json:"secondLastSnapName"`

	// LastSnapName is the last completed-backup's snapshot name
	LastSnapName string `json:"lastSnapName"`
}
```

From existing to proposed has only one schema change i.e CStorCompletedBackupSpec has been introduced. Previously spec of CStorCompletedBackup is same as CStorBackup Spec. Since spec of CStorBackup doesn't fit for CStorCompletedBackup usability issues has been raised. To incorporate and decouple specs of both resources a new spec i.e `CStorCompletedBackupSpec` has been introduced. Now CStorCompletedBackup will hold CStorCompletedBackupSpec as a spec of it.

##### Migration Workflows

###### Approach1(With Backward compatibility)

- Converting group and version of cStor backup and restore resources from `openebs.io/v1alpha1` to `cstor.openebs.io/v1` will break the support of backup and restore if control plane(CVC-Operator) alone is upgraded to latest version i.e 1.12.0 and data plane(cStor pools) is in lower version i.e 1.11.0. When control plane is upgraded it will understand `cstor.openebs.io` group but data plane is in old version so it will understand `openebs.io` group. To fix compatibility issues OpenEBS(CVC-Operator) needs to support backward compatibility for alpha features(backup and restore).
- How can we fix backward compatibility? We can achieve it by following steps:
  1. Whenever a CVC-Operator needs to perform CRUD request on backup and restore endpoints it will find the version of cStor pool by using payload(based on volume it will fetch CVR and using CVR labels CSPI info can be fetched) which was sent during request and takes a decision on which group it has to perform CRUD operations. For example if pool version is equal to 1.11.0 then CVC-Operator will make use `openebs.io` group client or if pool version is 1.12.0 then it will make use of `cstor.openebs.io` group.
  2. Migration of  group and versions of cStor backup and restore resources will be done during cStor pool(CSPC) upgrade time from 1.11.0 to later versions using upgrade job.

###### Cons

- Code needs to hold old and new group APIs to support backward compatibility.
- If CSP.Version.Status.Current is not equal to CSP.Version.Desired value then backup and restore endpoint of CVC-Operator will return error saying upgrade is in progress and can't perform backup/restore at this point.

*NOTE:*
- Upgrade/migrate is not atomic process there were three steps involved to upgrade/migrate:
  1. Control plane upgrades.
  2. CStor pools upgrade/migrate.
  3. CStor Volumes upgrade/migrate.
