---
oep-number: OEP 4074
title: Mayastor trim/unmap support
authors:
  - "@tiagolobocastro"
owners:
  - "@tiagolobocastro"
editor: TBD
creation-date: 09/06/2026
last-updated: 09/06/2026
status: provisional
---

# OEP: Mayastor trim/unmap support

## Table of Contents

- [Summary](#summary)
- [Motivation](#motivation)
  - [Gap 1: Rebuild Does Not Propagate Unmaps](#gap-1-rebuild-does-not-propagate-unmaps)
  - [Gap 2: Synchronous UNMAP Blocks the Reactor](#gap-2-synchronous-unmap-blocks-the-reactor)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
- [Proposal](#proposal)
  - [User Stories](#user-stories)
    - [Story 1: Space reclamation after rebuild](#story-1-space-reclamation-after-rebuild)
    - [Story 2: Flash device efficiency](#story-2-flash-device-efficiency)
    - [Story 3: No reactor stalls during fstrim](#story-3-no-reactor-stalls-during-fstrim)
  - [Part 1: Cluster Release During Rebuild](#part-1-cluster-release-during-rebuild)
    - [Constraints](#constraints)
    - [Rebuild Initialization](#rebuild-initialization)
    - [Full Rebuild](#full-rebuild)
    - [Partial Rebuild](#partial-rebuild)
    - [Optional Optimization: IO-log Operation Provenance](#optional-optimization-io-log-operation-provenance)
    - [Replica Geometry Discovery (Control-Plane vs Data-Plane)](#replica-geometry-discovery-control-plane-vs-data-plane)
    - [Component Change Summary](#component-change-summary)
  - [Part 2: Async UNMAP Passthrough to Backend Devices](#part-2-async-unmap-passthrough-to-backend-devices)
    - [Why TRIM Matters for Flash Devices](#why-trim-matters-for-flash-devices)
    - [Current State](#current-state)
    - [Async UNMAP for uring bdev](#async-unmap-for-uring-bdev)
    - [Async UNMAP for aio bdev](#async-unmap-for-aio-bdev)
    - [Blobstore Integration](#blobstore-integration)
    - [Component Change Summary](#component-change-summary-1)
  - [Interaction Between Parts](#interaction-between-parts)
  - [Risks and Mitigations](#risks-and-mitigations)
- [Graduation Criteria](#graduation-criteria)
- [Test Plan](#test-plan)
  - [Part 1: Rebuild UNMAP Tests](#part-1-rebuild-unmap-tests)
  - [Part 2: Backend UNMAP Tests](#part-2-backend-unmap-tests)
- [Implementation History](#implementation-history)
- [Alternatives](#alternatives)
  - [Alternative 1: Modify SPDK Blobstore to Support Sub-Cluster UNMAPs for ZEROES](#alternative-1-modify-spdk-blobstore-to-support-sub-cluster-unmaps-for-zeroes)
- [References](#references)

---

## Summary

This OEP proposes two complementary features to bring full UNMAP/DEALLOC support
to Mayastor:

1. **Cluster release during rebuild**: Correctly propagating unmapped (deallocated)
   clusters from source to destination replica during both full and partial nexus
   rebuilds, so that thin-provisioned space is actually reclaimed on rebuilt
   replicas.

2. **Async UNMAP passthrough to backend devices**: Forwarding UNMAP/TRIM commands
   asynchronously to underlying aio/uring bdevs, enabling flash devices to reclaim
   blocks and maintain write performance without blocking the SPDK reactor thread.

Also of note, there's currently a bug where unmapped clusters would not be correctly
reported, see fix [here](https://github.com/openebs/mayastor/pull/1994).

---

## Motivation

Mayastor already supports UNMAP/DEALLOC commands at the nexus level (controlled
by the `--bs-cluster-unmap` CLI flag). When a filesystem such as XFS issues
`fstrim` or punches holes, the corresponding blobstore clusters are freed on
each replica. This allows thin-provisioned storage pools to reclaim space as
users delete files.

However, two significant gaps remain:

### Gap 1: Rebuild Does Not Propagate Unmaps

When a replica is rebuilt (either after a brief outage triggering a partial
rebuild, or when a new replica is added triggering a full rebuild), unmapped
clusters on the source are **not correctly propagated** to the destination.

The root cause is a granularity mismatch: the SPDK blobstore only deallocates
a cluster when it receives an UNMAP that is **exactly cluster-sized and
cluster-aligned**, as enforced in `blobstore.c`:

```c
if (spdk_blob_is_thin_provisioned(blob) && is_allocated &&
    bs_io_units_per_cluster(blob) == length && g_cluster_unmap_enabled) {
```

The rebuild operates in fixed `SEGMENT_SIZE` (64 KiB) chunks. Even when a source
read returns "unallocated", the resulting 64 KiB UNMAP sent to the destination
does not satisfy the above condition (cluster size is typically 1MiB+), so the
destination cluster remains allocated with zeroed data. The result is that
rebuilt replicas consume more space than the source, defeating the purpose of
thin provisioning.

### Gap 2: Synchronous UNMAP Blocks the Reactor

The SPDK aio and uring bdev modules handle UNMAP by calling `fallocate()` with
`FALLOC_FL_PUNCH_HOLE` (for files) or `ioctl(BLKDISCARD)` (for block devices)
**synchronously and inline** on the SPDK reactor thread. These syscalls can
block for tens to hundreds of milliseconds, stalling all other I/O on that
reactor core. This can cause:

- I/O timeout escalation
- Nexus health check failures
- Cascading performance degradation under `fstrim` workloads

A previous PR ([openebs/spdk#11](https://github.com/openebs/spdk/pull/11))
implemented async UNMAP for the aio bdev but was later reverted. This OEP
proposes reviving that work and bringing it upstream directly.

### Goals

- Rebuilt replicas must have the **same cluster allocation state** as the source,
  including properly freed (unmapped) clusters.
- UNMAP commands to aio/uring bdevs must be handled **asynchronously** without
  blocking the SPDK reactor thread.
- Flash/NVMe devices must receive TRIM notifications, enabling FTL garbage
  collection, reduced write amplification, and sustained write performance.
- Thin-provisioned storage pools must reclaim space end-to-end: from filesystem
  delete → nexus UNMAP → blobstore cluster free → backend device TRIM.

### Non-Goals

- Changing UNMAP semantics for non-thin-provisioned replicas.
- Supporting UNMAP on LVM or other non-blobstore backends (out of scope for this OEP).
- Rate-limiting or QoS for TRIM workloads (future work).

---

## Proposal

### User Stories

#### Story 1: Space reclamation after rebuild

> As a Mayastor user with a thin-provisioned volume, when I delete files and
> run `fstrim`, and then a replica rebuild occurs, I expect the rebuilt replica
> to consume the same amount of pool space as the source replica — not inflate
> to the full provisioned size.

#### Story 2: Flash device efficiency

> As a Mayastor operator using NVMe or SSD-backed storage pools, I expect that
> UNMAP commands from the filesystem reach the physical device as TRIM
> operations, so the device's FTL can reclaim blocks, reduce write amplification,
> and maintain consistent write latency over time.

#### Story 3: No reactor stalls during fstrim

> As a Mayastor operator, when a user runs `fstrim` on a mounted volume, I
> expect I/O latency on other non-related volumes to remain unaffected. UNMAP processing must not block the SPDK reactor thread.

---

### Part 1: Cluster Release During Rebuild

#### Constraints

The following constraints govern the design:

1. **Cluster sizes may differ** between source and destination replicas.
   Although the current control-plane enforces matching cluster sizes, the rebuild
   design must not rely on that assumption so future relaxations remain safe.
2. **Nexus replica offset may not be cluster-aligned** — the data partition
   start may fall in the middle of a blobstore cluster.
3. **Replicas may be remote** — cluster size and alignment cannot always be
   read locally. They must be obtained via the geometry provider abstraction
   (see [Replica Geometry Discovery](#replica-geometry-discovery-control-plane-vs-data-plane)),
   which may be backed by control-plane metadata, gRPC, or data-plane vendor
   extension commands.
4. **I/O spanning a cluster must be nexus-locked** to prevent overlapping
   user I/O during rebuild.

#### Rebuild Initialization

At rebuild start, collect replica geometry for both source and destination:

- `cluster_size`
- `data_offset` (logical data partition start relative to lvol base)

> Note: retrieval path is implementation-dependent (control-plane vs data-plane),
> and must be abstracted behind a single geometry provider interface.

Compute:

```rust
effective_lock_span = max(src_cluster_size, dst_cluster_size)
```

Runtime segment policy:

- Add `max_rebuild_io_size` (configurable upper bound for a single rebuild I/O,
  suggested default: 4 MiB; must be >= largest expected cluster size to actually
  enable the fast path on common deployments).
- **Preferred mode (cluster-I/O mode)**: use a **single I/O** sized to the rebuild
  lock span when all are true:
  1. lock span is cluster-aligned for the evaluated source/destination mapping,
  2. `effective_lock_span <= max_rebuild_io_size`,
  3. mode is enabled by policy.
- **Fallback mode (sub-I/O mode)**: use `SEGMENT_SIZE = 64 KiB` sub-reads inside the lock span.

In cluster-I/O mode, one source read outcome is sufficient for range classification
(no per-64 KiB multi-read loop is needed for that locked span).

The first and last rebuild ranges may be partial clusters if `data_offset`
is not cluster-aligned. These edge ranges are handled with copy / write-zeroes
logic; partially covered destination clusters are **never** deallocated via
cluster UNMAP, regardless of source classification.

#### Full Rebuild

For each rebuild range (lock span = `effective_lock_span`):

1. **Lock** the full range via nexus range lock.
2. **Read source** using selected mode:
   - **cluster-I/O mode**: one cluster-sized read for the locked span;
   - **sub-I/O mode**: 64KB (or configured) sub-reads, tracking allocation per sub-read.
3. **Classify** results:
   - cluster-I/O mode: `ALL_UNALLOCATED` or `ALL_ALLOCATED` from the single read result.
   - sub-I/O mode: `ALL_UNALLOCATED`, `ALL_ALLOCATED`, or `MIXED`.
4. **Apply action**:

   | Classification | Action |
   | - | - |
   | `ALL_UNALLOCATED` | Issue destination-cluster-aligned UNMAPs for each destination cluster **fully covered** by the locked range; for any partially covered destination cluster at the edges, fall back to write-zeroes for the covered sub-range |
   | `ALL_ALLOCATED` | Copy data writes normally |
   | `MIXED` | Copy allocated sub-ranges; write-zeroes for unallocated sub-ranges; do not free partially covered destination clusters |

5. **Unlock** the range.

**Important**: when cluster sizes differ, UNMAP eligibility is evaluated against
**destination cluster boundaries**. Only fully covered destination clusters that
map to unallocated source data are deallocated.

#### Partial Rebuild

`IOLog` and `RebuildMap` remain 64KB-granular.

A dirty 64KB entry means **the range must be reconciled**, not necessarily copied.
The final action for that entry may be:

- data copy,
- write-zeroes, or
- destination-cluster UNMAP.

When `PartialSeqCopier` processes a dirty 64KB segment:

1. Perform the normal 64KB source read.
2. If the read is **allocated**, copy that 64KB range normally and mark the entry synced.
3. If the read is **unallocated**, treat this as a **cluster-reconciliation trigger**:
   1. Determine the impacted source/destination cluster window(s) from geometry mapping.
   2. Escalate lock to the required cluster window(s).
   3. Re-read the escalated window using selected mode:
      - **cluster-I/O mode**: single cluster-sized read when window is eligible and within `max_rebuild_io_size`;
      - **sub-I/O mode**: re-read all sub-segments inside the escalated window.
   4. Classify the whole window as `ALL_UNALLOCATED`, `ALL_ALLOCATED`, or `MIXED`.
   5. Apply the same action table as full rebuild:
      - `ALL_UNALLOCATED` → issue destination-cluster-aligned UNMAP for fully covered destination clusters;
      - `ALL_ALLOCATED` → copy normally;
      - `MIXED` → copy allocated sub-ranges and write-zeroes for unallocated sub-ranges.
   6. Mark **all** covered 64KB entries in that reconciled window as synced.
   7. Release lock(s).

Implementation note:

- Multiple dirty 64KB entries may map to the same cluster window. These should be
  coalesced so the window is reconciled once, avoiding repeated lock escalation and duplicate UNMAP decisions.
- A dirty bit must never be cleared solely because the first 64KB read returned unallocated; it is only cleared after the enclosing cluster window has been reconciled.

#### Optional Optimization: IO-log Operation Provenance

It may be beneficial to extend the `IOLog` so a dirty 64 KiB entry records whether
it was dirtied by a **write** or by an **UNMAP**, instead of tracking only a
single dirty bit.

This can be represented as either:

- two bitplanes (`DIRTY_WRITE`, `DIRTY_UNMAP`), or
- an equivalent compact state (`WRITE`, `UNMAP`).

Semantics and transitions:

- `WRITE`: at least one write hit this 64 KiB range since divergence.
- `UNMAP`: one or more UNMAPs hit this 64 KiB range and **no later write** observed.
- A subsequent write to an `UNMAP` entry collapses the state to `WRITE` (write
  always wins over UNMAP for partial-rebuild correctness).
- A subsequent UNMAP to a `WRITE` entry leaves it as `WRITE` until the rebuild
  reconciles the enclosing cluster window, since the entry must still be treated
  as potentially containing data that requires copy/zero handling.

Partial rebuild can then use this as a **hint**:

- `UNMAP` entry/window:
  - skip the initial 64 KiB probe read;
  - immediately escalate to the relevant cluster window;
  - reconcile at cluster granularity and issue destination UNMAP if the reconciled
    source window is still fully unallocated.
- `WRITE` entry/window:
  - use the normal partial rebuild flow.

Important correctness rule:

- IO-log provenance is only a scheduling/optimisation hint.
- Final UNMAP eligibility must still be decided under the cluster-window lock,
  after reconciliation of the full relevant window.

#### Replica Geometry Discovery (Control-Plane vs Data-Plane)

Rebuild requires two geometry values: `cluster_size` and `data_offset`.

- `cluster_size` is already part of replica usage metadata.
- `data_offset` is **geometry/alignment metadata**, not space-usage metadata.

Therefore:

- Do **not** overload `ReplicaSpaceUsage` with `data_offset`.
- Introduce/consume a separate geometry source (`ReplicaGeometry` concept), whose
  transport can be:
  1. control-plane propagated metadata, or
  2. data-plane query (including vendor extension commands), or
  3. a dedicated gRPC call if retained.

Implementation should depend on a geometry provider abstraction, not on a specific API transport.

#### Component Change Summary

| Component | Change |
| --------- | ------ |
| `RebuildDescriptor` | Store `src_cluster_size`, `dst_cluster_size`, `src_data_offset`, `dst_data_offset` at init |
| `NexusRebuildDescriptor` | Resolve geometry via provider abstraction (control-plane/data-plane/gRPC) |
| `FullRebuild` / `FullSeqCopier` | Cluster-span locking + dual-mode read path (single cluster-I/O fast path, 64KB fallback) + action matrix |
| `copy_segment` / `copy_one` | Fast-path classification from single cluster read when eligible; otherwise per-sub-read classification and destination-cluster UNMAP eligibility logic |
| `PartialSeqCopier` | Dirty 64KB entries become reconcile markers; optionally use IO-log write-vs-UNMAP provenance to fast-path pure UNMAP windows before cluster reconciliation |
| `nexus_io_log.rs` | Optional: extend dirty tracking to record write vs UNMAP provenance (`WRITE` / `UNMAP`), at increased metadata cost |
| Rebuild config | Add runtime policy for cluster-I/O mode and `max_rebuild_io_size` cap |

---

### Part 2: Async UNMAP Passthrough to Backend Devices

#### Why TRIM Matters for Flash Devices

Without TRIM/UNMAP reaching the physical device:

- **Write amplification increases**: NAND flash cannot overwrite in-place. The
  FTL's garbage collector must read-modify-write blocks containing logically
  deleted data, multiplying the actual writes to the medium.
- **Sustained write performance degrades**: The pre-erased block pool shrinks
  as the FTL cannot distinguish live from stale data. GC pressure increases,
  causing elevated write latency and throughput fluctuations.
- **Device lifespan shortens**: Unnecessary erase cycles consume P/E endurance.
- **Thin-provisioned backends waste space**: Enterprise SANs and cloud block
  storage cannot reclaim space without UNMAP reaching the backend.

#### Current State

The SPDK uring bdev handles UNMAP by calling `fallocate(FALLOC_FL_PUNCH_HOLE)`
or `ioctl(BLKDISCARD)` **synchronously on the reactor thread**. These calls
can block for extended periods under GC pressure, stalling all I/O on that
reactor core.

A previous PR ([openebs/spdk#11](https://github.com/openebs/spdk/pull/11))
implemented async UNMAP via `aio/io_uring` but was reverted. This OEP proposes
reviving and stabilising that work.

#### Async UNMAP for uring bdev

Leverage `io_uring`'s native async `fallocate` support
(`IORING_OP_FALLOCATE`, available since Linux 5.6):

1. When the uring bdev receives an UNMAP I/O, submit an
   `IORING_OP_FALLOCATE` SQE with
   `FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE` to the existing `io_uring`
   ring, instead of calling `fallocate()` synchronously.
2. Completion is reaped by the existing `bdev_uring_reap` poller alongside
   read/write completions — no additional threads or pollers required.
3. For raw block devices: use `IORING_OP_URING_CMD` with NVMe DSM passthrough
   (Linux 5.19+), or fall back to a threadpool-based async `ioctl(BLKDISCARD)`
   on kernels that do not support the uring command interface.

#### Async UNMAP for aio bdev

The Linux `libaio` interface does not natively support `fallocate`. Options:

1. **Threadpool offload**: Submit `fallocate()` / `ioctl(BLKDISCARD)` to an
   SPDK thread pool, signalling completion back to the reactor via eventfd.
2. **Migration recommendation**: For deployments on Linux 5.15+, prefer the
   uring bdev over the aio bdev. Document this as the supported async UNMAP
   path.

#### Blobstore Integration

When the blobstore frees a cluster due to UNMAP on a thin-provisioned lvol,
it optionally issues an UNMAP to the base bdev for that cluster range (via
`BS_CLEAR_WITH_UNMAP` / `LVS_CLEAR_WITH_UNMAP` in `lvol.h`). The async
backend ensures this does not block the reactor.

#### Component Change Summary

| Component | Change |
| --------- | ------ |
| `bdev_uring.c` | Replace synchronous `fallocate()` with `IORING_OP_FALLOCATE` SQE |
| `bdev_aio.c` | Offload `fallocate()` / `BLKDISCARD` to threadpool |
| SPDK blobstore | Verify cluster-free UNMAP to base bdev uses async path |
| `io-engine.rs` | New CLI flag to enable/disable backend UNMAP passthrough |

---

### Interaction Between Parts

The two parts form a complete end-to-end UNMAP pipeline:

```text
Filesystem UNMAP (fstrim, or file delete on a filesystem mounted with `discard`)
    │
    ▼
Nexus (forwards UNMAP to all healthy children; for any child currently
       rebuilding, the UNMAP is recorded in the per-child IO-log instead)
    │
    ├─► Replica A (lvol on blobstore)
    │       │
    │       ▼
    │   Blobstore: cluster freed      ← Part 1 ensures rebuild propagates this
    │       │
    │       ▼
    │   Base bdev UNMAP               ← Part 2: async, non-blocking
    │       │
    │       ▼
    │   Physical device: TRIM issued
    │
    └─► Replica B (lvol on blobstore)
            │ (same pipeline)
            ▼
        ...

Rebuild (when replica goes offline and returns):
    Source cluster unmapped
        │
        ▼
    Rebuild detects unallocated (cluster-sized lock)
        │
        ▼
    Issues destination-cluster-aligned UNMAP to destination  ← Part 1 fix
        │
        ▼
    Destination cluster freed → base bdev UNMAP → physical TRIM  ← Part 2
```

---

### Risks and Mitigations

| Risk | Likelihood | Mitigation |
| ---- | ---------- | ---------- |
| Large cluster size (up to 256MB) causes long nexus lock hold times during rebuild, stalling user I/O | Medium | Monitor lock hold time; consider adaptive sub-I/O batch sizing or configurable concurrency limits |
| Race between UNMAP and write during partial rebuild escalation causes stale data | Low | Mandatory re-read of all sub-segments under cluster lock before issuing UNMAP |
| `IORING_OP_FALLOCATE` not available on older kernels (< 5.6) | Low | Fall back to threadpool offload; document minimum kernel version |
| Revived async UNMAP PR had correctness issues causing original revert | Unknown | Thoroughly review original revert reason; add targeted regression tests before merging |
| Cluster size mismatch between replicas causes incorrect alignment calculations | Medium | Validate alignment math in unit tests; add assertion in rebuild init if sizes differ significantly |
| IO-log provenance tracking increases memory footprint | Medium | Make it optional; use compact encoding if needed; default to current dirty-bit-only mode |
| Write-after-UNMAP in IO-log silently lost if provenance not collapsed correctly | Medium | Enforce state transition rule (write always overrides UNMAP) and add targeted unit tests |

---

## Graduation Criteria

- [ ] Full rebuild correctly propagates cluster-sized UNMAPs to destination
- [ ] `num_allocated_clusters` on destination matches source after full rebuild
  with unmapped regions (`rebuild_thin_unmap_propagates_to_dst` test passes)
- [ ] Async unmap implemented for uring bdev
- [ ] Async unmap implemented for aio bdev
- [ ] No reactor stalls observed during UNMAP under unit test conditions
- [ ] Partial rebuild escalation implemented and tested
- [ ] Replica geometry (cluster_size, data_offset) available to rebuild via the
      geometry provider abstraction
- [ ] End-to-end test: filesystem delete → nexus UNMAP → blobstore cluster free
  → backing file space reclaimed
- [ ] Performance regression tests: I/O latency p99 unaffected during concurrent
  `fstrim` + read/write workload
- [ ] All tests passing in CI
- [ ] Documentation updated (CLI flags, minimum kernel version)
- [ ] No regressions in existing rebuild test suite
- [ ] Validated on at least one NVMe and one file-backed deployment

---

## Test Plan

### Part 1: Rebuild UNMAP Tests

| Test | Description |
| ---- | ----------- |
| `rebuild_thin_unmap_propagates_to_dst` | After full rebuild, destination `num_allocated_clusters` matches source |
| `rebuild_thin_partial_unmap_escalation` | Partial rebuild correctly unmaps destination cluster when source cluster is fully unallocated |
| `rebuild_thin_partial_dirty_bit_triggers_reconcile` | A dirty 64KB entry with unallocated source data triggers cluster-window reconcile rather than immediate completion |
| `rebuild_thin_partial_coalesces_same_window` | Multiple dirty 64KB entries in one cluster window are reconciled once and do not cause duplicate UNMAP/copy work |
| `rebuild_thin_partial_iolog_unmap_hint` | UNMAP-tagged IO-log entries skip the initial 64 KiB probe and still reconcile correctly at cluster scope |
| `rebuild_thin_partial_iolog_write_after_unmap` | A write following an UNMAP on the same 64 KiB range collapses the IO-log entry to `WRITE` and forces the normal copy path |
| `rebuild_thin_different_cluster_sizes` | Rebuild with src cluster size ≠ dst cluster size correctly issues cluster-aligned UNMAPs and falls back to write-zeroes on partially covered destination clusters |

### Part 2: Backend UNMAP Tests

| Test | Description |
| ---- | ----------- |
| `unmap_file_space_reclaimed` | After UNMAP on uring/aio-backed pool, sparse file allocated size decreases (hole punching verified) |
| `unmap_cluster_granularity` | Full-cluster UNMAP deallocates one cluster; sub-cluster UNMAP does not change allocation |
| `unmap_does_not_affect_snapshots` | UNMAP on active volume does not change snapshot cluster counts |
| `unmap_end_to_end` | `fstrim` → nexus UNMAP → blobstore cluster free → base bdev TRIM → physical space reclaimed |

---

## Implementation History

| Date | Description |
| ---- | ----------- |
| 2026-06-09 | Initial OEP draft |

---

## Alternatives

### Alternative 1: Modify SPDK Blobstore to Support Sub-Cluster UNMAPs for ZEROES

Modify the blobstore to iterate over clusters within an UNMAP range and free
any fully-covered cluster, regardless of whether the UNMAP request is exactly
cluster-sized as long as the cluster is all zeroes.
This would make the rebuild work transparently without cluster-
size awareness, though at a very high-cost when receiving an UNMAP I/O.

**Rejected (for now)**: Requires upstream SPDK changes with potentially broad
impact. Noted as future work.

---

## References

- [openebs/spdk#11](https://github.com/openebs/spdk/pull/11) — Reverted async UNMAP PR for file-based bdev
- SPDK blobstore source: `spdk/lib/blob/blobstore.c`
- SPDK lvol header: `spdk/include/spdk/lvol.h`
- Mayastor rebuild: `io-engine/src/rebuild/`
- `io_uring` op reference: `IORING_OP_FALLOCATE` (Linux 5.6+)
- `IORING_OP_URING_CMD` (Linux 5.19+) for NVMe passthrough
- Linux `fallocate(2)` man page: `FALLOC_FL_PUNCH_HOLE`
