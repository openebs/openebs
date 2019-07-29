---
oep-number: Backup 0001
title: Asynchronous backup of CStor Snapshot
authors:
  - "@mynktl"
owners:
  - "@amitd"
  - "@kmova"
  - "@vishnuitta"
editor: "@mynktl"
creation-date: 2019-07-23
last-updated: 2019-07-23
status: provisional
---

# Asynchronous backup of CStor Snapshot

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Current approach](#current-implementation)
* [Motivation](#motivation)
    * [Goals](#goals)
* [Proposal](#proposal)
    * [CStorBackup Spec](#spec-of-cstorbackup)
    * [Maya-ApiServer REST Interface](#new-rest-interface)
    * [Uploading of snapshot](#handling-of-backup-cr-at-csp)
      * [Handling of upload failure](#handling-of-error)
* [Upgrade](#upgrade)

## Summary

This proposal brings out the design details to implement asynchronous backup
solution for CStor Volume's snapshot.

## Current Implementation
As of now, uploading of CStor Snapshot is handled by `velero-plugin`.
When velero execute a snapshot request for a volume, `velero-plugin` will execute
the REST interface `/latest/backup` of Maya-apiserver, which will create a
snapshot for the given volume and upload it to the provided cloud-provider.
Uploading of a snapshot is backed by CStor-Pool-Management container(referenced
as `CSP` in further doc).
CSP container will send the snapshot data to `velero-plugin` and `velero-plugin`
will write this stream to the provided cloud-provider.

## Motivation

Existing backup support for CStor Volume through Velero is not asynchronous.
So, if user is having more than one CStor Volume then backup will consume more
time.
With asynchronous backup, user don't need to wait for backup completion. Since
backups are asynchronous, multiple snapshot can be uploaded in parallel.

### Goals

- Solution to upload CStor snapshot asynchronously.

## Proposal
#### Spec of CStorBackup
```
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

	// AsyncBackup is to check if backup is async or not
	AsyncBackup bool `json:"async"`

	// CloudCred is a map of cloud provider configuration
	CloudCred map[CloudKey]string `json:"cloudCred"`
}
```

#### New REST interface
As of now, `Maya-apiserver` have `/latest/backup` interface which execute
following task on POST request:
  - Create a snapshot for given PV
  - Create a CStorBackup CR for given backup and PV using relevant last
    CStorCompletedBackup CR.

We will leave this interface as it is and add new interface `/latest/upload`
which will process the backup request for CStor Snapshot. Sample data for POST
request will be as below :
```
{
   "spec" : {
      "backupName" : "testbackup",
      "cloudCred" : {
         "region" : "ap-south-1",
         "provider" : "aws",
         "secret" : "aws-cloud-credentials",
         "bucket" : "backup-bucket"
      },
      "async" : true,
      "snapName" : "testbackup",
      "volumeName" : "test-vol1"
   },
   "metadata" : {
      "namespace" : "openebs",
   }
}
```

This interface will execute following task:
  - If `AsyncBackup` is set and backup is scheduled backup then interface will
    check if previous backups for this schedule are completed or not.
      - If previous backups are completed then only, backup request should be
        executed.
      - If previous backups are not completed then backup request should fail.
  - Create a CStorBackup CR for given backup and PV using relevant last
    CStorCompletedBackup CR.

_**Note:**_

_**- This interface requires that snapshot should exist.**_

_**- secret should be created in operator namespace**_

#### Handling of Backup CR at CSP
On receiving a new event for CStorBackup, CSP will send the snapshot data to
cloud provider as mentioned in `CStorBackupSpec.CloudCred`.

##### Handling of error
- If `AsyncBackup` is set then CSP will retry the uploading of snapshot until
  it succeed.
- If `AsyncBackup` is not set then CSP will not retry the uploading of snapshot.

Once the uploading is done, CSP will update the status of CStorBackup CR and
update the `PrevSnapName` in relevant CStorCompletedBackup CR.


## Upgrade

For this proposal, no additional steps required for upgrade.

This proposal also supports synchronous backup, in old way, so it will not break
the old configuration.

