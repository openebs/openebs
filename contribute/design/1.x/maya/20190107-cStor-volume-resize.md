---
oep-number: draft Resize 20190701
title: cStor Volume Resize
authors:
  - "@mittachaitu"
owners:
  - "@kmova"
  - "@vishnuitta"
  - "@amitkumardas"
  - "@payes"
  - "@pawanpraka1"
editor: "@mittachaitu"
creation-date: 2019-07-01
last-updated: 2019-07-01
status: provisional
see-also:
  - NA
replaces:
  - NA
superseded-by:
  - NA
---

# cStor Volume Resize

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Resize cStor Volume](#resize-cstor-volume)
    * [Implementation Details](#implementation-details)
    * [Custom Resources used to resize cStor volume](#custom-resource-used-to-resize)
    * [Current Implementation](#current-implementation)
      * [High Level cStor Volume Resize Workflow](#high-level-cStor-volume-resize-workflow)
    * [High Level Design](#high-level-design)
      * [CStorVolumeClaim -- existing custom resource](#cstorvolumeclaim----existing-custom-resource)
      * [CStorVolume -- existing custom resource](#cstorvolume----existing-custom-resource)
      * [CStorVolumeReplica -- existing custom resource](#cstorvolumereplica----existing-custom-resource)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)

## Summary

This proposal charts out the design details to implement resize workflow on cStor Volumes.

## Motivation

Resizing volume is the most prominent feature for any storage providers.
In this we will concentrate only on cStor volumes.

### Goals

- Ability to resize a cStor volume in kubernetes cluster by taking trigger
  point as pvc spec capacity change.

## Proposal

### User Stories

#### Resize cStor Volume:
As an application developer I should be able to resize a volume on
fly(when application consuming volume).

### Implementation Details

There was a working flow for resizing cStor volumes via REST and grpc calls.
Since there are more visible barriers(mainly when container or pod restarts)
REST or grpc calls will fail.

The sections below can be assumed to be specific to `cStor` unless mentioned
otherwise.

### Custom Resources used to resize cStor volume

Sample CVC yaml when resize is in progress
```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorVolumeClaim
metadata:
  annotations:
    openebs.io/config-class: openebs-csi-default
    openebs.io/volumeID: pvc-b3e44fa5-98f2-11e9-b58e-42010a80006c
  creationTimestamp: "2019-06-27T15:46:19Z"
  finalizers:
  - cvc.openebs.io/finalizer
  generation: 2
  name: pvc-b3e44fa5-98f2-11e9-b58e-42010a80006c
  namespace: openebs
  resourceVersion: "2101768"
  selfLink: /apis/openebs.io/v1alpha1/namespaces/openebs/cstorvolumeclaims/pvc-b3e44fa5-98f2-11e9-b58e-42010a80006c
  uid: b51a35c9-98f2-11e9-b58e-42010a80006c
publish:
  nodeId: csi-node-2
spec:
  capacity:
    storage: 40Gi
status:
  phase: Bound
  ## Current underlying volume capacity
  capacity: 20Gi
  Conditions:
    - Type: Resizing
       Status: InProgress
       ##Last time we probed the condition
       LastProbeTime:
       ##Last time the condition transitioned from one status to another
       LastTransitionTime:
       Reason: Resize is in progress
       Message:

```

Sample cstorvolume yaml when resize is in progress
```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorVolume
metadata:
  annotations:
    openebs.io/fs-type: ext4
    openebs.io/lun: "0"
    openebs.io/storage-class-ref: |
      name: single-sc
      resourceVersion: 835
  creationTimestamp: "2019-07-01T04:56:04Z"
  generation: 1
  labels:
    openebs.io/cas-template-name: cstor-volume-create-default-1.0.0
    openebs.io/persistent-volume: pvc-87ac0046-9bbc-11e9-8959-54e1ad4a9dd4
    openebs.io/version: 1.0.0
  name: pvc-87ac0046-9bbc-11e9-8959-54e1ad4a9dd4
  namespace: openebs
  resourceVersion: "1552"
  selfLink: /apis/openebs.io/v1alpha1/namespaces/openebs/cstorvolumes/pvc-87ac0046-9bbc-11e9-8959-54e1ad4a9dd4
  uid: 87d11c54-9bbc-11e9-8959-54e1ad4a9dd4
spec:
  capacity: 40Gi
  consistencyFactor: 1
  iqn: iqn.2016-09.com.openebs.cstor:pvc-87ac0046-9bbc-11e9-8959-54e1ad4a9dd4
  nodeBase: iqn.2016-09.com.openebs.cstor
  replicationFactor: 1
  status: Init
  targetIP: 10.0.0.118
  targetPort: "3260"
  targetPortal: 10.0.0.118:3260
status:
  phase: ""
  ## Current underlying volume capacity
  capacity: 20Gi
  Conditions:
    - Type: Resizing
       Status: InProgress
       ##Last time we probed the condition
       LastProbeTime:
       ##Last time the condition transitioned from one status to another
       LastTransitionTime:
       Reason: Resize is in progress
       Message:

```

#### Current Implementation -- Volume Resize
- CSI controller will get gRPC call from kubernetes-csi external-resizer
  controller(when pvc storage field is updated).
- CSI controller acquire lease and update CVC capacity with latest size and
  status of CVC with resize conditions.
  Example status: status of CVC when resize request is in progress.
```yaml
      Status:
        capacity: 20Gi
        Conditions:
          - Type: Resizing
            Status: InProgress
            LastProbeTime: date
            LastTransitionTime: (update only when there is a change in size)
            Reason: Capacity changed
            Message: Resize pending
```
   Note: Please refer CVC under Custom Resources used to resize cStor volume section for entier CVC.
- Based on the status of CVC CSI will respond to the gRPC request which was from kubernetes-csi.
- CVC controller present in maya-apiserver will get update event on corresponding
  CVC CR. Update event will process below steps
  - Check is there any ongoing resize on cstorvolume(CV) if so return.
    Example status: CV status when resize is in progress
```yaml
      Status:
        capacity: 20Gi
        Conditions:
          - Type: Resizing
            Status: InProgress
            LastProbeTime: date
            LastTransitionTime: (update value by picking it from CVC LastTransitionTime)
            Reason: Capacity changed
            Message: Resize pending
```
   Note: Please refer CV under Custom Resources used to resize cStor volume
        section for entier CV.
  - Check is there any capacity changes in CV and CVC object if so update desired
    capacity field and status field with required details like (size, pending,
    LastTransitionTime, LastProbeTime) in CV object.
  - During CVC reconciliation time Check is there any resize is pending on CVC if
    so check corresponding CV resize status if it success/failure update the CVC
    resize condition with message present on CV status message and delete CV
    resize conditions on success.

    Example status: CVC status when resize is success
```yaml
      Status:
        capacity: 40Gi
        Conditions:
          - Type: Resizing
            Status: Success
            LastProbeTime: date
            LastTransitionTime: (update while updating resize condition status)
            Reason: Capacity changed
            Message: Resize Success
```
   Note: Please refer CVC under Custom Resources used to resize cStor volume section
         for entier CVC.

- Cstor-volume-mgmt container as a target side car which is already having a
  volume-controller watching on CV object will get update event (if missed at
  the time of sync event) and volume-controller will process the request with following steps
  - Volume-controller will process the CV update event in below steps
    - Volume-controller will executes `istgtcontrol resize <volume_name> <size_unit>`
      command(rpc call) if there is any resize status is pending on that
      volume(based on resize status condition and capacity change in spec and
      status of CV).
    - If above rpc call success volume-controller will updates istgt.conf file
      and update CVR capacity to latest size(with CV capacity). If volume
      controller succeed in updating cvr and istgt.conf file then update
      resize status as success and status capacity on CV.
    - If it is a failure response from rpc then generate kubernetes events and
      update CV reisze condition message with reason of failure.
      Do nothing just return(reconciliation will take care of doing the above
      process again).
- When cstor-istgt get a resize request it will trigger a resize request to zfs
  on successful response cstor-istgt will return a success response to
  cstor-volume-mgmt.
  - cstor-istgt will disconnect the replicas from which we have not received the
    response and then the successful response will send to the sidecar.
    cstor-istgt will send updated size to replicas at the time of management
    connection with the target.
  Note: Processing `istgtcontrol resize` is a blocking call.

- zfs will receives the resize request, it will resize the corresponding volume
  and sent back the response to cstor-istgt(aka target).
  Note:
    In ephemeral case(temporary storage) when resize is success at the time of
    node unavailable cases and when the node up need to take care of rebuilding
    snapshots of different sizes.

## High Level cStor Volume Resize Workflow
    https://docs.google.com/presentation/d/117m9gt-9BgbnzdHdKH8Ecqt8_SxB9zGsdIGh9UIPzlc/edit?usp=sharing

## Drawbacks

NA

## Alternatives

NA
