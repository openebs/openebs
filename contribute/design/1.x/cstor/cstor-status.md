---
title: Status for CStor CRs
authors:
  - "@shubham14bajpai"
owners:
  - "@vishnuitta"
  - "@kmova"
  - "@AmitKumarDas"
editor: "@shubham14bajpai"
creation-date: 2020-02-24
last-updated: 2020-02-24
status: Implementable
---

# Status for CStor CRs

## Table of Contents

- [Status for CStor CRs](#pod-disruption-budget)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
    - [Proposed Implementation](#proposed-implementation)
      - [CSPI Status](#cspi-status)
      - [CSPC Status](#cspc-status)

## Summary

This proposal includes design details of the status information provided by the CStor CRs. The status information is used to determine the state of the corresponding CR.

## Motivation

The current CStor CRs don't provide appropriate information about the state of the CR and the reason for that state.

### Goals
  - Make CSPC and CSPI status informative enough to know the current state of the CR and the reason for the given state.

## Proposal

### User Stories

As a OpenEBS user, the information regarding a CR should be present in the status or events of the CR itself rather than looking for it in controller logs.

### Proposed Implementation

Kuberentes provides a framework for status conditions and events which can be used to pass relevant information from the controllers to the CRs. 

#### CSPI Status

The current CSPI status gives us the following information via kubectl get command which are the zpool properties taken from the zfs commands and parsed to cspi status.

```diff
mayadata:maya$ kubectl -n openebs get cspi
-  NAME                  HOSTNAME    ALLOCATED   FREE    CAPACITY  STATUS   AGE
-  sparse-pool-1-7xq5    127.0.0.1     218K      9.94G    9.94G    ONLINE   134m
+  NAME                  HOSTNAME    ALLOCATED   FREE    CAPACITY  HEALTHYVOLUMES  STATUS   AGE
+  sparse-pool-1-7xq5    127.0.0.1     218K      9.94G    9.94G         3/5        ONLINE   134m
```

As the CSPI and CVR have their controllers clubbed together as cspi-mgmt having CVR information on CSPI will help with the debugging process.
The current CSPI gives the status as a form of Status.Phase which is the zpool state representation. This Phase is updated by the CSPI mgmt container. The mgmt container gets the health status from the zpool command and sets that to the phase of CSPI. The possible CSPI phases are:

**Online** : The device or virtual device is in normal working order. Although some transient errors might still occur, the device is otherwise in working order.

**Degraded** : The virtual device has experienced a failure but can still function. This state is most common when a mirror or RAID-Z device has lost one or more constituent devices. The fault tolerance of the pool might be compromised, as a subsequent fault in another device might be unrecoverable.

**Faulted** : The device or virtual device is completely inaccessible. This status typically indicates the total failure of the device, such that ZFS is incapable of sending data to it or receiving data from it. If a top-level virtual device is in this state, then the pool is completely inaccessible.

**Offline** : The device has been explicitly taken offline by the cspi-mgmt controller.

**Unavail** : The device or virtual device cannot be opened. In some cases, pools with UNAVAIL devices appear in DEGRADED mode. If a top-level virtual device is UNAVAIL, then nothing in the pool can be accessed.

**Removed** : The device was physically removed while the system was running. Device removal detection is hardware-dependent and might not be supported on all platforms.

The phase is the current state of the CSPI. With the addition of Conditions to the status we can represent the latest available observations of a CSPI’s current state. The conditions for cspi will be represented by the following structure.
```go
// CSPIConditionType describes the state of a CSPI at a certain point.
type CStorPoolInstanceCondition struct {
	// Type of CSPI condition.
	Type CSPIConditionType `json:"type" protobuf:"bytes,1,opt,name=type,casttype=DeploymentConditionType"`
	// Status of the condition, one of True, False, Unknown.
	Status corev1.ConditionStatus `json:"status" protobuf:"bytes,2,opt,name=status,casttype=k8s.io/api/core/v1.ConditionStatus"`
	// The last time this condition's reason (or) message was updated.
	LastUpdateTime metav1.Time `json:"lastUpdateTime,omitempty" protobuf:"bytes,6,opt,name=lastUpdateTime"`
	// Last time the condition transitioned from one status to another.
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty" protobuf:"bytes,7,opt,name=lastTransitionTime"`
	// The reason for the condition's last transition.
	Reason string `json:"reason,omitempty" protobuf:"bytes,4,opt,name=reason"`
	// A human readable message indicating details about the transition.
	Message string `json:"message,omitempty" protobuf:"bytes,5,opt,name=message"`
}
```

When the conditions like expansion or disk replacement is under progress the message and reason fields will get populated with corresponding details and once the condition has reached completion the fields will have some default values as placeholders until the condition is triggered again.

The proposed conditions for CSPI are :

**PodAvailable** : The PodAvailable condition represents whether the CSPI pool pod is running or not. Whenever the PodAvailable is set to False then the CSPI phase should be set to Unavail to tackle the stale phase on the CSPI when the pool pod is not in running state. The owner of this condition will be the CSPC operator as when the pool pod is lost the cspi-mgmt will not be able to update the conditions.
```yaml
Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    status: "True"
    type: PodAvailable

Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    message: 'pool pod not in running state'
    reason: MissingPoolDeployment
    status: "False"
    type: PodAvailable
```

**Created** : The Created condition represents whether the pool got created successfully or not.
```yaml
Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    status: "True"
    type: Created

Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    message: ‘error msg from zfs command'
    reason: CreationFailed
    status: "False"
    type: Created
```

**Expanded** : The Expanded condition gets appended when someone triggers pool expansion and represents the status of expansion. If multiple vdev were added for expansion then condition.status will be set as true further information will be available on events of corresponding CSPI.
```yaml
Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    status: "True"
    type: Expanded

Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    reason: ExpansionInProgress
    status: "Unknown"
    type: Expanded
```

**DiskReplaced** : The DiskReplaced condition gets appended when someone triggers disk replacement on that pool and represents the status of replacement. If multiple disks were replacing then condition message will show that the following are block devices that were under replacement. Further information will be available on corresponding CSPI events.
```yaml
Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    status: "True"
    type: DiskReplaced

Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    message: ‘error msg from zfs command'
    reason: ReplacementFailed
    status: "False"
    type: DiskReplaced
```

**DiskUnavailable** : The DiskUnavailable condition gets appended when someone when one or more disk gets into an unavailable state. If multiple disks were unavailable then same DiskUnavailable will set to true. The condition message will have information about the names disks were unavailable. Further information will be available on events of corresponding CSPI.
```yaml
Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    message: ‘disk gone bad’
    reason: DiskFailed
    status: "True"
    type: DiskUnavailable

Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    status: "False"
    type: DiskUnavailable
```

**PoolLost** : The PoolLost condition gets appended when the pool import fails because of some reason. 
```yaml
Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    message: ‘unable to import pool’
    reason: ImportFailed
    status: "True"
    type: PoolLost

Conditions:
  - lastUpdateTime: 
    lastTransitionTime: 
    status: "False"
    type: PoolLost
```

#### CSPC Status

The current CSPC does not have any status to represent the state of the CSPC whether all the CSPI got provisioned or not, how many CSPI are healthy or some other state.

The CSPC status should be informative enough to tell the current state of the provisioned instances whether they are in Healthy/Other phase and whether all instances are provisioned or not. It should not be having the details of the instances as the CSPI status already have the corresponding status and repeating the status is not required. The below example shows how the status should look like: 
```sh
NAME            PROVISIONEDINSTANCES   RUNNINGINSTANCES   HEALTHYINSTANCES   AGE
sparse-pool-1           2/3                  1           	      1            142M

NAME            PROVISIONEDINSTANCES   RUNNINGINSTANCES   HEALTHYINSTANCES   AGE
sparse-pool-1           3/3                  3           	      3            142M
```
**PROVISIONEDINSTANCES** gives the number of CSPI that needs to be provisioned and the actual number of CSPI provisioned.

**RUNNINGINSTANCES** is the count of CSPI which have been provisioned and the pod may or maynot be running and CSPI is not in ONLINE state.

**HEALTHYINSTANCE** is the count of CSPI which has a pod in running state and CSPI is in ONLINE state.

Any additional information needed for the user can be pushed as events to the CSPC object.