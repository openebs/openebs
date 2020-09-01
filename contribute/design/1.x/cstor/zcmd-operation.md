---
oep-number: ZCommands Execution Via CSP Custom Resource
title: ZCommands execution via custom resources
authors:
  - "@mittachaitu"
owners:
  - "@kmova"
editor: "@mittachaitu"
creation-date: 2020-08-26
last-updated: 2020-08-26
status: provisional
---

# ZCommands execution via Custom Resource

## Table of Contents

- [ZCommands execution via Custom Resource](#zcommands-execution-via-custom-resource)
	- [Table of Contents](#table-of-contents)
	- [Summary](#summary)
	- [Motivation](#motivation)
		- [Goals](#goals)
	- [Proposal](#proposal)
		- [Stories](#stories)
		- [Proposed Implementation](#proposed-implementation)
		- [Steps to be performed by high level operator](#steps-to-be-performed-by-high-level-operator)
		- [Low Level Design](#low-level-design)
			- [WrokFlow](#wrokflow)

## Summary

This proposal brings out the design details to implement zpool/zfs commands execution
via CSP custom resource.

## Motivation

- Zpool and ZFS command execution via CSP custom resource

### Goals

- High level operators which requires execution of Zpool/ZFS command can be executed via CStorPool(CSP) custom resource.

## Proposal

### Stories

High level operator should able to execute Zpool/ZFS commands even if user has tighten the RBAC rules.

### Proposed Implementation

High level operator will update the new field in CSP with command that it requires to execute in corresponding pool. After updating the CSP resource with command corresponding watcher present in CStor-pool-mgmt will get modified event and execute the command mention on CSP resource and update the result in status field.

**NOTE:** Changes can be eliminated if we set proper RBAC rules migration job(i.e allowing changes migration job to perform exec operation).

### Steps to be performed by high level operator

High level operator/job will add command on CSP resource that required to execute and wait for response in status.

### Low Level Design

#### WrokFlow

When CSP resource is updated with command and no.of times it has to retry for command execution watcher present in the cstor-pool-mgmt will get an event and execute the command during every sync time and update the output in status of corresponding CSP upon successfully execution of command or completion of retries. If retries are completed it will update the status as with corresponding error message.

**Current Schema**:

```go
// CStorPool describes a cstor pool resource created as custom resource.
type CStorPool struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec           CStorPoolSpec   `json:"spec"`
	Status         CStorPoolStatus `json:"status"`
	VersionDetails VersionDetails  `json:"versionDetails"`
}

// CStorPoolSpec is the spec listing fields for a CStorPool resource.
type CStorPoolSpec struct {
	Group    []BlockDeviceGroup `json:"group"`
	PoolSpec CStorPoolAttr      `json:"poolSpec"`
}

// BlockDeviceGroup contains a collection of block device for a given pool topology in CSP.
type BlockDeviceGroup struct {
	// Item contains a list of CspBlockDevice.
	Item []CspBlockDevice `json:"blockDevice"`
}

// CspBlockDevice contains the details of block device present on CSP.
type CspBlockDevice struct {
	// Name is the name of the block device resource.
	Name string `json:"name"`
	// DeviceID is the device id of the block device resource. In case of sparse
	// block device, it contains the device path.
	DeviceID string `json:"deviceID"`
	// InUseByPool tells whether the block device is present on spc. If block
	// device is present on SPC, it is true else false.
	InUseByPool bool `json:"inUseByPool"`
}

// BlockDeviceAttr stores the block device related attributes.
type BlockDeviceAttr struct {
	BlockDeviceList []string `json:"blockDeviceList"`
}

// CStorPoolAttr is to describe zpool related attributes.
type CStorPoolAttr struct {
	CacheFile string `json:"cacheFile"` //optional, faster if specified
	PoolType  string `json:"poolType"`  //mirrored, striped
	// OverProvisioning field is deprecated and not honoured
	OverProvisioning bool `json:"overProvisioning"` //true or false
	// ThickProvisioning, If true disables OverProvisioning
	ThickProvisioning bool `json:"thickProvisioning"` // true or false
	// ROThresholdLimit is threshold(percentage base) limit for pool read only mode, if ROThresholdLimit(%) of pool storage is used then pool will become readonly, CVR also. (0 < ROThresholdLimit < 100, default:100)
	ROThresholdLimit int `json:"roThresholdLimit"` //optional
}

// CStorPoolStatus is for handling status of pool.
type CStorPoolStatus struct {
	Phase    CStorPoolPhase        `json:"phase"`
	Capacity CStorPoolCapacityAttr `json:"capacity"`

	// LastTransitionTime refers to the time when the phase changes
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty"`

	//ReadOnly if pool is readOnly or not
	ReadOnly bool `json:"readOnly"`

	LastUpdateTime metav1.Time `json:"lastUpdateTime,omitempty"`
	Message        string      `json:"message,omitempty"`
}

// CStorPoolCapacityAttr stores the pool capacity related attributes.
type CStorPoolCapacityAttr struct {
	Total string `json:"total"`
	Free  string `json:"free"`
	Used  string `json:"used"`
}
```

**Proposed Schema Changes**

```go
// CStorPool describes a cstor pool resource created as custom resource.
type CStorPool struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec           CStorPoolSpec   `json:"spec"`
	Status         CStorPoolStatus `json:"status"`
	VersionDetails VersionDetails  `json:"versionDetails"`
}

// CStorPoolSpec is the spec listing fields for a CStorPool resource.
type CStorPoolSpec struct {
	Group    []BlockDeviceGroup `json:"group"`
	PoolSpec CStorPoolAttr      `json:"poolSpec"`
    // CommandExecution will contain the required information to execute the command
    CommandExecution CommandExecution
}

// CommandExecution contains the required details to execute command
type CommandExecution struct {
    // Command that need to execute on corresponding cStor pool
    Command string
    // MaxRetryCount desribes the max retries controller try for execution
    MaxRetryCount int
    // CurreentRetryCount describes the current iteration controller executing the command
    CurrentRetryCount int
}

// BlockDeviceGroup contains a collection of block device for a given pool topology in CSP.
type BlockDeviceGroup struct {
	// Item contains a list of CspBlockDevice.
	Item []CspBlockDevice `json:"blockDevice"`
}

// CspBlockDevice contains the details of block device present on CSP.
type CspBlockDevice struct {
	// Name is the name of the block device resource.
	Name string `json:"name"`
	// DeviceID is the device id of the block device resource. In case of sparse
	// block device, it contains the device path.
	DeviceID string `json:"deviceID"`
	// InUseByPool tells whether the block device is present on spc. If block
	// device is present on SPC, it is true else false.
	InUseByPool bool `json:"inUseByPool"`
}

// BlockDeviceAttr stores the block device related attributes.
type BlockDeviceAttr struct {
	BlockDeviceList []string `json:"blockDeviceList"`
}

// CStorPoolAttr is to describe zpool related attributes.
type CStorPoolAttr struct {
	CacheFile string `json:"cacheFile"` //optional, faster if specified
	PoolType  string `json:"poolType"`  //mirrored, striped
	// OverProvisioning field is deprecated and not honoured
	OverProvisioning bool `json:"overProvisioning"` //true or false
	// ThickProvisioning, If true disables OverProvisioning
	ThickProvisioning bool `json:"thickProvisioning"` // true or false
	// ROThresholdLimit is threshold(percentage base) limit for pool read only mode, if ROThresholdLimit(%) of pool storage is used then pool will become readonly, CVR also. (0 < ROThresholdLimit < 100, default:100)
	ROThresholdLimit int `json:"roThresholdLimit"` //optional
}

// CStorPoolStatus is for handling status of pool.
type CStorPoolStatus struct {
	Phase    CStorPoolPhase        `json:"phase"`
	Capacity CStorPoolCapacityAttr `json:"capacity"`

	// LastTransitionTime refers to the time when the phase changes
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty"`

	//ReadOnly if pool is readOnly or not
	ReadOnly bool `json:"readOnly"`

    // CommandResult contains the output of command requested in spec section
    CommandResult string `json:"commandResult"`

	LastUpdateTime metav1.Time `json:"lastUpdateTime,omitempty"`
	Message        string      `json:"message,omitempty"`
}

// CStorPoolCapacityAttr stores the pool capacity related attributes.
type CStorPoolCapacityAttr struct {
	Total string `json:"total"`
	Free  string `json:"free"`
	Used  string `json:"used"`
}
```
