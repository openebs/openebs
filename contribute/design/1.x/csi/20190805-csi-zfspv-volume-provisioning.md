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
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Create a volume](#create-a-volume)
      * [Delete the volume](#delete-the-volume)
    * [Implementation Details](#implementation-details)
      * [Volume Creation Workflow](#volume-creation-workflow)
      * [Volume Deletion Workflow](#volume-deletion-workflow)
    * [High Level Design](#high-level-design)
* [Implementation](#implementation)
* [Infrastructure Needed](#infrastructure-needed)

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
- ZfsVolume (Kubernetes custom resource)
- ZfsVolume will be watched for the property change

#### Volume Deletion Workflow
- CSI driver will handle CSI request for volume delete
- CSI driver will read the request parameters and delete corresponding ZFSPV volume resource

#### High Level Design
- user will setup all the node and setup the ZFS pool on each of those nodes.
- user will deploy below sample storage class where we will get input of all the needed zfs properties. The storage class will have allowedTopologies and pool name which will tell us that pool is available on those nodes and it can pick any of that node to schedule the application pod.

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: openebs-zfspv
provisioner: openebs.io/zfs
parameters:
  blocksize: "4k"
  compression: "on"
  dedup: "on"
  thinprovision: "yes"
  poolname: "zfspv-pool"
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: kubernetes.io/hostname
    values:
    - csi-ubuntu-16
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
At CSI when we get a volume create request, we will create a PV object. The actual volume will be created at the Node publish time. We will have StorageClass at this point. We will create a ZfsVolume custom resource with all the volume properties that are present in the PVC and corresponding Storage Class . This custom resource will be used for creating and managing the ZFS dataset.

### 2. CSI Node Publish
When kubernetes schedules the application pod according to the Topology mentioned in the StorageClass, The CSI will get a NodePublish event. It will get all the volume properties from ZfsVolume custom resource and it will fire zfs create command and creates the volume. It will get the pool name from the ZfsVolume custom resource and create a volume on that pool with pvc name. Then it will format and mount the created zvol to the desired location and return.

- the kubernetes managed ZFS volume will look like this

```yaml
apiVersion: v1
items:
- apiVersion: openebs.io/v1alpha1
  kind: ZFSVolume
  metadata:
    creationTimestamp: "2019-08-25T08:02:14Z"
    generation: 2
    name: pvc-a6855135-c70e-11e9-8fa2-42010a80012d
    namespace: openebs
    resourceVersion: "13735"
    selfLink: /apis/openebs.io/v1alpha1/namespaces/openebs/zfsvolumes/pvc-a6855135-c70e-11e9-8fa2-42010a80012d
    uid: a691916c-c70e-11e9-8fa2-42010a80012d
  spec:
    blocksize: 4k
    capacity: "4294967296"
    compression: "on"
    dedup: "on"
    devicePath: /dev/zvol/zfspv-pool/pvc-a6855135-c70e-11e9-8fa2-42010a80012d
    ownerNodeID: gke-user-zfspv-default-pool-354050c7-wl8v
    poolName: zfspv-pool
    thinprovison: "yes"
    volName: pvc-a6855135-c70e-11e9-8fa2-42010a80012d
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

### 3. CSI delete volume

When CSI will get volume destroy request, it will destroy the created zvol and also deletes the corresponding ZfsVolume custom resource.

### 4. CSI ZFSPV property change
There will be a watcher watching for this ZfsVolume custom resource in the agent. We can update the ZfsVolume custom resource with the desired property and the watcher of this custom resource will apply the changes to the corresponding volume.

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
