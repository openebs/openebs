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
last-updated: 2019-07-08
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
    * [User Stories [optional]](#user-stories-optional)
      * [Story 1](#story-1)
      * [Story 2](#story-2)
    * [Implementation Details/Notes/Constraints [optional]](#implementation-detailsnotesconstraints-optional)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks [optional]](#drawbacks-optional)
* [Alternatives [optional]](#alternatives-optional)
* [Infrastructure Needed [optional]](#infrastructure-needed-optional)

## Summary

This proposal brings out the design details to implement a Disk identification
solution which can be used to uniquely identify a disk in the cluster. The main
aim is to identify the data.

## Motivation

Uniquely identifying a disk across a cluster is a major challenge which needs to 
be tackled. The identification is necessary, due to the fact that disk can move
from node to node and even attached to different ports on the same node. The unique
identification solution should help the NorthBound users of NDM to track the disk
and thus the data movement within the cluster.

### Goals

- A unique disk identification mechanism that will work within the cluster on
  disks having atleast a GPT label

### Non-Goals

- Identification of disks without GPT labels
- Identification of disks which removed the labels after claiming

## Proposal

### User Stories

#### Identify a physical disk
NDM should be able to generate a unqiue id for a physical disk attached to the node
and this id should not change even if the disk is attached at a different port on the
same host or moved to a different node.

#### Identify a virtual disk
NDM should be able to generate a unique id for Virtual Disks(which may not have all 
relevant information in VPD). This id should also persist between restarts of the node,
attaching to a different machine or a different SCSI port of the same machine.

### Implementation Details/Notes/Constraints

The implementation details for the disk identification. The current implementation 
works well for physical disks which have a unique WWN and model assigned by the 
manufacturer. But the implementation fails for `Virtual_disk`, because the fields
are provider dependent and are not guaranteed to be unique. Also when the disk path
changes, there is a high chance that the NorthBound consumers of NDM will use the
wrong disk and possibly corrupt the data.

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

If WWN is available on the disk, then we follow the current implementation.

If WWN is not available on the disk, then the new solution needs to be applied for
generating the UIDs

1. Check if the disk has a GPT label available on it.
	- If a GPT label is available we will use only that label for UID generation
	  of the disk. This will ensure that even if the path is changed, or the disk
	  comes up at a different node, the UID generated will be same and the disk
	  can be uniquely identified.
	- Once the GPT label is available, it is possible to identify partitions
	  also on the disk (if it exists). This will work by adding the partition
	  number along with the generated UID.
	  eg: disk-xxxx-1 (/dev/sdX1), disk-xxxx-2 (/dev/sdX2). 
	  This is guaranteed to be unique since the partition numbers won't change
	  even if the device path changes
2. If GPT label is not available on the disk, it can be logged to the user that
   "the device couldn't be identified uniquely". Either NDM itself can take up
   the GPT label creation part or ask the user to create a label so that the disk
   UID can be generated 

Data Cleanup:
NDM takes care of data clean up, after a BD is released from a BDC. i.e. a complete
wipe of the disk will be done `wipefs -fa`. This cause the GPT label to get erased.
Therefore, in such cases the cleanup job by NDM should take care of recreating the GPT
label after wiping it out, or should selectively wipe the disk.


### Risks and Mitigations

- 

## Graduation Criteria

- NDM should be able to uniquely identify the disks, across reboots, across different
  SCSI ports and anywhere within the cluster. The unique identification can be marked
  successful, if NDM detects the disk, and the user is able to retrieve his data
  from the disk

## Implementation History

Major milestones in the life cycle of a OEP should be tracked in `Implementation History`.
Major milestones might include

- the `Summary` and `Motivation` sections being merged signaling owner acceptance
- the `Proposal` section being merged signaling agreement on a proposed design
- the date implementation started
- the first OpenEBS release where an initial version of the OEP was available
- the version of OpenEBS where the OEP graduated to general availability
- when the OEP was retired or superseded

## Drawbacks [optional]

- Support will be available only for either physical disks or disks having
  a GPT label on them. This will result in many disks that currently NDM supports
  going into a not-supported mode.
- In cases where the complete disk is formatted with a filesystem, as in the case of
  local SSDs in GKE, there are not GPT labels available on the disk. This will result
  in the user having to manually create a GPT label on the disk, which can be tedious
  process.
- If the consumer of disk/BD provided by NDM, erases the GPT label on the disk,
  NDM has no way to identify the disk. Therefore it should be made mandatory that
  the users should not erase the GPT label on the disk.

## Alternatives [optional]

- NA

## Infrastructure Needed [optional]

- Test setup with different types of disks in different configurations to test and
  ensure the unique ID generation process.