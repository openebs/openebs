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

This proposal highlights the limitations of current `CStorVolumeConfig` and `CStorVolumePolicy` schema and
proposes improvements and feature changes.

# Goals

The major goal of this document is to freeze the APIs schema for `CStorVolumeConfig` and `CStorVolumePolicy`.
Apart from this the document focuses on following aspects too:

- Migrating the `CStorVolumeConfig` and `CStorVolumePolicy` CRD to `v1` apiversion inder `cstor.openebs.io` api group.
- Identify the breaking and upgrade changes and documentation around that.
- List of possible high level status fields on `CStorVolumeConfig` and `CStorVolumePolicy`.

# Non-Goals

- Introduction of new fields in the `CStorVolumeConfig` and `CStorVolumePolicy` to deliver feature etc.
- List of possible events that should be recorded on `CStorVolumeConfig` and `CStorVolumesPolicy`.
- List of conditions that should be put on the `CStorVolumeConfig` and `CStorVolumePolicy` CRs.

# Volume Config Schema Proposal

## `CStorVolumeConfig` APIs

```go

// CStorVolumeConfig describes a cstor volume config resource created as
// custom resource. CStorVolumeConfig is a request for creating cstor volume
// related resources like target deployment, replica resources and service etc.
type CStorVolumeConfig struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	// Spec defines a specification of a cstor volume claim required
	// to provisione cstor volume resources
	Spec CStorVolumeConfigSpec `json:"spec"`

	// Publish contains info related to attachment of a volume to a node.
	// i.e. NodeId etc.
	Publish CStorVolumeConfigPublish `json:"publish,omitempty"`

	// Status represents the current information/status for the cstor volume
	// claim, populated by the controller.
	Status         CStorVolumeConfigStatus `json:"status"`
  // VersionDetails contains version related info
  VersionDetails VersionDetails         `json:"versionDetails"`
}

// CStorVolumeConfigSpec is the spec for a CStorVolumeConfig resource
type CStorVolumeConfigSpec struct {
	// Capacity represents the actual resources of the underlying
	// cstor volume.
	Capacity corev1.ResourceList `json:"capacity"`
	
  // ReplicaCount represents the desired replica count for the underlying
	// cstor volume
	ReplicaCount int `json:"ReplicaCount"`

	// CStorVolumeRef has the information about where CstorVolumeClaim
	// is created from.
	CStorVolumeRef *corev1.ObjectReference `json:"cstorVolumeRef,omitempty"`
	
  // CStorVolumeSource contains the source volumeName@snapShotname
	// combaination.  This will be filled only if it is a clone creation.
	CStorVolumeSource string `json:"cstorVolumeSource,omitempty"`
	
  // Policy contains volume specific required policies target and replicas
	Policy CStorVolumePolicySpec `json:"policy"`
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
	//provisioned and bound to the cstor volume claim
	CStorVolumeConfigPhaseBound CStorVolumeConfigPhase = "Bound"

	//CStorVolumeConfigPhaseFailed indiacates that the cstorvolume provisioning
	//has failed
	CStorVolumeConfigPhaseFailed CStorVolumeConfigPhase = "Failed"

  //CStorVolumeConfigPhaseReconcile indicates that the changes currently
	//reconclied based on the cstor volume policy changes to achieve the desired
	//state
	CStorVolumeConfigPhaseReconcile CStorVolumeConfigPhase = "Reconcile"

)

// CStorVolumeConfigStatus is for handling status of CstorVolume Claim.
// defines the observed state of CStorVolumeConfig
type CStorVolumeConfigStatus struct {
	// Phase represents the current phase of CStorVolumeConfig.
	Phase CStorVolumeConfigPhase `json:"phase"`

	// PoolInfo represents current pool names where volume replicas exists
	PoolInfo []string `json:"poolInfo"`
	
  // Capacity the actual resources of the underlying volume.
	Capacity   corev1.ResourceList         `json:"capacity,omitempty"`
	
  Conditions []CStorVolumeConfigCondition `json:"condition,omitempty"`
}

// CStorVolumeConfigCondition contains details about state of cstor volume
type CStorVolumeConfigCondition struct {
	// Current Condition of cstor volume claim. If underlying persistent volume is being
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
	// CStorVolumeConfigResizePending means volume resize operation has been started
	CStorVolumeConfigResizing CStorVolumeConfigConditionType = "Resizing"

  // CStorVolumeConfigResizeFailed means volume resize operation has been failed
	CStorVolumeConfigResizeFailed CStorVolumeConfigConditionType = "VolumeResizeFailed"
	
  // CStorVolumeConfigResizeSuccess means volume resize operation has been successful
	CStorVolumeConfigResizeSuccess CStorVolumeConfigConditionType = "VolumeResizeSuccessful"
	
  // CStorVolumeConfigResizePending means volume resize operation has been pending
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

# Changes to existing types

- No changes

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
  // Provision represents volume provisioning configuration like replicaAffinity
  // etc
	Provision Provision `json:"provision"`

  // TargetSpec represents configuration related to cstor target and its resources
	Target TargetSpec `json:"target,omitempty"`

  // ReplicaSpec represents configuration related to replicas resources
	Replica ReplicaSpec `json:"replica,omitempty"`


	// ReplicaPoolInfo holds the pool information of volume replicas.
	// Ex: If volume is provisioned on which CStor pool volume replicas exist
	ReplicaPoolInfo []ReplicaPoolInfo `json:"replicaPoolInfo,omitempty"`
}

// TargetSpec represents configuration related to cstor target and its resources
type TargetSpec struct {
	// QueueDepth sets the queue size at iSCSI target which limits the
	// ongoing IO count from client
	QueueDepth string `json:"queueDepth,omitempty"`

	// Luworkers sets the number of threads that are working on above queue
	LuWorkers int64 `json:"luWorkers,omitempty"`

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
	// ZvolWorkers represents number of threads that executes client IOs
	ZvolWorkers *int32 `json:"zvolWorkers,omitempty"`
}

// Provision represents volume provisioning configuration
type Provision struct {
	// replicaAffinity is set to true then volume replica resources need to be
	// distributed across the cstor pool instances based on the given topology
	ReplicaAffinity bool `json:"replicaAffinity"`
}

// ReplicaPoolSpec represents the volume replicas pool information
type ReplicaPoolSpec struct {
	// PoolInfo represents the pool information of replicas
	PoolInfo []ReplicaPoolInfo `json:"poolInfo,omitempty"`
}

// ReplicaPoolInfo represents the pool information of volume replica
type ReplicaPoolInfo struct {
	// PoolName represents the pool name where volume replica exists
	PoolName string `json:"poolName,omitempty"`
	//TODO: UID also can be added
}

// CStorVolumePolicyStatus is for handling status of CstorVolumePolicy
type CStorVolumePolicyStatus struct {
	Phase string `json:"phase,omitempty"`
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

# Changes to existing types

- Added `ReplicaPoolSpec` in `VolumePolicy` schema represents pool related information required
  for replica scaleup/scale down operation.


# Risks and Mitigations

# Graduation Criteria

### Resource Migration from `v1alpha1` to `v1`:

- CRD will ensure that `v1alpha1` as well as `v1` is served but `v1` is the only storage version.

- A conversion webhook server will be deployed to support back and forth conversion of resources for the served version.
