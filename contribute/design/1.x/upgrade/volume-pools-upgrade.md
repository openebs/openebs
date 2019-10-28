---
oep-number: draft Upgrade 20190710
title: Upgrade via Kubernetes Job
authors:
  - "@kmova"
owners:
  - "@amitkumardas"
  - "@vishnuitta"
editor: "@kmova"
creation-date: 2019-07-10
last-updated: 2019-07-31
status: implementable
see-also:
  - NA
replaces:
  - current upgrade steps with scripts
superseded-by:
  - NA
---

# Upgrade via Kubernetes Job

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
    * [Design Constraints](#design-constraints)
    * [Proposed Implementation](#proposed-implementation)
    * [High Level Design](#high-level-design)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This design is aimed at providing a design for upgrading the data
plane components via `kubectl` and also allow administrators to
automate the upgrade process with higher level operators.

This proposed design will be rolled out in phases while maintaining
backward compatibility with the upgrade process defined in prior
releases starting with OpenEBS 1.1. At a high level the design is
implemented in the following phases:
- Phase 1: Ability to perform storage pool and volume upgrades using 
  a Kubernetes Job
- Phase 2: Allow for saving the history of upgrades on a given pool
  or volume on a Kubernetes custom resource called `UpgradeTask`.
  Manage the cleanup of Upgrade Jobs and UpgradeTask CRs along
  with the resource on which they operate. 
- Phase 3: An upgrade operator that:
  - Automatically trigger the upgrade of pools and volumes when the
    control plane is upgraded. The upgrade operator will create a
    UpgradeTask and pass that to a Upgrade Job.
  - Ability to set which pools or volumes should be automatically 
    upgraded or not. 
  
## Motivation

OpenEBS is Kubernetes native implementation comprising of a 
set of Deployments and Custom resources - that can be divided into 
two broad categories: control plane and data plane.

The control plane components install custom resources and help with 
provisioning and managing volumes that are backed by different 
storage engines (aka data plane). The control plane components 
are what an administrator installs into the cluster and creates 
storage configuration (or uses default configuration) that includes
storage classes. The developers only need to know about the storage
classes at their disposal.

OpenEBS can be installed using several ways like any other Kubernetes
application like using a `kubectl apply` or `helm` or via catalogs
maintained by Managed Kubernetes services like Rancher, AWS market 
place, OpenShift Operator Hub and so forth.

Hence upgrading of OpenEBS involves:
- Upgrading the OpenEBS Control plane using one of many options
  in which Kubernetes apps are installed. 
- Upgrading of the Data Plane components or deployments and 
  custom resources that power the storage pools and volumes. 

Up until 1.0, the process of upgrading involved a multi-step process
of upgrading the control plane followed by:
- upgrading the storage pools
- upgrading the persistent volumes one at a time. 

The upgrade itself involved downloading scripts out of band, 
customizing them and executing them.

While this may work for smaller clusters and when upgrades 
are infrequent, the dependency on a manual intervention for upgrades
becomes a bottleneck on Ops team when running thousands of clusters
across different geographic locations.

In addition to the scalability limitation, in some environments, 
additional steps may be required like running the upgrades from 
an external shell - that has access to the cluster and has 
live connection to the cluster in the process of upgrade.

Cluster administrators would like to automate the process of upgrade, 
with push-button access for upgrades and/or flexibility on which 
pools and volumes are upgraded. 

### Goals

- Ease the process of upgrading OpenEBS control plane components. 
- Ease the process of upgrading OpenEBS data plane components.
- Automate the process of upgrading OpenEBS data plane components. 

### Non-Goals
- Automating the OpenEBS control plane upgrades

## Proposal

### User Stories

- As an cluster administrator - I want to automate the upgrades of 
  OpenEBS on thousands of Edge Clusters that are running in my 
  organization. 
- As an OpenEBS user - I want the upgrade steps to be standardized, 
  so that I don't need to learn how to upgrade, every time there is a 
  new release.
- As an developer of managed Kubernetes platform - I want to provide 
  an option for my end-user (cluster administrator) an user-interface 
  to easily select the volumes and pools and schedule an upgrade. 
  

### Design Constraints

- Upgrading of the OpenEBS storage components should be possible
  via `kubectl`.
- Upgrade of a resource should be a single command and should be 
  idempotent. 
- Administrators should be able to use the GitOps to manage the
  OpenEBS configuration. 

### Proposed Implementation

This design proposes the following key changes:

1.  Control Plane components can handle the older versions of 
    data plane components. This design enforces that the control
    plane component that manage a resource has to take care of
    either: 
    - Support the reading of resource with old schema. This is the 
      case where the schema (data) is user generated. 
    - Auto upgrading of the schema to new format. This is the case
      where resource or the attributes are created and owned by the
      control plane component. 

    For example, a cstor-operator reads a user generated resource
    called SPC, as well as creates a resource called CSP. It is possible
    that both of these user-facing and internal resources go through
    a change to support some new functionality. With this design, 
    when the cstor operator is upgraded to latest version, the following
    will happen:
    - The non-user facing changes in SPC are handled by the cstor 
      operator, which could be like adding a finalizer or some 
      annotation that will help with internal bookkeeping. It will
      also continue to read and operate on the existing schema. If
      there has been a user api change, the steps will be provided 
      for the administrator to make the appropriate changes to their
      SPC (which is probably saved in their private Git) and re-apply 
      the YAML. 
    - The changes to the CSP will be managed completely by the upgraded
      cstor operator. User/Administrator need not interact with CSP. 

    Note: This eliminates the need for pre-upgrade scripts that were used 
    till 1.0. 

    Status: Available in 1.1

2.  Data plane components have an interdependence on each other and
    upgrading a volume typically involves upgrading multiple related
    components at once. For example upgrading a jiva volume involves
    upgrading the target and replica deployments. The functionality 
    to upgrade these various components are provided and delivered
    in a container hosted at `quay.openebs.io/m-upgrade`. 

    A Kubernetes Job with this upgrade container can be launched to 
    carry out the upgrade process. The upgrade job will have to run
    in the same namespace as openebs control plane and with same
    service account.

    Upgrade of each resource will be launched as a separate Job, that
    will allow for parallel upgrading of resources as well as 
    granular control on which resource is being upgraded. Upgrades
    are almost seamless, but still have to be planned to be run 
    at different intervals for different applications to minimize
    the impact of unforeseen events.

    As the upgrades are done via Kubernetes job, a pod is scheduled
    to perform the task within the cluster, eliminating any network 
    dependencies that might there between machine that triggers
    the upgrade to cluster. Also the logs of the upgrade are saved
    on the pod. 

    UpgradeJob is idempotent, in the sense it will start execution 
    from the point where it left off and finish the job. If the
    UpgradeJob is executed on an already upgraded resource, it will 
    return success. 

    Note: This replaces the script based upgrades from OpenEBS 1.0. 
    Sample Kubernetes YAMLs for upgrading various resources can be
    found [here](../../../../k8s/upgrades/1.0.0-1.1.0/).  

    Status: Available in 1.1 and supports upgrading of Jiva Volumes,
    cStor Volumes and cStor pools from 1.0 to 1.1

3.  A custom resource called `UpgradeTask` will be defined with the 
    details of the object being upgraded, and will in turn be updated
    with the status of the upgrade by the upgrade-container. This 
    will allow for tools to be written to capture the status of the
    upgrades and take any correction actions. One of the consumer
    for this UpgradeTask is openebs-operator itself that will automate
    the upgrade of all resources. 

    The `UpgradeTask` resource will be created by the Upgrade Job. 

    The UpgradeJob will also be enhanced to receive `UpgradeTask` 
    as input will all the details of the resources included. In this
    case, the Upgrade Job will append the results of the operation to
    the provided UpgradeTask. This is also implemented to allow for
    higher level operators to eliminate steps like determining 
    what is the name of the `UpgradeTask` created by the UpgradeJob. 

    Status: Under Development, planned for 1.2

4.  Improvements to the backward compatibility checks added to the 
    OpenEBS Control Plane in (1). The backward compatibility checks
    will involve checking for multiple resources and this process
    is triggered on a restart. This process will be optimized to 
    use a flag to check if the backward compatibility checks are 
    indeed required. On the resource being managed, the following 
    internal spec will be maintained that indicates if the backward
    compatibility checks need to be maintained. 

    ```yaml
    versionDetails:
      #Indicates if the resource should be auto upgraded 
      #More on this below (6). Default is false.
      #autoUpgrade:
      #Indicates the current version of the resource.
      currentVersion: 
      #Indicates the running version of the controller/component
      #as part of the start-up, this flag will be changed
      #running version if autoUpgrade is enabled. 
      desiredVersion: 
      #In some cases there can be a bunch of child resources
      #this flag will be set to "no" when current != desired. 
      #after upgrading all the child objects, this will be changed to yes. 
      dependentsUpgraded:
      #status gives the details about the reconciliation of the version
      status:
        #phase tells the phase of reconciliation of the current 
        #and desired version.
        phase: #STARTED, SUCCESS or ERROR can be the supported phases
        #message is a human readable message in case of failure
        message: Unable to set desired replication factor to CV
        #reason is the actual error received by the function calls
        reason: invalid config for the volume
        #lastUpdateTime is the time last modification of status occurred
        lastUpdateTime: "2019-10-03T14:37:03Z"
    ```

    The above spec will be used as a sub-resource under all the custom
    resource managed by OpenEBS. 
  
    Status: Under Development, planned for 1.3

5.  Downgrading a version. There are scenarios where the volumes will
    have to be downgraded to earlier versions. Some of the challenges
    around this are after upgrading a resource with a breaking change, 
    falling back to older version might make the resource un-readable. 
    To avoid this, the earlier version of the resource will be saved
    under a versioned name. When downgrading from higher (currentVersion)
    to lower (desiredVersion), the backup copy of the resource will
    be applied. 

    Note: This section will have to be revisited for detailed design 
    after scoping this item into a release. 

    Status: Under Development, planned for TBD

6.  Automated upgrades of data plane components. OpenEBS operator 
    will check for all the volumes and resources that need to be upgraded
    and will launch a Kubernetes Job for any resource that has the
    autoUpgrade set to true. In case there is a failure to upgrade, the
    volume will be downgraded back to its current version.

    Administrators can make use of this auto-upgrade facility 
    as a choice. The auto-upgrade true can be set on either
    SPC, StorageClass or the PVC and the flag will be trickled 
    down to the corresponding resources during provisioning. 

    Note: This section will have to be revisited for detailed design 
    after scoping this item into a release. 

    Status: Under Development, planned for TBD
  
### Backward Compatibility

This design overrides the earlier upgrade methodology. 

### Design Choices/Decisions

This section captures some of the alternative design considered
and the reasoning behind selecting a certain approach. 

- A generic UpgradeTask CR vs task specific ones like JivaUpgradeTask,
  CStorVolumeUpgradeTask, etc. Having specific tasks has the following
  advantages:
  * Each tasks can have its own spec. the fields may vary depending
    on the resource being upgraded.
  * Writing specific operators for each upgrade that operates on a
    given type of task will make the upgrades more modular. 
  
  However, this also means that every time a new resource type is
  added, another CR needs to be introduced, managed and learned by 
  the user. This may still be OK. But a similar pattern where 
  different specs are required is already addressed by the PVC. To 
  keep the resources management at a minimum, the PVC type, sub-resource
  spec pattern will be used to specify different resources under
  a generic UpgradeTask CR. 

  Note that, selecting the Generic Task - doesn't preclude from 
  writing specific upgrade task operators and upgrades task CRs as long
  as the management of these specific upgrade tasks are completely 
  management by the operators and user need not interact with them. One
  possible future implementation could be: The upgrade-operator can 
  look at the upgrade task (consider it as a claim) and create a 
  specific upgrade task and bind it. Then the specific upgrade 
  operator will operate on the their own resources.  

- Should the UpgradeTask have a provision to perform upgrades on 
  multiple resources of the same kind. For example, can a list of 
  jiva volumes be specified in a single UpgradeTask. Adding multiple
  jobs will result in adding additional status objects, which in 
  turn will make the co-relation of the object to its result harder
  to get. UpgradeTask CR provides a basic building block for 
  constructing higher order automation. In the future, a BulkUpgrade
  CR can be launched that can take multiple objects - probably 
  even based a namespace group or pv labels etc. The controller
  watching the BulkUpgrade can then launch individual UpgradeTasks. 

   
- How does this design compared to the `kubectl` based upgrade
  introduced for upgrading from [0.8.2 to 0.9](https://github.com/openebs/openebs/tree/master/k8s/upgrades/0.8.2-0.9.0). 

  The current design proposed in this document builds on top of the
  0.8.2 to 0.9 design, by improving on usability and agility of the 
  upgrade code development. 

  The implementation made use of the CAS Template feature and comprised 
  of the following: 
  - Each type of upgrade - like jiva volume upgrade, cstor pool upgrade, 
    were converted from shell to an CAS Template, with a series of  
    upgrade tasks (aka runtasks) to be executed. 
  - A custom resource called upgraderesults was defined to capture
    the results while executing the run tasks.
  - An upgrade agent, that can read the upgrade CAS Template and 
    execute the run tasks on a given volume or pool.
  - Administrator will have to create a Kubernetes Job out of the
    upgrade agent - by passing the upgrade cas template and the object
    details via a config map. 

  While the above approach was good enough to be automated via `kubectl`, 
  the steps that can be executed as part of upgrade were limited
  by the features or constructs available within the CAST/RunTasks. 

  Another short-coming of the CAST/RunTasks is the lack of developer
  friendly constructs for rapidly writing new CAST/RunTasks. This was
  severely impacting the time taken to push out new releases. 

### High Level Design

#### Upgrade Job Example

Here is an example of Kubernetes Job spec for upgrading the jiva volume.
```
#This is an example YAML for upgrading jiva volume. 
#Some of the values below needs to be changed to
#match your openebs installation. The fields are
#indicated with VERIFY
---
apiVersion: batch/v1
kind: Job
metadata:
  #VERIFY that you have provided a unique name for this upgrade job.
  #The name can be any valid K8s string for name. This example uses
  #the following convention: jiva-vol-<flattened-from-to-versions>-<pv-name>
  name: jiva-vol-100110-pvc-713e3bb6-afd2-11e9-8e79-42010a800065
  #VERIFY the value of namespace is same as the namespace where openebs components
  # are installed. You can verify using the command:
  # `kubectl get pods -n <openebs-namespace> -l openebs.io/component-name=maya-apiserver`
  # The above command should return status of the openebs-apiserver.
  namespace: openebs
spec:
  backoffLimit: 4
  template:
    spec:
      #VERIFY the value of serviceAccountName is pointing to service account
      # created within openebs namespace. Use the non-default account.
      # by running `kubectl get sa -n <openebs-namespace>`
      serviceAccountName: openebs-maya-operator
      containers:
      - name:  upgrade
        args: 
        - "jiva-volume"
        - "--from-version=1.0.0"
        - "--to-version=1.1.0"
        #VERIFY that you have provided the correct cStor PV Name
        - "--pv-name=pvc-713e3bb6-afd2-11e9-8e79-42010a800065"
        #Following are optional parameters
        #Log Level
        - "--v=4"
        #DO NOT CHANGE BELOW PARAMETERS
        env:
        - name: OPENEBS_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        tty: true 
        image: quay.io/openebs/m-upgrade:1.1.0
      restartPolicy: OnFailure
---
```

Execute the Upgrade Job Spec
```
$ kubectl apply -f jiva-vol-100110-pvc713.yaml
```

You can check the status of the Job using commands like:
```
$ kubectl get job -n openebs
$ kubectl get pods -n openebs #to check on the name for the job pod
$ kubectl logs -n openebs jiva-upg-100111-pvc-713e3bb6-afd2-11e9-8e79-42010a800065-bgrhx
```

#### UpgradeTask CR Example

Here is an example of UpgradeTask for upgrading Jiva Volume. The 
conditions are added by the Upgrade Job

```
apiVersion: openebs.io/v1alpha1
kind: UpgradeTask
metadata:
  name: upgrade-jiva-pv-001
  namespace: openebs
spec:
  fromVersion: 0.9.0
  toVersion: 1.0.0
  #flags can be used to change the default behavior 
  flags: 
    #maximum seconds to wait at any given step in the upgrade
    timeout: 0 #wait forever
  #the resource represents the type of resource being upgraded. 
  #some examples are jivaVolume, cstorVolume, cstorPool, cstorPoolClaim
  #and so forth. Each resource may pass a different set of parameters
  #to uniquely identify the resource being upgraded. 
  resourceType: 
    jivaVolume:
      pvName: pvc-3d290e5f-7ada-11e9-b8a5-54e1ad4a9dd4
      #flags can be used to change the default behaviour 
      flags: 
        #specify the steps that can be ignored on error.
        #ignoreStepsOnError: 
        # - PRE_CHECK
status:
  phase: #STARTED, SUCCESS or ERROR can be the supported phases
  #timestamp when the upgrade job started. Set the phase to STARTED
  startTime: 2019-07-11T17:39:01Z
  #timestamp when the phase changed to DONE or ERROR
  completedTime: 2019-07-11T17:40:01Z
  # upgrade statuses represent the various stages in the upgrade
  # and the current state of each stage.
  upgradeDetailedStatuses:
  #Upgrade can comprise of a series of steps like PRE_UPGRADE, 
  # TARGET_UPGRADE, REPLICA_UPGRADE, VERIFY, ROLLBACK and so forth
  # depending on the resource being upgraded.
  - step:   # Upgrade Stage - PRE_UPGRADE, TARGET_UPGRADE, ...,VERIFY
    startTime:
    #state represents the current state of the step. The 
    #state can be waiting, errored or completed. lastUpdatedAt
    #will contain the timestamp at which the current state is updated.
    lastUpdatedAt:
    state:
      #The state can be on one of the following 
      waiting:
        message: Initiated rollout of "deployment/pvc-dep-name"
      errored:
        #extract the error message and reason from kubectl
        message: Unable to patch "deployment/pvc-dep-name"
        reason: ErrorRollout
      completed:
        #include the details like which resource was patched
        message: patched "deployment/pvc-dep-name"

```

### Risks and Mitigations

## Graduation Criteria

## Implementation History

- Owner acceptance of `Summary` and `Motivation` sections - 2090731
- Agreement on `Proposal` section - 2090731
- Date implementation started - 2090731
- First OpenEBS release where an initial version of this OEP was available - 2090731 OpenEBS 1.1.0
- Version of OpenEBS where this OEP graduated to general availability - YYYYMMDD
- If this OEP was retired or superseded - YYYYMMDD

## Drawbacks

NA

## Alternatives

NA

## Infrastructure Needed

