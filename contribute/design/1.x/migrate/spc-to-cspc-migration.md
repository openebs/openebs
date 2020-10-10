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
last-updated: 2020-06-18
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

  1. The SPC label and finalizer on BDCs will be replaced by CSPC label and finalizer. This is done to avoid webhook validation failure while creating equivalent CSPC.

  2. Equivalent CSPC CR will be created for the migrating SPC.

  3. Equivalent CSPI CRs will be created by operator which will replace the CSP for given SPC. The CSPI will be created by disabling the reconciliation to avoid double import.

  4. The SPC owner reference on the BDCs will be replaced by equivalent CSPC owner reference.

  5. Sequentially for each CSP

      1. Old CSP deployment will be scaled down and sync will be enabled on equivalent CSPI.
      2. Old pool will be imported by renaming it from `cstor-cspuid` to `cstor-cspcuid`.
      3. The CVR with CSP labels and annotations will be replaced by CSPI labels and annotations.
      4. Finalizers from CSP will be removed to for proper cleanup.

  6. Clean up old SPC and CSP after successfull creation of CSPC and CSPI objects.

For migrating non-csi volumes to csi volumes following changes are proposed:

  1. New StorageClass with CSPC will be created and this will replace the old strageclass in the PVC of CStorVolume.

  2. Set the PV to `Retain` reclaim policy to prevent deletion of OpenEBS resources.

  3. A temporary CStorVolumePolicy with target deploy configurations and CSPI names from old CVRs will be created. This is facilitate the creation `cstor/v1` CVRs on the same pool as the old `openebs.io/v1alpha1` CVRs were. It also help preserve any configuration set on the target deployment of old volume.

  4. Recreate PVC with volumeName already populated & csi driver info
 
  5. Recreate PV with claimRef of PVC and csi spec

  6. Delete old target deployment.

  7. Create new CVC for volume with basic provision info of volume and annotation to temporary policy

  8. Update ownerreferences of target service with CVC.
  
  9. Wait for new `cstor/v1` CV to be Healthy.

  10. Patch the pod affinity if present on policy to the new target deployment.

  11. Remove the policy annotation from the CVC and clean up temporary policy and old CV and CVRs.

  12. If snapshots are present for the given PVC migrate them from old schema to new schema.
      - Check whether the snapshotClass `csi-cstor-snapshotclass` is installed.
      - Create equivalent `volumesnapshotcontent` for old `volumesnapshotdata`.
      - Create equivalent csi `volumesnapshot` for old `volumesnapshot`.
      - Check whether the `volumesnapshotcontent` and the csi `volumesnapshot` are bound.
      - Delete the old `volumesnapshot` which should automatically remove corresponding `volumesnapshotdata`.

### High Level Design

#### Phase 1: Migration of SPC to CSPC

The migration of SPC will be performed via a job which takes SPC name as one of its argument.

The CSPC CR created via job will have `reconcile.openebs.io/disable-dependants` annotation set to  `true`. This will help in disabling reconciliation of on all CSPIs created for the CSPC. The reconciliation is set off on CSPIs to avoid import while the old CSP pods are still running. Once all CSPI are successfully created the annotation will be removed.

Sequentially one CSPI is taken and the corresponding CSP is found using `kubernetes/hostname` label. The CSP deployment is scaled down to avoid multiple pods trying to import the same pool. Next the all the BDC for given CSPI are updated with CSPC information. The CSPI will be patched with the annotation `cstorpoolinstance.openebs.io/oldname`. When CSPI reconciliation is enabled then the pool manager will import the pool

The import command will be modified to import with or without the oldname. For example for renaming the command would look like:
```sh
/usr/local/bin/zpool import  -o cachefile=/var/openebs/cstor-pool/pool.cache  -d /var/openebs/sparse cstor-08bfced5-6a28-4a63-a76b-c48c69be6ad5 cstor-6b3bbf9e-451d-4333-b119-1bb5217e5bc2
```
For importing without renaming the command would look like:
```sh
/usr/local/bin/zpool import  -o cachefile=/var/openebs/cstor-pool/pool.cache  -d /var/openebs/sparse cstor-6b3bbf9e-451d-4333-b119-1bb5217e5bc2
```


The `cstorpoolinstance.openebs.io/oldname` annotation will be used to rename the pool which was named as `cstor-cspuid` to `cstor-cspcuid`. This annotation will be removed after successful import of the pool.

**Note: Before migrating make sure:**
 - OpenEBS version of old resources(control-plane and data-plane) should be atleast 1.11.0.
 - Apply new cstor-operators and csi driver which also should be atleast in 1.11.0 version.
 - Identify the nodes on which the `CSP` are present and run `fdisk -l` command on that node. If the command is hung then bad block file exists on that node. If such case occurs, please resolve this issue before proceeding with the migration. To identify the nodes look for the `kubernetes.io/hostname` label on the `CSP`.


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
        - "cstor-spc"
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

**Note: Before proceeding to the below steps the pool must be migrated successfully and the application using the volume to be migrated must be scale down.**

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
- OpenEBS version should be 1.11 or above.
- CSPC operator 1.11 or above should be installed.
- CStor CSI operator 1.11 or above should be installed.
