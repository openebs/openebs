---
oep-number: OEP TBD
title: Mayastor Changed Block Tracking (CBT)
authors:
  - "@tiagolobocastro"
owners:
  - "@tiagolobocastro"
editor: TBD
creation-date: 2026-07-04
last-updated: 2026-07-04
status: provisional
see-also:
  - designs/csi-changed-block-tracking.md
---

# Mayastor Changed Block Tracking (CBT)

## Table of Contents

- [Mayastor Changed Block Tracking (CBT)](#mayastor-changed-block-tracking-cbt)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [Metadata Source: SPDK Blobstore](#metadata-source-spdk-blobstore)
    - [Mapping to CSI SnapshotMetadata](#mapping-to-csi-snapshotmetadata)
    - [Architecture](#architecture)
    - [Workflow](#workflow)
  - [Implementation Details](#implementation-details)
    - [io-engine (Data Plane)](#io-engine-data-plane)
    - [agent-core (Control Plane)](#agent-core-control-plane)
    - [CSI Controller](#csi-controller)
    - [Helm Chart](#helm-chart)
    - [Rollout](#rollout)
  - [Risks and Mitigations](#risks-and-mitigations)
  - [Graduation Criteria](#graduation-criteria)
  - [Testing](#testing)

---

## Summary

Implement the CSI `SNAPSHOT_METADATA_SERVICE` in the Mayastor CSI
controller, backed by SPDK blobstore cluster-allocation metadata, so that
CSI-aware backup tools can perform incremental backups of Mayastor
volumes. See the top-level OEP:
[designs/csi-changed-block-tracking.md](../../csi-changed-block-tracking.md).

## Motivation

Mayastor volumes are built on the SPDK blobstore, which already tracks
per-cluster allocation state and per-snapshot allocation deltas. This is
exactly the information the CSI CBT API expects to expose. Exposing it
lets backup tools transfer only the changed clusters between snapshots
of a Mayastor volume, turning today's full-volume backup workflow into an
efficient incremental one.

## Goals

- Expose SPDK blobstore allocated and changed cluster information via the
  CSI `SnapshotMetadata` service in the Mayastor CSI controller.
- Serve both `GetMetadataAllocated` and `GetMetadataDelta` for existing
  Mayastor `VolumeSnapshot` objects.
- Provide the plumbing all the way from the CSI controller down to
  `io-engine` (the data plane) via `agent-core`.
- Ship the `external-snapshot-metadata` sidecar and the
  `SnapshotMetadataService` CR from the Mayastor Helm chart, opt-in.

## Non-Goals

- Changes to Mayastor's snapshot creation, restore, or cloning semantics.
  This OEP is read-only with respect to existing snapshot state.
- Cross-pool or cross-node deltas: CBT is defined against two snapshots
  of the same volume.
- Any new on-disk format or persistent state beyond what the blobstore
  already tracks.

## Proposal

### Metadata Source: SPDK Blobstore

The SPDK blobstore allocates data in fixed-size **clusters** (typically
1 MiB). Each blob (which backs a Mayastor volume or snapshot) tracks:

- The set of clusters it has allocated ("allocated cluster map").
- For a snapshot chain, which clusters are owned by which snapshot
  (i.e. which clusters differ from the parent).

From these primitives we can compute:

- **Allocated ranges for a snapshot** — the union of clusters that
  contain data at that snapshot point, expressed as byte ranges.
- **Delta ranges between two snapshots of the same volume** — the
  clusters written between the two snapshot points, expressed as byte
  ranges.

### Mapping to CSI SnapshotMetadata

- `block_metadata_type`: `FIXED_LENGTH`. Mayastor clusters have a fixed
  size, so each `BlockMetadata` tuple has `size_bytes` equal to a whole
  number of cluster sizes.
- `volume_capacity_bytes`: the capacity of the underlying volume.
- Tuples are strictly ascending and non-overlapping; consecutive
  allocated clusters MAY be coalesced into a single tuple to reduce
  stream length.
- `starting_offset` is honoured by seeking to the first cluster whose
  end byte is greater than `starting_offset`.

### Architecture

```
+----------------------+      Kubernetes gRPC
| Backup application   | <---- (auth: SA token) -----+
+----------+-----------+                             |
           v                                         v
+----------------------+          +------------------+-----------+
| SnapshotMetadataSvc  |          | external-snapshot-metadata    |
| CR (mayastor)        |          | sidecar (in CSI controller)   |
+----------------------+          +---------------+---------------+
                                                  | CSI Unix socket
                                                  v
                                  +---------------+---------------+
                                  | Mayastor CSI Controller       |
                                  | (implements SnapshotMetadata) |
                                  +---------------+---------------+
                                                  | control-plane gRPC
                                                  v
                                  +---------------+---------------+
                                  | agent-core                    |
                                  +---------------+---------------+
                                                  | io-engine gRPC
                                                  v
                                  +---------------+---------------+
                                  | io-engine (SPDK blobstore)    |
                                  +-------------------------------+
```

### Workflow

1. Backup application resolves the Mayastor `SnapshotMetadataService` CR
   and opens a streaming gRPC to the sidecar.
2. Sidecar authenticates the caller's SA token and forwards the request
   over the CSI Unix socket to the Mayastor CSI Controller.
3. CSI Controller translates the CSI request into a control-plane call
   to `agent-core` referencing the Mayastor snapshot(s) by UUID.
4. `agent-core` forwards the request to the `io-engine` hosting the
   snapshot(s) via the existing io-engine gRPC channel.
5. `io-engine` walks the blobstore allocated-cluster map (for
   `GetMetadataAllocated`) or the per-snapshot delta (for
   `GetMetadataDelta`), emits byte-range tuples, and streams them back
   up the chain to the backup application.

## Implementation Details

### io-engine (Data Plane)

Add a new gRPC service (or extend an existing snapshot service) with two
server-streaming RPCs:

```proto
service SnapshotMetadata {
  rpc GetSnapshotAllocated(GetSnapshotAllocatedRequest)
      returns (stream SnapshotBlockMetadataResponse);
  rpc GetSnapshotDelta(GetSnapshotDeltaRequest)
      returns (stream SnapshotBlockMetadataResponse);
}

message GetSnapshotAllocatedRequest {
  string snapshot_uuid    = 1;
  int64  starting_offset  = 2;
  int32  max_results      = 3;
}

message GetSnapshotDeltaRequest {
  string base_snapshot_uuid   = 1;
  string target_snapshot_uuid = 2;
  int64  starting_offset      = 3;
  int32  max_results          = 4;
}

message SnapshotBlockMetadataResponse {
  int64 volume_capacity_bytes = 1;
  // block_metadata_type is implicit: FIXED_LENGTH cluster-aligned.
  repeated BlockRange ranges  = 2;
}

message BlockRange {
  int64 byte_offset = 1;
  int64 size_bytes  = 2;
}
```

Implementation notes:

- Use SPDK blobstore APIs to enumerate allocated clusters for a snapshot
  blob and to compute per-snapshot deltas along a snapshot chain.
- Coalesce contiguous clusters into a single `BlockRange` before
  emitting.
- Serve tuples in strictly ascending `byte_offset` order; enforce
  non-overlap.
- Skip ranges that end at or before `starting_offset`.

### agent-core (Control Plane)

- Add a thin pass-through service that resolves the snapshot UUID(s) to
  the owning `io-engine` and forwards the streaming request/response.
- Reject requests whose snapshots belong to different volumes (for
  `GetSnapshotDelta`) with `INVALID_ARGUMENT`.
- Reject requests for unknown snapshot UUIDs with `NOT_FOUND`.

### CSI Controller

- Advertise `SNAPSHOT_METADATA_SERVICE` in `GetPluginCapabilities` when
  CBT is enabled at deploy time.
- Implement the CSI `SnapshotMetadata` service (`GetMetadataAllocated`,
  `GetMetadataDelta`) by:
  1. Mapping the CSI `snapshot_id` to a Mayastor snapshot UUID (existing
     mapping).
  2. Calling the `agent-core` streaming API.
  3. Emitting CSI `BlockMetadata` tuples with
     `block_metadata_type = FIXED_LENGTH` and the populated
     `volume_capacity_bytes`.
- Translate errors: engine `NotFound` → CSI `NOT_FOUND`,
  invalid args → `INVALID_ARGUMENT`,
  offset past volume size → `OUT_OF_RANGE`.

### Helm Chart

- Add `mayastor.csi.snapshotMetadata.enabled` (default `false`).
- When enabled:
  - Deploy the `external-snapshot-metadata` sidecar in the CSI
    controller Pod, wired to the CSI Unix socket.
  - Install the `SnapshotMetadataService` CRD if not already present.
  - Create a `SnapshotMetadataService` CR named after the Mayastor CSI
    driver, referencing the sidecar Service and its CA bundle.
  - Provision the RBAC required for backup applications' SAs to obtain
    audience-scoped tokens for the sidecar.

### Rollout

- Off by default while the upstream CSI CBT API is alpha.
- Enabling and disabling is a Helm-only change; no data migration is
  required.
- Cluster-scoped: enabling CBT covers all Mayastor volumes on the
  deployment.

## Risks and Mitigations

- **Streaming large deltas**: change-heavy volumes can produce large
  streams. Mitigation: use `max_results`; support `starting_offset`
  resumption.
- **Snapshot chain complexity**: deltas across long snapshot chains may
  require walking multiple parents. Mitigation: constrain
  `GetSnapshotDelta` to the standard case where `base` is an ancestor of
  `target`; reject other configurations with `INVALID_ARGUMENT`.
- **Control-plane fan-out**: the streaming request/response crosses
  CSI → agent-core → io-engine. Mitigation: keep the intermediate
  services pure pass-throughs; do not re-buffer entire streams.
- **Upstream alpha churn**: mitigated by keeping the feature opt-in.

## Graduation Criteria

- Alpha: CBT reachable end-to-end from a reference client against a
  single-replica volume, off by default, gated by the Helm toggle.
- Beta: multi-replica volumes covered; e2e tests with a real backup tool;
  documented backup/restore recipe.
- GA: only after upstream CSI CBT reaches GA.

## Testing

- Unit tests in `io-engine` for the blobstore-to-`BlockRange`
  translation, including coalescing, ascending order, and
  `starting_offset` semantics.
- Integration test: create a Mayastor volume, write a known pattern,
  snapshot, mutate a known set of clusters, snapshot again, and assert
  `GetMetadataDelta` returns exactly the mutated cluster ranges.
- Integration test: `GetMetadataAllocated` on a snapshot returns
  precisely the written cluster ranges.
- Negative tests: unknown snapshot UUIDs → `NOT_FOUND`; snapshots of
  different volumes → `INVALID_ARGUMENT`; oversized `starting_offset` →
  `OUT_OF_RANGE`.
- Helm test: with the toggle off, the sidecar and CR are absent and the
  driver does not advertise `SNAPSHOT_METADATA_SERVICE`.
