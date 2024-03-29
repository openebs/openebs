---
title: CSI Driver for ZFS  PV Provisioning
authors:
  - "@pawanpraka1"
owners:
  - "@kmova"
  - "@vishnuitta"
creation-date: 2019-08-05
last-updated: 2019-08-05
---

# CSI ZFSPV Volume Provisioning

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Design Constraints/Assumptions](#design-constraintsassumptions)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Create a volume](#create-a-volume)
      * [Delete the volume](#delete-the-volume)
    * [Implementation Details](#implementation-details)
      * [Volume Creation Workflow](#volume-creation-workflow)
      * [Volume Deletion Workflow](#volume-deletion-workflow)
    * [High Level Design](#high-level-design)
* [Implementation Plan](#implementation-plan)

## Summary

This is a design proposal to implement a CSI Driver for ZFS volume provisioning for Kubernetes. This design describes how a ZFS dataset will be represented/managed as a kubernetes customer resource, how CSI driver will be implemented  support dynamic provisioning of Volumes (ZFS Datasets)  on ZPOOL.
Using the design/solution described in this document, users will be able to dynamically provision a Local PV backed by a ZFS Volume. This design expects that the administrators have provisioned a ZPOOL on the nodes, as part of adding the node to the Kubernetes Cluster.
Using a ZFS Local PV has the following advantages - as opposed to Kubernetes native Local PV backed by direct attached devices:
- Sharing of the devices among multiple application pods.
- Enforcing quota on the volumes, making sure the pods don’t consume more than the capacity allocated to them.
- Ability to take snapshots of the Local PV
- Ability to sustain single disk failures - using the ZPOOL RAID functionality
- Ability to use data services like compression and encryption.

## Design Constraints/Assumptions

- Ubuntu 18.04
- Kubernetes 1.14+
- Node are installed with ZFS 0.7 or 0.8
- ZPOOLs are pre-created by the administrator on the nodes. Zpools on all the nodes will have the same name.
- StorageClass Topology specification will be used to restrict the Volumes to be provisioned on the nodes where the ZPOOLs are available.

## Proposal

### User Stories

#### Create a volume
I should be able to provide a volume that can be consumed by my application. This volume should get created dynamically during application creation time and the provision should happen from the ZFS pool which is already running on the local nodes.

#### Delete the volume
I should be able to delete the volume that was being consumed by my application. This volume should get deleted only when the application is deleted and it should be cleaned up from the ZFS pool running on the node.

### Implementation Details

#### Volume Creation Workflow
- CSI driver will handle CSI request for volume create
- CSI driver will read the request parameters and create following resources:
- ZFSVolume (Kubernetes custom resource)
- ZFSVolume will be watched for the property change

#### Volume Deletion Workflow
- CSI driver will handle CSI request for volume delete
- CSI driver will read the request parameters and delete corresponding ZFSPV volume resource

#### High Level Design
- user will setup all the node and setup the ZFS pool on each of those nodes.
- user will deploy below sample storage class where we get all the needed zfs properties for creating the volume. The storage class will have allowedTopologies and pool name which will tell us that pool is available on those nodes and it can pick any of that node to schedule the PV. If allowed topologies are not provided then it means the pool is there on all the nodes and scheduler can create the PV anywhere.

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: openebs-zfspv
provisioner: zfs.csi.openebs.io
parameters:
  blocksize: "4k"
  compression: "on"
  dedup: "on"
  thinprovision: "yes"
  poolname: "zfspv-pool"
allowedTopologies:
- matchLabelExpressions:
  - key: kubernetes.io/hostname
    values:
    - gke-zfspv-user-default-pool-c8929518-cgd4
    - gke-zfspv-user-default-pool-c8929518-dxzc
```

- user will deploy a PVC using above storage class

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: demo-zfspv-vol-claim
spec:
  storageClassName: openebs-zfspv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
```
## Workflow

### 1. CSI create volume
At CSI, when we get a Create Volume request, it will first try to find a node where it can create the PV object. The driver will trigger the scheduler which will return a node where the PV should be created.
In CreateVolume call, we will have the list of nodes where the ZFS pools are present and the volume should be created in anyone of the node present in the list.

#### 1.1 Scheduler
At this point the ZFS driver will have list of all nodes where ZFS pools are present. It will go through the list and pick the appropriate node to schedule the PV.

##### Volume Weighted Scheduler :-

In this scheduling algorithm the scheduler will pick the node where less number of volumes are provisioned. This is the default scheduling if no scheduling algorithm is provided.

Lets say there are 2 nodes node1 and node2 with below pool configuration :-
```
node1 
|
|-----> pool1
|         |
|         |------> pvc1
|         |------> pvc2
|-----> pool2
          |------> pvc3

node2
|
|-----> pool1
|         |
|         |------> pvc4
|-----> pool2
          |------> pvc5
	  |------> pvc6
```
So if application is using pool1 as shown in the below storage class, then ZFS driver will schedule it on node2 as it has one volume as compared to node1 which has 2 volumes in pool1.
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: openebs-zfspv
provisioner: zfs.csi.openebs.io
parameters:
  blocksize: "4k"
  compression: "on"
  dedup: "on"
  thinprovision: "yes"
  scheduler: "VolumeWeighted"
  poolname: "pool1"
```

So if application is using pool2 as shown in the below storage class, then ZFS driver will schedule it on node1 as it has one volume only as compared node2 which has 2 volumes in pool2.
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: openebs-zfspv
provisioner: zfs.csi.openebs.io
parameters:
  blocksize: "4k"
  compression: "on"
  dedup: "on"
  thinprovision: "yes"
  scheduler: "VolumeWeighted"
  poolname: "pool2"
```
In case of same number of volumes on all the nodes for the given pool, it can pick any node and schedule the PV on that.

##### Capacity Weighted Scheduler :-
In this scheduling algorithm the scheduler will account the available space in ZFS pool into scheduling consideration and schedule the PV to the appropriate ZFS pool where sufficient space is available.
Consider the below scenario in a two node cluster setup :-
node1
|
|-----> pool1 (available 1TB)
|-----> pool2 (available 500GB)

node2
|
|-----> pool1 (available 300 GB)
|-----> pool2 (available 2TB)

Here, if application is using pool1 then the volume will be provisioned on node1 as it has more space available than node2 for pool1.
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: openebs-zfspv
provisioner: zfs.csi.openebs.io
parameters:
  blocksize: "4k"
  compression: "on"
  dedup: "on"
  thinprovision: "yes"
  scheduler: "CapacityWeighted"
  poolname: "pool1"
```
If application is using pool2 then volume will be provisioned on node2 as it has more space available that node1 for pool2.
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: openebs-zfspv
provisioner: zfs.csi.openebs.io
parameters:
  blocksize: "4k"
  compression: "on"
  dedup: "on"
  thinprovision: "yes"
  scheduler: "CapacityWeighted"
  poolname: "pool2"
```
In case if same space is available for all the nodes, the scheduler can pick anyone and create the PV for that.

#### 1.2  Volume Creation

It will create the PV object on scheduled node so that the application using that PV always comes to the same node and also it creates the ZFSVolume object for that volume in order to manage the creation of the ZFS dataset. There will be a watcher at each node which will be watching for the ZFSVolume resource which is aimed for them. The watcher is inbuilt into ZFS node-agent. As soon as ZFSVolume object is created for a node, the corresponding watcher will get the add event and it will create the ZFS dataset with all the volume properties from ZFSVolume custom resource. It will get the pool name from the ZFSVolume custom resource and creates the volume in that pool with pvc name.

### 2. CSI Node Publish
When the application pod is scheduled on a node, the CSI node-agent will get a NodePublish event. The driver will get the device path from the ZFSVolume customer resource and try to mount the file system as per user request given in the storage class. Once the ZFS volume dataset is created it will put a finalizer and return successful for the NodePublish event.

- the kubernetes managed ZFS volume will look like this

```yaml
apiVersion: openebs.io/v1alpha1
kind: ZFSVolume
metadata:
  creationTimestamp: "2019-11-03T06:08:02Z"
  finalizers:
  - zfs.openebs.io/finalizer
  generation: 1
  labels:
    kubernetes.io/nodename: gke-pawan-zfspv-default-pool-8b577544-5wgl
  name: pvc-4b083833-fe00-11e9-b162-42010a8001b1
  namespace: openebs
  resourceVersion: "147959"
  selfLink: /apis/openebs.io/v1alpha1/namespaces/openebs/zfsvolumes/pvc-4b083833-fe00-11e9-b162-42010a8001b1
  uid: 4b0fd8bc-fe00-11e9-b162-42010a8001b1
spec:
  blocksize: 4k
  capacity: "4294967296"
  compression: "on"
  dedup: "on"
  ownerNodeID: gke-pawan-zfspv-default-pool-8b577544-5wgl
  poolName: zfspv-pool
  thinProvison: "yes"
```

### 3. CSI delete volume

When CSI will get volume destroy request, it will destroy the created zvol and also deletes the corresponding ZFSVolume custom resource.

### 4. CSI ZFSPV property change
There will be a watcher watching for this ZFSVolume custom resource in the agent. We can update the ZFSVolume custom resource with the desired property and the watcher of this custom resource will apply the changes to the corresponding volume.

### 5. CSI SnapShot

When ZFS CSI controller gets a snapshot create request :-

```yaml
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1beta1
metadata:
  name: zfspv-snapclass
  annotations:
    snapshot.storage.kubernetes.io/is-default-class: "true"
driver: zfs.csi.openebs.io
deletionPolicy: Delete
```

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: zfspv-snap
  namespace: openebs
spec:
  volumeSnapshotClassName: zfspv-snapclass
  source:
    persistentVolumeClaimName: zfspv-pvc
```

it will create a ZFSSnapshot custom resource. This custom resource will get all the details from the ZFSVolume CR, ownerNodeID will be same here as snapshot will also be there on same node where the original volume is there. The controller will create the request with status as Pending and set a label "openebs.io/volname" to the volume name from where the snapshot has to be created.

```yaml
apiVersion: openebs.io/v1alpha1
kind: ZFSSnapshot
metadata:
  name: snapshot-ead3b8ab-306a-4003-8cc2-4efdbb7a9306
  namespace: openebs
  labels:
    openebs.io/persistence-volum: pvc-34133838-0d0d-11ea-96e3-42010a800114
spec:
  blocksize: 4k
  capacity: "4294967296"
  compression: "on"
  dedup: "on"
  ownerNodeID: zfspv-node1
  poolName: zfspv-pool
  status: Pending
```

The watcher of this resource will be the ZFS node agent. The agent running on ownerNodeID node will check this event and create a snapshot with the given name. Once the node agent is able to create the snapshot, it will add a finalizer "zfs.openebs.io/finalizer" to this resource. Also, it will update the status field to Ready, so that the controller can check this and return successful for the snap create request, the final snapshot object will be :-

```yaml
apiVersion: openebs.io/v1alpha1
kind: ZFSSnapshot
metadata:
  name: zfspv-snap
  namespace: openebs
  Finalizers:
    zfs.openebs.io/finalizer
  labels:
    openebs.io/persistence-volume: pvc-34133838-0d0d-11ea-96e3-42010a800114
spec:
  blocksize: 4k
  capacity: "4294967296"
  compression: "on"
  dedup: "on"
  ownerNodeID: zfspv-node1
  poolName: zfspv-pool
status:
  state: Ready
```
### 5.1 Alternate Design

We can use GRPC call also to create the snapshot, The controller plugin will call node plugin's grpc server to create the snapshot. Creating a ZFSSnapshot custom resource has advantages :-

- Even if Node plugin is down we can get the info about snapshots
- No need to do zfs call every time to get the list of snapshots
- Controller plugin and Node plugin can run without knowledge of each other
- Reconciliation is easy to manage as K8s only supports a reconciliation based snapshots as of today. For example, the operation to create a snapshot is triggered via K8s CR. Post that, K8s will be re-trying till a successful snapshot is created. In this case, having an API doesn't add much value.

However, there will be use cases where snapshots have to be taken while the file system is frozen to get an application-consistent snapshot. This can required that a snapshot API should be available with blocking API calls that can be aborted after an upper time limit.

Maybe, in a future version, we should add a wrapper around the snapshot functionality and expose it through node agent API. This can be tracked in the backlogs.

### 6. CSI Clone

When ZFS CSI controller gets a clone create request :-

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: zfspv-clone
spec:
  dataSource:
    name: zfspv-snap
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
```

it will create a ZFSVolume custom resource with same spec as snapshot object. Since clone will be on the same node where snapshot exist so ownerNodeID will also be same.

```yaml
apiVersion: openebs.io/v1alpha1
kind: ZFSVolume
metadata:
  name: zfspv-clone
  namespace: openebs
spec:
  blocksize: 4k
  capacity: "4294967296"
  compression: "on"
  dedup: "on"
  ownerNodeID: zfspv-node1
  poolName: zfspv-pool
  snapName: pvc-34133838-0d0d-11ea-96e3-42010a800114@snapshot-ead3b8ab-306a-4003-8cc2-4efdbb7a9306
```

The watcher of this resource will be the ZFS node agent. The agent running on ownerNodeID node will check this event and create a clone from the snapshot with the given name. Once the node agent is able to create the clone from the given snapshot, it will add a finalizer "zfs.openebs.io/finalizer" to this resource. the final clone ZFSVolume object will be :-


```yaml
apiVersion: openebs.io/v1alpha1
kind: ZFSVolume
metadata:
  name: pvc-e1230d2c-b32a-48f7-8b76-ca335b253dcd
  namespace: openebs
  Finalizers:
    zfs.openebs.io/finalizer
spec:
  blocksize: 4k
  capacity: "4294967296"
  compression: "on"
  dedup: "on"
  ownerNodeID: zfspv-node1
  poolName: zfspv-pool
  snapName: pvc-34133838-0d0d-11ea-96e3-42010a800114@snapshot-ead3b8ab-306a-4003-8cc2-4efdbb7a9306
```
Note that if ZFSVolume CR does not have snapName, then a normal volume will be created, the snapName field will specify whether we have to create a volume or clone.

## Implementation Plan

### Phase 1
1. Provisioning via node selector/affinity.
2. De-Provisioning of volume.
3. Volume Property change support.

### Phase 2
1. Support provisioning without Node Selector/Affinity.
2. Monitoring of Devices and ZFS statistics.
3. Alert based on Device and ZFS observability metrics.

### Phase 3
1. BDD for ZFSPV.
2. CI  pipelines setup to validate the software.
