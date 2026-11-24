---
oep-number: OEP TBD
title: Rawfile-LocalPV Changed Block Tracking (CBT)
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

# Rawfile-LocalPV Changed Block Tracking (CBT)

## Table of Contents

- [Rawfile-LocalPV Changed Block Tracking (CBT)](#rawfile-localpv-changed-block-tracking-cbt)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
  - [Prerequisites](#prerequisites)
  - [Proposal](#proposal)
    - [Metadata Source: FIEMAP on Reflink Files](#metadata-source-fiemap-on-reflink-files)
    - [Alternative: btrfs `send -p`](#alternative-btrfs-send--p)
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

Implement the CSI `SNAPSHOT_METADATA_SERVICE` for Rawfile-LocalPV
volumes whose backing files live on a reflink-capable filesystem (XFS
with reflink, or btrfs), using `FIEMAP` extent maps to compute allocated
and changed byte ranges. This OEP is **conditional** on Rawfile-LocalPV
gaining reflink-based snapshots of the backing file. See the top-level
OEP:
[designs/csi-changed-block-tracking.md](../../csi-changed-block-tracking.md).

## Motivation

Rawfile-LocalPV backs each volume with a sparse file on a host
filesystem. On reflink-capable filesystems (XFS with reflink, or btrfs),
a snapshot of a rawfile volume can be represented as a `cp --reflink=always`
copy: the snapshot file shares extents with the source until either side
is written to, at which point only the modified extents diverge.

`FIEMAP` (the Linux `FS_IOC_FIEMAP` ioctl) reports the extent map of a
file: for each extent it returns `fe_logical`, `fe_physical`,
`fe_length`, and flags including `FIEMAP_EXTENT_SHARED`. From two such
extent maps we can compute:

- **Allocated ranges** in a snapshot = extents present in the snapshot
  file's map (excluding `FIEMAP_EXTENT_UNWRITTEN`).
- **Changed ranges** between two snapshots of the same volume = logical
  ranges where the physical extent differs (or one side is a hole).

This gives us native, byte-range-level CBT without any additional
metadata store.

## Goals

- Expose FIEMAP-derived allocated and changed extents of rawfile
  snapshots via the CSI `SnapshotMetadata` service, for rawfile volumes
  whose backing files live on reflink-capable filesystems.
- Provide `GetMetadataAllocated` for a single snapshot file and
  `GetMetadataDelta` between two snapshot files of the same volume.

## Non-Goals

- CBT on non-reflink filesystems (e.g. ext4) — FIEMAP alone cannot
  determine "changed since previous snapshot" without a reflink or
  send-stream primitive.
- Introducing a new snapshot format. This OEP assumes Rawfile-LocalPV
  represents snapshots as reflink copies (or btrfs subvolume snapshots)
  of the backing file.
- Support for compressed / encrypted rawfile backends where FIEMAP does
  not faithfully reflect logical byte ranges.

## Prerequisites

CBT for Rawfile-LocalPV depends on both of the following:

1. **Reflink-capable backing filesystem** for the rawfile store: XFS
   mounted with reflink enabled, or btrfs. On btrfs, subvolume snapshots
   are an equivalent and preferred primitive.
2. **Reflink-based snapshot support** in the Rawfile-LocalPV driver
   itself, so that a snapshot is represented as a reflink copy (or a
   btrfs subvolume snapshot) of the backing file. At the time of
   writing, the upstream Rawfile-LocalPV README still lists such
   snapshots as a TODO. This OEP is **provisional** and its
   implementation is gated on that support landing.

When either prerequisite is missing, the driver MUST NOT advertise
`SNAPSHOT_METADATA_SERVICE`, and CBT requests (if any) MUST return
`FAILED_PRECONDITION`.

## Proposal

### Metadata Source: FIEMAP on Reflink Files

For a snapshot represented as a reflink copy of a rawfile:

- Call `FS_IOC_FIEMAP` on the snapshot file to enumerate extents.
- For `GetMetadataAllocated`, emit `(fe_logical, fe_length)` ranges for
  every extent that is not `FIEMAP_EXTENT_UNWRITTEN`, coalescing
  contiguous extents.
- For `GetMetadataDelta`, enumerate extents from both the base and
  target snapshot files and merge:
  - Logical ranges present in `target` but not in `base` → changed
    (allocated in target only).
  - Logical ranges present in both, with **different physical offsets**
    → changed (rewritten; reflink was broken).
  - Logical ranges present in `base` but not in `target` → changed
    (hole-punched in target).
  - Logical ranges present in both with the **same physical offset**
    AND `FIEMAP_EXTENT_SHARED` set on both → unchanged (still shared).
  Emit the union of changed logical ranges, coalesced.

### Alternative: btrfs `send -p`

On btrfs, the driver MAY implement `GetMetadataDelta` using the
metadata-only headers of a `btrfs send -p base target` stream, similar
to the approach used by ZFS. This is optional and left to the
implementation; the FIEMAP-based path above is the default because it
works uniformly on XFS reflink and btrfs.

### Mapping to CSI SnapshotMetadata

- `block_metadata_type`: `VARIABLE_LENGTH`. FIEMAP extents are
  variable-sized.
- `volume_capacity_bytes`: the logical size of the rawfile volume.
- Consecutive changed / allocated extents are coalesced.
- `starting_offset` is honoured by skipping tuples that end at or before
  it.

### Architecture

```
+----------------------+     Kubernetes gRPC
| Backup application   | <---- (auth: SA token) --------+
+----------+-----------+                                |
           v                                            v
+----------------------+          +---------------------+---------+
| SnapshotMetadataSvc  |          | external-snapshot-metadata     |
| CR (rawfile-localpv) |          | sidecar (CSI controller Pod)   |
+----------------------+          +---------------------+----------+
                                                        | CSI Unix socket
                                                        v
                                        +---------------+---------------+
                                        | Rawfile-LocalPV CSI Controller|
                                        +---------------+---------------+
                                                        | node-agent gRPC
                                                        v
                                        +---------------+---------------+
                                        | Rawfile-LocalPV Node Agent    |
                                        | (FS_IOC_FIEMAP,               |
                                        |  optional btrfs send)         |
                                        +---------------+---------------+
                                                        |
                                                        v
                                        +---------------+---------------+
                                        | Reflink filesystem (XFS/btrfs)|
                                        | rawfile snapshots             |
                                        +-------------------------------+
```

### Workflow

1. Backup application opens a streaming CBT call to the sidecar.
2. Sidecar authenticates and forwards to the Rawfile-LocalPV CSI
   Controller.
3. Controller resolves the CSI `snapshot_id`(s) to snapshot file paths
   on the owning node.
4. Controller invokes the node agent with those file paths.
5. Node agent runs `FS_IOC_FIEMAP` on the file(s), merges maps (for
   delta), streams `BlockRange` tuples back to the controller, which
   emits CSI `BlockMetadata` responses.

## Implementation Details

### Node Agent

Add a new node-agent gRPC service:

```proto
service RawfileSnapshotMetadata {
  rpc GetAllocated(GetAllocatedRequest)
      returns (stream RawfileBlockMetadataResponse);
  rpc GetDelta(GetDeltaRequest)
      returns (stream RawfileBlockMetadataResponse);
}

message GetAllocatedRequest {
  string snapshot_file    = 1;
  int64  starting_offset  = 2;
  int32  max_results      = 3;
}

message GetDeltaRequest {
  string base_snapshot_file   = 1;
  string target_snapshot_file = 2;
  int64  starting_offset      = 3;
  int32  max_results          = 4;
}

message RawfileBlockMetadataResponse {
  int64 volume_capacity_bytes = 1;
  repeated BlockRange ranges  = 2;
}

message BlockRange {
  int64 byte_offset = 1;
  int64 size_bytes  = 2;
}
```

Implementation notes:

- Reject requests when the backing filesystem is not reflink-capable
  with `FAILED_PRECONDITION`. Detect via `statfs` magic and,
  additionally, `xfs_info` (XFS reflink flag) where applicable.
- Use `FS_IOC_FIEMAP` in a loop with `FIEMAP_FLAG_SYNC`, paging through
  extents in ascending `fe_logical` order.
- For `GetDelta`, run a two-pointer merge over the two ascending extent
  streams and apply the classification described above.
- Coalesce contiguous output ranges; enforce strictly ascending,
  non-overlapping output; honour `starting_offset` and `max_results`.

### CSI Controller

- Advertise `SNAPSHOT_METADATA_SERVICE` when CBT is enabled **and** the
  driver has reflink-based snapshot support.
- Implement CSI `GetMetadataAllocated` / `GetMetadataDelta` by:
  1. Resolving the CSI `snapshot_id`(s) to node + snapshot file path(s).
  2. Verifying the snapshot files are on a reflink-capable FS; if not,
     `FAILED_PRECONDITION`.
  3. Verifying base and target belong to the same volume (for delta);
     otherwise `INVALID_ARGUMENT`.
  4. Forwarding to the node agent on the owning node.
  5. Emitting CSI responses with
     `block_metadata_type = VARIABLE_LENGTH` and populated
     `volume_capacity_bytes`.
- Error mapping: not-found → `NOT_FOUND`; different-volume delta →
  `INVALID_ARGUMENT`; offset beyond logical size → `OUT_OF_RANGE`.

### Helm Chart

- Add `rawfile-localpv.csi.snapshotMetadata.enabled` (default `false`).
- When enabled:
  - Deploy `external-snapshot-metadata` sidecar in the CSI controller
    Pod.
  - Install the `SnapshotMetadataService` CRD if not already present.
  - Create the `SnapshotMetadataService` CR for the Rawfile-LocalPV
    driver with the sidecar's Service and CA bundle.
  - Provision RBAC for backup applications' SAs.
- The chart SHOULD refuse to enable the feature when the driver version
  in use does not yet support reflink-based snapshots.

### Rollout

- Off by default while upstream CSI CBT is alpha and while the driver's
  reflink-based snapshot support matures.
- Volumes on non-reflink filesystems are transparently excluded via
  `FAILED_PRECONDITION` at request time.

## Risks and Mitigations

- **Non-reflink filesystems**: FIEMAP alone cannot compute "changed
  since previous snapshot" on ext4 or similar. Mitigation: gate on
  detected reflink support; return `FAILED_PRECONDITION` otherwise.
- **Encrypted/compressed extents**: FIEMAP may not reflect logical
  ranges faithfully. Mitigation: reject with `FAILED_PRECONDITION` when
  such flags are seen (e.g. `FIEMAP_EXTENT_ENCODED`,
  `FIEMAP_EXTENT_DATA_ENCRYPTED`).
- **Driver readiness**: reflink-based snapshots are still a TODO in the
  upstream driver. Mitigation: this OEP is provisional; implementation
  is gated on that support landing.
- **Physical-offset stability**: `FIEMAP_EXTENT_SHARED` combined with
  identical `fe_physical` is used to detect unchanged extents; on
  filesystems where the physical layout can shift without a logical
  write, this could over-report changes. Mitigation: default to
  reporting such ranges as changed (safe, over-reports rather than
  under-reports); document the trade-off.

## Graduation Criteria

- Alpha: `GetMetadataAllocated` and `GetMetadataDelta` working for
  rawfile volumes on XFS reflink or btrfs, gated by the Helm toggle and
  by driver capability.
- Beta: e2e coverage with a real backup tool on both XFS reflink and
  btrfs; documented prerequisites.
- GA: gated on upstream CSI CBT GA and on Rawfile-LocalPV reflink-based
  snapshots reaching stable status.

## Testing

- Unit tests for the FIEMAP two-pointer merge classifier (shared,
  same-physical, different-physical, hole-in-base, hole-in-target).
- Integration test on XFS with reflink: create a rawfile volume, write a
  known pattern, snapshot, mutate a known set of byte ranges, snapshot
  again, and assert `GetMetadataDelta` yields exactly the mutated
  ranges.
- Same integration test on btrfs.
- `GetMetadataAllocated` returns exactly the written ranges of a fresh
  snapshot.
- Negative: ext4 backing FS → `FAILED_PRECONDITION`; delta across
  volumes → `INVALID_ARGUMENT`; offset past logical size →
  `OUT_OF_RANGE`.
- Helm test: with the toggle off, no sidecar, no CR, capability not
  advertised.
