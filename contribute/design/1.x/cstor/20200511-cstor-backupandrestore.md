---
oep-number: CStor Backup and Restore REV1
title: Backup and Restore for V1 version of CStorVolumes
authors:
  - "@mynktl"
  - "@mittachaitu"
owners:
  - "@kmova"
  - "@vishnuitta"
  - "@mynktl"
editor: "@mittachaitu"
creation-date: 2020-05-11
last-updated: 2020-06-12
status: provisional
---

# Backup and Restore for V1 version of CStorVolumes

## Table of Contents

- [Backup and Restore for V1 version of CStorVolumes](#backup-and-restore-for-v1-version-of-cstorvolumes)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
      - [Create a backup for CStorVolumes](#create-a-backup-for-cstorvolumes)
      - [Create a restore for backuped CStorVolumes](#create-a-restore-for-backuped-cstorvolumes)
      - [Scheduled backup of CStorVolumes](#scheduled-backup-of-cstorvolumes)
    - [Proposed Implementation](#proposed-implementation)
      - [CVC-Operator REST Interface](#cvc-operator-rest-interface)
    - [Steps to perform user stories](#steps-to-perform-user-stories)
    - [Low Level Design](#low-level-design)
      - [Work Flow](#work-flow)
        - [Velero Server sends CreateSnapshot Request](#velero-server-sends-createsnapshot-request)
        - [Velero Server Sends DeleteSnapshot Request](#velero-server-sends-deletesnapshot-request)
        - [Velero Server Sends CreateVolumeFromSnapshot Request](#velero-server-sends-createvolumefromsnapshot-request)
        - [Accessing CVC REST Endpoint](#accessing-cvc-rest-endpoint)
        - [Velero Server Sends DeleteSnapshot Request](#velero-server-sends-deletesnapshot-request-1)
        - [Work flow in backup controller](#work-flow-in-backup-controller)
        - [Work flow in restore controller](#work-flow-in-restore-controller)
  - [Design Details](#design-details)
    - [CStorBackup Schema](#cstorbackup-schema)
    - [CStorRestore Schema](#cstorrestore-schema)
    - [CStorCompletedBackup Schema](#cstorcompletedbackup-schema)

## Summary

This proposal brings out the design details to implement backup and restore
solution for V1 version of CStorVolumes.

## Motivation

- Create a backup of the cStor persistent volume to the desired storage location(
  this can be AWS, GCP or any storage provider). This backup will be either on-demand or scheduled backup.
- Restore this backup to the same cluster or another cluster.

### Goals

- Solution to create an on-demand backup of cStor persistent volumes.
- Solution to create an on-demand restore of backuped up cStor persistent volumes.
- Solution to create a scheduled backup of cStor persistent volumes.
- Solution to create an incremental/differential backup of cStor persistent volumes. With incremental/differential backup, the user will be able to save backup storage space and it 

### Non-Goals

- Supporting local backup and restore.

## Proposal

### User Stories

#### Create a backup for CStorVolumes
As an OpenEBS user, I should be able create a backup for CStorVolumes.

#### Create a restore for backuped CStorVolumes
As an OpenEBS user, I should be restore a backuped CStorVolumes.

#### Scheduled backup of CStorVolumes
As an OpenEBS user, I should be able to create a scheduled backups for CStorVolumes.

### Proposed Implementation

#### CVC-Operator REST Interface

The volume management api like create, delete, snapshot, clone etc have moved from m-apiserver to CVC-Operator as part of supporting the CSI Driver. REST API of Maya-ApiServer to trigger backup/restore also needs to be implemented in the CVC operator as these APIs are using volume snapshot/clone API. Currently CVC Operator only supports declarative API via CRs, but plugin requires imperative API(REST API). The proposal is to implement a REST server within CVC-Operator to perform velero-plugin operations. The velero-plugin should identify the type of the volume and forward the REST API requests to the CVC Operator.

Velero-plugin execute different REST API of CVC-Apiserver based on the type-of-request/API from velero.

### Steps to perform user stories

- User can create backup using velero CLI

Example:
```sh
velero backup create <BACKUP_NAME> --include-namespaces=<NAME_SPACE> --snapshot-volumes –volume-snapshot-locations=<SNAPSHOT_LOCATION>
```
- User can resotre a backup using velero CLI

Example
```
velero restore create --from-backup <BACKUP_NAME> --restore-volumes=true
```

### Low Level Design

#### Work Flow

##### Velero Server sends CreateSnapshot Request

Velero server sends CreateSnapshot API with volumeID to create the snapshot. Velero Interface will execute `CreateSnapshot` API of the cStor velero-plugin controller.

cStor velero-plugin controller is responsible for executing below steps:
1.  BackUp the relevant PVC object to the cloud provider.
2.  Execute the REST API(POST `/latest/backups`) of CVC-Operator (This object will include the IP Address of snapshot receiver/sender module) to create backup.
    1.  Create a snapshot using volume name and snapshot name(which will get during the    CreateSnapshot request).
    2.  If the request is to create `local backup` then return from here else continue with other steps.
    3.  Find the Healthy cStorVolumeReplica if it doesn't exist return error.
    4.  Create CStorCompletedBackUp resources if it doesn’t exist(Intention of creating this resource is used for incremental backup purpose).
    5.  Create CStorBackUp resource by populating the current snapshot name and previous snapshot name(if exists from CStorCompletedBackUp) with Healthy CStorVolumeReplica pool UID.
    6.  Corresponding backup controllers exist in pool-manager will responsible for sending the snapshot data from pool to velero-plugin         and velero-plugin will write this stream to cloud-provider.
3. Call cloud interface API `UploadSnapshot` which will upload the backup to the cloud provider.
4. This API will return the unique ‘snapshotID’ (volumeID + "-velero-bkp-" + backupName) to the velero server. This ‘snapshotID’ will be used to refer to the backup snapshot.

##### Velero Server Sends DeleteSnapshot Request

Velero server sends `DeleteSnapshot` API of Velero Interface to delete the backup/snapshot with argument `snapshotID`. This snapshotID is generated during the backup creation of this snapshot. Velero Interface will execute the DeleteSnapshot API of cStor velero-plugin. cStor velero-plugin is responsible for performing below steps:
1.  Delete the PVC object for this backup from the cloud provider.
2.  Execute REST API(`latest/backups/`) of the CVC-Operator to delete the resources created for this particular backup.
    1.  Delete the CStorCompletedBackUp resources if the given cstorbackup is the last backup of schedule or cstorcompletedbackup doesn't have any successful backup.
    2.  Delete the snapshot created for that backup.
    3.  Delete the CStorBackUp resource.
3. Execute the `RemoveSnapshot` API of the cloud interface to delete the snapshot from the cloud provider.

##### Velero Server Sends CreateVolumeFromSnapshot Request

Velero Server will execute the `CreateVolumeFromSnapshot` API of the velero interface to restore the backup with the argument (snapshotID, volumeType). Velero interface will execute `CreateVolumeFromSnapshot` API of velero-plugin. velero-plugin will perform following below steps:
1.  Download the PVC object from the cloud provider through a cloud interface and deploy the PVC. If PVC already exists in the cluster then skip the PVC creation. (only for remote restore)
2.  Check If PVC status is bounded. (Only for remote restore)
3.  Execute the REST API(`latest/restore`) with CVC-Operator restore details(includes the   IP address of snapshot receiver/sender module) to initiate the restore of the snapshot.
    1.  Create CVC with clone configuration(i.e CVC will hold source volume and snapshot information in spec) only if the restore request is local restore and for remote restore velero-plugin creates PVC with annotation `openebs.io/created-through: restore` then CSI-Provisioner will propogate this annotation to CVC and then CVC-controller will create CVR with annotation `isRestoreVol: true` only if `openebs.io/created-through` annotation is set. If CVR contains annotation `isRestoreVol: true` then CVR controller will skip setting targetIP(targetIP helpful for replica to connect to target to serve IOs).
    2.  Wait till CVC comes to Bound state(blocking call and it will be retried for 10 seconds at interval of 2 seconds in case if it is not Bound).
    3.  Create a replica count number of restore CR’s which will be responsible for dumping backup data into the volume dataset.
4. Call cloud interface API `RestoreSnapshot` to download the snapshot from the cloud provider.

##### Accessing CVC REST Endpoint

- One can access the REST endpoint of CVC by fetching the details of CVC-Operator service. Below command will be help to get the CVC-Operator service
```sh
  kubectl get service -n <openebs_namespace> -l openebs.io/component-name: cvc-operator-svc
```

##### Velero Server Sends DeleteSnapshot Request

Restore delete will delete restore resource object only.

Note: It will not delete the resources restored in that restore(ex: PVC).

##### Work flow in backup controller

When REST API `/latest/backups` is executed it creates CStorBackUp CR with `Pending` status. Backup controller which present in pool-manager will get event and perform the following operations:
1.  Update the CStorBackUp status to `Init`(which conveys controller instantiate process).
2.  In next reconciliation update the Status of CStorBackUp resource as `InProgress`(Which will help to understand the backup process is started).
3.  Execute the below command and ZFS will send the data to `sender/receiver module`(blocking call and this command execution will be retried for 50 seconds at interval of 5 seconds in case of errors).

CMD:
1.  If request is for full backup then command is `zfs send <snapshot_dataset_name> | nc -w 3 <ip_address> <port>`
2.  If request is for incremental backup then command is `zfs send -i <old_snapshot_dataset_name> <new_snapshot_dataset_name> | nc -w 3 <ip_address> <port>`
3.  Updates the corresponding CStorCompletedBackups with last two completed backups. For example, if schedule `b` has last two backups b-0 and b-1 (b-0 created first and after that b-1 was created) having snapshots
  b-0 and b-1 respectively then CStorCompletedBackups for the schedule `b` will have following information :
```go
   CStorCompletedBackups.Spec.PrevSnapName =  b-1
   CStorCompletedBackups.Spec.SnapName = b-0
```
NOTE: ip_address and port are the IP Address and port of snapshot sender/receiver module.

##### Work flow in restore controller

When REST API `/latest/restore` is executed it creates CStorRestore CR with `Pending` status. Restore controller which present in pool-manager will get event and perform the following operations:
1.  Update the CStorRestore status to `Init`(which conveys controller instantiate process).
2.  Update the status of CStorRestore resource as `InProgress`(Which will help to understand the restore process is started).
3.  Execute the below command and ZFS will receive the data from `sender/receiver module`(blocking call and this command execution will be retried for 50 seconds at interval of 5 seconds in case of errors).

CMD: `nc -w 3 <ip_address> <port> | zfs recv -F <volume_dataset_name>`

NOTE: ip_address and port are the IP Address and port of snapshot sender/receiver module.

## Design Details

### CStorBackup Schema
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

// Status written onto CStorBackup objects.
const (
	// BKPCStorStatusDone , backup is completed.
	BKPCStorStatusDone CStorBackupStatus = "Done"

	// BKPCStorStatusFailed , backup is failed.
	BKPCStorStatusFailed CStorBackupStatus = "Failed"

	// BKPCStorStatusInit , backup is initialized.
	BKPCStorStatusInit CStorBackupStatus = "Init"

	// BKPCStorStatusPending , backup is pending.
	BKPCStorStatusPending CStorBackupStatus = "Pending"

	// BKPCStorStatusInProgress , backup is in progress.
	BKPCStorStatusInProgress CStorBackupStatus = "InProgress"

	// BKPCStorStatusInvalid , backup operation is invalid.
	BKPCStorStatusInvalid CStorBackupStatus = "Invalid"
)
```

### CStorRestore Schema
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

// Status written onto CStrorRestore object.
const (
	// RSTCStorStatusEmpty ensures the create operation is to be done, if import fails.
	RSTCStorStatusEmpty CStorRestoreStatus = ""

	// RSTCStorStatusDone , restore operation is completed.
	RSTCStorStatusDone CStorRestoreStatus = "Done"

	// RSTCStorStatusFailed , restore operation is failed.
	RSTCStorStatusFailed CStorRestoreStatus = "Failed"

	// RSTCStorStatusInit , restore operation is initialized.
	RSTCStorStatusInit CStorRestoreStatus = "Init"

	// RSTCStorStatusPending , restore operation is pending.
	RSTCStorStatusPending CStorRestoreStatus = "Pending"

	// RSTCStorStatusInProgress , restore operation is in progress.
	RSTCStorStatusInProgress CStorRestoreStatus = "InProgress"

	// RSTCStorStatusInvalid , restore operation is invalid.
	RSTCStorStatusInvalid CStorRestoreStatus = "Invalid"
)
```

### CStorCompletedBackup Schema
Following is the existing CStorCompletedBackup schema in go struct:
```go
// CStorCompletedBackup describes a cstor completed-backup resource created as custom resource
type CStorCompletedBackup struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`
    Spec              CStorBackupSpec `json:"spec"`
}
```
