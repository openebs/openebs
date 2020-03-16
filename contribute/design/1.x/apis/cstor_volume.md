# Move `CStorVolumes`, `CStorVolumeReplica` resources Schema to version `v1`

## Table of Contents

* [Introduction](#introduction)
* [Goals](#goals)
* [Non-Goals](#non-goals)
* [Schema Proposal](#volume-schema-proposal)
* [Risk and Mitigations](#risks-and-mitigations)
* [CRD Migration and Graduation](#graduation-criteria)

## Introduction

This proposal highlights the limitations of current `CStorVolumes` and `CStorVolumeReplicas` schema and
proposes improvements.

# Goals

The major goal of this document is to freeze the APIs schema for `CStorVolumes` and `CStorVolumeReplica`.
Apart from this the document focuses on following aspects too:

- Migrating the `CStorVolumes` and `CStorVolumeReplica` CRD to `v1` apiversion.
- Identify the breaking and upgrade changes and documentation around that.
- List of possible high level status fields on `CStorVolumes` and `CStorVolumeReplica`.

# Non-Goals

- Introduction of new fields in the `CStorVolumes` and `CStorVolumeReplica` to deliver feature etc.
- List of possible events that should be recorded on `CStorVolumes` and `CStorVolumesReplicas`.
- List of conditions that should be put on the `CStorVolumes` and `CStorVolumesReplicas` CRs.

# Volume Schema Proposal

## `CStorVolumes` APIs

```go
// +genclient
// +k8s:openapi-gen=true
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// CStorVolume describes a cstor volume resource created as custom resource
type CStorVolume struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	Spec              CStorVolumeSpec   `json:"spec"`
	VersionDetails    VersionDetails    `json:"versionDetails"`
	Status            CStorVolumeStatus `json:"status"`
}

// CStorVolumeSpec is the spec for a CStorVolume resource
type CStorVolumeSpec struct {
	// Capacity represents the desired size of the underlying volume.
	Capacity          resource.Quantity `json:"capacity"`
	TargetIP          string            `json:"targetIP"`
	TargetPort        string            `json:"targetPort"`
	Iqn               string            `json:"iqn"`
	TargetPortal      string            `json:"targetPortal"`
	NodeBase          string            `json:"nodeBase"`
	ReplicationFactor int               `json:"replicationFactor"`
	ConsistencyFactor int               `json:"consistencyFactor"`
	// DesiredReplicationFactor represents maximum number of replicas
	// that are allowed to connect to the target
	DesiredReplicationFactor int `json:"desiredReplicationFactor"`
	//ReplicaDetails refers to the trusty replica information
	ReplicaDetails CStorVolumeReplicaDetails `json:"replicaDetails,omitempty"`
}

// ReplicaID is to hold replicaID information
type ReplicaID string

// CStorVolumePhase is to hold result of action.
type CStorVolumePhase string

// CStorVolumeStatus is for handling status of cvr.
type CStorVolumeStatus struct {
	Phase           CStorVolumePhase `json:"phase"`
	ReplicaStatuses []ReplicaStatus  `json:"replicaStatuses,omitempty"`
	// Represents the actual resources of the underlying volume.
	Capacity resource.Quantity `json:"capacity,omitempty"`
	// LastTransitionTime refers to the time when the phase changes
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty"`
	LastUpdateTime     metav1.Time `json:"lastUpdateTime,omitempty"`
	Message            string      `json:"message,omitempty"`
	// Current Condition of cstorvolume. If underlying persistent volume is being
	// resized then the Condition will be set to 'ResizePending'.
	// +optional
	// +patchMergeKey=type
	// +patchStrategy=merge
	Conditions []CStorVolumeCondition `json:"conditions,omitempty" patchStrategy:"merge" patchMergeKey:"type" protobuf:"bytes,4,rep,name=conditions"`
	// ReplicaDetails refers to the trusty replica information which are
	// connected at given time
	ReplicaDetails CStorVolumeReplicaDetails `json:"replicaDetails,omitempty"`
}

// CStorVolumeReplicaDetails contains trusty replica inform which will be
// updated by target
type CStorVolumeReplicaDetails struct {
	// KnownReplicas represents the replicas that target can trust to read data
	KnownReplicas map[ReplicaID]string `json:"knownReplicas,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// CStorVolumeList is a list of CStorVolume resources
type CStorVolumeList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`

	Items []CStorVolume `json:"items"`
}

// CVStatusResponse stores the reponse of istgt replica command output
// It may contain several volumes
type CVStatusResponse struct {
	CVStatuses []CVStatus `json:"volumeStatus"`
}

// CVStatus stores the status of a CstorVolume obtained from response
type CVStatus struct {
	Name            string          `json:"name"`
	Status          string          `json:"status"`
	ReplicaStatuses []ReplicaStatus `json:"replicaStatus"`
}

// ReplicaStatus stores the status of replicas
type ReplicaStatus struct {
	ID                string `json:"replicaId"`
	Mode              string `json:"mode"`
	CheckpointedIOSeq string `json:"checkpointedIOSeq"`
	InflightRead      string `json:"inflightRead"`
	InflightWrite     string `json:"inflightWrite"`
	InflightSync      string `json:"inflightSync"`
	UpTime            int    `json:"upTime"`
	Quorum            string `json:"quorum"`
}

// CStorVolumeCondition contains details about state of cstorvolume
type CStorVolumeCondition struct {
	// Type is a different valid value of CStorVolumeCondition
	Type   CStorVolumeConditionType `json:"type" protobuf:"bytes,1,opt,name=type,casttype=CStorVolumeConditionType"`
	
	Status ConditionStatus `json:"status" protobuf:"bytes,2,opt,name=status,casttype=ConditionStatus"`
	// Last time we probed the condition.
	// +optional
	LastProbeTime metav1.Time `json:"lastProbeTime,omitempty" protobuf:"bytes,3,opt,name=lastProbeTime"`
	// Last time the condition transitioned from one status to another.
	// +optional
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty" protobuf:"bytes,4,opt,name=lastTransitionTime"`
	// Unique, this should be a short, machine understandable string that gives the reason
	// for condition's last transition. If it reports "ResizePending" that means the underlying
	// cstorvolume is being resized.
	// +optional
	Reason string `json:"reason,omitempty" protobuf:"bytes,5,opt,name=reason"`
	// Human-readable message indicating details about last transition.
	// +optional
	Message string `json:"message,omitempty" protobuf:"bytes,6,opt,name=message"`
}

// CStorVolumeConditionType is a valid value of CStorVolumeCondition.Type
type CStorVolumeConditionType string

const (
	// CStorVolumeResizing - a user trigger resize of pvc has been started
	CStorVolumeResizing CStorVolumeConditionType = "Resizing"
)

// ConditionStatus states in which state condition is present
type ConditionStatus string

// These are valid condition statuses. "ConditionInProgress" means corresponding
// condition is inprogress. "ConditionSuccess" means corresponding condition is success
const (
	// ConditionInProgress states resize of underlying volumes are in progress
	ConditionInProgress ConditionStatus = "InProgress"
	// ConditionSuccess states resizing underlying volumes are successfull
	ConditionSuccess ConditionStatus = "Success"
)
```
# Changes to existing types

- Remove the `Spec.Status` field of the `CStorvolumeSpec`. `Status` field has been used to set the initial `init` state of `CStorVolume` in case of openebs-director.

## `CStorVolumeReplicas` APIs

```go

// +genclient
// +k8s:openapi-gen=true
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// CStorVolumeReplica describes a cstor volume resource created as custom resource
type CStorVolumeReplica struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	Spec              CStorVolumeReplicaSpec   `json:"spec"`
	Status            CStorVolumeReplicaStatus `json:"status"`
	VersionDetails    VersionDetails           `json:"versionDetails"`
}

// CStorVolumeReplicaSpec is the spec for a CStorVolumeReplica resource
type CStorVolumeReplicaSpec struct {
	TargetIP string `json:"targetIP"`
	Capacity string `json:"capacity"`
	// ZvolWorkers represents number of threads that executes client IOs
	ZvolWorkers string `json:"zvolWorkers"`
	// ReplicaID is unique number to identify the replica
	ReplicaID string `json:"replicaid"`

    // BlockSize size of data block. The blocksize cannot be changed once
    // the volume has been written, so it should be set at volume creation
    // time.The default blocksize for volumes is 4 Kbytes. Any power of 2 
    // from 512 bytes to 128 Kbytes is valid.
	BlockSize string `json:"blockSize"`
}

// CStorVolumeReplicaPhase is to hold result of action.
type CStorVolumeReplicaPhase string

// Status written onto CStorVolumeReplica objects.
const (

	// CVRStatusEmpty describes CVR resource is created but not yet monitored by
	// controller(i.e resource is just created)
	CVRStatusEmpty CStorVolumeReplicaPhase = ""

	// CVRStatusOnline describes volume replica is Healthy and data existing on
	// the healthy replica is up to date
	CVRStatusOnline CStorVolumeReplicaPhase = "Healthy"

	// CVRStatusOffline describes volume replica is created but not yet connected
	// to the target
	CVRStatusOffline CStorVolumeReplicaPhase = "Offline"

	// CVRStatusDegraded describes volume replica is connected to the target and
	// rebuilding from other replicas is not yet started but ready for serving
	// IO's
	CVRStatusDegraded CStorVolumeReplicaPhase = "Degraded"

	// CVRStatusNewReplicaDegraded describes replica is recreated (due to pool
	// recreation[underlying disk got changed]/volume replica scaleup cases) and
	// just connected to the target. Volume replica has to start reconstructing
	// entier data from another available healthy replica. Until volume replica
	// becomes healthy whatever data written to it is lost(NewReplica also not part
	// of any quorum decision)
	CVRStatusNewReplicaDegraded CStorVolumeReplicaPhase = "NewReplicaDegraded"

	// CVRStatusRebuilding describes volume replica has missing data and it
	// started rebuilding missing data from other replicas
	CVRStatusRebuilding CStorVolumeReplicaPhase = "Rebuilding"

	// CVRStatusReconstructingNewReplica describes volume replica is recreated
	// and it started reconstructing entier data from other healthy replica
	CVRStatusReconstructingNewReplica CStorVolumeReplicaPhase = "ReconstructingNewReplica"

	// CVRStatusError describes either volume replica is not exist in cstor pool
	CVRStatusError CStorVolumeReplicaPhase = "Error"

	// CVRStatusDeletionFailed describes volume replica deletion is failed
	CVRStatusDeletionFailed CStorVolumeReplicaPhase = "DeletionFailed"

	// CVRStatusInvalid ensures invalid resource(currently not honoring)
	CVRStatusInvalid CStorVolumeReplicaPhase = "Invalid"

	// CVRStatusInit describes CVR resource is newly created but it is not yet
	// created zfs dataset
	CVRStatusInit CStorVolumeReplicaPhase = "Init"

	// CVRStatusRecreate describes the volume replica is recreated due to pool
	// recreation/scaleup
	CVRStatusRecreate CStorVolumeReplicaPhase = "Recreate"
)

// CStorVolumeReplicaStatus is for handling status of cvr.
type CStorVolumeReplicaStatus struct {
	// Phase represents different states of CStorVolumeReplicas
	Phase    CStorVolumeReplicaPhase `json:"phase"`
	
	// CStorVolumeCapacityDetails represents capacity information releated to volume
    // replica
    Capacity CStorVolumeCapacityDetails `json:"capacity"`
	
    // LastTransitionTime refers to the time when the phase changes
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty"`
	LastUpdateTime     metav1.Time `json:"lastUpdateTime,omitempty"`
	Message            string      `json:"message,omitempty"`
}


// CStorVolumeCapacityDetails represents capacity information releated to volume
// replica
type CStorVolumeCapacityDetails struct {
	// The amount of space consumed by this volume replica and all its descendents
	Total string `json:"total"`
	
    // The amount of space that is "logically" accessible by this dataset. The logical
	// space ignores the effect of the compression and copies properties, giving a
	// quantity closer to the amount of data that applications see.  However, it does
	// include space consumed by metadata
	Used string `json:"used"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// CStorVolumeReplicaList is a list of CStorVolumeReplica resources
type CStorVolumeReplicaList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata"`

	Items []CStorVolumeReplica `json:"items"`
}
```

# Changes to existing types
- Rename `CStorVolumeCapacityAttr` to `CStorVolumeCapacityDetails`
- Rename `TotalAllocated` to `Total` under `CStorVolumeCapacityDetails` referenced to `used` zfs get property
- `Used` field under `CStorVolumeCapacityDetails.Used` will be referenced to `logicalreferenced` zfs get property.

# Risks and Mitigations

# Graduation Criteria

### Resource Migration from `v1alpha1` to `v1`:

- CRD will ensure that `v1alpha1` as well as `v1` is served but `v1` is the only storage version.

- A conversion webhook server will be deployed to support back and forth conversion of resources for the served version.
