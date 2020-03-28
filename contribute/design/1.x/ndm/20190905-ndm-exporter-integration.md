---
oep-number: NDM 0002
title: Metrics Collection using Node-Disk-Manager
authors:
  - "@akhilerm"
owners:
  - "@kmova"
  - "@vishnuitta"
editor: "@akhilerm"
creation-date: 2019-09-05
last-updated: 2020-03-26
status: provisional
---

# Metrics Collection using Node-Disk-Manager

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Rarely changing metrics](#rarely-changing-metrics)
      * [Frequently changing metrics](#frequently-changing-metrics)
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

This proposal brings out the design details to implement a metrics collector
for block devices. The metrics will include static data like NDM assigned
UUID, Device state along with continuously varying data like used capacity,
temperature data etc.

## Motivation

NDM currently stores all the data related to the block devices in etcd in a
custom resource. This is not a good approach for continuously varying metrics.
Also the metrics should be available on demand at an end point from where users
can query and get relevant information. This will help in monitoring of the block
devices rather at the pool or volume level.

### Goals

- A cluster level exporter that exposes static and rarely changing metrics of
  block devices like device state and UUIDs
- A node level exporter that exposes continuously varying metrics like temperature
  and free space on the block device

### Non-Goals

- The exporter will be working only at the block level and will not provide
  metrics about pool or volumes that are built on top of these devices.

## Proposal

### User Stories

#### Rarely changing metrics
For a high level view of storage on the cluster, data points like when the
disk went offline, total capacity of the disk etc should be available to the
cluster admin.

#### Frequently changing metrics
For deep monitoring of the storage devices, metrics like IOPS, drive temperature etc
are required and these data should be queried from each block device from each node.

### Implementation Details/Notes/Constraints

The implementation details of exporter for collecting block level metrics. The current
implementation just stores all the data related to the block devices in etcd, which
is difficult to retrieve by monitoring systems like prometheus.

#### Current Implementation
In the current implementation all the details related to the block devices are stored
in etcd. Even information like temperature is stored in the custom resource. The data
in etcd is updated only when a udev event happens on the system.

#### Shortcomings of current implementation
Since the time at which udev events occur cannot be predicted and is not so frequent
the metric data stored in etcd will be obsolete most of the time. Also, this approach
cannot be used in cases of continuously varying metrics like temperature and free space
on the drive.

#### Proposed Implementation

There will be 2 components to the exporter. One will be running at the cluster level
and the other at node level. The components can be customized depending on the metrics
you need to fetch from the cluster.

##### Cluster level Exporter
This component of the exporter will run at the cluster level and there will be only one
running instance of this component at any time in the cluster. The primary responsibility
of this exporter is to take static / rarely changing data about the block devices from
etcd and expose it as prometheus metrics. The static data like Model number, UUID etc
will be cached in the exporter, and metrics like state(Offline/Online) of the device will be
fetched from etcd every time a request comes at the end point for the metrics.

##### Node level Exporter
The node level exporter runs as a daemon in each node and collects all the metrics of the
block device like IOPS, temperature, free space etc. It exposes a rest endpoint which can
be queried to get the data. Every time the exporter is queried, all the metrics related are
fetched from the disk using SMART and Seachest libraries and returned.

#### Workflow
```
+---------------+                      +---------------+      2      +---------+
|               |         1            |               +------------>+         |
|               +--------------------->+ cluster level |             | etcd    |
|   Prometheus  |                      | exporter      +<------------+         |
|               |                      |               |      3      +---------+
|               +<---------------------+               |
|               |         4            |               |
++--+---+----+--+                      +---------------+
 |  ^   |    ^
 |  |   |    +-----------------8-------------------------+
 |  |   |                                                |
 |  |   +-----------------5----------------------+       |
 5  |                                            |       |
 |  8           +----------------+            +--v-------+-----+
 |  |           |                |            |                |
 |  +-----------+                |            |                |
 |              |      Node1     |            |      Node2     |
 |              |                |            |                |
 +------------->+ exporter-d     |            |  exporter-d    |
                +--------+-------+            +--------+-------+
                     6|  ^                        6|   ^
                      v  |7                        v   |7
                    +-+-------+                  +-+-------+
                    |::Disk   |                  |::Disk   |
                    +---------+                  +---------+

```

- Cluster Level exporter

    1. Queries the cluster level operator for static data about all block devices
     in the cluster
    2. Requests etcd for all blockdevices and their properties
    3. Response from etcd with all blockdevices
    4. Response from cluster level exporter to prometheus with static metrics

Sample metrics when cluster exporter endpoint is queried
```
# HELP node_block_device_state State of BlockDevice (0,1,2) = {Active, Inactive, Unknown}
# TYPE node_block_device_state gauge
node_block_device_state{blockdevicename="blockdevice-6a0ec0732d1f709810a3fbbde81fc3bb",hostname="minikube",nodename="minikube",path="sda"} 0
# HELP node_error_request_count No. of requests errored out by the exporter
# TYPE node_error_request_count counter
node_error_request_count 2
# HELP node_reject_request_count No. of requests rejected by the exporter
# TYPE node_reject_request_count counter
node_reject_request_count 0
```

- Node Level exporter

    5. Queries each storage node for disk metrics
    6. exporter-d queries certain pages on the disk to get relevant metrics data
    7. The information from the pages is analysed using SMART and seachest libraries
       to get relevant metric about the disk
    8. The live metrics are send back to prometheus.

Sample metrics when node level exporter is queried
```
# HELP seachest_block_device_current_temperature_celsius Current reported temperature of the blockdevice. -1 if not reported
# TYPE seachest_block_device_current_temperature_celsius gauge
seachest_block_device_current_temperature_celsius{blockdevicename="blockdevice-6a0ec0732d1f709810a3fbbde81fc3bb",hostname="minikube",nodename="minikube",path="sda"} 38
# HELP seachest_block_device_current_temperature_valid Validity of the current temperature data reported. 0 means not valid, 1 means valid
# TYPE seachest_block_device_current_temperature_valid gauge
seachest_block_device_current_temperature_valid{blockdevicename="blockdevice-6a0ec0732d1f709810a3fbbde81fc3bb",hostname="minikube",nodename="minikube",path="sda"} 1
# HELP seachest_error_request_count No. of requests errored out by the exporter
# TYPE seachest_error_request_count counter
seachest_error_request_count 0
# HELP seachest_reject_request_count No. of requests rejected by the exporter
# TYPE seachest_reject_request_count counter
seachest_reject_request_count 0
```
##### Enabling NDM exporter
NDM Exporter can be installed by following the YAML [here](https://github.com/openebs/node-disk-manager/blob/master/ndm-operator.yaml).
Make sure that the exporter deployment and daemonset is installed in the
same namespace as of OpenEBS-NDM. 

##### Using with Prometheus Node Exporter
The NDM exporter exposes metrics such that it can be used along with prometheus
node exporter. The `hostname`, `nodename` and `path` labels are made available
in all metrics exposed by NDM exporter. This labels help to club together metrics
from NDM exporter and node exporter, thus giving a complete details view of the
block devices in the system.

##### Adding new collector / metrics
New collectors for fetching additional metrics can be added by following
the steps described [here](https://github.com/openebs/node-disk-manager/blob/master/docs/exporter.md). 

## Graduation Criteria

- The exporter should be able to expose both static and dynamic metrics of the
  block devices. The exporter should be also customizable such that depending on the
  type of metrics required, the cluster or node level exporter should be deployed.

## Implementation History

- Owner acceptance of `Summary` and `Motivation` sections - YYYYMMDD
- Agreement on `Proposal` section - YYYYMMDD
- Date implementation started - YYYYMMDD
- First OpenEBS release where an initial version of this OEP was available - YYYYMMDD
- Version of OpenEBS where this OEP graduated to general availability - YYYYMMDD
- If this OEP was retired or superseded - YYYYMMDD

## Drawbacks

- NA

## Infrastructure Needed

- NA