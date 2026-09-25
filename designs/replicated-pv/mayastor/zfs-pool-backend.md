---
oep-number: OEP 4278
title: Mayastor ZFS pool backend
authors:
  - "@patrickdk77"
owners:
  - "@patrickdk77"
editor: TBD
creation-date: 30/07/2026
last-updated: 30/07/2026
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
  properties, capacity bounded by `?quota=`) is what makes that coexistence safe.
- The backend is CLI-driven (`zfs(8)` arg-vector exec, no libzfs), so it carries no new
  linked dependency, exactly like zfs-localpv.

### Goals

- A `Zfs` pool backend selectable per DiskPool, gated by `ENABLE_ZFS`.
- Replicas as zvols; pool/replica options (volblocksize, compression, dedup, logbias,
  sync) configurable, with ZFS inheritance from pool to child zvols.
- Native snapshots and clones, including deferred destroy semantics.
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

- Deferred destroy: destroying a snapshot that still has clones sets
  `io.mayastor:discarded=true` and `zfs destroy -d`; it lingers until the last clone goes.
- Replica destroy with snapshots: no snapshots -> destroy; only discarded clone-less
  snapshots -> `destroy -r`; snapshot with clones -> `zfs promote` then re-evaluate; a
  remaining **live** clone-less snapshot -> refuse with `HasLiveSnapshots`. This diverges
  from `Lvs` (where snapshots outlive the replica) because a ZFS snapshot is physically
  bound to its dataset; the control-plane delete-but-keep-snapshots flow must delete
  snapshots first. **This divergence is the main item needing maintainer sign-off.**

### Options

- Pool defaults: query params on the disks string
  (`tank/data?compression=zstd&volblocksize=16k&quota=200GiB`); ZFS inheritance applies
  them to child zvols.
- Per-replica overrides: `map<string,string> properties` on `CreateReplicaRequest`
  (allowlist: volblocksize, compression, dedup, logbias, sync). `Lvs`/`Lvm` reject a
  non-empty map, so a misdirected request fails loudly.

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

- StorageClass: a pool-type selector reaching a `Zfs` DiskPool; optional per-replica zfs
  properties parameter.
- DiskPool CRD: optional `poolType: zfs`; `disks` carries the dataset path.
- Deployment: io-engine image needs `zfs` userland and `/dev/zvol` mounted; DaemonSet sets
  `ENABLE_ZFS=true`.

## Implementation surface (3 repos, coordinated)

1. mayastor-dependencies: `PoolType::Zfs`, `CreateReplicaRequest.properties` (proto).
2. mayastor / io-engine: the `zfs` backend module + backend/gRPC/env registration +
   `bdev_as_replica` URI-based resolution (nexus snapshot path) + BDD tests.
3. mayastor-control-plane: `PoolBackend` as a first-class concept end-to-end (transport,
   store with serde defaults for etcd back-compat, gRPC, REST/OpenAPI, translation
   un-hardcode, DiskPool CRD version, scheduler pool-type filter, CSI param plumbing).

## Graduation Criteria

- Pool/replica/snapshot/clone BDD suites green on zfs-kmod-capable runners.
- Nexus-driven volume snapshot succeeds end to end on ZFS replicas (local and NVMf).
- fstrim on a published volume reclaims zpool space through a sparse zvol replica.
- Pool export/import (including node reboot) preserves replicas, shares, and snapshots.
- Control-plane places replicas only on Zfs pools when the StorageClass requests it.

## Testing

- Rust unit tests (no zfs binary): options/argv building, `-Hp` parse fixtures
  (local/inherited/none sources), property round-trips, dataset-name validation.
- Python BDD mirroring LVM (pool/replica/snapshot), gated to skip when `/sys/module/zfs`
  is absent (needs the zfs kmod on the runner).
- Scheduler: replicas placed only on `Zfs` pools when requested.

## Alternatives

- libzfs linkage: rejected (heavy dependency, matches zfs-localpv's CLI-only choice).
- Reusing the LVM backend path: rejected (no native snapshot/clone).

## Decided positions

1. Replica destroy with a live (non-discarded, clone-less) snapshot is REFUSED with
   `HasLiveSnapshots`. A ZFS snapshot is physically bound to its dataset, so LVS-style
   "snapshots outlive the replica" is not reproduced; the control-plane
   delete-volume-but-keep-snapshots flow must delete snapshots first. (A hidden-trash
   rename remains a documented option if control-plane compatibility later demands
   it, but is not part of this OEP.)
2. Nexus-driven snapshots are part of the initial implementation, not a follow-up.
   The nexus resolves a child replica via `IReplicaFactory::bdev_as_replica(bdev)`
   (both the local path and the remote NVMe admin passthru path); for `Zfs` the
   replica bdev is an aio bdev, so the implementation derives the replica identity
   from the bdev URI (`aio:///dev/zvol/<dataset>?uuid=<uuid>`), which carries both the
   dataset and the uuid. Subsequent operations are async and may query `zfs` as
   needed.
3. Deferred-destroyed snapshots vanish when their last clone goes; the control-plane
   snapshot GC must tolerate NotFound on delete.
4. Shared-zpool capacity floats with zpool free space unless `?quota=` is set; quota
   is the documented recommendation for shared zpools.
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
