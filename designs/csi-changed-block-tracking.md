---
oep-number: OEP TBD
title: OpenEBS Enhancement Proposal for CSI Changed Block Tracking (CBT)
authors:
  - "@tiagolobocastro"
owners:
  - "@tiagolobocastro"
  - TBD
editor: TBD
creation-date: 2026-07-04
last-updated: 2026-07-04
status: provisional
see-also:
  - designs/replicated-pv/mayastor/changed-block-tracking.md
  - designs/local-pv/zfs/changed-block-tracking.md
  - designs/local-pv/lvm/changed-block-tracking.md
  - designs/local-pv/rawfile/changed-block-tracking.md
---

# OpenEBS Enhancement Proposal for CSI Changed Block Tracking (CBT)

## Table of Contents

- [OpenEBS Enhancement Proposal for CSI Changed Block Tracking (CBT)](#openebs-enhancement-proposal-for-csi-changed-block-tracking-cbt)
  - [Table of Contents](#table-of-contents)
  - [Overview: what is CBT and why it is useful](#overview-what-is-cbt-and-why-it-is-useful)
  - [Motivation](#motivation)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [Key Concepts](#key-concepts)
    - [Architecture](#architecture)
    - [Workflow](#workflow)
  - [Per-engine Feasibility](#per-engine-feasibility)
  - [Implementation Details](#implementation-details)
    - [Common CSI Surface](#common-csi-surface)
    - [Deployment](#deployment)
    - [Rollout](#rollout)
    - [Components to Update](#components-to-update)
  - [Risks and Mitigations](#risks-and-mitigations)
  - [Graduation Criteria](#graduation-criteria)
  - [Testing](#testing)

---

## Overview: what is CBT and why it is useful

Change Block Tracking (CBT) is a capability that lets a storage backend report,
for a given volume:

1. Which blocks of a volume snapshot are actually **allocated** (i.e. hold
   real data), and
2. Which blocks **changed** between two snapshots of the same volume.

With this information, a backup or disaster-recovery tool can transfer only
the data that has actually changed since the previous backup instead of
scanning and copying the whole volume every time.

Concretely, CBT enables:

- **Fast incremental backups**: only changed blocks are read and shipped,
  turning what would be a full-volume copy into a small delta transfer.
- **Shorter backup windows**: backups of large volumes fit into normal
  maintenance windows because the amount of data moved is proportional to
  the change rate, not to the volume size.
- **Lower I/O and network load**: production nodes and the backup network
  are not saturated by repeated full reads of unchanged data.
- **Smaller backup storage footprint**: incremental backups store only
  deltas, avoiding repeated full copies of the same underlying data.
- **Efficient DR and near-CDP workflows**: frequent, cheap incrementals
  make it practical to keep a remote copy closely up to date.

Typical consumers are Kubernetes-native backup and DR platforms such as
Velero, Kasten K10, Trilio, and Kanister-style operators. These tools call
the CSI Snapshot Metadata API, obtain the list of allocated or changed
block ranges, and stream only those ranges from the volume snapshots.

This OEP proposes adopting CBT across the OpenEBS engines that can
technically support it and defines the shared design that all engines will
implement. Per-engine implementation details are captured in separate,
linked OEPs.

## Motivation

Modern Kubernetes deployments increasingly host stateful workloads with
large persistent volumes. As those volumes grow, full-volume backups
become the dominant cost of any data-protection strategy: they consume
long backup windows, saturate networks, and inflate backup storage. The
same problem shows up in DR replication, where full re-syncs are
impractical over the wire.

The Kubernetes CSI ecosystem has standardised a solution: the CSI
`SNAPSHOT_METADATA_SERVICE` (alpha) exposes allocated-block and
changed-block metadata for snapshots, and the `external-snapshot-metadata`
sidecar makes this metadata safely available to backup applications via a
Kubernetes-native, authenticated API.

OpenEBS provides several storage engines. Some of them already have the
underlying primitives needed to report allocated and changed blocks
(Mayastor blobstore, ZFS, LVM thin provisioning, and — conditionally —
reflink-based raw files). Exposing that information through the standard
CSI CBT API lets any CSI-aware backup tool light up incremental backup
support on OpenEBS volumes without engine-specific integrations.

## Goals

- Adopt the CSI `SNAPSHOT_METADATA_SERVICE` API across all OpenEBS engines
  that can technically support it.
- Provide a single, consistent user experience for backup tools: the same
  Kubernetes-visible `SnapshotMetadataService` CR and the same gRPC surface,
  regardless of the underlying OpenEBS engine.
- Keep the feature opt-in per engine while upstream CBT is alpha.
- Define a per-engine feasibility matrix so operators know which engines
  and volume modes support CBT.

## Non-Goals

- Implement CBT for engines whose storage stack is not block-based
  under the hood. In particular, the Hostpath LocalPV provisioner is
  out of scope because it hands out directories on the host filesystem
  and owns no block device from which to derive block-level metadata.
- Define or ship a new backup tool. This OEP integrates with existing
  CSI-aware backup applications; it does not build one.
- Change the existing snapshot lifecycle for any engine. CBT only reads
  metadata about snapshots that were created via the existing snapshot APIs.
- Provide in-flight encryption for the CBT gRPC stream beyond what the
  `external-snapshot-metadata` sidecar already provides.

## Proposal

### Key Concepts

1. **SnapshotMetadata service**: an optional CSI service, advertised via
   the `SNAPSHOT_METADATA_SERVICE` plugin capability, that exposes two
   server-streaming RPCs:
   - `GetMetadataAllocated(snapshot_id)` — streams the byte ranges that
     hold data in the given snapshot.
   - `GetMetadataDelta(base_snapshot_id, target_snapshot_id)` — streams
     the byte ranges that changed between two snapshots of the same volume.
2. **BlockMetadata tuples**: each streamed range is a `(byte_offset,
   size_bytes)` pair. Tuples are strictly ascending, non-overlapping, and
   the sequence style is one of `FIXED_LENGTH` or `VARIABLE_LENGTH`, kept
   constant for the whole stream.
3. **Sidecar + CR**: the `external-snapshot-metadata` sidecar sits in
   front of the CSI plugin and is exposed to cluster clients via a
   `SnapshotMetadataService` CR advertising the driver, its endpoint, and
   its CA bundle.
4. **Streaming and resumability**: requests carry a `starting_offset` so
   an interrupted stream can be resumed without restarting from zero.

### Architecture

```
+----------------------+     ServiceAccount token +
| Backup application   | <----- gRPC (streaming) ------+
+----------+-----------+                               |
           |                                           |
           | reads SnapshotMetadataService CR          |
           v                                           |
+----------------------+                               |
| Kubernetes API       |                               |
+----------+-----------+                               |
           ^                                           |
           |                                           v
+----------+-----------+   Unix socket   +-------------+-----------+
| SnapshotMetadataSvc  |<----------------|  external-snapshot-     |
| CR (per driver)      |                 |  metadata sidecar        |
+----------------------+                 +-------------+-----------+
                                                       |
                                                       | gRPC over
                                                       | Unix socket
                                                       v
                                         +-------------+-----------+
                                         |  OpenEBS CSI plugin      |
                                         |  (per-engine)            |
                                         +-------------+-----------+
                                                       |
                                                       v
                                         +-------------+-----------+
                                         |  Engine backend          |
                                         |  (Mayastor / ZFS / LVM / |
                                         |   Rawfile)               |
                                         +--------------------------+
```

- The CSI plugin implements the `SnapshotMetadata` gRPC service and
  advertises `SNAPSHOT_METADATA_SERVICE` in `GetPluginCapabilities`.
- The `external-snapshot-metadata` sidecar terminates the client-facing
  connection, authenticates the caller via a Kubernetes ServiceAccount
  token, and proxies to the CSI plugin over the CSI Unix socket.
- The `SnapshotMetadataService` CR published by the driver tells backup
  applications where to reach the sidecar and how to trust it (CA bundle).

### Workflow

1. **Install-time**: the OpenEBS Helm chart for a supported engine
   optionally deploys the `external-snapshot-metadata` sidecar alongside
   the CSI controller and creates a `SnapshotMetadataService` CR for the
   driver.
2. **Snapshot creation**: unchanged from today — the user creates a
   `VolumeSnapshot` and the engine's existing snapshot logic runs.
3. **Backup initiation**: the backup application resolves the CSI driver
   for a `VolumeSnapshot`, looks up the corresponding
   `SnapshotMetadataService` CR, and opens a streaming gRPC call:
   - `GetMetadataAllocated` for the first backup of a volume, to learn
     which byte ranges are worth reading.
   - `GetMetadataDelta` for subsequent backups, using the previous
     snapshot as `base_snapshot_id` and the new one as
     `target_snapshot_id`.
4. **Data movement**: the backup application reads only the byte ranges
   returned in the stream, from the snapshot data path already used by
   the engine.
5. **Resumption**: if the stream is interrupted, the backup application
   re-issues the same request with `starting_offset` set to the byte
   position immediately after the last range it received.

## Per-engine Feasibility

| Engine            | Delta source                                                                             | CBT viable                            |
|-------------------|------------------------------------------------------------------------------------------|---------------------------------------|
| Mayastor          | SPDK blobstore cluster allocation and per-snapshot deltas                                | Yes                                   |
| ZFS-LocalPV       | `zfs diff` / incremental `zfs send -i` / block-birth txg comparison                      | Yes (zvol-backed volumes)             |
| LVM-LocalPV       | `thin_ls` / `thin_delta` from `thin-provisioning-tools`                                  | Yes (thin-provisioned volumes)        |
| Rawfile-LocalPV   | `FIEMAP` extent comparison on reflink files (XFS reflink or btrfs); btrfs `send -p` alt. | Yes, conditional (see per-engine OEP) |
| Hostpath-LocalPV  | N/A                                                                                      | No — driver owns no block device     |

Per-engine implementation details live in the linked OEPs:

- Mayastor: [designs/replicated-pv/mayastor/changed-block-tracking.md](replicated-pv/mayastor/changed-block-tracking.md)
- ZFS-LocalPV: [designs/local-pv/zfs/changed-block-tracking.md](local-pv/zfs/changed-block-tracking.md)
- LVM-LocalPV: [designs/local-pv/lvm/changed-block-tracking.md](local-pv/lvm/changed-block-tracking.md)
- Rawfile-LocalPV: [designs/local-pv/rawfile/changed-block-tracking.md](local-pv/rawfile/changed-block-tracking.md)

## Implementation Details

### Common CSI Surface

Every engine that opts into CBT MUST:

- Advertise `SNAPSHOT_METADATA_SERVICE` in `GetPluginCapabilities`.
- Implement the two streaming RPCs of the `SnapshotMetadata` service:
  - `GetMetadataAllocated(GetMetadataAllocatedRequest) → stream GetMetadataAllocatedResponse`
  - `GetMetadataDelta(GetMetadataDeltaRequest) → stream GetMetadataDeltaResponse`
- Populate each response with:
  - `block_metadata_type`: `FIXED_LENGTH` or `VARIABLE_LENGTH`, constant for
    the whole stream.
  - `volume_capacity_bytes`: the capacity of the underlying volume.
  - `block_metadata`: strictly ascending, non-overlapping `(byte_offset,
    size_bytes)` tuples.
- Respect `starting_offset` in the request: the first returned tuple MUST
  overlap or come after `starting_offset` (per CSI spec: the tuple MUST
  NOT end before `starting_offset`).
- Return the specified error codes for the well-defined conditions:
  - `INVALID_ARGUMENT` for missing/invalid arguments.
  - `NOT_FOUND` for unknown `snapshot_id` / `base_snapshot_id` /
    `target_snapshot_id`.
  - `FAILED_PRECONDITION` if the engine cannot serve the request because
    CBT is not enabled in the backend (relevant for engines where CBT is
    an opt-in feature of the underlying storage).
  - `OUT_OF_RANGE` for a `starting_offset` beyond the volume size.

Engines SHOULD prefer `VARIABLE_LENGTH` when the underlying backend
naturally produces variable-sized extents, and `FIXED_LENGTH` when the
backend has a natural fixed block/cluster size.

### Deployment

- Each supported OpenEBS engine ships the `external-snapshot-metadata`
  sidecar in its CSI controller Pod when CBT is enabled.
- The engine's Helm chart:
  - Installs the `SnapshotMetadataService` CRD if not already present.
  - Creates a `SnapshotMetadataService` CR named after the driver, with
    the driver's Kubernetes Service address and CA bundle.
  - Provisions RBAC allowing backup applications' ServiceAccounts to
    obtain audience-scoped tokens for the sidecar's audience.
- CSI Node Plugins are not affected: CBT is a Controller-side capability.

### Rollout

- CBT is **off by default** on every engine while the upstream CSI CBT
  API remains alpha.
- Each engine exposes a Helm values toggle to enable it, e.g.
  `<engine>.csi.snapshotMetadata.enabled=true`.
- When disabled, the engine does not advertise
  `SNAPSHOT_METADATA_SERVICE`, does not deploy the sidecar, and does not
  create the `SnapshotMetadataService` CR — so backup applications
  transparently fall back to full backups.

### Components to Update

- **CSI plugins** for Mayastor, ZFS-LocalPV, LVM-LocalPV, and
  Rawfile-LocalPV: implement the `SnapshotMetadata` service.
- **Engine backends**: expose the block metadata source (see per-engine
  OEPs).
- **Helm charts** for each engine: optional sidecar deployment,
  `SnapshotMetadataService` CR, and RBAC.
- **Docs**: user-facing documentation on enabling CBT and integrating
  with backup tools.

## Risks and Mitigations

- **Upstream API is alpha**: the CSI `SNAPSHOT_METADATA_SERVICE` may
  evolve before GA. Mitigation: keep CBT off by default, gate it behind a
  per-engine toggle, and track the upstream spec revisions.
- **Large streams for very large volumes**: a change-heavy volume can
  produce large metadata streams. Mitigation: rely on the streaming
  contract, honour `max_results`, and support `starting_offset`-based
  resumption.
- **Consistency between snapshot data path and metadata**: metadata must
  describe the exact snapshot bytes the backup tool will read.
  Mitigation: source metadata from the same snapshot objects the engine
  already exposes for reads; never compute against a live volume.
- **Backend prerequisites** (e.g. LVM thin pool, ZFS zvol, reflink-capable
  FS for rawfile): CBT may not be available on all installations of an
  engine. Mitigation: document prerequisites clearly and return
  `FAILED_PRECONDITION` when they are not met.

## Graduation Criteria

- Alpha: implemented behind a per-engine toggle on at least one engine
  (target: Mayastor); Helm chart wiring in place; smoke-tested with a
  reference backup client.
- Beta: implemented on all engines listed as viable in this OEP; e2e
  tested with at least one production backup tool; upstream CSI CBT at
  beta.
- GA: on-by-default consideration only when upstream CSI CBT is GA and
  all supported engines have shipped CBT in at least one release.

## Testing

Common tests, to be specialised per engine:

- `GetMetadataAllocated` on a freshly written volume snapshot returns
  ranges that cover exactly the written regions, with the declared
  `block_metadata_type` respected.
- `GetMetadataDelta` between two snapshots taken around a known write
  pattern returns exactly the byte ranges of the writes.
- Streaming resumption: interrupting the stream and re-issuing the
  request with the correct `starting_offset` yields the remainder without
  duplicates or gaps.
- Error semantics: invalid arguments, missing snapshots, and out-of-range
  offsets return the CSI-specified gRPC codes.
- CBT disabled: with the per-engine toggle off, the driver does not
  advertise `SNAPSHOT_METADATA_SERVICE` and the `SnapshotMetadataService`
  CR is absent.
