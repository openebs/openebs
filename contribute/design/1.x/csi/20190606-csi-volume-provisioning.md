---
oep-number: CSI Volume Provisioning 20190606
title: CSI Volume Provisioning
authors:
  - "@amitkumardas"
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
      * [CStorVolumeConfigClass -- new custom resource](#cstorvolumeconfigclass----new-custom-resource)
      * [CStorVolumeConfig -- new custom resource](#cstorvolumeconfig----new-custom-resource)
      * [ConfigInjector -- new custom resource](#configinjector----new-custom-resource)
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

- Providing tunables w.r.t creating and deleting a volume
- Ability to resize a volume
- Ability to take volume snapshots
- Ability to clone a volume
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
  - CStorVolumePolicy _(Kubernetes custom resource)_
- CSI driver will read the request parameters and create following resources:
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
CStorVolumeConfig ---|--- CStor Target.................K8s Deployment
                     |
                     |--- CStor Target Service.........K8s Service
                     |
                     |--- CStorVolumeReplica(1..n).....K8s Custom Resource

\----------------/   \----------------------------------------------------/
        |                                        |
      owner                                    owned
```

Below represents resources that are in a constant state of reconciliation
```
                    |--- CStorVolume
                    |   
CStorVolumeConfig --|
                    |
                    |--- CStorVolumeReplica
```

Next sections provide details on these resources that work in tandem to ensure 
smooth volume create & delete operations.

#### CStorVolumePolicy -- new custom resource
This resource kind does not have a controller i.e. watcher logic. It holds
the config information to be utilized by cstor volume config controller.

Following is the proposed schema for `CStorVolumePolicy`:
```
type CStorVolumePolicySpec struct {
        // TargetSpec represents configuration related to cstor target and its resources
        Target TargetSpec `json:"target"`
        // ReplicaSpec represents configuration related to replicas resources
        Replica ReplicaSpec `json:"replica"`
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
        
        // Affinity if specified, are the target pod's affinities
        Affinity *corev1.PodAffinity `json:"affinity,omitempty"`
        
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
        ZvolWorkers string `json:"zvolWorkers"`
        // Affinity if specified, are the replica affinities
        Affinity *corev1.PodAffinity `json:"affinity"`
}

```

##### NOTES
- Default cstorVolumePolicy yamls will be present in case the user doesn't provide one.
- App based default csstorVolumePolicies will also be present for users to pick one.
- Whenever a user provides a cstorVolumePolicy, the empty feilds will be autofilled by webhook from the default cstorVolumePolicy yaml.

#### CStorVolumeConfig -- new custom resource
This resource is built & created by the CSI driver on a volume create request.
This resource will be the trigger to get the desired i.e. requested cstor volume
into the actual state in Kubernetes cluster. CStorVolumeConfig controller will 
reconcile this config into actual resources. CStorVolumeConfig controller will 
operate from within the maya-apiserver pod. Once all the below resources are 
created successfully, the CstorVolumeConfig phase is marked as Bound.

CStorVolumeConfig will be reconciled into following owned resources:
- CStorVolume _(Kubernetes custom resource)_
- CStor volume target _(Kubernetes Deployment)_
- CStor volume service _(Kubernetes Service)_
- CStorVolumeReplica _(Kubernetes custom resource)_

Following is the proposed schema for `CStorVolumeConfig`:

```yaml
kind: CStorVolumeConfig
metadata:
  name: <name of the volume>
  namespace: <openebs system namespace>
  labels:
  annotations:
    openebs.io/volume-id:
// Spec defines a specification of a cstor volume config required
// to provision cstor volume resources
spec:
  // Capacity represents the actual resources of the underlying
  // cstor volume.
  Capacity corev1.ResourceList `json:"capacity"`
  
  // Policy represents the config parameters to be used for volume provisioning 
  policy:
    spec:
      target:
        ...
      replica:
        ...
  
  // CStorVolumeRef contains the reference to CStorVolume i.e. CstorVolume Name
  // This field will be updated by maya after cstor Volume has been
  // provisioned
  CStorVolumeRef *corev1.ObjectReference `json:"cstorVolumeRef,omitempty"`
  
  // CstorVolumeSource contains the source volumeName@snapShotname
  // combaination.  This will be filled only if it is a clone creation.
  CstorVolumeSource string `json:"cstorVolumeSource,omitempty"`


// Publish contains info related to attachment of a volume to a node.
// i.e. NodeId etc.
publish:
  nodeId:
// Status represents the current information/status for the cstor volume
// config, populated by the controller.
status:
  phase: # INIT, BOUND, RECONCILE and ERROR can be the supported phases
  capacity:
  # conditions represent current reconciliation
  # activities
  conditions:
  - type:  # RESIZE_IN_PROGRES, etc. TODO Need to think of proper names.
    active:
    message:
    createdAt:
    lastUpdatedAt:
    count:
```
Whenever a policy is changed by the user, webhook inturrupts and updates the phase as reconciling.
It is assumed if webhook server is not running, the editing of the resource would not be allowed.
On detecting the phase as reconciling, the CVC controller will reverify all the policies and update the change to the corresponding resource. After successful changes, phase is updated back to bound.

#### CStorVolume -- existing custom resource

#### CStorVolumeReplica -- existing custom resource

### CVC Controller Patterns
These are some of the controller patterns that can be followed while implementing
controllers.

- Status.Phase of a CStorVolumeConfig (CVC) resource can have following:
  - Pending
  - Bound
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

We shall try to avoid major disruptions, by having following processes in place:
- Test Driven Development (TDD) methodology
  - Need to implement automated test cases in parallel to development
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
