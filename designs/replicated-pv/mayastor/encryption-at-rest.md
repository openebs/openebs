---
oep-number: OEP 3843
title: OpenEBS Enhancement Proposal for Mayastor At-Rest Encryption of data
authors:
  - "@dsharma-dc"
owners:
  - "@dsharma-dc"
  - "@Abhinandan-Purkait"
editor: TBD
creation-date: 2025-01-24
last-updated: 2025-01-24
status: provisional
---

# OpenEBS Enhancement Proposal for Mayastor At-Rest Encryption of data

## Table of Contents

1. [Overview](#overview)
2. [Motivation](#motivation)
3. [Goals](#goals)
4. [Non-Goals](#non-goals)
5. [Proposal](#proposal)
6. [User Stories](#user-stories)
7. [Implementation Details](#implementation-details)
8. [Testing](#testing)

---

## Overview

This proposal introduces the encryption of data at-rest in the Replicated PV Mayastor (hereafter referred as Mayastor) diskpools. This feature ensures that:

1. All the data on a Maystor diskpool is stored encrypted if the encryption has been requested on the pool during pool creation.
2. It is not possible to disable encryption on a pool that has been created with encryption enabled initially.
3. The encryption can not be enabled on a pool that is already created un-encrypted.
4. A volume that is created with a topology for encrypted pools gets all the replicas placed on encrypted pools.

This feature ensures data protection and compliance for various use-cases of data management.

## Motivation

Implementing data encryption at rest ensures that sensitive information remains secure even if storage media is lost, stolen, or compromised. It protects against unauthorized access by ensuring data is only readable by authorized users or systems. Encryption also helps meet regulatory compliance requirements, demonstrating a commitment to privacy and data protection. Additionally, it mitigates the risk of data breaches, maintaining trust with stakeholders.

## Goals

- Implement the at-rest encryption of data in Mayastor, at a diskpool level so that all user data on the diskpool is stored encrypted.
- Support FIPS compliant encryption methods.

## Non-Goals

- This proposal does not implement (or integrate with) any Key management service for the encryption keys.
- This proposal does not implement in-flight data encryption.
- This proposal does not implement support for disabling encryption on a pool that has been created with encryption.
- This proposal does not implement support for enabling encryption on a pool that is already created as un-encrypted.
- This proposal does not implement or strengthen any existing communication protocols between various services.

## Proposal

### Key Concepts

1. **Diskpool Level Encryption**: Ability to encrypt data at a pool level without differentiating which replica the data belongs to. All replicas' data on such a pool will get encrypted.
2. **Encryption Key Management**: This is a prerequisite.
   - A key is provisioned by admin or a Key Management Service (KMS) with a supported cipher, for the use of storage system, and stored as a Kubernetes Secret.
   - The admin can additionally safeguard the key via Resource-Encryption-at-Rest facility provided by Kubernetes.

### Workflow

1. **Encrypted Diskpool Creation**:
   - The user/admin creates a diskpool yaml spec that contains the name of the Secret which holds the key.
   - When the spec is applied, the diskpool operator picks up this request and dispatches the create pool request containing Secret name to the Mayastor agents that complete the diskpool provisioning.
   - The spec for creating a pool with encryption will look like below:

```
apiVersion: "openebs.io/v1beta3"
kind: DiskPool
metadata:
  name: <pool-name>
  namespace: <namespace>
spec:
  node: <node-name>
  disks: ["/dev/disk/by-id/<id>"]
  topology:
    labelled:
      topology-key: topology-value
  encryptionKeyConfig:
    type: Secret
    config:
      name: <myKeySecretName>
```
2. **Diskpool CRD migration**:
   - After an upgrade to Diskpool CRD version v1beta3 happens in the cluster, any existing CRs that are on version v1beta2 will have to be migrated to version v1beta3 by the implementation. This would also require that the new field `encryptionKeyConfig` be defined as optional in the CRD.

3. **Diskpool import upon node or io-engine restart**:
   - In the event of a node restart, io-engine restart or a node going offline and coming up again - the diskpool
   is imported. The import needs to be done using the same DEK that was used during diskpool creation.

4. **Volume Provisioning**:
   - Pool topology rules ensure that for a volume requesting encryption, the replicas are only placed on the diskpools that have
   encryption enabled on them. This will be handled by storageclass via the poolHasTopologyKey setting to let the volume replica placement happen on pools that are labelled with a specific key identifying encryption.
   - The storageclass definition required for volumes to be encrypted will have an additional field named `secure`, which needs to be set to `true` if encryption is required.
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: mayastor-3
parameters:
  secure: "true"
  repl: "3"
provisioner: io.openebs.csi-mayastor
```

## User Stories

1. **Story 1**: As an organisation's security lead, I want all our data getting stored on the storage systems be encrypted with a key that our admins provide.
2. **Story 2**: As a system administrator, I want minimal configuration control to easily let storage use the encryption keys for data at-rest encryption.

## Implementation Details

### Design

- **Secret Name Parameter**: 
   - Add a new field `encryptionKeyConfig` to the diskpool CR. This fields holds the name of Secret object that contains actual DEK.
   - The control plane agent-core refers the metadata info from `encryptionKeyConfig` and then parses the actual Data Encryption Key(DEK) from the Secret, via Kubernetes client APIs.
   - The data plane receives the request to create the pool using the provided DEK.
   - Once the pool is created using a Secret, the key for that pool can't be transparently changed via a different Secret. Doing so will require a full rebuild of pool onto a different pool.

- **Secret Name during Pool Import**: 
  - Set the `encryptionKeyConfig` in the PoolSpec.
  - When a pool import is required, use the `encryptionKeyConfig` from PoolSpec to fetch the DEK again.
  - Dispatch the import operation to data plane.

### Components to Update

- **Diskpool Custom Resource Definition**: The Custom Resource need to identify the `encryptionKeyConfig` field.
- **Control-Plane agent-core**: The agent needs to be modified to have an ability to read Kubernetes API objects.
- **Data-Plane io-engine**: io-engine need to be able to create and place a crypto block device on top of base block device of the diskpool.

## Testing

 - Create a diskpool with a Secret of AES_CBC cipher and 128-bit key. The pool creation must succeed.
 - Create a diskpool with a Secret of AES_CBC cipher and 256-bit key. The pool creation must succeed.
 - Create a diskpool with a Secret of AES_XTS cipher and 128-bit keys. The pool creation must succeed.
 - Upon a node restart, the import of the encrypted pool on that node must successfully complete.
 - Provision a volume via encryption storage class. The volume replicas must get placed only on encrypted pools.
 - Scale up an encrypted volume. The new replicas must get placed only on encrypted pools.
