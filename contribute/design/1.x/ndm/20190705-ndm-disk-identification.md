---
oep-number: NDM 0001
title: Uniquely identify disk in cluster
authors:
  - "@akhilerm"
owners:
  - "@gila"
  - "@kmova"
  - "@vishnuitta"
editor: "@akhilerm"
creation-date: 2019-07-05
last-updated: 2020-09-01
status: provisional
---

# Disk Identification using NDM

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories(#user-stories)
      * [Identify a physical disk](#identify-a-physical-disk)
      * [Identify a virtual disk](#identify-a-virtual-disk)
    * [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
      * [Current Implementation](#current-implementation)
      * [Shortcomings of current implementation](#shortcomings-of-current-implementation)
      * [Proposed Implementation](#proposed-implementation)
      * [Workflow](#workflow)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This proposal brings out the design details to implement a Disk identification
solution which can be used to uniquely identify a disk across the cluster.

## Motivation

Uniquely identifying a disk across a cluster is a major challenge which needs to 
be tackled. The identification is necessary, due to the fact that disk can move
from node to node and even attached to different ports on the same node. The unique
identification solution will help the consumers of NDM to track the disk
and thus the data movement within the cluster.

### Goals

- Configurable device detection mechanism
- A unique disk identification mechanism that will work across the cluster on
  disks having atleast a GPT label
- Should be able to identify same disk attached at multiple paths.
- Should be able to generate separate IDs for partitions

### Non-Goals

- Identification of disk attached to 2 nodes at the same time

## Proposal

### User Stories

#### Identify a physical disk
NDM should be able to generate a unique id for a physical disk attached to the node
and this id should not change even if the disk is attached at a different port on the
same host or moved to a different node or altogether moved to a different cluster.

#### Identify a virtual disk
NDM should be able to generate a unique id for Virtual Disks(which may not have all 
relevant information in VPD). This id should also persist between restarts of the node,
attaching to a different machine or a different SCSI port of the same machine.

### Implementation Details/Notes/Constraints

The implementation details for the disk identification. The current implementation 
works well for physical disks which have a unique WWN and model assigned by the 
manufacturer. But the implementation fails for `Virtual_disk`, because the fields
are provider dependent and are not guaranteed to be unique. 

#### Current Implementation
The following data is fetched from the disk: 
1. `ID_WWN`
2. `ID_MODEL`
3. `ID_SERIAL_SHORT`
4. `ID_VENDOR`
5. `ID_TYPE`

If the `ID_MODEL` is not `Virtual_disk` or `EphemeralDisk`:
	- field 1-4 are appended
	- md5 hash of the result is generated which will be UID for the disk by NDM

If the `ID_TYPE` is empty or `ID_MODEL` is `Virtual_disk` or `EphemeralDisk`:
	- There is a chance that the values in fields 1-4 will be either empty or all 
	  the same depending on the provider.
	- fields 1-4 are appended. Along with it, the hostname and DEVNAME(`/dev/sda`) is
	  appended to the result
	- md5 hash of the result is generated which will be UID for the disk by NDM

#### Shortcomings of current implementation
In case of virtual disks, since we are using the DEVNAME for generating UID, everytime 
the same disk comes at a different path, the UID gets changed. This results in getting 
the device identified as a new disk. This will lead to data corruption as the disk that 
was being claimed by some users has now came up with a new UID, but with the old data.
Also, since this disk is now in an Unclaimed state, it will be available for others to
claim possibly leading to data loss

#### Proposed Implementation

If the disk has WWN, then a combination of WWN and Serial will be used, else a GPT
partition will be created on the disk.

##### Disk Identification using GPT partitions

This method describes the algorithm used to generate UUID for different device types:
- `disk` type
1. Check if the device has a WWN, if yes then use the combination of WWN and Serial to generate UUID

2. Else,

    1. Check if the disk has a Filesystem label available on it. This is in cases where the 
       complete disk is formatted with a filesystem without a partition table. If filesystem
       label is available we use it for generating the UUID.
    3. If WWN and FS label is not available on the disk, we create a GPT partition table on the disk,
       and then create a single partition which spans the complete disk. This new partition will
       be consumed by the users. This will help to identify a virtual disk for movements across
       the cluster also.
       
- `partition` type
1. The Partition entry ID (ID_PART_ENTRY_UUID) will be used to generate the UUID.

This will be further configurable, so that users can specify how many partition to be created etc. This
partitions will be automatically by NDM during start-up itself.

Data Cleanup:
NDM takes care of data clean up, after a BD is released from a BDC. i.e. a complete
wipe of the disk will be done `wipefs -fa`. Since in case of NDM created GPT labels, 
only partition is being wiped, it won't cause the labels to be removed.

##### Workflow
```

+-----------+           +----v-------------+        +-----------+      +-------------------+
|if DEVTYPE |           |                  |        |  Check    |      | Create GPT        |
| equals    |   No      |     If           |    No  | FS label  |  No  | partition         |
|"partition"|---------->+ WWN is present   +------->+           +----->+ table and         |
|use PART   |           |                  |        |           |      | one partition     |
|ENTRY ID   |           |                  |        |           |      | spanning the disk |
+----+------+           +------------------+        +-----------+      +-------------------+
     |                       |                           |                  |
     | Yes                   |Yes                        |                  |
     |                       |                           |Yes               |
     |                       |                           |                  |
+----v------+                |                           |                  |
|           |                |                           |                  |
|Use md5 of |                |                           |                  |
| generated |                |                           |                  |
|   UID     |<---------------+---------------------------+-------------------
|           |                        
|           |                        
+-----------+                        

```

The algorithm used for upgrading from devices using old UUID to new UUID is mentioned [here](https://gist.github.com/akhilerm/cb9cfff929bff00efaa0d3f70d25a116)

## Graduation Criteria

- NDM should be able to uniquely identify the disks, across reboots, across different
  SCSI ports and anywhere within the cluster. The unique identification can be marked
  successful, if NDM detects the disk, and the user is able to retrieve his data
  from the disk. 
  
- A mechanism to seamlessly upgrade from old UUID to new UUID.

## Implementation History

- Owner acceptance of `Summary` and `Motivation` sections - 2020-02-29
- Agreement on `Proposal` section - 2020-02-29
- Date implementation started - 2020-02-29
- First OpenEBS release where an initial version of this OEP was available - OpenEBS 1.10
- Version of OpenEBS where this OEP graduated to general availability - OpenEBS 2.0
- If this OEP was retired or superseded - YYYYMMDD

## Drawbacks

- Do not have a mechanism to identify disks that are attached in multipath mode.
- Cannot identify disks and create BDs if the same disk is connected to 2 nodes 
  at the same time.
- The partition created on the disk for identification will remain even after NDM
  is uninstalled from the node.
- Consumers of NDM will not be able to create a partition on blockdevices on which
  NDM already created a partition for identification. 

## Infrastructure Needed

- Test setup with different types of disks in different configurations to test and
  ensure the unique ID generation process.
