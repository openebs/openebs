---
oep-number: OEP 4012
title: Quality of Service (QoS) for Mayastor
authors:
  - "@urso"
owners:
  - "@urso"
editor: TBD
creation-date: 2025-08-27
last-updated: 2025-08-27
status: provisional
---

# Quality of Service (QoS) for Mayastor

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
  * [Goals](#goals)
  * [Non-Goals](#non-goals)
* [Proposal](#proposal)
  * [User Stories](#user-stories)
     * [Story 1: StorageClass with QoS Parameters](#story-1-storageclass-with-qos-parameters)
     * [Story 2: Runtime QoS Modification](#story-2-runtime-qos-modification)
     * [Story 3: Adding QoS to Non-QoS StorageClass](#story-3-adding-qos-to-non-qos-storageclass)
  * [Implementation Details](#implementation-details)
  * [Risks and Mitigations](#risks-and-mitigations)
* [Testing](#testing)

## Summary

This proposal adds Quality of Service (QoS) support to Mayastor volumes, enabling users to set IOPS and bandwidth rate limits per volume. QoS limits can be configured via StorageClass parameters at provisioning time or modified through PVC annotations at runtime without disrupting active workloads. This provides resource isolation and predictable performance characteristics for applications in multi-tenant storage environments.

## Motivation

Mayastor needs QoS controls to enable resource isolation and predictable performance in multi-tenant storage environments. SPDK provides native QoS capabilities through rate limiting that can be leveraged to implement per-volume IOPS and bandwidth controls.

### Goals

- Implement IOPS and bandwidth rate limiting per volume using SPDK's native QoS capabilities
- Enable runtime QoS modification via PVC annotations without volume restart

### Non-Goals

- Performance guarantees or QoS scheduling policies
- Node-level or pool-level aggregate QoS limits
- Historical QoS metrics collection or alerting

## Proposal

This is where we get down to the nitty gritty of what the proposal actually is.

### User Stories

#### Story 1: StorageClass with QoS Parameters

As a user, I want to create a storage class with QoS parameters so that volumes provisioned from this StorageClass have IOPS and bandwidth limits applied.

**StorageClass:**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: mayastor
provisioner: io.openebs.csi-mayastor
parameters:
  protocol: "nvmf"
  repl: "3"
  qos-iops-limit: "5000"
  qos-bandwidth-limit-mb: "200"
```

**PVC using the StorageClass:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage
spec:
  storageClassName: mayastor
  ...
```

#### Story 2: Runtime QoS Modification

As a user, I want to modify QoS annotations on an existing PVC so that I can override StorageClass settings, increase/decrease limits, or disable QoS without disrupting the volume.

**Original StorageClass:**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: mayastor
provisioner: io.openebs.csi-mayastor
parameters:
  protocol: "nvmf"
  repl: "3"
  qos-iops-limit: "2000"
  qos-bandwidth-limit-mb: "100"
```

**PVC with runtime QoS override:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-storage
  annotations:
    openebs.io/qos-iops-limit: "8000"      # Override: increased from 2000
    openebs.io/qos-bandwidth-limit-mb: "300"  # Override: increased from 100
spec:
  storageClassName: mayastor
  ...
```

#### Story 3: Adding QoS to Non-QoS StorageClass

As a user, I want to add QoS annotations to a PVC that uses a StorageClass without QoS limits so that I can apply performance controls to volumes that didn't originally have them.

**StorageClass without QoS:**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: mayastor
provisioner: io.openebs.csi-mayastor
parameters:
  protocol: "nvmf"
  repl: "2"
```

**PVC adding QoS via annotations:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: analytics-storage
  annotations:
    openebs.io/qos-iops-limit: "3000"
    openebs.io/qos-bandwidth-limit-mb: "150"
spec:
  storageClassName: mayastor-basic
  ...
```

### Implementation Details

**CSI Integration:**
- CSI driver processes StorageClass parameters for initial QoS configuration
- SPDK QoS integration via existing JsonGrpc proxy
- VolumeSpec integration for persistence

**QoS Parameters:**
- SPDK rate limit types (`rw_ios_per_sec`, `rw_mbytes_per_sec`, `r_mbytes_per_sec`, `w_mbytes_per_sec`) mapped to new StorageClass parameters and PVC annotations
- Annotation names match StorageClass parameter names using `openebs.io/` namespace prefix
- `qos-iops-limit` / `openebs.io/qos-iops-limit` - IOPS rate limit, becomes `rw_ios_per_sec`
- `qos-bandwidth-limit-mb` / `openebs.io/qos-bandwidth-limit-mb` - Combined read/write bandwidth limit, becomes `rw_mbytes_per_sec`
- `qos-read-bandwidth-limit-mb` / `openebs.io/qos-read-bandwidth-limit-mb` - Read-only bandwidth limit, becomes `r_mbytes_per_sec`
- `qos-write-bandwidth-limit-mb` / `openebs.io/qos-write-bandwidth-limit-mb` - Write-only bandwidth limit, becomes `w_mbytes_per_sec`

**PVC Annotation Monitoring:**
- Dedicated PVC watcher added to CSI driver monitors annotation changes on existing PVCs
- Detects QoS annotation additions, modifications, and removals
- Validates parameters before applying changes to live volumes
- Applies changes to live volumes without restart via JsonGrpc → SPDK RPC calls
- Updates VolumeSpec persistence layer to maintain consistency
- Reports validation errors and operation status via PVC status field

**Status Reporting:**
- Applied QoS limits added to volume status when configured for operational visibility
- Validation errors and conflicts reported in PVC status field
- Status reflects actual SPDK-applied limits regardless of source (StorageClass or PVC annotations)

**Validation and Constraints:**
- Parameter validation ensures non-negative values and meets SPDK minimum limits
- QoS applied at nexus level (published volumes only)
- SPDK minimum limits: 1000 IOPS, 10 MB/s bandwidth
- Units: IOPS (operations/second), bandwidth in megabytes/second

### Risks and Mitigations

**Resource Contention:**
- Risk: Multiple volumes with high QoS limits could exceed underlying storage capabilities, causing system-wide performance degradation despite individual volume limits.
- Mitigation: Document the fact that QoS limits are per-volume and do not account for aggregate node capacity.

**Configuration Errors on Live Volumes:**
- Risk: Invalid parameters requested by users.
- Mitigation: Reject invalid parameter changes, preserve existing QoS settings, and report validation errors in PVC status field.

**State Consistency:**
- Risk: VolumeSpec persistence and actual SPDK QoS state could become inconsistent due to system failures or manual interventions.
- Mitigation: Document use of existing `bdev_get_qos_rate_limits` RPC via JsonGrpc proxy for debugging.

## Testing

- Volume creation with StorageClass QoS parameters applies limits correctly
- PVC annotation changes update live volume QoS without restart
- Invalid QoS parameters are rejected and reported in PVC status
- QoS settings persist across io-engine restart
- Verify actual SPDK QoS state matches configuration using `bdev_get_qos_rate_limits`
