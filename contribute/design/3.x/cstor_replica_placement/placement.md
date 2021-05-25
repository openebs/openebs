---
oep-number: CStor Volume Replica Placement
title: Placement of CStor Volumes to a CStor Pool by enforcing constraints and policies
authors:
  - "@sonasingh46"
owners:
  - "@kmova"
  - "@sonasingh46"
  - "@prateekpandey14"
creation-date: 2021-05-25
last-updated: 2021-05-25
status: provisional
---

# CStor Pool Migration

## Table of Contents

- [CStor Volume Replica Placement](#cstor-volume-replica-placement)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
      - [Support to disable overprovisioning on cstor pool](#support-to-disable-overprovisioning-on-cstor-pool)
    - [Proposed Implementation](#proposed-implementation)
      - [cvr-scheduler](#cvr-scheduler)
    - [Steps to perform user stories](#steps-to-perform-user-stories)
    - [Schema changes](#schema-changes)

## Summary

This proposal brings out the design details to implement volume placement on
CStor pool.

## Motivation

In current impementation, the CVR (CStor Volume Replica) gets bound to a CSPI
(CStor Pool Instance) by the cvr controller in a random fashion. As a result of
this, users have no way to specify to bind a CVR to a preferred CSPI. 

- CStor volume placement should be supported for the following cases
(not exhaustive):
  1. Disable overprovisoning on CSPI
  2. Migration of a CVR from one CSPI to another
  3. Selecting the best CSPI(s) for the CVR(s) based on node and zone locality


### Goals

- The bind of a CVR to a CSPI should be deterministic and users should be able to
specify policies for the binding. As a first cut implementation, the policy of 
interest here is the overprovisioning restriction. 

### Non-Goals

- Migrating a CVR from one CSPI to another
- Policies around node and zone locality

## Proposal

### User Stories

#### Disable overprovisioning on CStor pools
As an OpenEBS user, I should be able to disable overprovisioning on CStor pools.

#### Migrating a CVR from one CSPI to another
As an OpenEBS user, I should be able to migrate volume from one CStor pool to
another CStor pool.

#### Enforce policies on CVR binding
As an OpenEBS user, I should be able to enforce policies e.g. node,zone locality
to bind to a most suitable(best effort) CSPI.

### Proposed Implementation

#### CVR-Scheduler

In current impementation, the CVR (CStor Volume Replica) gets bound to a CSPI
(CStor Pool Instance) by the cvr controller in a random fashion. See this [link]
(https://github.com/openebs/cstor-operators/blob/master/pkg/controllers/cstorvolumeconfig/volume_operations.go#L396)

A separate controller i.e cvr-scheduler watches for CVR(s). Once the CVR is 
created, it is unassigned, meaning it does not belong to any CSPI. Now, this 
cvr-scheduler enforces policies and requirements e.g. overprovisioning etc and 
picks up appropriate or most suitable CSPI for the particular CVR and assigns 
this CVR to a CSPI by patching the CVR. This patching will basically put the 
selected CSPI name and UUID on the CVR.

The replica controller that also watches for the CVRs. It ignores the CVR that 
has not been assigned any CSPI. Once the CVR is assigned to a CSPI, the replica 
controller processes the CVR to carry out the volume provisioning.

In case a quick binding is required, there will be an option to by pass the cvr
scheduler and the usual way of randomised binding will prevail via the replica
controller.

The policies for the cvr-scheduler (e.g. overprovisioning, binding) can be passed
to the CVR(s) via the CSPC.
So, the CSPC is the user-interacting API where the policies can be mentioned for
CVR bindings.

### Steps to perform user stories

Add annotations on CSPC to apply policies for CVR binding. 

### Schema changes

No schema changes are required. Policies can be passed via the annotations.
