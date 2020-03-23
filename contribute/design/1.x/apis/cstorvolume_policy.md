# Move `CStorVolumeConfig`, `CStorVolumePolicy` resources Schema to version `v1`

## Table of Contents

* [Introduction](#introduction)
* [Goals](#goals)
* [Non-Goals](#non-goals)
* [VolumeConfig Schema Proposal](#volume-config-schema-proposal)
* [VolumePolicy Schema Proposal](#volume-policy-schema-proposal)
* [Risk and Mitigations](#risks-and-mitigations)
* [CRD Migration and Graduation](#graduation-criteria)

## Introduction

This proposal highlights enhancements and migration of current `CStorVolumeConfig` and `CStorVolumePolicy` schema and
proposes feature changes.

# Goals

The major goal of this document is to freeze the APIs schema for `CStorVolumeConfig` and `CStorVolumePolicy`.
Apart from this the document focuses on following aspects too:

- Migrating the `CStorVolumeConfig` and `CStorVolumePolicy` CRD to `v1` API version under `cstor.openebs.io` api group.
- Identify the breaking and upgrade changes and documentation around that.
- List of possible high level status fields on `CStorVolumeConfig` and `CStorVolumePolicy`.
- Enhancements related to Day 2 operations which going to be control via `CStorVolumeConfig`:
    - Seamless Volume online resize operations via just changing PVC capacity
    - Scaling up/down of CStor volume replicas by add/delete pool under poolInfo
    - Replica migrations from one pool to another pool across the nodes (via scale down one pool and scale up in other pool operation)
    - Support for policy tunnables reconciliation per volume bases like tolerations, resource limits etc.
    - High available volumes will have PodDistruptionBudget enforced via `CStorVolumeConfig`
    - Events based on different supported volume operations like resize and scale
    - Initial capacity as meta information for volume clone support as part of day 2-ops
    - IOWorkers and QueueDepth at runtime reconcilation per volume bases

- Enhancements related to Day 2 operations which going to be control via `CStorVolumePolicy`:
    - Volume replica distributions based on the provisioning topology configured in StorageClass
    - Policy based scheduling based on properties like Resource/auxResources limits, defaults will be set if not provided
    - Policy can be used to configure target PodAffinities, PriorityClass, tolerations, NodeSelector etc based on the user requirements
    - To enable/disable ReplicaAffinity feature to replica distribution based on user requirements
    - Using Policy user can configure cstor volume related tunnables like IOWorkers, QueueDepth
    - Pool selection feature for selecting specific pools across the pool cluster via adding pool names under PoolInfo


# Non-Goals

- Introduction of new fields in the `CStorVolumeConfig` and `CStorVolumePolicy` to deliver feature etc.
- List of possible events that should be recorded on `CStorVolumeConfig` and `CStorVolumesPolicy`.
- List of conditions that should be put on the `CStorVolumeConfig` and `CStorVolumePolicy` CRs.

# Debugging and Measures

- Enhanced `CStorVolumeConfig` conditional status and events performed on volumes
- Enhanced `CStorVolumeConfig` Status to validate and verify scale up/down operations
- Additional initial capacity and replica count information related to day 2-ops
- Different  events has been added for step by step processing of resize and scale operations
- For easy debugging status of cvc will have following details:
    * Replicas phase information
    * volume phase information
    * Making sure phase and state information will be sync with exact state
    * Active number of replicas are connected to target

# Volume Config Schema Proposal

## `CStorVolumeConfig` APIs

```go

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +k8s:openapi-gen=true

// CStorVolumeConfig describes a cstor volume config resource created as
// custom resource. CStorVolumeConfig is a request for creating cstor volume
// related resources like deployment, svc etc.
type CStorVolumeConfig struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	// Spec defines a specification of a cstor volume config required
	// to provisione cstor volume resources
	Spec CStorVolumeConfigSpec `json:"spec"`

	// Publish contains info related to attachment of a volume to a node.
	// i.e. NodeId etc.
	Publish CStorVolumeConfigPublish `json:"publish,omitempty"`

	// Status represents the current information/status for the cstor volume
	// config, populated by the controller.
	Status         CStorVolumeConfigStatus `json:"status"`
	VersionDetails VersionDetails          `json:"versionDetails"`
}

// CStorVolumeConfigSpec is the spec for a CStorVolumeConfig resource
type CStorVolumeConfigSpec struct {
	// Capacity represents the actual resources of the underlying
	// cstor volume.
	Capacity corev1.ResourceList `json:"capacity"`
	// CStorVolumeRef has the information about where CstorVolumeClaim
	// is created from.
	CStorVolumeRef *corev1.ObjectReference `json:"cstorVolumeRef,omitempty"`
	// CStorVolumeSource contains the source volumeName@snapShotname
	// combaination.  This will be filled only if it is a clone creation.
	CStorVolumeSource string `json:"cstorVolumeSource,omitempty"`
	// Provision represents the initial volume configuration for the underlying
	// cstor volume based on the persistent volume request by user.
	Provision VolumeProvision `json:"provision"`
	// Policy contains volume specific required policies target and replicas
	Policy CStorVolumePolicySpec `json:"policy"`
}

type VolumeProvision struct {
	// Capacity represents initial capacity of volume replica required during
	// volume clone operations to maintain some metadata info related to child
	// resources like snapshot, cloned volumes.
	Capacity corev1.ResourceList `json:"capacity"`
	// ReplicaCount represents initial cstor volume replica count, its will not
	// be updated later on based on scale up/down operations, only readonly
	// operations and validations.
	ReplicaCount int `json:"replicaCount"`
}

// CStorVolumeConfigPublish contains info related to attachment of a volume to a node.
// i.e. NodeId etc.
type CStorVolumeConfigPublish struct {
	// NodeID contains publish info related to attachment of a volume to a node.
	NodeID string `json:"nodeId,omitempty"`
}

// CStorVolumeConfigPhase represents the current phase of CStorVolumeConfig.
type CStorVolumeConfigPhase string

const (
	//CStorVolumeConfigPhasePending indicates that the cvc is still waiting for
	//the cstorvolume to be created and bound
	CStorVolumeConfigPhasePending CStorVolumeConfigPhase = "Pending"

	//CStorVolumeConfigPhaseBound indiacates that the cstorvolume has been
	//provisioned and bound to the cstor volume config
	CStorVolumeConfigPhaseBound CStorVolumeConfigPhase = "Bound"

	//CStorVolumeConfigPhaseFailed indiacates that the cstorvolume provisioning
	//has failed
	CStorVolumeConfigPhaseFailed CStorVolumeConfigPhase = "Failed"
)

// CStorVolumeConfigStatus is for handling status of CstorVolume Claim.
// defines the observed state of CStorVolumeConfig
type CStorVolumeConfigStatus struct {
	// Phase represents the current phase of CStorVolumeConfig.
	Phase CStorVolumeConfigPhase `json:"phase"`

	// PoolInfo represents current pool names where volume replicas exists
	PoolInfo []string `json:"poolInfo"`

	// Capacity the actual resources of the underlying volume.
	Capacity corev1.ResourceList `json:"capacity,omitempty"`

	Conditions []CStorVolumeConfigCondition `json:"condition,omitempty"`
}

// CStorVolumeConfigCondition contains details about state of cstor volume
type CStorVolumeConfigCondition struct {
	// Current Condition of cstor volume config. If underlying persistent volume is being
	// resized then the Condition will be set to 'ResizeStarted' etc
	Type CStorVolumeConfigConditionType `json:"type"`
	// Last time we probed the condition.
	// +optional
	LastProbeTime metav1.Time `json:"lastProbeTime,omitempty"`
	// Last time the condition transitioned from one status to another.
	// +optional
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty"`
	// Reason is a brief CamelCase string that describes any failure
	Reason string `json:"reason"`
	// Human-readable message indicating details about last transition.
	Message string `json:"message"`
}

// CStorVolumeConfigConditionType is a valid value of CstorVolumeConfigCondition.Type
type CStorVolumeConfigConditionType string

// These constants are CVC condition types related to resize operation.
const (
	// CStorVolumeConfigResizePending ...
	CStorVolumeConfigResizing CStorVolumeConfigConditionType = "Resizing"
	// CStorVolumeConfigResizeFailed ...
	CStorVolumeConfigResizeFailed CStorVolumeConfigConditionType = "VolumeResizeFailed"
	// CStorVolumeConfigResizeSuccess ...
	CStorVolumeConfigResizeSuccess CStorVolumeConfigConditionType = "VolumeResizeSuccessful"
	// CStorVolumeConfigResizePending ...
	CStorVolumeConfigResizePending CStorVolumeConfigConditionType = "VolumeResizePending"
)

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +k8s:openapi-gen=true

// CStorVolumeConfigList is a list of CStorVolumeConfig resources
type CStorVolumeConfigList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`

	Items []CStorVolumeConfig `json:"items"`
}
```

## Changes to existing types

- Move `ReplicaCount` under `Spec.Provision` section from `Spec` (readonly property).
- Add initial `Capacity` under `Spec.Provision` section (readonly property).


# Volume Policy Schema Proposal

## `CStorVolumePolicy` APIs

```go

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +k8s:openapi-gen=true

// CStorVolumePolicy describes a configuration required for cstor volume
// resources
type CStorVolumePolicy struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	// Spec defines a configuration info of a cstor volume required
	// to provisione cstor volume resources
	Spec   CStorVolumePolicySpec   `json:"spec"`
	Status CStorVolumePolicyStatus `json:"status"`
}

// CStorVolumePolicySpec ...
type CStorVolumePolicySpec struct {
	// replicaAffinity is set to true then volume replica resources need to be
	// distributed across the pool instances
	Provision Provision `json:"provision"`

	// TargetSpec represents configuration related to cstor target and its resources
	Target TargetSpec `json:"target"`

	// ReplicaSpec represents configuration related to replicas resources
	Replica ReplicaSpec `json:"replica"`

	// ReplicaPoolInfo holds the pool information of volume replicas.
	// Ex: If volume is provisioned on which CStor pool volume replicas exist
	ReplicaPoolInfo []ReplicaPoolInfo `json:"replicaPoolInfo"`
}

// TargetSpec represents configuration related to cstor target and its resources
type TargetSpec struct {
	// QueueDepth sets the queue size at iSCSI target which limits the
	// ongoing IO count from client
	QueueDepth string `json:"queueDepth,omitempty"`

	// IOWorkers sets the number of threads that are working on above queue
	IOWorkers int64 `json:"luWorkers,omitempty"`

	// Monitor enables or disables the target exporter sidecar
	Monitor bool `json:"monitor,omitempty"`

	// ReplicationFactor represents maximum number of replicas
	// that are allowed to connect to the target
	ReplicationFactor int64 `json:"replicationFactor,omitempty"`

	// Resources are the compute resources required by the cstor-target
	// container.
	Resources *corev1.ResourceRequirements `json:"resources,omitempty"`

	// AuxResources are the compute resources required by the cstor-target pod
	// side car containers.
	AuxResources *corev1.ResourceRequirements `json:"auxResources,omitempty"`

	// Tolerations, if specified, are the target pod's tolerations
	Tolerations []corev1.Toleration `json:"tolerations,omitempty"`

	// PodAffinity if specified, are the target pod's affinities
	PodAffinity *corev1.PodAffinity `json:"affinity,omitempty"`

	// NodeSelector is the labels that will be used to select
	// a node for target pod scheduleing
	// Required field
	NodeSelector map[string]string `json:"nodeSelector,omitempty"`

	// PriorityClassName if specified applies to this target pod
	// If left empty, no priority class is applied.
	PriorityClassName string `json:"priorityClassName,omitempty"`
}

// ReplicaSpec represents configuration related to replicas resources
type ReplicaSpec struct {
	// IOWorkers represents number of threads that executes client IOs
	IOWorkers string `json:"zvolWorkers,omitempty"`
	// Controls the compression algorithm used for this volumes
	// examples: on|off|gzip|gzip-N|lz4|lzjb|zle
	//
	// Setting compression to "on" indicates that the current default compression
	// algorithm should be used.The default balances compression and decompression
	// speed, with compression ratio and is expected to work well on a wide variety
	// of workloads. Unlike all other set‐tings for this property, on does not
	// select a fixed compression type.  As new compression algorithms are added
	// to ZFS and enabled on a pool, the default compression algorithm may change.
	// The current default compression algorithm is either lzjb or, if the
	// `lz4_compress feature is enabled, lz4.

	// The lz4 compression algorithm is a high-performance replacement for the lzjb
	// algorithm. It features significantly faster compression and decompression,
	// as well as a moderately higher compression ratio than lzjb, but can only
	// be used on pools with the lz4_compress

	// feature set to enabled.  See zpool-features(5) for details on ZFS feature
	// flags and the lz4_compress feature.

	// The lzjb compression algorithm is optimized for performance while providing
	// decent data compression.

	// The gzip compression algorithm uses the same compression as the gzip(1)
	// command.  You can specify the gzip level by using the value gzip-N,
	// where N is an integer from 1 (fastest) to 9 (best compression ratio).
	// Currently, gzip is equivalent to gzip-6 (which is also the default for gzip(1)).

	// The zle compression algorithm compresses runs of zeros.
	Compression string `json:"compression,omitempty"`
}

// Provision represents different provisioning policy for cstor volumes
type Provision struct {
	// replicaAffinity is set to true then volume replica resources need to be
	// distributed across the cstor pool instances based on the given topology
	ReplicaAffinity bool `json:"replicaAffinity"`
	// BlockSize is the logical block size in multiple of 512 bytes
	// BlockSize specifies the block size of the volume. The blocksize
	// cannot be changed once the volume has been written, so it should be
	// set at volume creation time. The default blocksize for volumes is 4 Kbytes.
	// Any power of 2 from 512 bytes to 128 Kbytes is valid.
	BlockSize uint32 `json:"blockSize"`
}

// ReplicaPoolInfo represents the pool information of volume replica
type ReplicaPoolInfo struct {
	// PoolName represents the pool name where volume replica exists
	PoolName string `json:"poolName"`
	// UID also can be added
}

// CStorVolumePolicyStatus is for handling status of CstorVolumePolicy
type CStorVolumePolicyStatus struct {
	Phase string `json:"phase"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +k8s:openapi-gen=true

// CStorVolumePolicyList is a list of CStorVolumePolicy resources
type CStorVolumePolicyList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`

	Items []CStorVolumePolicy `json:"items"`
}
```

## Changes to existing types

- Added initial `BlockSize` under `Provision` section in Policy ( readonly field).
- Renamed `ZvolWorkers` and `Luworkers` as `IOWorkers` in `TargetSpec` and `ReplicaSpec`
- Added `Compression` under ReplicaSpec in Policy

# Risks and Mitigations

# Graduation Criteria

### Resource Migration from `v1alpha1` to `v1`:

- CRD will ensure that `v1alpha1` as well as `v1` is served but `v1` is the only storage version.

- A conversion webhook server will be deployed to support back and forth conversion of resources for the served version.
