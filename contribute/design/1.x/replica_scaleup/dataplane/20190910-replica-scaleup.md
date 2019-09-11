---
oep-number: Replica Scaleup REV1
title: Replica Scaleup
authors:
  - "@vishnuitta"
owners:
  - "@kmova"
  - "@mynktl"
  - "@pawanpraka1"
  - "@mittachaitu"
editor: "@vishnuitta"
creation-date: 2019-09-10
last-updated: 2019-09-10
status: provisional
---

# Replica Scaleup

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Add new replica](#add-new-replica)
      * [Replace non-existing replica](#replacing-non-existing-replica)
    * [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
      * [Current Implementation -- Config](#current-implementation----config)
      * [Current Implementation](#current-implementation)
      * [Shortcomings with Current Implementation](#shortcomings-with-current-implementation)
    * [Proposed Implementation](#proposed-implementation)
      * [Adding new replica](#adding-new-replica-workflow)
      * [Replacing non-existing replica](#replacing-non-existing-replica-workflow)
    * [High Level Design](#high-level-design)
      * [Components Interaction](#components-interaction)
      * [Sample YAMLs](#sampleyamls)
      * [Notes](#notes)
    * [Low Level Design](#low-level-design)
      * [Replica Connection](#replica-connection)
      * [Maintaining Known Replicas List](#maintaining-known-replicas-list)
      * [Notes](#notes)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This proposal includes design for cStor data plane to allow adding new replicas
to it so that replication factor of the volume will be increased.

## Motivation

There are cases arising where OpenEBS user lost multiple copies of data, and,
working with available single copy.
This proposal is to enable him to add more replicas to it again.

### Goals

- Increase ReplicationFactor of volume by adding replicas
- Identify replicas which are allowed to connect to target

### Non-Goals

- Scaling down replicas
- Add replicas in GitOps model
- Workflow to replace non-existing replica
- operator that detects the need to increase ReplicationFactor
- Allow adding replicas to replace particular replica (volume distribution case)

## Proposal

### User Stories

#### Add new replica
As an OpenEBS user, I should be able to add replicas to my volume.

#### Replace non-existing replica
As an OpenEBS user, I should be able to replace non-existing replica with new
replica.

### Implementation Details/Notes/Constraints

Currently, cstor-istgt reads replication related configuration, i.e.,
ReplicationFactor (RF) and ConsistencyFactor (CF), from istgt.conf file.
cstor-volume-mgmt is the container that fills the RF and CF details into
istgt.conf file by reading from CStorVolume CR.

Another property that cstor-istgt uses is 'quorum'. This property is set at
replica, and, replica sends this to istgt during handshake phase.
This property can take values of 'on' and 'off'.
'on' means that data written to this replica is available for reads.
'off' means that data written to this replica is lost.
cstor-pool-mgmt is the container that sets quorum property at replica.
It sets property as 'on' if replica is created first time related to that CVR.
Otherwise, it sets to 'off'.

#### Current Implementation -- Config
- cstor-volume-mgmt reads configuration from CStorVolume CR.
  - spec.replicationFactor
  - spec.consistencyFactor
- cstor-volume-mgmt updates the above info into istgt.conf file as
  - ReplicationFactor
  - ConsistencyFactor
- Based on the status of CVR and availability of replica, cstor-pool-mgmt
sets quorum property while creating replica.

#### Current Implementation
Above mentioned properties are used as below at istgt:
- Allow replicas (upto max of 5) to connect to target until RF number of
healthy replicas are available.
- Atleast CF in-quorum replicas are required to perform rebuilding and start IOs
- Rebuilding will be triggered and replicas become healthy. As RF number of
replicas are healthy, other connected replicas, if any, gets disconnected.

#### Shortcomings With Current Implementation
- Due to misconfiguration from user, if old replica connects back instead of
the replaced one, there are chances of serving wrong data, and can lead to
data corruption.
- There is no data-consistent way of increasing RF and CF of CStorVolume CR.

### Proposed Implementation
Increase in replication factor will be provided in declarative way.
For replicas identification that can connect to target, replicas information
as well need to be stored in CStorVolume CR and istgt.conf.

New fields will be added to CStorVolume CR and istgt.conf.
In CStorVolume CR, spec.DesiredReplicationFactor will be added to help in
adding replicas, and, status.ReplicaList to store list of known replicas.
In istgt.conf, DesiredReplicationFactor and ReplicaList will be added.


#### Adding new replica
- User will create proper CVR with other than Empty status.phase
- User will edit CStorVolume CR to set 'DesiredReplicationFactor'

#### Replacing non-existing replica
Assuming user has reduced RF, CF of CStorVolume CR to have volume in Online
state, leaving the DesiredReplicationFactor as it is will increase the RF.

### High Level Design
cstor-volume-mgmt watches for CStorVolume CR and updates istgt.conf file if
there is any change in DesiredReplicationFactor.
It will trigger istgtcontrol command so that istgt updates DRF during runtime.

A listener will be created on UnixDomain socket in cstor-volume-mgmt container.
istgt connects to this listener to update the replica related information if
there is any change in the list.
cstor-volume-mgmt updates the status.ReplicaList part of CStorVolume CR and
sends the success/failure of CR update as reponse to istgt.

During start phase of cstor-volume-mgmt container, it updates the istgt.conf
file with values from spec.DesiredReplicationFactor and status.ReplicaList of
CStorVolume CR.

#### Components interaction:

```
[Conf file] --->  ISTGT <--- REPLICAS
                  |  /|\
   (UnixSocket Conn)  |
                  |   | 
                  |  (istgtcontrol) 
                 \|/  | 
            CSTOR-VOLUME-MGMT <---->[CStorVolume CR]                          V
                    | 
                    | 
                   \|/ 
               [Conf file]
```

#### Sample YAMLs

#### NOTES

##### Is there a need to maintain the list of known replicas:
This can be better explained with scenarios.
1. Consider case where 3 replicas (R1, R2, R3) are connected and are fine.
Lets say, one replica(R3) was lost and new one (R4) got added.
After R4 got reconstructed with data, another replica (R2) got lost and
new one (R5) got connected.
Once R5 got reconstructed, all replicas have quorum propery on. But, just that
R2 and R3 are not reachable.
At a later point of time, if R1, R4, R5 are down and R2, R3 are connected to
istgt (which can be due to attachment of old disks), istgt cannot identify that
there is missing data with R2, R3.

2. Consider replacing non-existing replica.
When user reduced replication factor, and later increased it, if old replicas
gets connected, istgt can't identify that there is missing data with replicas.

### Low Level Design
Current code takes care of reconstructing data to non-quorum replica once it
does handshake with target. But, changes are required in allowing replica to
perform handshake with target to achieve DesiredReplicationFactor.

#### Replica Connection
Below are the steps to allow replica handshake with istgt:
- If currently connected replicas count >= 5, reject this if it is non-quorum or
another connected non-quorum replica if the new one is in quorum
- If DesiredRF number of replicas are healthy, reject
- Make sure connected replica is an appropriate one to the volume, by checking
replica name with vol name
- If quorum is off, allow replica to connect and follow existing code flow
(i.e, adding to non_quorum linked list etc)
- If quorum is on, allow to connect only if it is new replica i.e.,
its checkpointed nums are zero.
- If quorum is on and its checkpointed nums are not zero, allow to connect only
if it is in known lists, else reject


#### Maintaining known replicas lists
status.ReplicaList of CStorVolume CR need to contain the replicas information
such that data can be correctly served from these replicas.
There should be RF number of such replicas with quorum property 'on'.
Such replicas are termed as 'Known Replicas'.

For the case of newly created volume, all the RF number of replicas that connect
to it with quorum ‘on’ can be added to known list. So,
- Add the newly created replicas with quorum 'on' and checkpointed numbers as
zero to known list by sending message to cstor-volume-mgmt.

For the case of adding new replica or a replacment replica,
- Identify the case when replica turned from quorum ‘off’ to quorum ‘on’ state.
Let this replica referred as R.
- Make sure there are no pending IOs on R [Why? If CR got updated, and there are
pending IOs on R, CF of those IOs MAY NOT be met with new RF]
- All IOs need to be verified to be successful on R until updating to
CStorVolume CR is successful. [Why? This is similar to above reason. CF of those
IOs may not met with new RF. If it is made sure that CF of those IOs is met wrt
new RF, this and above checks would become optional]
- Inform cstor-volume-mgmt with new replicas and replication factor details
- If udpating CR succeeds, update in-memory data structures of istgt
- If updating CR fails, retry after some time

Testcases:
- Start old replica and make sure it doesn't connect

#### Notes
- Control plane should never create more than initially configured RF number of
CVRs with quorum ‘on’.
- Quorum should be 'off' for replicas that are later created either to
re-create replica as data got lost or adding new replica to increase RF.
- CF is set at Lower_Ceil(RF/2) + 1 following the formula used in control plane.
However, data plane can take any number of CF which is less than RF.
- I/P validation need to be done such that DRF is >= RF
- Considering the case of reduction in RF, istgt need to update ReplicaList
whenever in-memory list doesn't match with the list in conf file.

### Risks and Mitigations

## Graduation Criteria

## Implementation History

- Owner acceptance of `Summary` and `Motivation` sections - YYYYMMDD
- Agreement on `Proposal` section - YYYYMMDD
- Date implementation started - YYYYMMDD
- First OpenEBS release where an initial version of this OEP was available - YYYYMMDD
- Version of OpenEBS where this OEP graduated to general availability - YYYYMMDD
- If this OEP was retired or superseded - YYYYMMDD

## Drawbacks

NA

## Alternatives

NA

## Infrastructure Needed

NA
