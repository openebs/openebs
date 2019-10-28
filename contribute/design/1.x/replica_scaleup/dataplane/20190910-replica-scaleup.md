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
      * [Move replica from one pool to another](#move-replica-from-one-pool-to-another)
      * [Replace non-existing replica](#replace-non-existing-replica)
    * [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
      * [More Info on Quorum](#more-info-on-quorum)
      * [Current Implementation -- Config](#current-implementation----config)
      * [Current Implementation](#current-implementation)
      * [Shortcomings With Current Implementation](#shortcomings-with-current-implementation)
    * [Proposed Implementation](#proposed-implementation)
      * [Increasing Replication Factor](#increasing-replication-factor)
      * [Replacing/Moving replica](#replacingmoving-replica)
    * [Steps to perform user stories](#steps-to-perform-user-stories)
      * [Adding new replica](#adding-new-replica)
      * [Replacing non-existing replica](#replacing-non-existing-replica)
      * [Moving replica](#moving-replica)
    * [High Level Design](#high-level-design)
      * [Components Interaction](#components-interaction)
      * [Sample YAMLs](#sample-yamls)
      * [Notes](#notes)
    * [Low Level Design](#low-level-design)
      * [Replica list segregation](#replica-list-segregation)
      * [Condition to start IOs](#condition-to-start-ios)
      * [Replica Connection](#replica-connection)
      * [Maintaining Known Replicas List](#maintaining-known-replicas-list)
      * [Notes](#LLDnotes)
    * [Testcases](#testcases)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This proposal includes design for cStor data plane
- to allow adding new replicas to it so that replication factor of the volume
will be increased.
- to move replica from one pool to another

## Motivation

There are cases arising where OpenEBS user lost multiple copies of data, and,
working with available single copy.
This proposal is to enable him to add more replicas to it again.

This also allows OpenEBS user to distribute volume replicas

### Goals

- Increase ReplicationFactor of volume by adding replicas
- Replace a replica with other one which is used in volume distribution and
ephemeral cases
- Identify replicas which are allowed to connect to target

### Non-Goals

- Scaling down replicas
- Add replicas in GitOps model
- Workflow to replace non-existing replica
- operator that detects the need to increase ReplicationFactor

## Proposal

### User Stories

#### Add new replica
As an OpenEBS user, I should be able to add replicas to my volume.

#### Move replica from one pool to another
As an OpenEBS user, I should be able to move replica across pools.

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

#### More Info on Quorum

cstor-pool-mgmt creates replica with quorum as 'on' if status.Phase is Init.
If state is 'Recreate', it creates replica (if needed) with quorum as 'off'.

At cstor-istgt,
	if quorum is off for a replica,
		that replica won't participate in IO related consistency factor
		checks. Its there to rebuild missing data while its taking
		ongoing IOs.
	if quorum is on,
		that replica participate in deciding the fate of IOs.
		cstor-istgt returns success/failure to client based on the
		response from replicas in quorum list.

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
data corruption. To understand this with example, look at #notes section.
- There is no data-consistent way of increasing RF and CF of CStorVolume CR.

### Proposed Implementation

#### Increasing Replication Factor
Increase in replication factor will be provided in declarative way.
For replicas identification that can connect to target, replicas information
as well need to be stored in CStorVolume CR and istgt.conf.

New fields will be added to CStorVolume CR and istgt.conf.
In CStorVolume CR, `spec.DesiredReplicationFactor` will be added to help in
adding replicas, and, `status.ReplicaList` to store list of known replicas.
In istgt.conf, `DesiredReplicationFactor` and `ReplicaList` will be added.

status.ReplicaList of CStorVolume CR need to contain the replicas information
that are allowed to connect to target.
There can be <= RF number of entries, which eventually becomes RF entries.
All the replicas in this list will be with quorum property 'on'. Replicas in
this list are termed as 'Known Replicas'.
If RF < DRF, new replicas are allowed to connect to target. Once it becomes
healthy, RF will be increased and new replica will be added to spec.ReplicaList.

#### Replacing/Moving replica
Replica that need to be replaced/moved will also be done in declarative way.

During handshake, replicas will share `ReplicaGUID_Data` related to particular
`ReplicaID_CVR` with target.
`ReplicaID_CVR` is a unique number related to CVR for which replica is created
in dataplane whose GUID is `ReplicaGUID_Data`.

If replica is recreated for particular CVR, `ReplicaGUID_Data` will be changed
but not `ReplicaID_CVR`.

If replica is moved to another pool, new CVR should be created on new pool with
`ReplicaID_CVR` same as that of old pool, and status.Phase as 'Recreate'.

If new replica need to added to volume, new CVR will be created.
So, `ReplicaID_CVR` will be new, and its `ReplicaGUID_Data` also will be new.

In CStorVolumeReplica, new field `spec.ReplicaID` will be added.
During dataset creation, cstor-pool-mgmt will set this at dataset with property
as `io.openebs:replicaID`.

### Steps to perform user stories

#### Adding new replica
- User will create proper CVR with status.phase as `Recreate`.
- User will edit CStorVolume CR to set 'DesiredReplicationFactor'

#### Replacing non-existing replica
Volume is available online as user reduced RF when too many replicas are lost
(or) sufficient replicas i.e., CF are available.
Leave the DesiredReplicationFactor as it is, and cStor increases the RF
if descreased by user.

#### Moving replica
- User will delete CVR which is on old pool
- User will create proper CVR with status.phase as `Recreate` on new pool and
`spec.ReplicaID` same as the one of CVR on old pool.

### High Level Design
cstor-volume-mgmt watches for CStorVolume CR and updates istgt.conf file if
there is any change in DesiredReplicationFactor.
It will trigger istgtcontrol command so that istgt updates DRF during runtime.

A listener will be created on UnixDomain socket in cstor-volume-mgmt container.
istgt connects to this listener to update the replica related information if
there is any change in the list.
cstor-volume-mgmt updates the status.ReplicaList part of CStorVolume CR and
sends the success/failure of CR update as response to istgt.

During start phase of cstor-volume-mgmt container, it updates the istgt.conf
file with values from spec.DesiredReplicationFactor and status.ReplicaList of
CStorVolume CR.

#### Components interaction:

```
[Conf file] --->  ISTGT <---(R_ID&R_GUID)--- REPLICAS <--(R_ID)- CSTOR-POOL-MGMT
                  |  /|\                                             /|\
   (UnixSocket Conn)  |                                               |
                  |   |                                               |
                  |  (istgtcontrol)                                 (R_ID)
                 \|/  |                                               |
            CSTOR-VOLUME-MGMT <---->[CStorVolume CR]               [CVR CR]
                    |
                    |
                   \|/
               [Conf file]
```

#### Sample YAMLs

#### Notes

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

##### Do we need ReplicaID in CVR CR
This is needed to identify the replica that gets moved across pools.

For the case of replacement also, this is needed to identify the replica.
Consider case of RF as 5 and CF as 3. R1, R2, R3, R4 and R5 are replicas.
R1, R2 and R3 are online and IOs are happening. R6 connects and gets added.
Here, 2 approaches are possible
- one approach is to add R6 to known replicas of R1, R2, R3, R4, R5
- (or) another approach is to replace R4 and R5 with R6.
Later R6 also disconnected. And, after few more IOs, R1, R2, R3 also
got disconnected.

At this point
- if first approach is followed, if R4, R5 and R6 connects, there will be data
inconsistency.
- if second approach is followed, there will be only 4 replicas.
If 5th one, either R4 or R5 connects, it need to become healthy before getting
added to to list. This would be time consuming.

### Low Level Design
Current code takes care of reconstructing data to non-quorum replica once it
does handshake with target. But, changes are required in allowing replica to
perform handshake with target to achieve DesiredReplicationFactor.

#### Replica list segregation
`spec`'s `rq` need to contain only known replicas, which should be having
quorum as 'on'. All other replicas need to get into `non_quorum_rq` (whose name
can be changed to `unknown_rq`)

There won't be any change for `healthy_rcount` and `degraded_rcount` which
looks at `spec`'s `rq`

#### Condition to start IOs
Current implementation says that CF number of in-quorum replicas are needed.

But, with addition of known replica list to achieve data consistency, CF number
of any known replicas need to be connected.

#### Replica Connection
Below are the steps to allow replica handshake with istgt:
- If currently connected replicas count >= DRF, reject this if it is non-quorum
(or) another connected replica (in the order non-quorum, not-in-the-known-list)
if the new one is part of known list with `ReplicaID_CVR` or `ReplicaGUID_Data`,
and, raise a log/alert as too many
replicas are connecting.
- If DesiredRF number of known replicas are connected, i.e.,
(`healthy_rcount` + `degraded_rcount` == DRF), reject all and raise log/alert
- Make sure connected replica is an appropriate one to the volume, by checking
replica name with vol name

- Allow replica if it is in known list
- Allow replica if its `ReplicaID_CVR` is in known list, but add to unknown
list (Replacement case)(here, quorum might be off or on. It can be on
if this replica got disconnected during transitioning to known list)
- Allow replica if its `ReplicaID_CVR` is NOT in known list only if RF < DRF,
but add to unknown list [Replica addition case]
- If RF number of known replicas are NOT available [new volume or upgrade case]
  - Add to unknown list if quorum is off (replacement case)
  - Add to known list if quorum is on
- Allow if RF < DRF, but, add to unknown list
- Reject otherwise

Note: Make sure there is only one replica for a given `ReplicaID_CVR`

#### Maintaining known replicas lists
When a replica completes rebuilding and turns healthy, it might be undergoing
either replacement or addition.

If replica's `ReplicaID_CVR` is already in known list, it is replacement case.
Replace the `ReplicaGUID_Data` with new one for `ReplicaID_CVR` in known list.

If replica's `ReplicaID_CVR` is NOT in known list, it is replica addition case.
Add `ReplicaID_CVR` with `ReplicaGUID_Data` to known replica list.

For the case of adding new replica or a replacement replica,
steps to follow for data consistency are:
- Identify the case when replica turned from quorum ‘off’ to quorum ‘on’ state.
Let this replica referred as R.
- If RF number of known replicas are NOT available or `ReplicaID_CVR` is in
known list, update CStorVolume CR and in-memory structures (Replica replacement
or replica movement case)
- If RF == DRF, disconnect
- (Replica scaleup case) If there is no change in CF with increase in RF,
update the CStorVolume CR and in-memory structures with increased RF
- Pause IOs for few seconds, and, make sure there are no pending IOs on R
[Why? If CR got updated, and there are pending IOs on R, CF of those IOs MAY
NOT be met with new RF]
- If pending IOs still exists, resume IOs and retry above steps in next
iteration.
- If there are no pending IOs,
  - mark `R` as scaleup replica and resume IOs
  - When any replica is marked as scaleup replica, all write IOs need to be
verified to be successful with new and old consistency models.
  - Inform cstor-volume-mgmt with new replicas and replication factor details
- If udpating CR succeeds, update in-memory data structures of istgt
- If updating CR fails, retry above steps after some time

#### LLDNotes
- Control plane should never create more than initially configured RF number of
CVRs with quorum ‘on’.
- Quorum should be 'off' for replicas that are later created either to
re-create replica as data got lost or adding new replica to increase RF.
- CF is set at Lower_Ceil(RF/2) + 1 following the formula used in control plane.
However, data plane can take any number of CF which is less than RF.
- I/P validation need to be done such that DRF is >= RF
- Considering the case of reduction in RF, istgt need to update ReplicaList
whenever in-memory list doesn't match with the list in conf file.

### Testcases:
- Start old replica and make sure it doesn't connect
- Not more than DRF number of quorum replicas at any time
- No non-quorum replicas if DRF number of quorum replicas exists
- Data consistency checks in the newly added replicas
- Updated `ReplicaList` in CV CR when new replicas got added
- Failure case handling to update CV CR
- Only replicas in ReplicaList should be allowed to connect even with different
components restarts
- replicas that are NOT in ReplicaList should NOT be allowed to connect even
with different components restarts
- Upgrade cases
- I/P values validation like smaller DRF, reducing DRF/RF
- Start with 3 replicas and write data. Recreate 2 pools and reduce RF to 1.
Increase it to 3 and verify data consistency.

### Risks and Mitigations

## Graduation Criteria
All testcases mentioned in `Testcases` section need to be automated

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
