---
title: LVM LocalPV Node Capacity Management and Monitoring
authors:
  - "@avishnu"
owners:
  - "@kmova"
creation-date: 2021-06-17
last-updated: 2021-06-17
status: In-progress
---

# LVM LocalPV Node Capacity Management and Monitoring

## Table of Contents

- [LVM LocalPV Node Capacity Management and Monitoring](#lvm-localpv-node-capacity-management-and-monitoring)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
    - [Concepts](#concepts)
        - [Physical Volume](#physical-volume)
        - [Volume Group](#volume-group)
        - [Logical Volume](#logical-volume)
        - [Thin Logical Volume](#thin-logical-volume)
    - [Implementation Details](#implementation-details)
      - [Metrics Identification](#metrics-identification)
        - [Capacity-based Metrics](#capacity-based-metrics)
        - [Usage-based Metrics](#usage-based-metrics)
      - [Metrics Export](#metrics-export)
        - [Node Exporter](#node-exporter)
        - [Custom Exporter](#custom-exporter)
    - [Sample Dashboards](#sample-dashboards)
    - [Sample Alerts](#sample-alerts)
    - [Test Plan](#test-plan)
        - [Pre-requisites](#pre-requisites)
        - [Test Cases](#test-cases)
  - [Graduation Criteria](#graduation-criteria)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)

## Summary
This proposal charts out the design details to implement monitoring for doing effective capacity management on nodes having LocalPV-LVM Volumes.

## Motivation
Platform SREs must be able to easily query the capacity details at per node level for checking the utilization and planning purposes.

### Goals
- Platform SREs must be able to query the information at the following granularity:
  - Node level
  - Volume Group level
- Platform SREs need the following information that will help with planning based on the capacity:
  - Total Provisioned Capacity
  - Total Allocated Capacity to the PVCs ( (When thin-provisioned PVs are used - it is possible that total allocated capacity can be greater than total provisioned capacity.)
  - Total Used Capacity by the PVCs
- Platforms SREs need the following performance metrics that will help with planning based on the usage:
  - Read / Write Throughput and IOPS (PV)
  - Read / Write Latency (PV)
  - Outstanding IOs (PV)
  - Status ( online / offline )

This document lists the relevant metrics for the above information and the steps to fetch the same.

### Non-Goals

- The visualization and alerting for the above metrics.
- Clustered LVM.
- Snapshot space management (currently a non-goal, will be a future goal).

## Proposal

### User Stories

As a platform SRE, I should be able to efficiently manage the capacity-based provisioning of LVM LocalPV volumes on my cluster nodes.

### Concepts

LVM (Logical Volume Management) is a system for managing Logical Volumes and file-systems, in a manner more advanced and flexible than the traditional disk-partitioning method.
Benefits of using LVM:
- Resizing volumes on the fly
- Moving volumes on the fly
- Unlimited volumes
- Snapshots and data protection

Following are the basic concepts (components) that LVM manages:
- Physical Volume
- Volume Group
- Logical Volume

![LVM-architecture](https://user-images.githubusercontent.com/7765078/122776107-6aadcf80-d2c8-11eb-814b-86ba9407c09f.png)

##### Physical Volume
A Physical Volume is a disk or block device, it forms the underlying storage unit for a LVM Logical Volume. In order to use a block device or its partition for LVM, it should be first initialized as a Physical Volume using `pvcreate` command from the LVM2 utils package. This places an LVM label near the start of the device.

##### Volume Group
A Volume Group (VG) is a named collection of physical and logical volumes. Physical Volumes are combined into Volume Groups. This creates a pool of disk space out of which Logical Volumes can be allocated. A Volume Group is divided into fixed-sized chunk called extents, which is the smallest unit of allocatable space. A VG can be created using the `vgcreate` command.

##### Logical Volume
A Logical Volume (LV) is an allocatable storage space of the required capacity from the VG. LVs look like devices to applications and can be mounted as file-systems. An LV is like a partition, but it is named (not numbered like a partition), can span across multiple underlying physical volumes in the VG and need not be contiguous. An LV can be created using the `lvcreate` command.

##### Thin Logical Volume
Logical Volumes can be thinly provisioned, which allows to create an LV, larger than the available physical extents. Using thin provisioning, a storage pool of free space known as a thin pool can be allocated to an arbitrary number of devices as thin LVs when needed by applications. The storage administrator can over-commit (over-provision) the physical storage by allocating LVs from the thin pool. As and when applications write the data and the thin pool fills up gradually, the underlying volume group (VG) can be expanded dynamically (using `vgextend`) by adding Physical Volumes on the fly. Once, VG is expanded, the thin pool can also be expanded (using `lvextend`).

### Implementation Details

This involves two phases - identifying the metrics and making them available for consumption.

#### Metrics Identification

##### Capacity-based Metrics
- **Total Provisioned Capacity** on a node is the aggregate capacity of all Volume Groups on that node. Run the command `vgs -o vg_size <vg_name>` to get the total capacity (vg_size) of a VG. Run the command without <vg_name> to fetch for all VGs.
- **Total Free Capacity** on a node is the aggregate free capacity of all Volume Groups on that node. Run the command `vgs -o vg_free <vg_name>` to get the free capacity (vg_free) of a VG. Run the command without <vg_name> to fetch for all VGs.
- **Total Used Capacity** on a node is the aggregate used capacity of all Volume Groups on that node. The difference between the vg_size and vg_free gives the used capacity (vg_used) for a VG.
- **Total Allocated Capacity** on a node is the aggregate size of all LVs on that node. Run the command `lvs -o lv_size <lv_full_name>` to get the size (lv_size) of an LV. Run the command without <lv_full_name> to fetch for all LVs.
- **Total Used Capacity** for all PVCs on a node is the aggregate used capacity of all LVs on that node. Run the command `lvs -o lv_size,data_percent,snap_percent,metadata_percent <lv_full_name>` to get the used capacity (lv_used) of an LV.  Run the command without <lv_full_name> to fetch for all LVs.

##### Usage-based Metrics
- **Read IOPs**: Number of read requests completed per second from the LV.
- **Write IOPs**: Number of write requests completed per second to the LV.
- **Read Throughput**: Number of Bytes read per second from the LV.
- **Write Throughput**: Number of Bytes written per second to the LV.
- **Read Latency**: Average time in milliseconds for read requests issued to the LV to be served.
- **Write Latency**: Average time in milliseconds for write requests issued to the LV to be served.
- **Outstanding IOs**: The number of read and write requests that were queued to the LV and not yet served.
- **Status**: Status of LV indicates if it is 'Active' or 'Not available'.
  
Since each LV corresponds to a device-mapper volume on the node, the performance statistics like IOPs, Throughput, Latency and Outstanding IOs can be obtained by running the standard `iostat -x` command on the node. The Status of each LV can be obtained from the `lvs -o lv_active <lv_full_name>` command output. When an LV is available, its status will show as 'Active', else it may show as 'Not available'.

#### Metrics Export

##### Node Exporter
Node Exporter is a Prometheus exporter for collecting hardware and OS kernel metrics exposed by *NIX* kernels using pluggable metrics collectors. There are many built-in collectors which are enabled by default in the node-exporter. Using collectors 'diskstats' and 'filesystem', the node exporter is able to collect and export all the capacity and performance metrics for LVM Logical Volumes. These metrics can be stored in a  time-series database like Prometheus and visualized in Grafana with promQL queries. Since a thin pool is also an LV, the node-exporter is able to collect its usage metrics as well.  
This [document](https://docs.google.com/document/d/1Nm84UJsRKlOFtxY9eSGZGDwUSJWtzI2j5v74uyxxup4/edit?usp=sharing) captures the correlation of iostat metrics with the metrics from node exporter.

##### Custom Exporter
Node-exporter is able to fetch all metrics related to Logical Volumes. However, there is currently no in-built support for collecting metrics related to Volume Groups. We need a custom-exporter to scrape VG metrics like vg_size, vg_used and vg_free.  
This [document](https://docs.google.com/document/d/1Lk__5J4MDa1fEgYFWFPCx1_Guo3Ai2EnnY1e39N7_gA/edit) describes the approach for custom-exporter deployment.
![LocalPV-LVM-CSI-Plugin](https://user-images.githubusercontent.com/7765078/122904191-bcf4fc00-d36d-11eb-8219-1e0a475728da.png)

### Sample Dashboards
Below are sample Grafana dashboards:
![Capacity](https://user-images.githubusercontent.com/32039199/121763305-80005c80-cb58-11eb-8bf8-99f62cac2e1d.png)
![IOPs and Latency](https://user-images.githubusercontent.com/32039199/121762850-2ac34b80-cb56-11eb-903d-50c63a60c50a.png)
![Throughput](https://user-images.githubusercontent.com/32039199/121762853-2eef6900-cb56-11eb-8320-da299d4fb7f0.png)

### Sample Alerts
Type | Condition | Resolution
--------- | ----------- | ----------
VG capacity alert (thick pool threshold) | Used capacity of a VG crosses 80% of its total capacity. | Resize VG by adding more Physical Volumes (disks) or clean up space.
VG unhealthy alert | One or more missing PVs (vg_missing_pv_count > 0) in the VG. | Investigate the cause of the missing PV.
Thin pool capacity alert (thin pool threshold) | Used capacity of a thin pool crosses 90% of its allocated size. | Extend (resize) thin pool or clean up space.
LV capacity alert | Used capacity of a logical volume crosses 90% of its allocated size. | Extend (resize) LV or clean up space.
LV unhealthy alert | Status of LV is 'Not available'. | Check the status of underlying VG and PVs. Once confirmed, attempt to activate the LV by running the command `lvchange -ay <lv_full_name>`.
LV latency alert | Read / write latency crosses 100 ms consistently over 5 min interval. | Investigate the cause of slowness, maybe a disk is under-performing or IO load has increased.

### Test Plan
##### Pre-requisites
- Install OpenEBS LVM components (follow [these](https://github.com/openebs/lvm-localpv/blob/master/README.md) steps).
- Install OpenEBS monitoring stack (follow [these](https://github.com/openebs/monitoring/blob/develop/README.md) steps).
- Create a Volume Group using available node disks.

##### Test Cases
- T1: Provision an OpenEBS LVM local PV of 5 GB capacity from a thick pool (VG) and mount it on an application pod, dump 3 GB of data onto the volume. Check the usage of the volume from the backend and compare against the dashboard value.
- T2: Perform T1, then check the usage of the VG from the backend and compare against the dashboard value.
- T3: Provision an OpenEBS LVM Local PV of 1 GB from the VG and mount it on fio application pod. Run different fio workloads with combinations of read/write IOs on the volume. Observe the various performance metrics using `iostat -x` and compare the same against the dashboard values.
- T4: Remove (de-provision) one or more disks from the VG till the LV status changes from "Active" to "Not available". Check the status in the dashboard.

## Graduation Criteria

All testcases mentioned in [Test Plan](#test-plan) section need to be automated.

## Drawbacks
NA

## Alternatives
NA
