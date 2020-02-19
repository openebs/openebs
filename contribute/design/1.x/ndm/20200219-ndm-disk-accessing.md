---
oep-number: NDM 0002
title: Uniquely accessing disk in cluster
authors:
  - "@mittachaitu"
owners:
  - "@gila"
  - "@kmova"
  - "@vishnuitta"
  - "@pawanpraka1"
  - "@akhilerm"
editor: "@mittachaitu"
creation-date: 2020-02-19
last-updated: 2020-02-19
---

# Disk Identification using NDM

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Accessing Uniquely Identified Disk](#accessing-uniquely-identified-disk)
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

This proposal brings out the design details to implement a uniquely access the
uniquely identified disks across the cluster.

## Motivation

Uniquely identifying disk is addressed via PR https://github.com/openebs/openebs/pull/2666
Now applications required some mechanism to access uniquely identified disk
across the clusters. This accessing is necessary, due to the fact that disk can
move from one node to node and even disk can attached back to different ports of
same node. The unique accessing solution will be help the consumers of NDM to
access the disks uniquely.

### Goals

- Configurable device accessing mechanism.
- A unique disk accessing mechanism that will work across the clusters.

### Non-Goals

- NA

## Proposal

### User Stories

- As a NDM user I should be able to access devices uniquely even if device
  doesn't have any unique identification from manufacturer.

#### Current Implementation

Currently NDM gives some information on blockdevice to access the device.

**Example dev links on blockdevice:**
```sh
devlinks:
  - kind: by-path
    links:
    - /dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:2:0
  filesystem: {}
  nodeAttributes:
    nodeName: d2iq-node5.mayalabs.io
  partitioned: "No"
  path: /dev/sdc
```
Application should consume this device by mounting `/dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:2:0`
(or) `/dev/sdc` into the pod then application can start consuming device. In
case of manufacturer giving some unique identification then application can
consume device via disk by-id.

#### Shortcomings of current implementation

Current accessing of disk has following shortcomings

1. In case of virtual environment device accessing is tightly coupled with the
   port where device was attached. If that is the case when in use device was
   detached and attached new device in the same port then it can leads to data
   corruption (or) data lost scenarios(Even though disk is available and
   accessible via different path).
2. Till now NDM doesn't provide a way to consume only required multiple block
   devices by an application i.e I have an application A that consumes multiple
   blockdevices. Now to make my application to work I need to mount `/dev` into my
   application and should give `privileged` access to access the device since it
   is `/dev` which leads to security issues or concerns i.e My application can
   access any disks present in the node which shouldn't be the case.

#### Proposed Implementation

- User will specify a path on blockdeviceclaim during the process of claiming
  blockdevice. Now NDM will observe that user is requesting for unique access of
  the block device and it creates a loop device and block file(which was created
  using mknod)[Why loop device? loop device(kind of lock) which will helpful to hold a Maj:Min
  number of disks. Major & Minor number of the disk will change depends on order of
  attaching the disks. For example attached the disk1 to the node it came
  on `/dev/sdb` and it has Major and Minor number of disk as `8:16` then detached
  disk1 and attached disk2 to the same node disk2 access path came as same `/dev/sdb`
  and Maj:Min number will be `8:16` which will be not recommended to use them.
  So to tackle this created loop device on `disk1` access path and given to the
  application(application starts consuming disk via block file). Now the disk1 was
  detached and attached back to the node kernel will allocate new Major & Minor
  number and new access path `/dev/sdx(next available path)` to the same disk because
  loop device is holding old disk path & Maj:Min number] in the tempfs(Ex: /tmp) + user specified path +
  uniquely identified id[
  Why input from user? Because multiple application can consuming blockdevice so
  it is recommended to provide some unique path to block file.
  Why tempfs? Upon reboots of the nodes loop devices will be destroyed because
  of devfs is temporary kind of filesystem up on reboots.
  Why uniquely identified id? application can identify the disk using that
  unique id]. This entire path will be updated on blockdevice status(New field).
  So user can access the disk with the path exists on status of blockdevice.

- Now if application requires multiple blockdevices application should make a
  claim of all the blockdevices with some common path on blockdeviceclaim.

##### Workflow

- NDM will create blockdevices for uniquely identified blockdevices when NDM pod
  up or when disk was attached.
- Application will make request to claim the blockdevice using blockdeviceclaim.
  User will mention path on blockdeviceclaim(new field) on which path it needs to
  access the blockdevice.
- NDM will create a loop device and block file on requested blockdevice.
  Ex: To create loop device command used -- `losetup loop0 /dev/disk/by-id/path`
      To create block file command used -- `mknod <path_to_file> b Maj Min`
- Once the above step is successful NDM will update the status as `Claimed` and
  path to access block device.
- When the existing claimed blockdevice was detached and attached back during
  updating the status as `Active` NDM should create new loop device on new path
  recreate block file to point it to new Major and Minor number(Application
  consuming blockdevice should reopen the ports because file got recreated on
  same path with same name).
- Upon reboots of the node NDM should create blockfiles and loop devices for
  claimed disks in the specified path.

## Graduation Criteria

- NDM should be able to uniquely access the disks, across reboots, across different
  SCSI ports and anywhere within the cluster. The unique accessing of disk can be
  marked successful, if the user is able to access and retrieve his data from the disk.

## Implementation History
- Owner acceptance of `Summary` and `Motivation` sections - YYYYMMDD
- Agreement on `Proposal` section - YYYYMMDD
- Date implementation started - YYYYMMDD
- First OpenEBS release where an initial version of this OEP was available - YYYYMMDD
- Version of OpenEBS where this OEP graduated to general availability - YYYYMMDD
- If this OEP was retired or superseded - YYYYMMDD

## Drawbacks

NA

## Infrastructure Needed

- Test setup with different types of Linux OS Distributions in different
  configurations to test and ensure the unique accessing the disk.
