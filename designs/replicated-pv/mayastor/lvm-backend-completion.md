---
oep-number: OEP 4279
title: Completing the Mayastor LVM pool backend
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
  - OEP 4278
---

# OEP: Completing the Mayastor LVM pool backend

## Table of Contents

- [Summary](#summary)
- [Motivation](#motivation)
- [Relationship to the ZFS backend OEP](#relationship-to-the-zfs-backend-oep)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
- [Proposal](#proposal)
  - [Layering, compared with the blobstore path](#layering-compared-with-the-blobstore-path)
  - [Phase 1: dm-thin (thin provisioning + snapshots together)](#phase-1-dm-thin-thin-provisioning--snapshots-together)
  - [Phase 2: stats, grow, properties](#phase-2-stats-grow-properties)
  - [Phase 3: encryption](#phase-3-encryption)
- [Decided positions](#decided-positions)
- [Graduation Criteria](#graduation-criteria)
- [Testing](#testing)
- [Open items to settle during review](#open-items-to-settle-during-review)
- [Implementation History](#implementation-history)

## Summary

The `Lvm` pool backend today is thick-only and snapshotless: `ReplicaArgs.thin` is
rejected (`Error::ThinProv`), every LV is created with `-L<size>`, and
create/destroy-snapshot and create-clone return `SnapshotNotSup`. Pool/replica I/O
stats, pool grow, replica properties, encryption, and `bdev_as_replica` are also
unimplemented. This OEP proposes bringing LVM to functional parity in three phases,
built on dm-thin.

## Motivation

- Thick-only means no over-provisioning and no space reclamation: the trim passthrough
  (OEP 4074) delivers only the pass-down TRIM to the physical device for LVM today,
  because a fully-mapped LV has nothing to reclaim. dm-thin turns that same plumbing
  into real space reclamation (measured: a thin LV exposes discard at the thin-pool
  chunk size, e.g. 64 KiB, regardless of pool `discards` passdown mode).
- No snapshots means CSI VolumeSnapshot cannot be used on LVM-backed volumes at all,
  which rules LVM out as a general-purpose backend.

## Relationship to the ZFS backend OEP

The two OEPs share a common plumbing layer that either can carry: the per-replica
`CreateReplicaRequest.properties` map, and the control-plane work that makes pool
backend type first-class end to end (transport/store `PoolBackend`, translation
un-hardcode, DiskPool CRD `poolType`, scheduler pool-type filter, CSI parameters),
all of which covers `Lvm` and `Zfs` identically.

In the current development order this OEP is a follow-up to the ZFS backend OEP (4278) and
consumes that plumbing from it. The order can be inverted: land the shared plumbing
with this OEP instead, so the ZFS merge stays compact (the zfs module and its
`PoolType::Zfs` additions only, without the additional-layer plumbing). Which OEP
carries the shared layer is a review-time decision; the content is identical either
way.

### Goals

The phases are the planned development order of the deliverable (natural testing
points and edge case handling check points) and do not dictate the order in which
pieces are presented for review or merged into the project.

- Phase 1: thin provisioning and snapshots/clones via dm-thin.
- Phase 2: pool/replica I/O statistics, pool grow, replica properties.
- Phase 3: encryption.
- Honest capability reporting throughout (a thick LV on a non-discard PV must not
  advertise unmap; see the OEP 4074 follow-up for the nexus-side handling).

### Non-Goals

- Changing the LVS or ZFS backends.
- Thin-aware rebuild (the allocation-query mechanism); that is the OEP 4074
  follow-up's Part 1 work and applies to all aio-backed backends equally.
- RAID/dm-integrity layering under the VG (orthogonal to this OEP).

## Proposal

### Layering, compared with the blobstore path

Both backends share everything from the nexus up; they differ only below the replica
bdev. The trim/unmap work (OEP 4074) sits at the replica-bdev layer in both, which
is why it is backend-general.

```
                      LVS (blobstore)                  LVM
                      ---------------                  ---
host filesystem       app + csi-node (mkfs, mount)     same
NVMe-oF initiator     csi-node + kernel nvme           same
  ~~~ network ~~~
NVMf target           io-engine subsys/nvmf            same
nexus bdev            io-engine bdev/nexus             same
replica bdev          bdev_lvol (blob as bdev)         bdev_aio over /dev/<vg>/<lv>
thin allocation       SPDK blobstore (4 MiB clusters,  dm-thin (chunk granularity,
                      userspace)                       kernel; today: none, thick)
snapshots/clones      blob clones (userspace)          dm-thin snapshots (kernel;
                                                       today: none)
encryption            crypto vbdev wraps the pool      dm-crypt: under the PV
                      base bdev (pool-scoped)          (pool-scoped) or per LV
                                                       (volume-scoped)
device path           can bypass the kernel entirely   always kernel (block layer
                      (userspace nvme bdev)            + device-mapper)
physical disk         firmware                         firmware (via PV)
```

Consequences of the split:

- LVS can run kernel-bypass end to end; LVM always crosses the kernel (aio submission
  plus device-mapper). This is inherent, not a gap to fix.
- Thin/snapshot intelligence lives in userspace for LVS and in the kernel (dm-thin)
  for LVM. The rebuild allocation-query mechanism (`UNWRITTEN_READ_FAIL`) is
  blobstore-only, so thin-aware rebuild for LVM needs a different source of
  allocation truth (the OEP 4074 follow-up).
- A thin LV advertises discard at the thin-pool chunk size and reads back zeros for
  unprovisioned chunks; a thick LV is a pass-through whose capabilities are whatever
  the PV device offers. This is the honest-capability-reporting requirement in the
  Goals.

### Phase 1: dm-thin (thin provisioning + snapshots together)

dm-thin provides both missing features with one mechanism, which is why they are one
phase:

- Pool: a thin pool LV inside the VG (`lvcreate --thinpool`), sized by policy (option
  on the pool disks string, mirroring the ZFS backend's query-param idiom). The
  existing thick path remains for pools/replicas that request it; `thin` stops being
  rejected and selects the thin pool.
- Replica: `lvcreate -V <size> --thin` for thin; existing `-L` path for thick.
  `is_thin()` reports from the LV attributes instead of the current hardcoded false.
- Snapshot: `lvcreate -s` of a thin LV (thin snapshots are cheap COW within the
  pool, unlike old-style thick LVM snapshots which require a fixed COW area and
  degrade). Snapshot metadata persisted as LVM tags in the existing
  `io.mayastor`-equivalent tag namespace (the backend already stores share protocol,
  allowed hosts, entity_id as tags).
- Clone: a writable `lvcreate -s` of the snapshot (thin snapshots are writable;
  activation controlled with `-kn`/`-ay` as needed).
- Destroy ordering mirrors the ZFS backend's decided semantics: replica destroy with
  a live snapshot is refused; snapshot-with-dependents uses deferred deletion at the
  control-plane level (dm-thin has no native deferred destroy, so the backend refuses
  instead, consistent with the stricter of the two backends).
- Capability note: thin LVs expose discard at the chunk size irrespective of the
  pool's `discards` passdown mode, and read back zeros for unprovisioned/discarded
  chunks, so the discard-reads-zeros optimization in the OEP 4074 follow-up applies
  to thin LVM by construction.

### Phase 2: stats, grow, properties

- Stats: replica I/O stats come from the SPDK bdev layer (the aio bdev already
  counts); pool-level stats aggregate replica bdevs plus `vgs`/`lvs` capacity fields
  already parsed by the CLI layer. This mirrors whatever shape the ZFS backend adopts
  for the same gap so the two land once in the shared traits.
- Grow: `pvresize` + `vgextend`-driven pool expansion, surfaced through the existing
  grow API that currently returns `GrowNotSup`.
- Properties: consume the `CreateReplicaRequest.properties` map (introduced by the
  ZFS backend work) with an LVM allowlist (e.g. thin chunk size, zeroing mode)
  instead of rejecting a non-empty map.

### Phase 3: encryption

We defer to the volume encryption OEP as the standard to follow for the
implementation (key sourcing, key lifecycle, and the user-facing surface), with
dm-crypt as the mechanism satisfying it for LVM:

- Pool-scoped (parity with OEP 3843): dm-crypt under the PV (or LUKS on the PV
  device), managed at pool create/import; the SPDK crypto-vbdev path used for LVS
  does not apply because the pool is not an SPDK bdev.
- Volume-scoped: dm-crypt per LV. LVM has no native per-LV encryption (unlike ZFS
  encryption roots), so the backend owns the crypt mapping lifecycle around the LV,
  with the replica bdev URI pointing at the crypt mapping instead of the LV.

The existing `dm_setup.rs` machinery (dmsetup table load/suspend/resume, with key
suppression handling for crypt targets already accounted for) is the foundation for
both shapes.

## Decided positions

1. Scope is full parity, phased as above; phase 1 (dm-thin) is the priority and is a
   prerequisite for LVM benefiting from thin-side trim reclamation.
2. Thick LVs remain supported and are the compatibility default for existing pools;
   thin is selected per replica via the existing `thin` flag once phase 1 lands.
3. Mixed-capability handling (a thick LV on a PV without discard alongside capable
   replicas) is NOT solved in this OEP; it is the nexus-side per-child
   unmap-to-write-zeroes conversion in the OEP 4074 follow-up. This OEP only requires
   the backend to report capabilities honestly.

## Graduation Criteria

- Thin replica lifecycle plus snapshot/clone BDD suites green on loop-device VGs.
- fstrim on a thin-LV-backed volume reclaims thin-pool space end to end.
- Capability matrix honest: thick LV on a discardless PV does not advertise unmap; thin LVs advertise at chunk-size granularity.
- Pool/replica I/O statistics and pool grow surfaced through the existing APIs.

## Testing

- BDD suites mirroring the existing LVM pool/replica suites, extended with thin
  pool/replica/snapshot/clone flows on loop-device VGs.
- Trim: fstrim on a thin LVM replica reclaims thin-pool space (extends the OEP 4074
  e2e test to LVM thin).
- Capability matrix tests: thick-on-discardless-PV must not advertise unmap; thin
  must advertise at chunk-size granularity.

## Open items to settle during review

1. Thin-pool sizing/growth policy (fixed at create vs auto-extend via
   `thin_pool_autoextend`), and metadata LV sizing.
2. Snapshot deferred-delete semantics at the control-plane when dependents exist
   (backend refuses; does the control-plane retry-queue or surface the error?).
3. Phase 3 timing relative to the volume encryption OEP (this OEP implements to that
   standard once it is ratified).

## Implementation History

- 30/07/2026: initial draft (provisional). Phase ordering follows the ZFS backend OEP (4278) shared-plumbing decision.
