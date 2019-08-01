---
oep-number: draft deep visibility into istgt 20190726
title: Deep visibility into istgt
authors:
  - "@utkarshmani1997"
owners:
  - "@utkarshmani1997"
editor: "@utkarshmani1997"
creation-date: 2019-05-31
last-updated: 2019-07-26
status: provisional
see-also:
  - NA
replaces:
  - NA
superseded-by:
  - NA
---

 # Deep visibility into istgt

 ## Table of Contents

 * [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Deep visibility into cstor components](#deep-visibility-into-cstor-components)
    * [Implementation Details](#implementation-details)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)

 ## Summary

 This design doc covers various parts of istgt and pools, that will be very helpful in debugging as well as visualization of critical parts. Currently we already have various  status of the openebs components available in the maya-exporter which can be queried using PromQl and can be analyzed in grafana. Please refer to openebs-monitoring doc for more information about maya-exporter and the metrics that it already exposes.

 ## Motivation

Motivation behind this doc is to reduce the efforts and time that is being taken by team for debugging purpose and represent everything in the form of graph, histograms, counters etc.

 ### Goals

 - Ability to identify the errors in cstor components by looking at the various error counters and other metrics.

 ## Proposal
 Display various error metrics and statistics in maya-exporter which can be pulled from istgt.

 ### User Stories
 #### Deep visibility into cstor components
 As a user i want to know/understand the errors and perform corrective measures to fix them easily without looking for the logs.

 ### Implementation Details

Implement a command `istgtcontrol istgtstatus` which will gather the info from istgt and maya-exporter (sidecar) will collect these metrics querying on the shared socket path between these two containers. Here are the list of metrics which will be gathered:

1. Status: Status of target (already available)
2. IQN: Iqn of the target (already available)
3. IP: ip of controller (already available)
4. Replica Count: Healthy replica count (already available), degraded replica count (already available), offline replica count, unknown replica count 
5. Replicas [poolname]: (BUILD_REPLICA_MGMT_HDR (cmd table))
    - Capacity and performance stats : capacity stats consists info of used, available capacity and performance stats includes info about latency, throughput, read/write io counts. (available)
    - Status: Status of replicas such as healthy, degraded, offline, rebuilding (available)
    - Uptime: uptime of target since it started (available)
    - Read io count (started and done): no of read io’s (available)
    - Write io count (started and done): no of write io’s (available)
    - Sync io count (started and done): no of sync io’s (available)
    - IO timeout count (read/write/sync): no of io timeouts
    - Time taken by io’s (all opcodes): time took to complete read/write/sync io’s 
    - Mgmt connection all opcodes (started and done): snapshot, resize, list
    - Zrepl_prot.h (zvol_op_code)
    - Opcode failure count 
    - Opcode version mismatch count (different opcodes metrics such as: openebs_write16_mismatch_count etc)
    - Mgmt connection error counts: connection errors such as snapshot failed, rebuild failed etc. (accept_mgmt_connection)
    - Data connection errors: connection errors such as r/w timeout due to network delay on data connection (init_replication, zvol_handshake->update_replica_entry)
    - Read opcode failure count: 
    - Write opcode failure count:
    - Queue count: (ready/ blocked/ wait/ inflight/ dispatched/ done) (move_to_blocked_or_ready_q)

6. ISCSI Connection: (istgt_iscsi_execute)
    - Login request count : No of logins attempted to target (iscsi_op_login)
    - Logout request count: No of logout attempted to target (iscsi_op_logout)
    - Discovery request count: No of discovery requests (iscsiadm) ()
    - Login Request duration (Histogram): Duration took to process the login request.
    - Lu workers count: No of lu worker thread  (spec->luworkers)
    - Used capacity: Used capacity of volume
7. IO counters:  (replicate)
    - Read10 count
    - Read12 count
    - Read16 count
    - …. All the scsi opcodes
8. Q count: 
    - Ready
    - Blocked
    - … etc

 ## Schema
 ```
 {
  "loginReqCnt": "6",
  "loginReqSuccessCnt": "6",
  "logoutReqCnt": "5",
  "logoutReqSuccessCnt": "5",
  "discoveryReqCnt": "6",
  "discoveryReqSuccessCnt": "6",
  "read6Cnt": "0",
  "read10Cnt": "749",
  "read12Cnt": "0",
  "read16Cnt": "0",
  "write6Cnt": "0",
  "write10Cnt": "1122",
  "write12Cnt": "0",
  "write16Cnt": "0",
  "sync10Cnt": "70",
  "sync16Cnt": "0",
  "luWorkers": 6,
  "snapshotCreateReqCnt": "321",
  "snapshotPrepareReqCnt": "1",
  "snapshotCreateReqSuccessCnt": "47",
  "snapshotPrepareReqSuccessCnt": "1",
  "startRebuildReqCnt": "4",
  "startRebuildReqSuccessCnt": "0",
  "prepareRebuildReqCnt": "4",
  "prepareRebuildReqSuccessCnt": "0",
  "maintCmdQLen": "0",
  "maintBlockedQLen": "0",
  "cmdQLen": "26",
  "blockedQLen": "0",
  "replicas": [
    {
      "replicaId": "6162",
      "Address": "127.0.0.1",
      "Mode": "Healthy",
      "checkpointedIOSeq": "1000",
      "inflightRead": "0",
      "inflightWrite": "0",
      "inflightSync": "0",
      "quorum": "1",
      "upTime": 379,
      "waitQ": 0,
      "readyQ": 0,
      "blockedQ": 0,
      "snapshotCreateReqCnt": "81",
      "snapshotPrepareReqCnt": "1",
      "snapshotCreateReqSuccessCnt": "64",
      "snapshotPrepareReqSuccessCnt": "1",
      "startRebuildReqCnt": "1",
      "startRebuildReqSuccessCnt": "1",
      "prepareRebuildReqCnt": "2",
      "prepareRebuildReqSuccessCnt": "1"
    },
    {
      "replicaId": "6163",
      "Address": "127.0.0.1",
      "Mode": "Healthy",
      "checkpointedIOSeq": "1000",
      "inflightRead": "0",
      "inflightWrite": "0",
      "inflightSync": "0",
      "quorum": "1",
      "upTime": 377,
      "waitQ": 0,
      "readyQ": 0,
      "blockedQ": 0,
      "snapshotCreateReqCnt": "81",
      "snapshotPrepareReqCnt": "0",
      "snapshotCreateReqSuccessCnt": "61",
      "snapshotPrepareReqSuccessCnt": "0",
      "startRebuildReqCnt": "1",
      "startRebuildReqSuccessCnt": "1",
      "prepareRebuildReqCnt": "1",
      "prepareRebuildReqSuccessCnt": "1"
    },
    {
      "replicaId": "6161",
      "Address": "127.0.0.1",
      "Mode": "Degraded",
      "checkpointedIOSeq": "1000",
      "inflightRead": "0",
      "inflightWrite": "6",
      "inflightSync": "0",
      "quorum": "1",
      "upTime": 43,
      "waitQ": 1,
      "readyQ": 1,
      "blockedQ": 1,
      "snapshotCreateReqCnt": "0",
      "snapshotPrepareReqCnt": "0",
      "snapshotCreateReqSuccessCnt": "0",
      "snapshotPrepareReqSuccessCnt": "0",
      "startRebuildReqCnt": "1",
      "startRebuildReqSuccessCnt": "1",
      "prepareRebuildReqCnt": "0",
      "prepareRebuildReqSuccessCnt": "1"
    }
  ],
  "errors": [
    {
      "mgmtConnErrCnt": "0",
      "dataConnErrCnt": 1,
      "poolGuid": "0"
    },
    {
      "mgmtConnErrCnt": "1",
      "dataConnErrCnt": 0,
      "poolGuid": "0"
    },
    {
      "mgmtConnErrCnt": "1",
      "dataConnErrCnt": 0,
      "poolGuid": "0"
    },
    {
      "mgmtConnErrCnt": "0",
      "dataConnErrCnt": 1,
      "poolGuid": "0"
    }
  ]
 }
```
 ## Drawbacks
- These metrics shouldn't be gathered frequently as it may impact the ongoing IO's

 ## Alternatives

 - `istgtcontrol iostats`
