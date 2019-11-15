---
oep-number: draft Migrate 20191115
title: Migration of SPC to CSPC
authors:
  - "@shubham14bajpai"
owners:
  - "@amitkumardas"
  - "@vishnuitta"
  - "@kmova"
editor: "@shubham14bajpai"
creation-date: 2019-11-15
last-updated: 2019-11-15
status: implementable
see-also:
  - NA
replaces:
  - current SPC with CSPC
superseded-by:
  - NA
---

# Migrate SPC to CSPC

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
* [Proposal](#proposal)
    * [Proposed Implementation](#proposed-implementation)
    * [High Level Design](#high-level-design)
* [Infrastructure Needed](#infrastructure-needed)

## Summary

This design is aimed at providing a design for migrating SPC to CSPC
via kubernetes job which will take SPC-name as input. 

This proposed design will be rolled out in phases. At a high level the design is
implemented in the following phases:
- Phase 1: Ability to perform migration from SPC to CSPC using 
  a Kubernetes Job.
- Phase 2: Allow for migration of old CStor volumes to CSI CStor volumes. 

## Motivation

### Goals

- Ease the process of migrating SPC to CSPC by automating it via kubernetes job. 
- Enable day 2 operations on CStor Volumes by migrating them to CSI volumes.

## Proposal

### Proposed Implementation

This design proposes the following key changes while migrating from a SPC to CSPC:

  1. New CSPC CR will be created for the migrating SPC.

  2. New CSPI CRs will be created which will replace the CSP for given SPC.

  3. The BDC with SPC label and finalizer will be replaced by CSPC label and finalizer.
  
  4. The imported pools in each CSPI will be renamed to cstor-${CSPC uid}.

  5. The CVR with CSPI labels and annotations will be replaced by CSPI labels and annotations.

  6. New CVC CR for the volume will be created with the CV details.

  7. New StorageClass with CSPC will be created and this will replace the old strageclass in the PVC of CStorVolume.

  8. Clean up old SPC and csp after successfull creation of CSPC and cspi objects.
