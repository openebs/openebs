# Moving CSPC and CSPI Schema to v1

## Table of Contents

* [Introduction](#introduction)
* [Goals](#goals)
* [Non-Goals](#non-goals)
* [Current State of Things](#current-state-of-things)
* [CSPC Schema Proposal](#cspc-schema-proposal)

## Introduction

This proposal highlights the limitations of current CSPC and CSPI schema and
proposes improvements for the same.
Please refer to the following link for cstor operator design document. 
https://github.com/openebs/openebs/blob/master/contribute/design/1.x/cstor-operator/doc.md

# Goals

The major goal of this document is to freeze the schema for CSPC and CSPI schema.
Apart from this the document focuses on following aspects too:

- Migrating the CSPC and CSPI CRD to v1 apiversion.
- Identify the breaking and upgrade changes and documentation around that.
- List of possible high level statuses fields on CSPC/CSPI.

# Non-Goals

- Introduction of new fields in the CSPC/CSPI to deliver feature etc.
- List of possible events that should be recorded on CSPC and CSPI.
- List of conditions that should be put on the CSPC and CSPI CRs.

**Note:** Conditions vs Events

Events can be of "Normal" or "Warning" only as of now in Kubernetes and components that processes the API object
(in this case, the CSPC or CSPI CR) can record some useful event on the custom resource(CR). Events let us understand the state of action performed by the component for the object (CR) and if those are recorded to the CR object, it can help in debugging. 
One typical example is -- Your pod was not created as part of applying the deployment object or the pods are in non-running state then we can describe the deployment object and see the events recorded by different components e.g. scheduler, attach-detach controller to understand why such thing happened.

Conditions can be a set of well-defined state that can occur for an API object.
For example, POD API object has "PodScheduled" as a conditions ( value being true of false ) and status.phase field in the API object that gives an high level overview of the pod e.g. Running, Pending etc.
 

## Current State of Things

### CSPC Schema

The CSPC API has the following capabilities : 
 
- CSPC API can be used to provision cStor pools on a single or multiple nodes. Pool configuration for each node can be specified in the CSPC. 

- Stripe, mirror, raidz1, and raidz2 are the only supported raid topologies.


- A single cStor pool on a node can have any number of raid groups. API schema can support heterogeneous raid topologies. ( e.g One raid group of mirror other of raidz and so on). ( Not sure if it works from the data plane side and can be of niche or trivial use case )


- A stripe raid group can have any number of block devices but not less than 1.


- A mirror, raidz and raidz2 raid group can only have exactly 2, 3 and 6 block devices only.  


- A raid group can be designated to be a write cache, read cache or spare, apart from regular vdev in a pool.


- CSPC has the capability to specify a cache file for faster imports.


- CSPC has the capability to specify for overprovisioning and compression.


- CSPC has the capability to specify a default raid group type for a pool spec at the node level. If the raid group spec does not have a type -- this default raid group type is used.


- Resource requirements can be passed for cstor-pool and side-car containers via CSPC and there is a defaulting mechanism too. Please refer to the following PRs to understand more on this:
https://github.com/openebs/maya/pull/1444
https://github.com/openebs/maya/pull/1567
NOTE: If resource and limit requirements are mentioned nowhere in the CSPC then there is no default value that gets applied.


- CSPC can be used to specify pod priority for pool pods and there is a defaulting mechanism too. Please refer to the following PR to understand more.
https://github.com/openebs/maya/pull/1566


- CSPC can be used to specify tolerations for pool pods and there is a defaulting mechanism too. Please refer to the following PR to understand more.
https://github.com/openebs/maya/pull/1549


- CSPC can be used to do block device replacement.


- CSPC can be used to do pool expansion.


- CSPC can be used to create a pool on a new brought up node. ( Horizontal scale )


Following is the current CSPC schema in go struct : 

```go
// CStorPoolCluster describes a CStorPoolCluster custom resource.
type CStorPoolCluster struct {
  metav1.TypeMeta   `json:",inline"`
  metav1.ObjectMeta `json:"metadata,omitempty"`
  Spec              CStorPoolClusterSpec   `json:"spec"`
  Status            CStorPoolClusterStatus `json:"status"`
  VersionDetails    VersionDetails         `json:"versionDetails"`
}

// CStorPoolClusterSpec is the spec for a CStorPoolClusterSpec resource
type CStorPoolClusterSpec struct {
  // Pools is the spec for pools for various nodes
  // where it should be created.
  Pools []PoolSpec `json:"pools"`
  // DefaultResources are the compute resources required by the cstor-pool
  // container.
  // If the resources at PoolConfig is not specified, this is written
  // to CSPI PoolConfig.
  DefaultResources *corev1.ResourceRequirements `json:"resources"`
  // AuxResources are the compute resources required by the cstor-pool pod
  // side car containers.
  DefaultAuxResources *corev1.ResourceRequirements `json:"auxResources"`
  // Tolerations, if specified, are the pool pod's tolerations
  // If tolerations at PoolConfig is empty, this is written to
  // CSPI PoolConfig.
  Tolerations []corev1.Toleration `json:"tolerations"`

  // DefaultPriorityClassName if specified applies to all the pool pods
  // in the pool spec if the priorityClass at the pool level is
  // not specified.
  DefaultPriorityClassName string `json:"priorityClassName"`
}

//PoolSpec is the spec for pool on node where it should be created.
type PoolSpec struct {
  // NodeSelector is the labels that will be used to select
  // a node for pool provisioning.
  // Required field
  NodeSelector map[string]string `json:"nodeSelector"`
  // RaidConfig is the raid group configuration for the given pool.
  RaidGroups []RaidGroup `json:"raidGroups"`
  // PoolConfig is the default pool config that applies to the
  // pool on node.
  PoolConfig PoolConfig `json:"poolConfig"`
}

// PoolConfig is the default pool config that applies to the
// pool on node.
type PoolConfig struct {
  // Cachefile is used for faster pool imports
  // optional -- if not specified or left empty cache file is not
  // used.
  CacheFile string `json:"cacheFile"`
  // DefaultRaidGroupType is the default raid type which applies
  // to all the pools if raid type is not specified there
  // Compulsory field if any raidGroup is not given Type
  DefaultRaidGroupType string `json:"defaultRaidGroupType"`

  // OverProvisioning to enable over provisioning
  // Optional -- defaults to false
  OverProvisioning bool `json:"overProvisioning"`
  // Compression to enable compression
  // Optional -- defaults to off
  // Possible values : lz, off
  Compression string `json:"compression"`
  // Resources are the compute resources required by the cstor-pool
  // container.
  Resources *corev1.ResourceRequirements `json:"resources"`
  // AuxResources are the compute resources required by the cstor-pool pod
  // side car containers.
  AuxResources *corev1.ResourceRequirements `json:"auxResources"`
  // Tolerations, if specified, the pool pod's tolerations.
  Tolerations []corev1.Toleration `json:"tolerations"`

  // PriorityClassName if specified applies to this pool pod
  // If left empty, DefaultPriorityClassName is applied.
  // (See CStorPoolClusterSpec.DefaultPriorityClassName)
  // If both are empty, not priority class is applied.
  PriorityClassName string `json:"priorityClassName"`
}

// RaidGroup contains the details of a raid group for the pool
type RaidGroup struct {
  // Type is the raid group type
  // Supported values are : stripe, mirror, raidz and raidz2

  // stripe -- stripe is a raid group which divides data into blocks and
  // spreads the data blocks across multiple block devices.

  // mirror -- mirror is a raid group which does redundancy
  // across multiple block devices.

  // raidz -- RAID-Z is a data/parity distribution scheme like RAID-5, but uses dynamic stripe width.
  // radiz2 -- TODO
  // Optional -- defaults to `defaultRaidGroupType` present in `PoolConfig`
  Type string `json:"type"`
  // IsWriteCache is to enable this group as a write cache.
  IsWriteCache bool `json:"isWriteCache"`
  // IsSpare is to declare this group as spare which will be
  // part of the pool that can be used if some block devices
  // fail.
  IsSpare bool `json:"isSpare"`
  // IsReadCache is to enable this group as read cache.
  IsReadCache bool `json:"isReadCache"`
  // BlockDevices contains a list of block devices that
  // constitute this raid group.
  BlockDevices []CStorPoolClusterBlockDevice `json:"blockDevices"`
}

// CStorPoolClusterBlockDevice contains the details of block devices that
// constitutes a raid group.
type CStorPoolClusterBlockDevice struct {
  // BlockDeviceName is the name of the block device.
  BlockDeviceName string `json:"blockDeviceName"`
  // Capacity is the capacity of the block device.
  // It is system generated
  Capacity string `json:"capacity"`
  // DevLink is the dev link for block devices
  DevLink string `json:"devLink"`
}

// CStorPoolClusterStatus is for handling status of pool.
type CStorPoolClusterStatus struct {
  Phase    string                `json:"phase"`
  Capacity CStorPoolCapacityAttr `json:"capacity"`
}

// CStorPoolClusterList is a list of CStorPoolCluster resources
type CStorPoolClusterList struct {
  metav1.TypeMeta `json:",inline"`
  metav1.ListMeta `json:"metadata"`

  Items []CStorPoolCluster `json:"items"`
}
```

### Limitations of Current CSPC

Although CSPC has an extensive schema, it suffers few limitations. I find following necessary improvements that can be done to make it more feature rich and pool related things more informative and debuggable.

Consider following improvement points : 

- Raidz can have 2+1, 4+1 or in general 2^n + 1 number of disks where n > 0.


- Similarly raidz2 can have 2^n + 2 number of disks where n>2. Although we can have 4 disks in raidz2 but that does not serve the purpose hence this should be restricted in the control plane.


- Write cache, read cache and spare property of a raid group cannot be specified simultaneously and there exists three different fields in CSPC to declare that. These three fields can be merged to be one field.


- CSPC does not have any status specifying the state of healthy pool instances vs total pool instances.


- There should exist a field to specify that the pool ( CSPI ) should not be considered for placing a cStor volume replica. ( Cordoning )


- The status field of CSPC should have following fields :
    - **currentNumberInstances:** Indicates the number of CSPI(s) present in the system.
    - **desiredNumberInstance:** Indicates the desired number of CSPI(s) that should be present in the system.
    - **healthyNumberInstances:** Indicates the number of healthy CSPI(s) that are present in the system.
    - **conditions:** Represents the latest available observations of a CSPC’s current state. It is an array that can represent various conditions as an when required and hence will give more flexibility in terms of improving in areas of information and debuggability as and when required.


## CSPC Schema Proposal

```go
// CStorPoolCluster describes a CStorPoolCluster custom resource.
type CStorPoolCluster struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	Spec              CStorPoolClusterSpec   `json:"spec"`
	Status            CStorPoolClusterStatus `json:"status"`
	VersionDetails    VersionDetails         `json:"versionDetails"`
}

// CStorPoolClusterSpec is the spec for a CStorPoolClusterSpec resource
type CStorPoolClusterSpec struct {
	// Pools is the spec for pools for various nodes
	// where it should be created.
	Pools []PoolSpec `json:"pools"`
	// DefaultResources are the compute resources required by the cstor-pool
	// container.
	// If the resources at PoolConfig is not specified, this is written
	// to CSPI PoolConfig.
	DefaultResources *corev1.ResourceRequirements `json:"resources"`
	// AuxResources are the compute resources required by the cstor-pool pod
	// side car containers.
	DefaultAuxResources *corev1.ResourceRequirements `json:"auxResources"`
	// Tolerations, if specified, are the pool pod's tolerations
	// If tolerations at PoolConfig is empty, this is written to
	// CSPI PoolConfig.
	Tolerations []corev1.Toleration `json:"tolerations"`

	// DefaultPriorityClassName if specified applies to all the pool pods
	// in the pool spec if the priorityClass at the pool level is
	// not specified.
	DefaultPriorityClassName string `json:"priorityClassName"`
}

//PoolSpec is the spec for pool on node where it should be created.
type PoolSpec struct {
	// NodeSelector is the labels that will be used to select
	// a node for pool provisioning.
	// Required field
	NodeSelector map[string]string `json:"nodeSelector"`
	// RaidConfig is the raid group configuration for the given pool.
	RaidGroups []RaidGroup `json:"raidGroups"`
	// PoolConfig is the default pool config that applies to the
	// pool on node.
	PoolConfig PoolConfig `json:"poolConfig"`
}

// PoolConfig is the default pool config that applies to the
// pool on node.
type PoolConfig struct {
	// Cachefile is used for faster pool imports
	// optional -- if not specified or left empty cache file is not
	// used.
	CacheFile string `json:"cacheFile"`
	// DefaultRaidGroupType is the default raid type which applies
	// to all the pools if raid type is not specified there
	// Compulsory field if any raidGroup is not given Type
	DefaultRaidGroupType string `json:"defaultRaidGroupType"`

	// OverProvisioning to enable over provisioning
	// Optional -- defaults to false
	OverProvisioning bool `json:"overProvisioning"`
	// Compression to enable compression
	// Optional -- defaults to off
	// Possible values : lz, off
	Compression string `json:"compression"`
	// Resources are the compute resources required by the cstor-pool
	// container.
	Resources *corev1.ResourceRequirements `json:"resources"`
	// AuxResources are the compute resources required by the cstor-pool pod
	// side car containers.
	AuxResources *corev1.ResourceRequirements `json:"auxResources"`
	// Tolerations, if specified, the pool pod's tolerations.
	Tolerations []corev1.Toleration `json:"tolerations"`

	// PriorityClassName if specified applies to this pool pod
	// If left empty, DefaultPriorityClassName is applied.
	// (See CStorPoolClusterSpec.DefaultPriorityClassName)
	// If both are empty, not priority class is applied.
	PriorityClassName string `json:"priorityClassName"`
}

// RaidGroup contains the details of a raid group for the pool
type RaidGroup struct {
	// Type is the raid group type
	// Supported values are : stripe, mirror, raidz and raidz2

	// stripe -- stripe is a raid group which divides data into blocks and
	// spreads the data blocks across multiple block devices.

	// mirror -- mirror is a raid group which does redundancy
	// across multiple block devices.

	// raidz -- RAID-Z is a data/parity distribution scheme like RAID-5, but uses dynamic stripe width.
	// radiz2 -- TODO
	// Optional -- defaults to `defaultRaidGroupType` present in `PoolConfig`
	Type string `json:"type"`

	// LoadType can have following values :
	// readCache -- The raid group is a read cache.
	// writeCache -- The raid group is a write cache.
	// spare -- The raid group is spare.
	// "" -- Empty value means this will be used a regular vdev to form pool.
	// What about default value ? Can this be changed after some point of time.
	LoadType string `json:"load_type"`
	// BlockDevices contains a list of block devices that
	// constitute this raid group.

	// DiskCount applies to raidz1 and raidz2 topology only.
	// For raidz1 a valid DiskCount value is 2^n +1 where n>0
	// For raidz2 a valid diskCount value is 2^n+2 where n>1
	DiskCount int `json:"disk_count"`

	BlockDevices []CStorPoolClusterBlockDevice `json:"blockDevices"`
}

// CStorPoolClusterBlockDevice contains the details of block devices that
// constitutes a raid group.
type CStorPoolClusterBlockDevice struct {
	// BlockDeviceName is the name of the block device.
	BlockDeviceName string `json:"blockDeviceName"`
	// Capacity is the capacity of the block device.
	// It is system generated
	Capacity string `json:"capacity"`
	// DevLink is the dev link for block devices
	DevLink string `json:"devLink"`
}

// CStorPoolClusterStatus represents the latest available observations of a CSPC's current state.
type CStorPoolClusterStatus struct {
	// CurrentNumberInstances is the the number of CSPI present at the current state. 
	CurrentNumberInstances int32 `json:"currentNumberInstances"`
	
	// DesiredNumberInstances is the number of CSPI that should be present in the system.
	DesiredNumberInstances int32 `json:"desiredNumberInstances"`
	
	// HealthyNumberInstances is the number of Healthy CSPI present in the system.
	HealthyNumberInstances int32 `json:"healthyNumberInstances"`
}

type CSPCConditionType string

// CStorPoolClusterCondition describes the state of a CSPC at a certain point.
type CStorPoolClusterCondition struct {
	// Type of deployment condition.
	Type CSPCConditionType `json:"type" protobuf:"bytes,1,opt,name=type,casttype=DeploymentConditionType"`
	// Status of the condition, one of True, False, Unknown.
	Status corev1.ConditionStatus `json:"status" protobuf:"bytes,2,opt,name=status,casttype=k8s.io/api/core/v1.ConditionStatus"`
	// The last time this condition was updated.
	LastUpdateTime metav1.Time `json:"lastUpdateTime,omitempty" protobuf:"bytes,6,opt,name=lastUpdateTime"`
	// Last time the condition transitioned from one status to another.
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty" protobuf:"bytes,7,opt,name=lastTransitionTime"`
	// The reason for the condition's last transition.
	Reason string `json:"reason,omitempty" protobuf:"bytes,4,opt,name=reason"`
	// A human readable message indicating details about the transition.
	Message string `json:"message,omitempty" protobuf:"bytes,5,opt,name=message"`
}

// CStorPoolClusterList is a list of CStorPoolCluster resources
type CStorPoolClusterList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`

	Items []CStorPoolCluster `json:"items"`
}
```