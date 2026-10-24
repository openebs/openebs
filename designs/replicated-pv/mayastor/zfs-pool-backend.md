---
oep-number: OEP 4278
title: Mayastor ZFS pool backend
authors:
  - "@patrickdk77"
owners:
  - "@patrickdk77"
editor: TBD
creation-date: 30/07/2026
last-updated: 24/10/2026
status: provisional
see-also:
  - OEP 4074
  - OEP 3843
  - OEP 4279
---

# OEP: Mayastor ZFS pool backend

## Table of Contents

- [Summary](#summary)
- [Motivation](#motivation)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
- [Proposal](#proposal)
  - [Layering, compared with the blobstore path](#layering-compared-with-the-blobstore-path)
  - [Object model](#object-model)
  - [Ownership via ZFS user properties](#ownership-via-zfs-user-properties)
  - [Snapshot / clone / destroy semantics](#snapshot--clone--destroy-semantics)
  - [Options](#options)
  - [Encryption](#encryption)
- [User-facing changes](#user-facing-changes)
- [Implementation surface (3 repos, coordinated)](#implementation-surface-3-repos-coordinated)
- [Graduation Criteria](#graduation-criteria)
- [Testing](#testing)
- [Infrastructure Needed](#infrastructure-needed)
- [Alternatives](#alternatives)
- [Decided positions](#decided-positions)
- [Implementation phases](#implementation-phases)
- [Implementation History](#implementation-history)

## Summary

Add a third Mayastor pool backend, `Zfs`, alongside `Lvs` (SPDK blobstore) and `Lvm`
(volume group). A ZFS pool's `disks` entry is a ZFS dataset path; replicas are zvols
exposed to SPDK through an aio bdev; snapshots and clones map to native `zfs snapshot` /
`zfs clone`. This gives Mayastor native, first-class snapshots/clones on a widely deployed
filesystem, modeled on how openebs/zfs-localpv drives ZFS.

## Motivation

- Data integrity guarantees against corruption: ZFS checksums every block end to end,
  self-heals from redundant vdevs on checksum mismatch, and scrubs proactively.
  Neither the blobstore nor LVM detects silent corruption (bit rot, misdirected
  writes, phantom writes) at all; with ZFS backing, each replica independently
  guarantees the integrity of the data it returns, which composes with (rather than
  relies on) Mayastor's replica redundancy.
- The `Lvm` backend cannot do snapshots or clones at all; `Lvs` snapshots are blobstore
  internal. ZFS provides mature, native snapshot/clone/send primitives.
- Operators already running ZFS (via zfs-localpv or otherwise) can use the same storage
  model under Mayastor's replication/nexus layer (prior demand: openebs/openebs#4010,
  "Unable to use zvol in a disk pool").
- A shared ZFS pool can serve more than Mayastor volumes: the same zpool (and the
  same operational model) can host zfs-localpv volumes and filesystem datasets
  backing an S3 object store alongside Mayastor's container dataset. Mayastor
  claiming only its own container dataset (ownership via local `io.mayastor:`
  properties, capacity bounded by the pool's `quota`) is what makes that coexistence safe.
- The backend is CLI-driven (`zfs(8)` arg-vector exec, no libzfs), so it carries no new
  linked dependency, exactly like zfs-localpv.

### Goals

- A `Zfs` pool backend selectable per DiskPool, gated by `ENABLE_ZFS`.
- Replicas as zvols; pool/replica options (volblocksize, compression, dedup, logbias,
  sync) configurable through typed protobuf fields, with ZFS inheritance from pool to
  child zvols.
- Native snapshots and clones with the same destroy semantics as `Lvs`: snapshots
  outlive their replica, and clones outlive their snapshot.
- Ownership/metadata persisted in ZFS user properties (`io.mayastor:` namespace), so no
  external state store is needed.

### Non-Goals

- Changing `Lvs`/`Lvm` behavior.
- Encryption: deferred to its own OEP (see the Encryption section for how it maps).
  The SPDK-crypto pool path does not apply to `Zfs`; ZFS-native encryption satisfies
  the same `PoolArgs.enc_key` surface via the container dataset.
- The trim/unmap mechanism itself: that is backend-general and covered by OEP 4074. This
  backend simply benefits from it (zvols reclaim on trim through the aio bdev once the
  device supports discard).

## Proposal

### Layering, compared with the blobstore path

Both backends share everything from the nexus up; they differ only below the replica
bdev. The trim/unmap work (OEP 4074) sits at the replica-bdev layer in both, which is
why it is backend-general.

```
                      LVS (blobstore)                  ZFS
                      ---------------                  ---
host filesystem       app + csi-node (mkfs, mount)     same
NVMe-oF initiator     csi-node + kernel nvme           same
  ~~~ network ~~~
NVMf target           io-engine subsys/nvmf            same
nexus bdev            io-engine bdev/nexus             same
replica bdev          bdev_lvol (blob as bdev)         bdev_aio over /dev/zvol
thin allocation       SPDK blobstore (4 MiB clusters,  ZFS DMU (COW, volblocksize
                      userspace)                       granularity, kernel)
snapshots/clones      blob clones (userspace)          native zfs (kernel)
encryption            crypto vbdev wraps the pool      ZFS-native on the container
                      base bdev (pool-scoped)          dataset, inherited by zvols
device path           can bypass the kernel entirely   always kernel (block layer
                      (userspace nvme bdev)            + ZFS module)
physical disk         firmware                         firmware (via vdev)
```

Consequences of the split:

- LVS can run kernel-bypass end to end; ZFS always crosses the kernel (aio submission
  plus the ZFS module). This is inherent, not a gap to fix.
- Thin/snapshot intelligence lives in userspace for LVS and in the kernel for ZFS. The
  rebuild allocation-query mechanism (`UNWRITTEN_READ_FAIL`) is blobstore-only, so
  thin-aware rebuild for ZFS needs a different source of allocation truth (see the
  OEP 4074 follow-up).
- A zvol advertises discard (any vdev, sparse or thick zvol alike) but not
  write-zeroes; the aio bdev layer handles the difference (OEP 4074 follow-up covers
  making WRITE_ZEROES reclaim-friendly on such devices).

### Object model

| Concept | ZFS object | Notes |
| --- | --- | --- |
| Pool `P` on `tank/data` | container dataset `tank/data/P` | tagged with local `io.mayastor:pool=<uuid>` |
| Replica `<uuid>` | zvol `tank/data/P/<uuid>` | exposed via `aio:///dev/zvol/...` |
| Snapshot | `tank/data/P/<uuid>@<snap-uuid>` | native `zfs snapshot`, props set atomically |
| Clone | zvol `tank/data/P/<clone-uuid>` | native `zfs clone` from a snapshot |

### Ownership via ZFS user properties

Metadata lives in `io.mayastor:` user properties (analogous to LVM tags / LVS blob
xattrs): `pool`, `disks`, `volblocksize` on the container; `uuid`, `name`, `share`,
`allowed_hosts`, `entity_id`, `snapshot_uuid` on zvols; snapshot metadata on snapshots.

Critical subtlety: ZFS user properties are inherited, so every "is this ours" check
requires the property **source** to be `local`, not merely present.

### Snapshot / clone / destroy semantics

Destroy keeps the `Lvs` semantics. The io-engine handles the ZFS dependency rules itself
and returns success, so the control plane needs no ZFS-specific delete flow.

- Deferred destroy: destroying a snapshot that still has clones sets
  `io.mayastor:discarded=true` and `zfs destroy -d`; it lingers until the last clone goes.
  The request succeeds, so the control plane deletes its snapshot object straight away
  while the ZFS snapshot outlives it.
- Replica destroy with snapshots: no snapshots -> destroy; only discarded clone-less
  snapshots -> `destroy -r`; snapshot with clones -> `zfs promote` then re-evaluate; a
  remaining **live** clone-less snapshot -> the backend rolls the zvol back to its newest
  snapshot to free the blocks written after it, sets `io.mayastor:discarded=true` and
  leaves it out of replica listings, then destroys it with `destroy -r` once its last
  live snapshot is destroyed. A ZFS snapshot is bound to its dataset, so the zvol has to
  stay, but the snapshots outlive the replica as they do for `Lvs`, and the zvol keeps
  only the space those snapshots reference.

### Options

Options are typed protobuf fields in per-backend messages, the same shape as
`LvmPoolArgs` from OEP 4279. `CreatePoolRequest` gains `optional ZfsPoolArgs zfs` and
`CreateReplicaRequest` gains `optional ZfsReplicaArgs zfs`, each at the next free field
number. The disks entry stays a plain dataset path.

```proto
message ZfsPoolArgs {
  // Bytes the container dataset may use (zfs quota). Unset means the pool's capacity
  // floats with the zpool's free space.
  optional uint64 quota = 1;
  // Defaults for every replica zvol in the pool. They are set on the container dataset,
  // so ZFS inheritance passes them down.
  optional ZfsVolumeOptions defaults = 2;
}

message ZfsReplicaArgs {
  // Overrides for this replica's zvol.
  optional ZfsVolumeOptions options = 1;
}

message ZfsVolumeOptions {
  optional uint64 volblocksize = 1;       // bytes, a power of two, create-only
  optional ZfsCompression compression = 2;
  optional uint32 compression_level = 3;  // zstd and gzip levels
  optional bool dedup = 4;
  optional ZfsLogBias logbias = 5;
  optional ZfsSync sync = 6;
}
```

- Each enum starts with an Unknown value at 0. An io-engine that receives a value it
  doesn't know fails the request instead of applying a default.
- The enum members cover the values the backend supports. The exact lists are settled in
  the mayastor-dependencies PR.
- Other backends reject a request that sets `zfs`, the same rule as for `lvm`.

### Encryption

Mayastor's existing at-rest encryption (OEP 3843) is pool-scoped: a crypto vbdev wraps
the diskpool's base bdev, below the blobstore, one key per pool. That mechanism does
not apply to `Zfs` (there is no SPDK base bdev under a zvol); instead the same
`PoolArgs.enc_key` surface is satisfied by ZFS-native encryption, applied to the
container dataset and inherited by every child zvol.

ZFS-native encryption maps naturally onto both scopes, and more cleanly than the
blobstore mechanism:

- Pool-scoped: `PoolArgs.enc_key` sets `encryption`/`keyformat`/`keylocation` on the
  container dataset; every child zvol inherits it. Equivalent semantics to OEP 3843's
  encrypted pools, same user-facing surface.
- Volume-scoped: create an individual zvol with its own encryption root and key,
  overriding (or in the absence of) the container's. The blobstore has no equivalent
  without significant crypto-vbdev-per-lvol work; for ZFS it is a create-time option.

Encryption is phase 3. We defer to the volume encryption OEP as the standard to
follow for the implementation (key sourcing, key lifecycle, and the user-facing
surface), with ZFS-native encryption as the mechanism satisfying it: pool-scoped via
inheritance on the container dataset (parity with OEP 3843's encrypted pools,
including its placement/topology labels) and volume-scoped via per-zvol encryption
roots overriding (or standing alone without) the container's. ZFS-specific details
this backend adds on top of that standard: `zfs load-key` on pool import after
reboot, and the override semantics of a per-volume key against an encrypted
container.

## User-facing changes

- StorageClass: a pool-type selector reaching a `Zfs` DiskPool; optional per-replica ZFS
  options as typed parameters, camelCase like the existing ones, mapping onto
  `ZfsReplicaArgs`.
- DiskPool CRD: optional `poolType: zfs`; `disks` carries the dataset path; an optional
  `zfs` block carries the pool's quota and default options (`ZfsPoolArgs`).
- Deployment: io-engine image needs `zfs` userland and `/dev/zvol` mounted; DaemonSet sets
  `ENABLE_ZFS=true`.

## Implementation surface (3 repos, coordinated)

1. mayastor-dependencies: `PoolType::Zfs`, `ZfsPoolArgs` on `CreatePoolRequest` and
   `ZfsReplicaArgs` on `CreateReplicaRequest` (proto).
2. mayastor / io-engine: the `zfs` backend module + backend/gRPC/env registration +
   `bdev_as_replica` URI-based resolution (nexus snapshot path) + BDD tests.
3. mayastor-control-plane: `PoolBackend` as a first-class concept end-to-end (transport,
   store with serde defaults for etcd back-compat, gRPC, REST/OpenAPI, translation
   un-hardcode, DiskPool CRD version, scheduler pool-type filter, CSI param plumbing).

## Graduation Criteria

- Pool/replica/snapshot/clone BDD suites green in a `Zfs` CI workflow that runs in
  parallel with the `Lvs` and `Lvm` ones.
- Existing suites run for each backend they apply to. Tests that hardcode `Lvs`
  allocation sizes get per-backend values, and a test that fits only one backend is
  marked as such instead of failing on the others.
- Nexus-driven volume snapshot succeeds end to end on ZFS replicas (local and NVMf).
- fstrim on a published volume reclaims zpool space through a sparse zvol replica.
- Pool export/import (including node reboot) preserves replicas, shares, and snapshots.
- Control-plane places replicas only on Zfs pools when the StorageClass requests it.

## Testing

- Rust unit tests (no zfs binary): options/argv building, `-Hp` parse fixtures
  (local/inherited/none sources), property round-trips, dataset-name validation.
- Python BDD mirroring LVM (pool/replica/snapshot/clone). On CI a missing zfs kernel
  module fails the run instead of skipping it, so the `Zfs` suites can't pass by not
  running. A local run without the module skips with a message that says so.
- BDD for the destroy rules: a replica destroyed under a live snapshot disappears from
  the replica listing while the snapshot can still be cloned, and the zvol goes with the
  last snapshot.
- Scheduler: replicas placed only on `Zfs` pools when requested.

## Infrastructure Needed

- CI runners for the `Zfs` workflow with the OpenZFS kernel module loaded and the `zfs`
  userland installed.

## Alternatives

- libzfs linkage: rejected (heavy dependency, matches zfs-localpv's CLI-only choice).
- Reusing the LVM backend path: rejected (no native snapshot/clone).
- A generic `map<string,string>` of ZFS properties passed to `zfs create -o`, as in the
  first draft: dropped after review preferred typed fields. Typed fields let the
  receiver validate a request, and the API shows which options exist. A ZFS property
  outside the typed set needs an API change.
- Pool options as query parameters on the disks string, as in the first draft: dropped,
  as they were in review of the `Lvm` backend (openebs/mayastor#2077), which moved its
  thin pool size into `LvmPoolArgs`. `Zfs` follows the same shape.
- Refusing replica destroy while a live snapshot exists (`HasLiveSnapshots`), as in the
  first draft: dropped, because the control plane would need a ZFS-specific delete flow.

## Decided positions

1. Replica destroy keeps the `Lvs` semantics: snapshots outlive the replica. A zvol with
   a live snapshot is rolled back to its newest snapshot, marked
   `io.mayastor:discarded=true`, left out of listings and destroyed with its last live
   snapshot, so the control-plane delete-volume-but-keep-snapshots flow works unchanged.
   Destroying a snapshot that has clones succeeds and the control plane deletes its
   snapshot object, while ZFS keeps the snapshot until its last clone goes.
2. Nexus-driven snapshots are part of the initial implementation, not a follow-up.
   The nexus resolves a child replica via `IReplicaFactory::bdev_as_replica(bdev)`
   (both the local path and the remote NVMe admin passthru path); for `Zfs` the
   replica bdev is an aio bdev, so the implementation derives the replica identity
   from the bdev URI (`aio:///dev/zvol/<dataset>?uuid=<uuid>`), which carries both the
   dataset and the uuid. Subsequent operations are async and may query `zfs` as
   needed.
3. Deferred-destroyed snapshots vanish when their last clone goes; the control-plane
   snapshot GC must tolerate NotFound on delete. Pool not found and snapshot not found
   stay distinct. The control plane sends the pool uuid with every `DestroySnapshot`,
   and the io-engine resolves the pool first, which turns a missing pool into
   FailedPrecondition for every backend. NotFound means the pool is present and no
   backend has the snapshot. For `Zfs`, a container dataset or zpool that isn't
   imported counts as a missing pool, and a failing `zfs` command returns its own error,
   never NotFound.
4. Shared-zpool capacity floats with zpool free space unless `ZfsPoolArgs.quota` is set;
   quota is the documented recommendation for shared zpools.
5. CLI-driven `zfs(8)` (arg-vector exec, no libzfs linkage) is the supported driver
   mechanism, mirroring zfs-localpv; OpenZFS 2.3 JSON output is a later optimization,
   not a linkage.

## Implementation phases

The phases below are the planned development order of the deliverable (natural
testing points and edge case handling check points) and do not dictate the order
in which pieces are presented for review or merged into the project.

Phase 1 (this OEP's initial deliverable): pool/replica/snapshot/clone lifecycle,
options plumbing, ownership via user properties, nexus-driven snapshots, trim
reclamation on sparse zvols, control-plane/CRD/CSI surface.

Phase 2: pool and replica I/O statistics (shared trait shape with the LVM backend so
both land once).

Phase 3: encryption, both scopes, per the Encryption section (its own OEP).

Delivered by the OEP 4074 follow-up rather than here (this backend consumes them):

- Discard-granularity advertisement (NPDG/NPDA-only; physical_block_size is not an
  acceptable carrier since it also claims NAWUPF write atomicity and shifts io_min)
  plus mkfs alignment to volblocksize in the interim, so sub-volblocksize trims stop
  being silent no-ops.
- Thin WRITE_ZEROES via the discard-reads-zeros hint, so zeroing workloads do not
  allocate on sparse zvols.
- Thin-aware rebuild (hole propagation), so a rebuild does not re-inflate a sparse
  zvol.

## Implementation History

- 30/07/2026: initial draft (provisional). Backend implementation exists in review (io-engine, control-plane, api protos).
- 24/10/2026: review updates. Replica destroy keeps the `Lvs` semantics instead of
  refusing with `HasLiveSnapshots`, options are typed per-backend protobuf fields, and CI
  runs each backend in parallel with zfs required for the `Zfs` workflow.
