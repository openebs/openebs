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
last-updated: 2019-07-10
status: provisional
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

This proposal charts out the design details to perform pool and
volume upgrades via a Kubernetes Job. 

## Motivation

Once the OpenEBS control plane is upgraded, user has to manually 
upgrade the pools and volumes one at a time using the upgrade 
scripts. While this may work for smaller clusters and when upgrades 
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

This design provides the necessary abstractions to perform upgrades
of pools and volumes via Kubernetes Job. 

### Goals

- Ability to upgrade jiva volume or cstor pool/volume via `kubectl`
- Support for upgrading only a single cStor Pool from an SPC

### Non-Goals

- Scheduling of upgrades
- Support for upgrading all the volumes or pools at once. 

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

This design builds on top of the initial implementation of upgrade 
supported via kubectl for upgrading from [0.8.2 to 0.9](https://github.com/openebs/openebs/tree/master/k8s/upgrades/0.8.2-0.9.0). 


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

### Proposed Implementation

Since the upgrades using the scripts have been well tested and tried 
out on several test and production developments, we decided to re-use
the shell scripts to perform the upgrade tasks. 

The upgrade scripts will be packaged into upgrade container, with an 
entrypoint script that will invoke the required scripts depending on 
the object being upgraded. 

A custom resource called `UpgradeTask` will be defined with the 
details of the object being upgraded, and will in turn be updated
with the status of the upgrade by the upgrade-container scripts.  

OpenEBS team will release an openebs-upgrade-tools container 
that contains all the upgrade scripts supported by openebs. 

The workflow followed by administrator is as follows:
- Define the Custom Resource and a Service account
- Create a UpgradeTask CR for the object being upgraded 
- Create a Kubernetes Job with upgrade-container and passing the 
  UpgradeTask details. 
- Administrator can query the UpgradeTask to check the status 
  and result of the upgrade.

The upgrade scripts will be enhanced to work directly from the
command-line - in which case the error/info messages will be logged
to console; or invoked from within the container - which will update
the error/info messages to the UpgradeTask status spec.

### Backward Compatibility

Since this design re-uses the upgrade scripts, the users will 
have the option to upgrade the pools and volumes via the same 
procedure followed in earlier scripts. 

In addition, there will be an option to upgrade via `kubectl` 
using the steps detailed below. 

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

   

### High Level Design

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

The upgrade job will pass the name of the upgrade task as ENV. A
sample upgrade job will look like:

```
apiVersion: batch/v1
kind: Job
metadata:
  name: upgrade-jiva-pv-001-job
  namespace: openebs
spec:
  template:
    spec:
      #If running in openebs, openebs-maya-operator can be used as 
      #service account.
      serviceAccountName: super-admin
      containers:
      - name:  upgrade
        image: openebs/upgrade-executor:latest
        env:
        - name: UPGRADE_TASK_CR_NAME
          value: "upgrade-jiva-pv-001"
        - name: JOB_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: JOB_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        #In case the upgrade tasks are installed in another namespace.
        - name: OPENEBS_NAMESPACE
          value: "openebs"
      restartPolicy: Never
```


### Risks and Mitigations

## Graduation Criteria

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

