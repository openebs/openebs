---
oep-number: OEP TBD
title: ZFS-LocalPV Changed Block Tracking (CBT)
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

# ZFS-LocalPV Changed Block Tracking (CBT)

## Table of Contents

- [ZFS-LocalPV Changed Block Tracking (CBT)](#zfs-localpv-changed-block-tracking-cbt)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [Metadata Source: ZFS](#metadata-source-zfs)
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

Implement the CSI `SNAPSHOT_METADATA_SERVICE` for ZFS-LocalPV
**zvol-backed** volumes, using ZFS's native ability to describe
allocated and changed blocks of a snapshot. See the top-level OEP:
[designs/csi-changed-block-tracking.md](../../csi-changed-block-tracking.md).

## Motivation

ZFS tracks per-block birth transaction group (`txg`) numbers, and can
enumerate the changes between two snapshots of the same dataset via
`zfs diff` (records) and incremental `zfs send -i` (data stream).
Combined, these primitives give us both a per-snapshot allocation view
and the block-level delta between two snapshots of the same zvol —
exactly what CSI CBT expects.

## Goals

- Expose ZFS's allocated-block and changed-block information for
  **zvol-backed** ZFS-LocalPV volumes via the CSI `SnapshotMetadata`
  service.
- Reuse the existing ZFS-LocalPV node agent as the executor of the ZFS
  commands, because zvols are node-local.
- Ship the `external-snapshot-metadata` sidecar and CR from the
  ZFS-LocalPV Helm chart, opt-in.

## Non-Goals

- CBT for dataset-backed ZFS-LocalPV volumes. The delta primitives used
  here (per-block birth `txg`, incremental send WRITE records) are
  specific to zvols; datasets are out of scope.
- Changing ZFS-LocalPV's snapshot lifecycle.
- Cross-pool or cross-node deltas.
- Shipping ZFS itself or changing kernel modules.

## Proposal

### Metadata Source: ZFS

We consider three complementary ZFS mechanisms:

1. **`zfs diff <snap1> <snap2>`**: describes changed *objects*. For zvols
   this is a single object, so the record set is coarse; we use it for
   validation, not as the primary delta source.
2. **Incremental `zfs send -i <snap1> <snap2> | zstreamdump`**: the
   incremental send stream contains `WRITE` records identifying the
   byte ranges that changed on the zvol between the two snapshots.
   This is the direct source for `GetMetadataDelta`.
3. **Block-birth `txg` comparison**: for `GetMetadataAllocated`, we walk
   the snapshot's block pointers (via `zdb`-style introspection or a
   dedicated helper) and emit ranges for blocks whose birth `txg` is at
   or before the snapshot's `txg`.

Preferred approach:

- `GetMetadataAllocated` → block-birth traversal (self-contained, no
  need to reference another snapshot).
- `GetMetadataDelta` → parse the incremental send stream's write
  records; do **not** move the data itself, only the range headers.

### Mapping to CSI SnapshotMetadata

- `block_metadata_type`: `VARIABLE_LENGTH`. ZFS records/extents can vary
  in size depending on `volblocksize`, compression, and write patterns.
- `volume_capacity_bytes`: the zvol's `volsize`.
- Consecutive changed records are coalesced into a single
  `BlockMetadata` tuple where possible.
- `starting_offset` is honoured by skipping tuples that end at or before
  it.

### Architecture

```
+----------------------+     Kubernetes gRPC
| Backup application   | <---- (auth: SA token) --------+
+----------+-----------+                                |
           v                                            v
+----------------------+          +---------------------+------+
| SnapshotMetadataSvc  |          | external-snapshot-metadata  |
| CR (zfs-localpv)     |          | sidecar (CSI controller Pod) |
+----------------------+          +---------------------+-------+
                                                        | CSI Unix socket
                                                        v
                                        +---------------+---------------+
                                        | ZFS-LocalPV CSI Controller    |
                                        +---------------+---------------+
                                                        | node-agent gRPC
                                                        v
                                        +---------------+---------------+
                                        | ZFS-LocalPV Node Agent        |
                                        | (runs ZFS commands)           |
                                        +---------------+---------------+
                                                        | libzfs / CLI
                                                        v
                                        +---------------+---------------+
                                        | ZFS pool (zvols + snapshots)  |
                                        +-------------------------------+
```

### Workflow

1. Backup application opens a streaming CBT call to the sidecar.
2. Sidecar authenticates and forwards to the ZFS-LocalPV CSI controller.
3. Controller resolves the CSI `snapshot_id`(s) to `ZFSSnapshot`
   custom-resource entries and identifies the owning node.
4. Controller invokes a new node-agent RPC on that node with the ZFS
   snapshot name(s).
5. Node agent runs the appropriate ZFS operation (block-birth traversal
   or incremental send parse), streams `BlockRange` tuples back to the
   controller, which converts them into CSI `BlockMetadata` responses.

## Implementation Details

### Node Agent

Add a new node-agent gRPC service:

```proto
service ZfsSnapshotMetadata {
  rpc GetAllocated(GetAllocatedRequest)
      returns (stream ZfsBlockMetadataResponse);
  rpc GetDelta(GetDeltaRequest)
      returns (stream ZfsBlockMetadataResponse);
}

message GetAllocatedRequest {
  string zfs_snapshot   = 1;   // pool/dataset@snap
  int64  starting_offset= 2;
  int32  max_results    = 3;
}

message GetDeltaRequest {
  string base_zfs_snapshot   = 1;
  string target_zfs_snapshot = 2;
  int64  starting_offset     = 3;
  int32  max_results         = 4;
}

message ZfsBlockMetadataResponse {
  int64 volume_capacity_bytes = 1;
  repeated BlockRange ranges  = 2;
}

message BlockRange {
  int64 byte_offset = 1;
  int64 size_bytes  = 2;
}
```

Implementation notes:

- Reject datasets that are not zvols with `FAILED_PRECONDITION`.
- For `GetAllocated`: walk block pointers filtered by
  `birth_txg <= snapshot_txg`; emit ascending, coalesced ranges.
- For `GetDelta`:
  - Verify `base` and `target` belong to the same dataset (and `base` is
    an ancestor of `target`); reject otherwise with `INVALID_ARGUMENT`.
  - Run `zfs send -i base target` piped into a parser that consumes only
    the `WRITE` record headers (offset and length) and discards the
    payload; emit those as `BlockRange`s.
- Enforce ascending, non-overlapping output; honour `starting_offset`
  and `max_results`.

### CSI Controller

- Advertise `SNAPSHOT_METADATA_SERVICE` when CBT is enabled.
- Implement CSI `GetMetadataAllocated` / `GetMetadataDelta` by:
  1. Looking up the `ZFSSnapshot` CR(s) for the given CSI snapshot IDs.
  2. Verifying the underlying dataset is a zvol; if not,
     `FAILED_PRECONDITION`.
  3. Forwarding to the node agent on the owning node.
  4. Emitting CSI responses with
     `block_metadata_type = VARIABLE_LENGTH` and populated
     `volume_capacity_bytes`.
- Error mapping: not-found → `NOT_FOUND`; different-volume delta →
  `INVALID_ARGUMENT`; offset past `volsize` → `OUT_OF_RANGE`.

### Helm Chart

- Add `zfs-localpv.csi.snapshotMetadata.enabled` (default `false`).
- When enabled:
  - Deploy `external-snapshot-metadata` sidecar in the CSI controller
    Pod.
  - Install the `SnapshotMetadataService` CRD if not already present.
  - Create the `SnapshotMetadataService` CR for the ZFS-LocalPV driver
    with the sidecar's Service and CA bundle.
  - Provision RBAC for backup applications' SAs.

### Rollout

- Off by default while upstream CSI CBT is alpha.
- Volumes provisioned as datasets are unaffected — CBT requests for such
  snapshots return `FAILED_PRECONDITION`.

## Risks and Mitigations

- **`zfs send` overhead**: naively running `zfs send` reads the payload.
  Mitigation: consume only the send-stream record headers (offset,
  length) and discard payload bytes, or use a metadata-only introspection
  path if available.
- **Long `zfs` command output**: mitigated by streaming line-by-line and
  by `max_results`/`starting_offset`.
- **Node-local scope**: the controller must dispatch to the correct
  node. Mitigation: use the existing node-agent routing already used by
  the driver.
- **CLI vs library**: shelling out to `zfs`/`zdb` is easier initially but
  introduces parsing risk. Mitigation: prefer stable, parseable outputs
  (send stream); pin `zfs` versions in the Node Agent image where
  applicable.

## Graduation Criteria

- Alpha: `GetMetadataAllocated` and `GetMetadataDelta` working for
  single-node zvol volumes, gated by the Helm toggle.
- Beta: e2e coverage with at least one backup tool; docs and examples;
  performance validated on large zvols.
- GA: gated on upstream CSI CBT GA.

## Testing

- Unit tests for the send-stream header parser (correctly extracts
  offset/length; ignores payload).
- Integration test: create a zvol-backed volume, write a known pattern,
  snapshot, mutate a known set of blocks, snapshot again, and assert
  `GetMetadataDelta` yields exactly the mutated ranges.
- `GetMetadataAllocated` returns exactly the written ranges of a fresh
  snapshot.
- Negative: dataset-backed ZFS volumes → `FAILED_PRECONDITION`;
  cross-dataset delta → `INVALID_ARGUMENT`; offset past `volsize` →
  `OUT_OF_RANGE`.
- Helm test: with the toggle off, no sidecar, no CR, capability not
  advertised.
