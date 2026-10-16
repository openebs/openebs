---
oep-number: OEP TBD
title: LVM-LocalPV Changed Block Tracking (CBT)
authors:
  - "@tiagolobocastro"
owners:
  - TBD
editor: TBD
creation-date: 2026-07-04
last-updated: 2026-07-04
status: provisional
see-also:
  - designs/csi-changed-block-tracking.md
---

# LVM-LocalPV Changed Block Tracking (CBT)

## Table of Contents

- [LVM-LocalPV Changed Block Tracking (CBT)](#lvm-localpv-changed-block-tracking-cbt)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [Metadata Source: thin-provisioning-tools](#metadata-source-thin-provisioning-tools)
    - [Mapping to CSI SnapshotMetadata](#mapping-to-csi-snapshotmetadata)
    - [Architecture](#architecture)
    - [Workflow](#workflow)
  - [Implementation Details](#implementation-details)
    - [Node Agent](#node-agent)
    - [CSI Controller](#csi-controller)
    - [Helm Chart](#helm-chart)
    - [Rollout](#rollout)
  - [Risks and Mitigations](#risks-and-mitigations)
  - [Graduation Criteria](#graduation-criteria)
  - [Testing](#testing)

---

## Summary

Implement the CSI `SNAPSHOT_METADATA_SERVICE` for LVM-LocalPV
**thin-provisioned** volumes by driving the `thin-provisioning-tools`
utilities (`thin_ls`, `thin_delta`) on the node that owns the underlying
thin pool. See the top-level OEP:
[designs/csi-changed-block-tracking.md](../../csi-changed-block-tracking.md).

## Motivation

LVM thin pools track allocation at the granularity of thin-pool "chunks"
(typically 64 KiB to several MiB, configured at pool creation). The
`thin-provisioning-tools` package (already required by LVM thin-pool
snapshots) provides `thin_ls` to enumerate the mapped chunks of a
device, and `thin_delta` to compare mappings between two devices in the
same thin pool. These correspond exactly to the CSI CBT
`GetMetadataAllocated` and `GetMetadataDelta` semantics.

## Goals

- Expose LVM thin-pool allocated and changed chunk information for
  **thin-provisioned** LVM-LocalPV volumes via the CSI
  `SnapshotMetadata` service.
- Reuse the existing LVM-LocalPV node agent as the executor of the LVM /
  thin-provisioning-tools commands.
- Ship the `external-snapshot-metadata` sidecar and CR from the
  LVM-LocalPV Helm chart, opt-in.

## Non-Goals

- CBT for thick LVs. Thick LVs do not track per-block allocation or
  deltas; they are excluded.
- Changing LVM-LocalPV's snapshot lifecycle or storage class semantics.
- Providing CBT across different thin pools or nodes.

## Proposal

### Metadata Source: thin-provisioning-tools

For a thin pool the kernel exposes a metadata device (or a suitable
snapshot of it). The user-space `thin-provisioning-tools` operate on that
metadata device:

- `thin_ls` (or `thin_dump` filtered by device ID) enumerates the mapped
  virtual chunks of a specific thin device — this is what we need for
  `GetMetadataAllocated` on a given snapshot's device.
- `thin_delta --snap1 <id> --snap2 <id>` produces the differences
  between two thin devices (typically a volume and its snapshot, or two
  snapshots of the same volume): mapped-only in `snap1`, mapped-only in
  `snap2`, and different mappings. Their union gives the "changed
  chunks" we need for `GetMetadataDelta`.

Both tools output XML that is straightforward to stream-parse.

To safely run these tools against a live thin pool, LVM-LocalPV uses the
standard `lvcreate --type thin --snapshot` (or an equivalent temporary
snapshot) of the pool metadata to obtain a consistent view.

### Mapping to CSI SnapshotMetadata

- `block_metadata_type`: `FIXED_LENGTH`. Thin-pool chunks are of fixed
  size for a given pool; each `BlockMetadata` tuple has `size_bytes`
  equal to a whole number of chunk sizes.
- `volume_capacity_bytes`: the LV's virtual size.
- Consecutive mapped/changed chunks are coalesced into a single
  `BlockMetadata` tuple.
- `starting_offset` is honoured by skipping tuples that end at or before
  it.

### Architecture

```
+----------------------+     Kubernetes gRPC
| Backup application   | <---- (auth: SA token) --------+
+----------+-----------+                                |
           v                                            v
+----------------------+          +---------------------+--------+
| SnapshotMetadataSvc  |          | external-snapshot-metadata    |
| CR (lvm-localpv)     |          | sidecar (CSI controller Pod)  |
+----------------------+          +---------------------+---------+
                                                        | CSI Unix socket
                                                        v
                                        +---------------+---------------+
                                        | LVM-LocalPV CSI Controller    |
                                        +---------------+---------------+
                                                        | node-agent gRPC
                                                        v
                                        +---------------+---------------+
                                        | LVM-LocalPV Node Agent        |
                                        | (runs lvm2 + thin_ls/         |
                                        |  thin_delta)                  |
                                        +---------------+---------------+
                                                        |
                                                        v
                                        +---------------+---------------+
                                        | LVM thin pool + snapshots     |
                                        +-------------------------------+
```

### Workflow

1. Backup application opens a streaming CBT call to the sidecar.
2. Sidecar authenticates and forwards to the LVM-LocalPV CSI Controller.
3. Controller resolves the CSI `snapshot_id`(s) to `LVMSnapshot` CR
   entries; identifies the owning node and thin pool.
4. Controller invokes the node agent with the LVM thin device IDs of
   the referenced snapshot(s).
5. Node agent obtains a consistent view of the thin-pool metadata,
   runs `thin_ls` or `thin_delta`, streams parsed `BlockRange` results
   back to the controller, which emits CSI `BlockMetadata` responses.

## Implementation Details

### Node Agent

Add a new node-agent gRPC service:

```proto
service LvmThinSnapshotMetadata {
  rpc GetAllocated(GetAllocatedRequest)
      returns (stream LvmBlockMetadataResponse);
  rpc GetDelta(GetDeltaRequest)
      returns (stream LvmBlockMetadataResponse);
}

message GetAllocatedRequest {
  string vg               = 1;   // volume group
  string thin_pool        = 2;   // thin pool LV
  uint64 thin_device_id   = 3;   // thin device id of the snapshot
  int64  starting_offset  = 4;
  int32  max_results      = 5;
}

message GetDeltaRequest {
  string vg                   = 1;
  string thin_pool            = 2;
  uint64 base_thin_device_id  = 3;
  uint64 target_thin_device_id= 4;
  int64  starting_offset      = 5;
  int32  max_results          = 6;
}

message LvmBlockMetadataResponse {
  int64 volume_capacity_bytes = 1;
  int64 chunk_size_bytes      = 2;   // for FIXED_LENGTH
  repeated BlockRange ranges  = 3;
}

message BlockRange {
  int64 byte_offset = 1;
  int64 size_bytes  = 2;
}
```

Implementation notes:

- Reject non-thin LVs with `FAILED_PRECONDITION`.
- Take a consistent view of the pool metadata (metadata snapshot) before
  running `thin_ls` / `thin_delta`, and release it after.
- Stream-parse the tool's XML output; coalesce contiguous chunks.
- Enforce strictly ascending, non-overlapping ranges; honour
  `starting_offset` and `max_results`.
- Emit `chunk_size_bytes` so the controller can set `FIXED_LENGTH` with
  the correct alignment.

### CSI Controller

- Advertise `SNAPSHOT_METADATA_SERVICE` when CBT is enabled.
- Implement CSI `GetMetadataAllocated` / `GetMetadataDelta` by:
  1. Resolving the CSI `snapshot_id`(s) to `LVMSnapshot` CR entries and
     underlying thin device IDs.
  2. Verifying the underlying LV is thin; if not,
     `FAILED_PRECONDITION`.
  3. Verifying that base and target belong to the same LV (for delta);
     otherwise `INVALID_ARGUMENT`.
  4. Forwarding to the node agent on the owning node.
  5. Emitting CSI responses with
     `block_metadata_type = FIXED_LENGTH` and populated
     `volume_capacity_bytes`.
- Error mapping: not-found → `NOT_FOUND`; different-volume delta →
  `INVALID_ARGUMENT`; offset beyond LV virtual size → `OUT_OF_RANGE`.

### Helm Chart

- Add `lvm-localpv.csi.snapshotMetadata.enabled` (default `false`).
- When enabled:
  - Deploy `external-snapshot-metadata` sidecar in the CSI controller
    Pod.
  - Install the `SnapshotMetadataService` CRD if not already present.
  - Create the `SnapshotMetadataService` CR for the LVM-LocalPV driver
    with the sidecar's Service and CA bundle.
  - Provision RBAC for backup applications' SAs.
- Ensure the node-agent image includes `thin-provisioning-tools`.

### Rollout

- Off by default while upstream CSI CBT is alpha.
- Thick-LV volumes are unaffected; CBT requests for their snapshots
  return `FAILED_PRECONDITION`.

## Risks and Mitigations

- **Metadata locking**: running `thin_ls`/`thin_delta` against a live
  pool can conflict with pool operations. Mitigation: always operate on
  a metadata snapshot.
- **Chunk-size variability across pools**: chunk size is per-pool.
  Mitigation: read chunk size from the pool and report it explicitly to
  the controller.
- **Large streams for many chunks**: mitigated by coalescing contiguous
  chunks and by `starting_offset`-based resumption.
- **Tool availability/version drift**: mitigated by pinning the tools
  version inside the node-agent image and testing against a supported
  matrix.

## Graduation Criteria

- Alpha: `GetMetadataAllocated` and `GetMetadataDelta` working for a
  single thin-pool volume, gated by the Helm toggle.
- Beta: e2e coverage with a backup tool; docs and examples; multiple
  chunk sizes tested.
- GA: gated on upstream CSI CBT GA.

## Testing

- Unit tests for the `thin_ls`/`thin_delta` XML stream parser.
- Integration test: create a thin-provisioned volume, write a known
  pattern, snapshot, mutate a known set of chunks, snapshot again, and
  assert `GetMetadataDelta` yields exactly the mutated chunk ranges.
- `GetMetadataAllocated` returns exactly the written chunk ranges of a
  fresh snapshot.
- Negative: thick LVs → `FAILED_PRECONDITION`; delta across different
  LVs → `INVALID_ARGUMENT`; offset past virtual size → `OUT_OF_RANGE`.
- Helm test: with the toggle off, no sidecar, no CR, capability not
  advertised.
