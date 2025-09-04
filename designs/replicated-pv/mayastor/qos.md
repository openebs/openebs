---
oep-number: OEP 4012
title: Quality of Service (QoS) for Mayastor
authors:
  - "@urso"
owners:
  - "@urso"
editor: TBD
creation-date: 2025-08-27
last-updated: 2025-09-04
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
     * [Story 1: Volume Creation with QoS](#story-1-volume-creation-with-qos)
     * [Story 2: Runtime QoS Modification](#story-2-runtime-qos-modification)
     * [Story 3: Adding QoS to Existing Volume](#story-3-adding-qos-to-existing-volume)
  * [Implementation Details](#implementation-details)
  * [Risks and Mitigations](#risks-and-mitigations)
* [Testing](#testing)

## Summary

This proposal adds Quality of Service (QoS) support to Mayastor volumes, enabling users to set IOPS and bandwidth rate limits per volume. QoS limits can be configured through Volume Attribute Classes at provisioning time or modified at runtime without disrupting active workloads. This provides resource isolation and predictable performance characteristics for applications in multi-tenant storage environments.

## Motivation

Mayastor needs QoS controls to enable resource isolation and predictable performance in multi-tenant storage environments. SPDK provides native QoS capabilities through rate limiting that can be leveraged to implement per-volume IOPS and bandwidth controls.

### Goals

- Implement IOPS and bandwidth rate limiting per volume using SPDK's native QoS capabilities
- Enable runtime QoS modification via Volume Attribute Classes without volume restart

### Non-Goals

- Performance guarantees or QoS scheduling policies
- Node-level or pool-level aggregate QoS limits
- Historical QoS metrics collection or alerting

## Proposal

**Kubernetes Version Support:**
Volume Attribute Classes is supported in Kubernetes 1.31+ (beta) and 1.34+ (stable).

### User Stories

#### Story 1: Volume Creation with QoS

As a user, I want to create a volume with IOPS and bandwidth limits applied so that my application has predictable storage performance.

**Volume Attribute Class:**
```yaml
apiVersion: storage.k8s.io/v1beta1
kind: VolumeAttributesClass
metadata:
  name: standard-performance
driverName: io.openebs.csi-mayastor
parameters:
  qos-iops-limit: "5000"
  qos-bandwidth-limit-mb: "200"
```

**PVC with QoS:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage
spec:
  storageClassName: mayastor
  volumeAttributesClassName: standard-performance
  ...
```

#### Story 2: Runtime QoS Modification

As a user, I want to modify QoS settings on an existing volume so that I can increase/decrease limits without disrupting the volume.

**Higher performance tier:**
```yaml
apiVersion: storage.k8s.io/v1beta1
kind: VolumeAttributesClass
metadata:
  name: high-performance
driverName: io.openebs.csi-mayastor
parameters:
  qos-iops-limit: "8000"
  qos-bandwidth-limit-mb: "300"
```

**Upgrade existing PVC to higher tier:**
```bash
kubectl patch pvc app-storage -p '{"spec":{"volumeAttributesClassName":"high-performance"}}'
```

#### Story 3: Adding QoS to Existing Volume

As a user, I want to add QoS limits to an existing volume that was originally created without performance controls.

**Analytics performance tier:**
```yaml
apiVersion: storage.k8s.io/v1beta1
kind: VolumeAttributesClass
metadata:
  name: analytics-tier
driverName: io.openebs.csi-mayastor
parameters:
  qos-iops-limit: "3000"
  qos-bandwidth-limit-mb: "150"
```

**Add QoS to existing PVC:**
```bash
kubectl patch pvc analytics-storage -p '{"spec":{"volumeAttributesClassName":"analytics-tier"}}'
```

### Implementation Details

**CSI Integration:**
- CSI driver implements `MODIFY_VOLUME` capability to support Volume Attribute Classes
- Initial QoS configuration processed via VolumeAttributesClass parameters during `CreateVolume`
- Runtime modifications handled through `ControllerModifyVolume` CSI RPC
- SPDK QoS integration via existing JsonGrpc proxy
- VolumeSpec integration for persistence

**QoS Parameters:**
- SPDK rate limit types (`rw_ios_per_sec`, `rw_mbytes_per_sec`, `r_mbytes_per_sec`, `w_mbytes_per_sec`) mapped to VolumeAttributesClass parameters
- `qos-iops-limit` - IOPS rate limit, becomes `rw_ios_per_sec`
- `qos-bandwidth-limit-mb` - Combined read/write bandwidth limit, becomes `rw_mbytes_per_sec`
- `qos-read-bandwidth-limit-mb` - Read-only bandwidth limit, becomes `r_mbytes_per_sec`
- `qos-write-bandwidth-limit-mb` - Write-only bandwidth limit, becomes `w_mbytes_per_sec`

**Volume Modification Workflow:**
- Kubernetes triggers `ControllerModifyVolume` RPC when PVC's `volumeAttributesClassName` changes
- CSI driver validates new VolumeAttributesClass parameters
- Parameters applied to live volumes without restart via JsonGrpc → SPDK RPC calls
- VolumeSpec persistence layer updated to maintain consistency
- Operation status reported back to Kubernetes via RPC response

**Status Reporting:**
- Applied QoS limits added to volume status when configured for operational visibility
- Validation errors and conflicts reported via `ControllerModifyVolume` RPC response
- Status reflects actual SPDK-applied limits from VolumeAttributesClass parameters

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

- Volume creation with VolumeAttributesClass QoS parameters applies limits correctly
- `ControllerModifyVolume` workflow updates live volume QoS without restart
- Invalid QoS parameters are rejected and reported via RPC response
- QoS settings persist across io-engine restart
- Verify actual SPDK QoS state matches configuration using `bdev_get_qos_rate_limits`
