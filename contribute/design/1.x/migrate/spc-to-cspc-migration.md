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

  5. The CVR with CSP labels and annotations will be replaced by CSPI labels and annotations.

  6. Clean up old SPC and csp after successfull creation of CSPC and cspi objects.

For migrating non-csi volumes to csi volumes following changes are proposed:

  1. New StorageClass with CSPC will be created and this will replace the old strageclass in the PVC of CStorVolume.

  2. Set the PV to `Retain` reclaim policy to prevent deletion of OpenEBS resources.

  3. Recreate old PV with csi spec translation.

  4. Recreate old PVC with updated csi spec PV and StorageClass.

  5. Create CVC CR for the volume with the CV details.

  6. Update ownerreferences of CV, service with CVC and CVRs with CV.

### High Level Design

#### Phase 1: Migration of SPC to CSPC

The migration of SPC will be performed via a job which takes SPC name as one of its argument.

The CSPC CR created via job will have `reconcile.openebs.io/disable-dependants` annotation set to  `true`. This will help in disabling reconciliation of on all CSPIs created for the CSPC. The reconciliation is set off on CSPIs to avoid import while the old CSP pods are still running. Once all CSPI are successfully created the annotation will be removed.

Sequentially one CSPI is taken and the corresponding CSP is found using `kubernetes/hostname` label. The CSP deployment is scaled down to avoid multiple pods trying to import the same pool. Next the all the BDC for given CSPI are updated with CSPC information. The CSPI will be patched with the annotation `cstorpoolinstance.openebs.io/oldname`. Then CSPI reconciliation will be enabled which will create the CSPI deployment which will rename and import the pool. 

The import command will be modified to import with or without the oldname. For example for renaming the command would look like:
```sh
/usr/local/bin/zpool import  -o cachefile=/var/openebs/cstor-poolpool.cache  -d /var/openebs/sparse cstor-08bfced5-6a28-4a63-a76b-c48c69be6ad5 cstor-6b3bbf9e-451d-4333-b119-1bb5217e5bc2
```
For importing without renaming the command would look like:
```sh
/usr/local/bin/zpool import  -o cachefile=/var/openebs/cstor-poolpool.cache  -d /var/openebs/sparse cstor-6b3bbf9e-451d-4333-b119-1bb5217e5bc2
```


The `cstorpoolinstance.openebs.io/oldname` annotation will be used to rename the pool which was named as `cstor-cspuid` to `cstor-cspcuid`. This annotation will be removed after successful import of the pool.

The Job spec for migrating SPC is:
```yaml
---
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-spc-cstor-sparse-pool
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
      - name:  migrate
        args:
        - "pool"
        # name of the spc that is to be migrated
        - "--spc-name=cstor-sparse-pool"

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

        image: quay.io/openebs/migrate:ci
      restartPolicy: OnFailure
---
```

After successful completion of pool migration the logs will list out all applications having volumes on the given pool.

#### Phase 2: Migration of Non-CSI volume to CSI volume

**Note: Before proceeding to the below steps the pool must be migrated successfully and all the applications having volumes on the pool must be scale down.**

The migration of volumes will be performed via a job which takes the migrated CSPC name as one of its argument.

The Job spec for migrating SPC is:
```yaml
---
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-cstor-volume-pvc-b265427e-6a62-470a-a841-5a36be371e14
  namespace: openebs
spec:
  backoffLimit: 4
  template:
    spec:
      # VERIFY the value of serviceAccountName is pointing to service account
      # created within openebs namespace. Use the non-default account.
      # by running `kubectl get sa -n <openebs-namespace>`
      serviceAccountName: openebs-maya-operator
      containers:
      - name:  migrate
        args:
        - "cstor-volume"
        # pv-name of the volume which has to be migrated
        - "--pv-name=pvc-b265427e-6a62-470a-a841-5a36be371e14"

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

        image: quay.io/openebs/migrate:ci
      restartPolicy: OnFailure
---
```

After the successful completion of the job the applications can be scaled up to verify the migration of volumes. Once the application is up new `csivolume` CR will be generated for the volume.

## Infrastructure Needed

- Kubernetes version should be 1.14 or above.
- OpenEBS version should be 1.3 or above.
- CSPC operator should be installed.
- CStor CSI operator should be installed.
