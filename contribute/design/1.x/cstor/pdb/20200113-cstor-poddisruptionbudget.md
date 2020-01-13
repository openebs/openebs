---
oep-number: Pod Disruption Budget
title: Pod Disruption Budget for cStor
authors:
  - "@mittachaitu"
owners:
  - "@vishnuitta"
  - "@kmova"
  - "@AmitKumarDas"
editor: "@mittachaitu"
creation-date: 2020-01-13
last-updated: 2019-01-13
status: Implementable
---

# Pod Disruption Budget


## Table of Contents

- [Pod Disruption Budget](#pod-disruption-budget)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
      - [HighAvailable Volumes Shouldn't be disturbed for Cluster Upgrade Activities](#highavailable-volumes-shouldnt-be-disturbed-for-cluster-upgrade-activities)
    - [Proposed Implementation](#proposed-implementation)
    - [Steps to perform user stories](#steps-to-perform-user-stories)
    - [Low Level Design](#low-level-design)
      - [Work Flow](#work-flow)
      - [Sample Yaml](#sample-yaml)
      - [Notes:](#notes)
    - [TestCases](#testcases)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)
  - [Infrastructure Needed](#infrastructure-needed)

## Summary

This proposal includes design details of Pod Disruption Budget(PDB) for cStor pool
pods.
- Not to allow more than quorum no.of HighAvailable(HA i.e volume provisioned
  with >= 3 replicas) volume replicas pool pods to go down.

## Motivation

There are cases arising where OpenEBS users upgrade cluster or take out the
multiple nodes for maintenance due to this HA volume is going to ReadOnly mode
without informing users/admin[How? Multiple pool pod nodes are taken at time].

### Goals

- Create Pod Disruption Budget among the cStor pool pods where HA volume replicas exists.
  Below are examples of valid voluntary disruptions
  - Draining a node for repair or upgrade.
  - Draining a node from a cluster to scale the cluster down.

### Non-Goals

- Invalid/Other valid voluntary disruptions are not supported via PDB.

## Proposal

### User Stories

#### HighAvailable Volumes Shouldn't be disturbed for Cluster Upgrade Activities
As an OpenEBS user, HA volumes shouldn't be disturbed for cluster upgrade or maintenance
activities.

### Proposed Implementation

Kubernetes will send volume creation request to CSI driver when PVC is created.
CSI driver will send a cStorVolume provision request via CVC CR to cStorVolumeConfig(CVC)
controller. CVC controller will schedule the replicas among the pools after that
CVC controller will create a PDB among the pool pods where the volume replicas
are scheduled.

Example:
- Provisioned a CSPC with five pool specs that intern creates 5 cStor Pools.
- Now, when 'n' no.of HA volumes are provisioned(with replica count as 3) then
  volume replicas can be schedule in any available cStor pools.
- After volume replicas are placed then cStorVolumeConfig controller will
  create PDB among those cStor pools.
- After successful creation of PDB corresponding cStorVolumeConfig will be
  updated with PDB label.

So when `n` no.of HA volumes are provisioned then sigma(nCr)[where n is no.of pools,
r is no.of replicas] no.of PDB's will be created. For example if `n` pools are
created then at max nC3 + nC4 + nC5 PDB's will be created(Where 3, 4 & 5 are
replicas).

Note: PDB will be created only for HA volumes(i.e only for the volumes greater
than or equal to 3 replica count).

### Steps to perform user stories
- User has to create HighAvailable volumes on cStor then PDB will be created by
  default.

### Low Level Design

#### Work Flow
- User/Admin provisioned HA volume, Now CVC controller schedules the replicas in
  the cStor pools. After scheduling the replicas CVC controller will try to get
  PDB that was created among those cStor pools. If PDB doesn't exist then PDB will
  be created with following details:
    - All the pool names where the volume replicas are scheduled will be added as
      labels on PDB[Why? to identify the PDB without iterating over all the existing PDBS].
    - PDB name will be added as label(openebs.io/pod-disruption-budget: <pdb_name>)
      on CVC name will be added as annotation[why? To identify how many volumes
      are referring particular PDB. So during deprovisioning time if there are no
      reference to PDB then PDB can be deleted].
- During deprovision of volume CVC controller will verify is there any other
  volume referring to PDB created among those pools. If such volume exists then
  PDB will be destroyed and then finalizers will be removed from CVC or else
  finalizers will be removed from CVC.

#### Sample Yaml
Example PDB yaml:
```yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: cspc-name-<hash>
  labels:
    openebs.io/<cstor-pool1>:
    openebs.io/<cstor-pool2>:
    openebs.io/<cstor-pool3>:
spec:
  minAvailable: replicaCount/2 + 1  ###[We can also have maxUnavailable as 1].
  selector:
    matchLabels:
      app: cstor-pool
    matchExpression:
      - key: openebs.io/cstor-pool-instance
        Operator: In
        Values: {pool1, pool2, pool3}
```
Note: Above PDB is populated with value less labels[why? To make ease of
processing(to avoid unnecessary iterations to find out PDB created among those
pools)].

#### Notes:

- PodDisruptionBudget is supported but not guaranteed!
- For more detailed conversation please take a look into doc https://docs.google.com/document/d/1Pq2ZDE7K1ttmqdJl4LgZW1B6JImxzJsLGrydOpjV7rs/edit?usp=sharing.

### TestCases

- Provision a cStorVolume with less than 3 replicas then verify PDB shouldn't be created.
- Provision a cStorVolume with greaterthan or equal to 3 replicas then PDB
  should be created among those pools.
- Create multiple volumes referring to same PDB then PDB should be deleted only
  after last referring volume deprovision time.
- Induce network error during PDB creation time then PDB should be created
  during next reconciliation time.

## Drawbacks

NA

## Alternatives

NA

## Infrastructure Needed

NA
