---
oep-number: CSI Volume Provisioning 20190606
title: CSI Volume Provisioning
authors:
  - "@amitkumardas"
  - "@payes"
  - "@prateekpandey14"
owners:
  - "@kmova"
  - "@vishnuitta"
editor: "@amitkumardas"
creation-date: 2019-06-06
last-updated: 2019-07-04
status: provisional
see-also:
  - NA
replaces:
  - current cstor volume provisioning in v1.0.0
superseded-by:
  - NA
---

# CSI Volume Provisioning

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
      * [Create a volume](#create-a-volume)
      * [Delete the volume](#delete-the-volume)
    * [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
      * [Current Implementation -- Config](#current-implementation----config)
      * [Current Implementation -- Volume Create](#current-implementation----volume-create)
      * [Shortcomings with Current Implementation](#shortcomings-with-current-implementation)
    * [Proposed Implementation](#proposed-implementation)
      * [Volume Creation Workflow](#volume-creation-workflow)
      * [Volume Deletion Workflow](#volume-deletion-workflow)
    * [High Level Design](#high-level-design)
      * [CStorVolumePolicy -- new custom resource](#cstorvolumepolicy----new-custom-resource)
      * [CStorVolumeConfig -- new custom resource](#cstorvolumeconfig----new-custom-resource)
      * [CStorVolume -- existing custom resource](#cstorvolume----existing-custom-resource)
      * [CStorVolumeReplica -- existing custom resource](#cstorvolumereplica----existing-custom-resource)
    * [CVC Controller Patterns](#cvc-controller-patterns)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This proposal charts out the design details to implement Container Storage 
Interface commonly referred to as **CSI** to create and delete openebs volumes.

## Motivation

CSI implementation provides the necessary abstractions for any storage provider
to provision volumes and related use-cases on any container orchestrator. This
is important from the perspective of all OpenEBS storage engines, since it will 
make all OpenEBS storage engines adhere to CSI specifications and hence abstract
the same from inner workings of a container orchestrator.

### Goals

- Ability to create and delete a volume in a kubernetes cluster using CSI
- Enable higher order applications to consume this volume

### Non-Goals

- Handling high availability in cases of node restarts
- Handling volume placement related requirements

## Proposal

### User Stories

#### Create a volume
As an application developer I should be able to provide a volume that can be 
consumed by my application. This volume should get created dynamically during 
application creation time.

#### Delete the volume
As an application developer I should be able to delete the volume that was being
consumed by my application. This volume should get deleted only when the 
application is deleted.

### Implementation Details/Notes/Constraints

Current provisioning approach works well given day 1 operations. However, we 
consider this approach as limiting when day 2 operations come into picture. There
has been a general consensus to adopt to reconcile driven approach (pushed by 
Kubernetes ecosystem) that handles day 2 operations effectively.

The sections below can be assumed to be specific to `CStor` unless mentioned
otherwise.

#### Current Implementation -- Config
- CSI executes REST API calls to maya api server to create and delete volume
- Most of volume creation logic is handled via CASTemplate _(known as CAST)_
  - name: cstor-volume-create-default
- CAST makes use of various configurations required for volume operations
  - Config _(can be set at PVC, SC or at CASTemplate itself)_
    - StoragePoolClaim       -- pools of this claim are selected
    - VolumeControllerImage  -- docker image
    - VolumeTargetImage      -- docker image
    - VolumeMonitorImage     -- docker image
    - ReplicaCount           -- no. of replicas for this volume
    - TargetDir              -- 
    - TargetResourceRequests
    - TargetResourceLimits
    - AuxResourceRequests
    - AuxResourceLimits
    - RunNamespace
    - ServiceAccountName
    - FSType
    - Lun
    - ResyncInterval
    - TargetNodeSelector
    - TargetTolerations
  - Volume _(runtime configuration specific to the targeted volume)_
    - runNamespace
    - capacity
    - pvc
    - isCloneEnable
    - isRestoreVolume
    - sourceVolume
    - storageclass
    - owner
    - snapshotName
- Above configurations can be categorized broadly into two groups:
  - Volume specific
  - Kubernetes specific

#### Current Implementation -- Volume Create
- Uses PVC for below actions:
  - get .metadata.annotations.volume.kubernetes.io/selected-node
  - get .metadata.labels.openebs.io/replica-anti-affinity
  - get .metadata.labels.openebs.io/preferred-replica-anti-affinity
  - get .metadata.labels.openebs.io/target-affinity
  - get .metadata.labels.openebs.io/sts-target-affinity
  - derive statefulset application name
- Uses CStorPoolList for below actions:
  - filter CSPs based on StoragePoolClaim name
  - compares desired volume replica count against available number of pools
  - maps CSP uid with its .metadata.labels.kubernetes.io/hostname
- Uses StorageClass for below actions:
  - get .metadata.resourceVersion
  - get .metadata.labels.openebs.io/sts-target-affinity
- Creates a Kubernetes Service for cstor target
  - stores its name
  - stores its cluster IP
- Creates CStorVolume custom resource
- Creates Kubernetes deployment for cstor target
  - lot of config items are applied here conditionally
- Create CStorVolumeReplica custom resource
  - pool selection is done here
  - lot of config items are applied here conditionally
  - lot of CVR properties get derived from above config items

#### Shortcomings With Current Implementation
- OpenEBS volumes are aware of higher order resources i.e. kubernetes based PVC & SC
  - In other words OpenEBS volumes cannot be managed without the presence of PVC & SC
  - Inorder to implement CSI as per its standards, OpenEBS volumes should decouple
itself from being aware of container orchestrator (read Kubernetes native 
resources which are higher order entities).
- Logic like pool selection are currently done via go-templating which is not 
sustainable going forward
  - go based templating cannot replace a high level language
- Building cstor volume target deployment is currently done via go-templating
which has become quite complex to maintain

### Proposed Implementation
Since OpenEBS itself runs on Kubernetes; limiting OpenEBS provisioning
to be confined to CSI standards will prove difficult to develop and improve upon
OpenEBS features.

This proposal tries to adhere to CSI standards and make itself CSI compliant. 
At the same time, this proposal lets OpenEBS embrace use of Kubernetes custom
resources and custom controllers to provide storage for stateful applications.
This also makes OpenEBS implementation idiomatic to Kubernetes practices which is
implement features via Custom Resources.

#### Volume Creation Workflow
- CSI driver will handle CSI request for volume create
- Kubernetes will have following as part of the infrastructure required to operate 
OpenEBS CSI driver
  - CStorVolumeConfig _(Kubernetes custom resource)_
- CStorVolumeConfig will be watched and reconciled by a dedicated controller

#### Volume Deletion Workflow
- CSI driver will handle CSI request for volume delete
- CSI driver will read the request parameters and delete corresponding CStorVolume
resource

##### NOTES:
- The resources owned by CStorVolume will be garbage collected

### High Level Design
Below represents `cstor volume lifecycle` with Kubernetes as the container
orchestrator.
```
[PVC]--1-->(CSI Provisioner)--2-->(OpenEBS CSI Driver)--3--> 
                 |
                 |4
                \|/
               [PV]

                                      [CStorVolumePolicy]
                                                 |
                                                 |6
                                                \|/
--3-->[CStorVolumeConfig]--5-->(CStorVolumeConfigController)


[Mount]--7-->(CSI Node)--8-->[CStorVolumeConfig]--9-->(CStorVolumeConfigController)--10-->

--10-->[CStorVolume + Deployment + Service + CStorVolumeReplica(s)]
```

Below represents owner and owned resources
```
                    |--- CStorVolume..................K8s Custom Resource
                    |
CStorVolumeConfig --|--- CStor Target.................K8s Deployment
                    |
                    |--- CStor Target Service.........K8s Service
                    |
                    |--- CStorVolumeReplica(1..n).....K8s Custom Resource

\----------------/   \----------------------------------------------------/
        |                                        |
      owner                                    owned
```

Bow represents resources that are in a constant state of reconciliation
```
                    |--- CStorVolume
CStorVolumeConfig ---|
                    |--- CStorVolumeReplica
```

Next sections provide details on these resources that work in tandem to ensure 
smooth volume create & delete operations.

#### CStorVolumePolicy -- new custom resource
This is a new Kubernetes custom resource that holds volume policy information to be
used by cstor volume config controller while provisioning cstor volumes.

Whenever a cstor volume policy field is changed by the user, webhook inturrupts
and updates the phase as reconciling. It is assumed if webhook server is not running,
the editing of the resource would not be allowed. On detecting the phase as reconciling,
the CVC controller will reverify all the policies and update the change to the
corresponding resource. After successful changes, phase is updated back to bound.

NOTE: This resource kind does not have a controller i.e. watcher logic. It holds
the config policy information to be utilized by cstor volume config controller.

Following is the proposed schema for `CStorVolumePolicy`:

```go
type CStorVolumePolicy struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	// Spec defines a configuration info of a cstor volume required
	// to provisione cstor volume resources
	Spec   CStorVolumePolicySpec   `json:"spec"`
	Status CStorVolumePolicyStatus `json:"status,omitempty"`
}

// CStorVolumePolicySpec ...
type CStorVolumePolicySpec struct {
	// replicaAffinity is set to true then volume replica resources need to be
	// distributed across the pool instances
	Provision Provision `json:"provision,omitempty"`

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
	BlockSize uint32 `json:"blockSize,omitempty"`
}

// ReplicaPoolInfo represents the pool information of volume replica
type ReplicaPoolInfo struct {
	// PoolName represents the pool name where volume replica exists
	PoolName string `json:"poolName"`
	// UID also can be added
}
```

##### NOTES
- `spec.targetDeployment.spec`, `spec.replica.spec` and `spec.targetService.spec` 
will be of same data type
- It will have below fields:
  - labels,
  - annotations,
  - env,
  - owners,
  - nodeAffinity,
  - podAntiAffinity,
  - containers,
  - initContainers,
  - & so on
- `spec.*.spec` will mostly reflect the fields supported by Pod kind

#### CStorVolumeConfig -- new custom resource
This resource is built & created by the CSI driver on a volume create request.
This resource will be the trigger to get the desired i.e. requested cstor volume
into the actual state in Kubernetes cluster. CStorVolumeConfig controller will 
reconcile this config into actual resources. CStorVolumeConfig controller will 
will be deployed as k8s deployment in k8s cluster.

CStorVolumeConfig will be reconciled into following owned resources:
- CStorVolume _(Kubernetes custom resource)_
- CStor volume target _(Kubernetes Deployment)_
- CStor volume service _(Kubernetes Service)_
- CStorVolumeReplica _(Kubernetes custom resource)_

Following is the proposed schema for `CStorVolumeConfig`:

```go
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
	// cstor volume based on the persistent volume request by user. Provision
	// properties are immutable
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
	Phase CStorVolumeConfigPhase `json:"phase,omitempty"`

	// PoolInfo represents current pool names where volume replicas exists
	PoolInfo []string `json:"poolInfo,omitempty"`

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
```

#### CStorVolume -- existing custom resource

Refer [CStorVolume APIs Spec](https://github.com/openebs/api/blob/master/pkg/apis/cstor/v1/cstorvolume.go)

#### CStorVolumeReplica -- existing custom resource

Refer [CStorVolumeReplica APIs Spec](https://github.com/openebs/api/blob/master/pkg/apis/cstor/v1/cstorvolumereplica.go)

### CVC Controller Patterns
These are some of the controller patterns that can be followed while implementing
controllers.

- Status.Phase of a CStorVolumeConfig (CVC) resource can have following:
  - Pending
  - Bound
  - Reconciling
- Status.Phase is only set during creation
  - Once the phase is Bound it should never revert to Pending
- Status.Conditions will be used to track an on-going operation or sub status-es
  - It will be an array
  - It will have ConditionStatus as a field which can have below values:
    - True
    - False
    - Unknown
  - An item within a condition can be added, updated & deleted by the resource’s own controller
  - An item within a condition can be updated by a separate controller
    - The resource’s own controller still holds the right to delete this condition item

Below is a sample schema snippet for `CStorVolumeConfigStatus` resource
```go
type CStorVolumeConfigStatus struct {
  Phase      CStorVolumeConfigPhase       `json:"phase"`
  Conditions []CStorVolumeConfigCondition `json:"conditions"`
}

type CStorVolumeConfigCondition struct {
  Type                CStorVolumeConfigConditionType   `json:"type"`
  Status              CStorVolumeConfigConditionStatus `json:"status"`
  LastTransitionTime  metav1.Time                     `json:"lastTransitionTime"`
  LastUpdateTime      metav1.Time                     `json:"lastUpdateTime"`
  Reason              string                          `json:"reason"`
  Message             string                          `json:"message"`
}

type CStorVolumeConfigConditionType string

const (
  CVCConditionResizing CStorVolumeConfigConditionType = "resizing"
)

type CStorVolumeConfigConditionStatus string

const (
  CVCConditionStatusTrue    CStorVolumeConfigConditionStatus = "true"
  CVCConditionStatusFalse   CStorVolumeConfigConditionStatus = "false"
  CVCConditionStatusUnknown CStorVolumeConfigConditionStatus = "unknown"
)
```

### Risks and Mitigations

This proposal tries to do away with existing ways to provision and delete volume.
OpenEBS control plane (known as Maya) currently handles all the volume provisioning
requirements. 

This will involve considerable risk in terms of time and effort since existing way
that works will be done away with.

We shall try to avoid major disruptions, by having the following processes in place:
- Test-Driven Development (TDD) methodology
  - Need to implement automated test cases in parallel to the development
- Try to reuse custom resources that enable provisioning openebs volumes

## Graduation Criteria

- Integration test covers volume creation & volume deletion usecases
- Implementation does not need a custom (i.e. forked) CSI Kubernetes provisioner
- Existing/Old way of volume provisioning is not impacted
- Kubernetes CSI testsuite passes this CSI implementation

## Implementation History

- Owner acceptance of `Summary` and `Motivation` sections - YYYYMMDD
- Agreement on `Proposal` section - YYYYMMDD
- Date implementation started - YYYYMMDD
- First OpenEBS release where an initial version of this OEP was available - YYYYMMDD
- Version of OpenEBS where this OEP graduated to general availability - YYYYMMDD
- If this OEP was retired or superseded - YYYYMMDD

## Drawbacks

NA

## Alternatives

NA

## Infrastructure Needed

- Availability of github.com/openebs/csi repo 
- Enable integration with Travis as the minimum CI tool
