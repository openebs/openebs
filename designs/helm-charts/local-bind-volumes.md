---
oep-number: Issue also needs to be created
title: OpenEBS Enhancement Proposal for Mayastor Local Feature
authors:
  - "@todeb"
owners:
  - "@todeb"
  - "@tiagolobocastro"
editor: TBD
creation-date: 2024-11-07
last-updated: 2024-11-07
status: provisional
---

# OpenEBS Enhancement Proposal for Mayastor Local Feature

## Table of Contents

1. [Overview](#overview)
2. [Motivation](#motivation)
3. [Goals](#goals)
4. [Non-Goals](#non-goals)
5. [Proposal](#proposal)
6. [User Stories](#user-stories)
7. [Implementation Details](#implementation-details)
8. [Drawbacks](#drawbacks)
9. [Alternatives](#alternatives)
10. [Unresolved Questions](#unresolved-questions)

---

## 1. Overview

This proposal reintroduces a "local" feature for the Mayastor storage engine in OpenEBS, designed specifically for single-replica volumes. This feature ensures that:

1. A Mayastor Persistent Volume (PV) is created on the same node where the consuming pod is initially scheduled (using `volumeBindingMode: WaitForFirstConsumer`).
2. Pods are prevented from rescheduling onto nodes where their Mayastor PVs are not present, maintaining strict local attachment to the original node.
3. Users can configure the local behavior using a `local` flag, which can be set or unset via `kubectl-mayastor` commands.

By implementing these features, the local configuration improves performance and resilience in environments without dedicated storage nodes.

## 2. Motivation

In clusters that do not have dedicated storage nodes, keeping application pods on the same node as their Mayastor volumes is essential. While `volumeBindingMode: WaitForFirstConsumer` is intended to ensure that volumes are created on the same node as their consuming pods, it does not always work as expected with Mayastor volumes. Reintroducing the `local` feature with this proposal enforces both local provisioning and node-level affinity for single-replica volumes, thereby avoiding cross-node data access and potential latency or availability issues.

## 3. Goals

- Implement the local feature for single-replica volumes in Mayastor, ensuring that PVs are created on the same node as their consuming pods when `volumeBindingMode: WaitForFirstConsumer` is used.
- Prevent pods from being rescheduled to nodes where the associated volume does not exist.
- Allow users to set or unset the `local` flag for a volume through `kubectl-mayastor`, providing flexibility and administrative control.

## 4. Non-Goals

- This proposal does not implement the local feature for multi-replica volumes, as cross-node replication complicates strict local binding.

## 5. Proposal

### Key Concepts

1. **Local Provisioning for Single Replica**: Enforce that Mayastor PVs with a single replica are provisioned on the same node as their consuming pods.
2. **Anti-rescheduling Affinity**: Once scheduled, a pod cannot move to a different node unless the corresponding volume is also located on that node.
3. **Configurable Local Flag**: Add a `local` flag to Mayastor volumes, which can be set or unset via `kubectl-mayastor`. This flag enables administrators to toggle local binding behavior dynamically.

### Workflow

1. **Initial Pod Scheduling and Volume Creation**:
   - The user sets `local: true` in the storage class for Mayastor.
   - If `volumeBindingMode: WaitForFirstConsumer` in the storage class for Mayastor:
     - When the pod is created, Kubernetes will defer scheduling until the volume is provisioned on the node.
     - Mayastor provisions the volume on the same node as the pod, enforcing local attachment.
   - If `volumeBindingMode: Immediate` in the storage class for Mayastor:
     - Mayastor provisions the volume with the `local` flag enabled. The provisioned volume will include a node affinity term specifying the node where the volume resides.
     - Kubernetes scheduler will schedule the pod on the node where the volume is provisioned, ensuring local attachment.

2. **Single-Replica Restriction**:
   - This local feature only applies to volumes with a single replica. If additional replicas are added, the local flag becomes ineffective, and the volume no longer maintains strict local binding.

3. **Anti-Rescheduling Enforcement**:
   - Node affinity rules are set to ensure that a pod cannot be rescheduled to a node without the volume.
   - If the node with the local volume goes offline, the pod remains unscheduled rather than migrating, preventing data access issues due to cross-node scheduling.

4. **Configuring the Local Flag**:
   - The `local` flag can be modified by administrators using `kubectl-mayastor` commands, allowing on-demand toggling.
   - Setting `local: true` enables strict local attachment; setting `local: false` removes the affinity restrictions, allowing the volume to be scheduled across nodes if required.
   - The enforcement of the `local` flag applies only during the scheduling and rescheduling processes. If a pod is located on a different node from the storage, the scheduling or rescheduling should not be managed by this implementation. Instead, this behavior should be left to the Kubernetes scheduler itself.
.

## 6. User Stories

1. **Story 1**: As an application developer, I want my application pod and its Mayastor volume to stay on the same node, ensuring low latency and high performance for data access.
2. **Story 2**: As a DevOps engineer, I want control over the local behavior for volumes, so I can enable or disable this feature as needed, using `kubectl-mayastor`.
3. **Story 3**: As a system administrator, I want the flexibility to toggle local binding without disrupting active volumes, providing seamless adaptability for different workload requirements. Additionally, when cordoning a node for maintenance or reboot, I want to ensure that the pods using local volumes will not be rescheduled to other nodes, ensuring the system's stability during such operations.

## 7. Implementation Details

### Design

- **Local Flag Parameter**: 
  - Add a `local` flag to the volume specification. When `local: true` is set, Mayastor enforces both local provisioning and anti-rescheduling of single-replica volumes.
  - `kubectl-mayastor` commands can be used to set or unset the `local` flag for active volumes, dynamically controlling local binding.

- **Single-Replica Volume Constraint**: 
  - This feature applies only to volumes configured with one replica, as multi-replica configurations may require cross-node replication.
  - If additional replicas are added, the `local` flag is automatically disabled, and cross-node rescheduling may occur.

- **Affinity Management**:
  - Node affinity rules are applied to the volume based on the `local` flag setting, ensuring that the pod and volume remain co-located.
  - Kubernetes will use these affinity rules to restrict rescheduling to the initial node only.

### Components to Update

- **Mayastor Volume Provisioner**: Update the provisioner to recognize and enforce the `local` flag.
- **kubectl-mayastor Tool**: Extend `kubectl-mayastor` to support commands for setting or unsetting the `local` flag on a per-volume basis.

## 8. Drawbacks

- **Reduced Flexibility**: Local binding restricts pod migration, limiting resilience in scenarios where cross-node scheduling might improve availability.
- **Potential Downtime**: If a node fails, applications using local binding will remain unscheduled until the node is restored, potentially leading to increased downtime.

## 9. Alternatives

- **Manual Affinity Configurations**: Users could manually configure node affinity, but this is more complex and does not ensure initial volume provisioning on the correct node.
- **Scheduler extension or plugin**: Adding some implementation to k8s scheduler to check mayastor topology before schedule a pod, but that will only work for volumes already provisioned, but will not strict volume provisioning when `volumeBindingMode: WaitForFirstConsumer`.

