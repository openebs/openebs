---
oep-number: OEP 4011
title: Add Raid0 DiskPool support to OpenEBS Mayastor
authors:
  - "@urso"
owners:
  - "@urso"
editor: TBD
creation-date: 2025-08-26
last-updated: 2025-08-26
status: provisional
---

# Add Raid0 DiskPool support to OpenEBS Mayastor

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories](#user-stories)
    * [Workflow](#workflow)
    * [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Testing](#testing)

## Summary

This proposal adds RAID0 support to Mayastor disk pools, enabling users to combine multiple devices into single pools with aggregate capacity. The implementation leverages SPDK RAID0 functionality while preserving all existing LVS features including encryption, snapshots, and thin provisioning. This enhancement addresses current limitations where users must create separate pools per device, leading to potential sub-optimal disk space utilization across multiple small pools.

## Motivation

Mayastor currently requires separate disk pools per device, resulting in multiple small pools with potential sub-optimal disk space utilization. RAID0 support enables users to consolidate multiple devices into larger pools with improved capacity utilization.

### Goals

- Enable multi-device RAID0 pools with aggregate capacity from multiple devices
- Preserve all existing LVS features (encryption, snapshots, thin provisioning) on RAID0 pools
- Maintain backward compatibility with existing single-device pools
- Provide foundation for future RAID level support (RAID1, RAID5)

**Success Criteria:**
- Users can create RAID0 pools from multiple devices
- RAID0 pools function identically to single-device pools from user perspective
- No regressions in existing single-device functionality

### Non-Goals

- RAID0 device replacement maybe future enhancement
- Migration from existing single-device pools to RAID0
- Other RAID levels (RAID1, RAID5) - separate OEPs

## Proposal

### User Stories

1. **Story 1**: As a user, I want to create large storage pools (e.g., combining 4x 2TB devices into an 8TB pool) to support applications requiring substantial storage capacity.

### Workflow

#### Single Device Pool (Existing)

1. **Create DiskPool CRD**: Specify single device (no `poolType` needed)
2. **Apply configuration**: Controller creates pool directly on device
3. **Pool ready**: Single-device pool available

```yaml
apiVersion: openebs.io/v1beta3
kind: DiskPool
metadata:
  name: single-pool
spec:
  node: node-1
  disks:
    - /dev/nvme0n1
```

#### RAID0 Pool (New)

1. **Prepare devices**: Ensure multiple devices are available
2. **Create DiskPool CRD**: Specify multiple devices with `poolType: "raid0"`
3. **Controller validation**: Validates RAID0 requirements (min 2 devices)
4. **RAID0 creation**: io-engine creates SPDK RAID0 bdev from devices
5. **Pool creation**: LVS blobstore created on RAID0 bdev
6. **Pool ready**: RAID0 pool available as single large pool

```yaml
apiVersion: openebs.io/v1beta3
kind: DiskPool
metadata:
  name: raid0-pool
spec:
  node: node-1
  poolType: "raid0"
  disks:
    - /dev/nvme0n1
    - /dev/nvme1n1
    - /dev/nvme2n1
  raid0:                # <- optional
    stripSize: "64k"
```


### Implementation Details/Notes/Constraints

**Architecture:**
- Multiple devices → SPDK RAID0 → Encryption (if enabled) → LVS blobstore
- All existing LVS features work transparently
- Performance optimized with single encryption layer

**Configuration:**
- Add optional `poolType` and `raid0` fields to existing DiskPool CRD
- No CRD version bump needed
- Backward compatibility maintained

**Core Implementation:**
- io-engine detects multi-device + `poolType: "raid0"`
- Uses SPDK `spdk_bdev_raid_create()` API
- LVS blobstore created on RAID0 bdev (encrypted if specified)

**Key Constraints:**
- Minimum 2 devices required for RAID0
- Single device failure fails entire pool
- No migration from existing pools

### Risks and Mitigations

**Risk**: Any single device failure destroys entire pool (inherent RAID0 behavior)

**Mitigations:**
1. **Clear Documentation**: Explicitly document RAID0 failure characteristics and appropriate use cases to ensure users understand the trade-offs
2. **Device Health Monitoring**: Ensure existing device monitoring works properly with RAID0 pools to provide early warning of potential failures

Note: SPDK supports device replacement capabilities that could be added as a future enhancement to provide additional mitigation options.

## Testing

- RAID0 pool creation with multiple devices
- Configuration validation (minimum devices, strip size)
- Volume operations work on RAID0 pools
- Single-device pools continue working unchanged
- Device failure behavior
