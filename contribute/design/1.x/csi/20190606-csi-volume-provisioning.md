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
      * [CStorVolumeClaim -- new custom resource](#cstorvolumeclaim----new-custom-resource)
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
- Coupling CSI implementation with any particular container orchestrator e.g. Kubernetes
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

There were previous attempts to implement CSI which is tightly coupled with the 
way Kubernetes works. This attempt will revisit to have an implementation that
is not tied to Kubernetes native resources.

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
  - CStorVolumeConfigClass _(Kubernetes custom resource)_
- CSI driver will read the request parameters and create following resources:
  - CStorVolumeClaim _(Kubernetes custom resource)_
- CStorVolumeClaim will be watched and reconciled by a dedicated controller

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

                                      [CStorVolumeConfigClass]
                                                 |
                                                 |6
                                                \|/
--3-->[CStorVolumeClaim]--5-->(CStorVolumeClaimController)


[Mount]--7-->(CSI Node)--8-->[CStorVolumeClaim]--9-->(CStorVolumeClaimController)--10-->

--10-->[CStorVolume + ConfigInjector + Deployment + Service + CStorVolumeReplica(s)]
```

Below represents owner and owned resources
```
                    |--- CStorVolume..................K8s Custom Resource
                    |
                    |--- ConfigInjector...............K8s Custom Resource
                    |
CStorVolumeClaim ---|--- CStor Target.................K8s Deployment
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
CStorVolumeClaim ---|--- ConfigInjector
                    |
                    |--- CStorVolumeReplica


                    |--- CStor Target
                    |
                    |--- CStor Service
ConfigInjector -----|
                    |--- CStorVolumeReplica
                    |
                    |--- CStorVolume
```

Next sections provide details on these resources that work in tandem to ensure 
smooth volume create & delete operations.

#### CStorVolumeConfigClass -- new custom resource
This is a new Kubernetes custom resource that holds config information to be
used by cstor volume claim controller while provisioning cstor volumes.

NOTE: This resource kind does not have a controller i.e. watcher logic. It holds
the config information to be utilized by cstor volume claim controller.

Following is the proposed schema for `CStorVolumeConfigClass`:

```yaml
kind: CStorVolumeConfigClass
metadata:
  name: <some name -- can be same as storage class name>
  namespace: <namespace of openebs i.e. openebs system namespace>
spec:
  targetDeployment:
    # this gets applied to cstor volume target
    # deployment via ConfigInjector
    spec:
  targetService:
    # this gets applied to cstor volume target
    # service via ConfigInjector 
    spec:
  cv:
    # this gets applied to CStorVolume via 
    # ConfigInjector
    spec:
  cvr:
    # this gets applied to all CStorVolumeReplicas
    # via ConfigInjector
    spec:
```

Detailed specifications:
```yaml
kind: CStorVolumeConfigClass
metadata:
  name: <some name -- can be same as storage class name>
  namespace: <namespace of openebs i.e. openebs system namespace>
spec:
  targetDeployment:
    spec:
      containers:
      - name: cstor-istgt
        env:
        - name: QueueDepth
          value: 6
        - name: Luworkers
          value: 3
  targetService:
    spec:
      labels:
      annotations:
  cv:
    spec:
      labels:
      annotations:
  cvr:
    spec:
      labels:
      annotations:
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

#### CStorVolumeClaim -- new custom resource
This resource is built & created by the CSI driver on a volume create request.
This resource will be the trigger to get the desired i.e. requested cstor volume
into the actual state in Kubernetes cluster. CStorVolumeClaim controller will 
reconcile this claim into actual resources. CStorVolumeClaim controller will 
operate from within the maya-apiserver pod.

CStorVolumeClaim will be reconciled into following owned resources:
- ConfigInjector _(Kubernetes custom resource)_
- CStorVolume _(Kubernetes custom resource)_
- CStor volume target _(Kubernetes Deployment)_
- CStor volume service _(Kubernetes Service)_
- CStorVolumeReplica _(Kubernetes custom resource)_

Following is the proposed schema for `CStorVolumeClaim`:

```yaml
kind: CStorVolumeClaim
metadata:
  name: <name of the volume>
  namespace: <openebs system namespace>
  labels:
  annotations:
    openebs.io/config-class: 
    openebs.io/volume-id:
spec:
  capacity:
  claimRef:
publish:
  nodeId:
status:
  phase: # INIT, BOUND and ERROR can be the supported phases

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

#### ConfigInjector -- new custom resource
This is a new Kubernetes custom resource whose object will get created by cstor
volume claim controller. This resource gets built and applied by cstor volume 
claim controller after referring to `CStorVolumeConfigClass`.

ConfigInjector kind has its dedicated controller residing in maya api 
server. The job of this controller is to inject infrastructure related 
configurations to targeted Kubernetes resources (native as well as custom).

_NOTE: ConfigInjector is a generic resource and is not tied to cstor volume operations._

_NOTE: This can be implemented as part of Phase 2 of CSI implementation_

Following is the proposed schema for `ConfigInjector`:

```yaml
kind: ConfigInjector
metadata:
  name: <name of cstor volume -- in this case>
  namespace: <openebs system namespace -- in this case>
spec:
  policies:
  - name:   # name given to this injection
    select: # select kubernetes resource(s)
    apply:  # apply values against above selected kubernetes resource(s)
```

```yaml
kind: ConfigInjector
metadata:
  name: <name of cstor volume>
  namespace: <openebs system namespace>
spec:
  policies:
  - name: inject-perf-tunables
    select: 
      kind: Deployment
      name: <name of cstor volume deployment>
      namespace: <openebs system namespace>
    apply:
      containers:
      - name: cstor-istgt
        env:
        - name: QueueDepth
          value: 6
        - name: Luworkers
          value: 3
```

##### NOTES:
- policies[*].apply will have below fields:
  - labels,
  - annotations,
  - owners,
  - nodeAffinity,
  - podAntiAffinity,
  - containers,
  - initContainers,
  - & so on
- policies[*].apply will mostly reflect the fields supported by Pod kind

#### CStorVolume -- existing custom resource

#### CStorVolumeReplica -- existing custom resource

### CVC Controller Patterns
These are some of the controller patterns that can be followed while implementing
controllers.

- Status.Phase of a CStorVolumeClaim (CVC) resource can have following:
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

Below is a sample schema snippet for `CStorVolumeClaimStatus` resource
```go
type CStorVolumeClaimStatus struct {
  Phase      CStorVolumeClaimPhase       `json:"phase"`
  Conditions []CStorVolumeClaimCondition `json:"conditions"`
}

type CStorVolumeClaimCondition struct {
  Type                CStorVolumeClaimConditionType   `json:"type"`
  Status              CStorVolumeClaimConditionStatus `json:"status"`
  LastTransitionTime  metav1.Time                     `json:"lastTransitionTime"`
  LastUpdateTime      metav1.Time                     `json:"lastUpdateTime"`
  Reason              string                          `json:"reason"`
  Message             string                          `json:"message"`
}

type CStorVolumeClaimConditionType string

const (
  CVCConditionResizing CStorVolumeClaimConditionType = "resizing"
)

type CStorVolumeClaimConditionStatus string

const (
  CVCConditionStatusTrue    CStorVolumeClaimConditionStatus = "true"
  CVCConditionStatusFalse   CStorVolumeClaimConditionStatus = "false"
  CVCConditionStatusUnknown CStorVolumeClaimConditionStatus = "unknown"
)
```

### Risks and Mitigations

This proposal tries to do away with existing ways to provision and delete volume.
OpenEBS control plane (known as Maya) currently handles all the volume provisioning
requirements. 

This will involve considerable risk in terms of time and effort since existing way
that works will be done away with.

Below can pose a significant challenge for this proposal:
- Volume provisioning is tightly coupled with Clone provisioning
- There might be a need to change existing custom resources' schema

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
