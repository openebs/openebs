---
oep-number: OEP 4074
title: Mayastor trim/unmap support, follow-up amendment
authors:
  - "@patrickdk77"
  - "@tiagolobocastro (parent OEP author)"
owners:
  - "@patrickdk77"
editor: TBD
creation-date: 30/07/2026
last-updated: 30/07/2026
status: provisional
see-also:
  - OEP 3843
  - OEP 4278
  - OEP 4279
---

# OEP 4074 amendment: trim/unmap follow-up

## Table of Contents

- [Summary](#summary)
- [Motivation (what is broken or missing today)](#motivation-what-is-broken-or-missing-today)
- [Proposal](#proposal)
  - [1. Enable the blobstore path](#1-enable-the-blobstore-path)
  - [2. Mixed-capability replicas: advertise any, converge all](#2-mixed-capability-replicas-advertise-any-converge-all)
  - [3. Bound and advertise sizes honestly](#3-bound-and-advertise-sizes-honestly)
  - [4. Thin WRITE_ZEROES on discard-reads-zeros devices](#4-thin-write_zeroes-on-discard-reads-zeros-devices)
  - [5. Part 1 coupling: rebuild hole propagation, destination-capability driven](#5-part-1-coupling-rebuild-hole-propagation-destination-capability-driven)
- [Graduation Criteria](#graduation-criteria)
- [Testing](#testing)
- [Decided positions](#decided-positions)
- [Open items to settle during review](#open-items-to-settle-during-review)
- [Implementation History](#implementation-history)

## Summary

This document amends OEP 4074 (designs/replicated-pv/mayastor/unmap.md) under the
same tracking issue, openebs/openebs#4074; it proposes no new OEP number. Whether
it merges as an amendment to unmap.md or stands as a companion document is the
maintainers' choice in review.

OEP 4074 Part 2 (async UNMAP passthrough to backend bdevs) is implemented by the
in-review Part 2 changes (openebs/spdk aio and uring commits plus the io-engine
wiring): the aio bdev offloads UNMAP/WRITE_ZEROES to a worker thread off the reactor
(BLKDISCARD/BLKZEROOUT for block devices, fallocate punch-hole for files, each op
gated per device by its queue limits), and the uring bdev submits them natively on
its ring (block-device discard gated by a one-time loop-device kernel probe, since
neither the kernel version nor the opcode probe can answer it). This follow-up
covers what remains against upstream: enabling the blobstore path end to end,
correct behavior with mixed-capability replicas, bounding and advertising
sizes/granularity honestly, thin WRITE_ZEROES on discard-reads-zeros devices, and
the Part 1 rebuild coupling.

## Motivation (what is broken or missing today)

1. The OEP's primary target is not enabled: nothing opts an LVS pool's base bdev into
   `fallocate=true`, and `--bs-cluster-unmap` defaults to false, so blobstore trims
   free no clusters and reach no device. Two independent gates, both off.
2. Mixed-capability replicas become possible for the first time, and the existing
   nexus behavior mishandles them. Baseline (upstream, unchanged by Part 2): the
   nexus advertises UNMAP only when ALL children support it; lvol children always
   do, aio children never did (fallocate was hardcoded false), so a volume was
   either all-capable (pure LVS) or not advertised at all, so the AND never saw a
   mixed case. Part 2's per-device advertisement changes that: aio children now
   advertise per their device, so a mix (e.g. an LVM thick LV on a discardless PV
   alongside capable replicas; LVS lvols, zvols sparse or thick, and LVM thin LVs
   are all always-capable) is now reachable. Under the existing AND, one such child
   silently disables trim volume-wide; and if a child is added after a host
   connected, the pre-existing retire path turns the first trim into a fault: the
   incapable aio child completes -ENOTSUP -> generic INTERNAL_DEVICE_ERROR -> child
   faulted and retired, the volume re-advertises unmap, and the cycle repeats on the
   next placement.
3. Sizes and granularity are advertised wrong in both directions, and this is
   upstream behavior today for every volume type (including pure LVS): io-engine
   never sets the NVMf subsystem's max_discard_size, so the host derives
   discard_max ~ 2 TiB from an unset dmrsl, and granularity is reported as the
   logical block size (512 B) because NPDG derives from a defaulted
   physical_block_size. Against real backings (measured: a zvol accepts 256 MiB per
   ioctl and frees only whole 16 KiB volblocksize blocks; an LVS lvol frees only
   whole 4 MiB clusters) sub-granularity trims silently reclaim nothing and
   oversized trims arrive unbounded.
4. WRITE_ZEROES fattens thin devices that lack native write-zeroes (zvol, thin LV):
   the SPDK bdev layer emulates it with real zero writes (upstream behavior since
   2018), allocating the very space the volume is trying to stay thin about.
5. Part 1 (thin-aware rebuild) is unimplemented, and every nexus rebuild re-inflates
   a thin source's holes onto the destination.

## Proposal

### 1. Enable the blobstore path

- io-engine opts the LVS pool base aio/uring bdev into `fallocate=true` using the
  capability probe introduced by Part 2 (the same probe its LVM wiring uses, and the
  ZFS backend OEP's (4278) zvol path adopts).
- Flip `--bs-cluster-unmap` handling: keep the flag, benchmark, and propose the
  default in this OEP's review. Note: enabling base-bdev unmap also flips new lvol
  clear_method to UNMAP (release-note item).
- Node-level control: a CLI flag/env on io-engine acting as a master enable/disable
  for backend unmap passthrough (per host, so an admin can switch off a misbehaving
  machine without per-volume surgery), with the runtime probes doing per-device
  gating beneath it.

### 2. Mixed-capability replicas: advertise any, converge all

- The nexus's existing all-children AND gate for UNMAP advertisement (pre-existing
  upstream behavior, which mixed capability never exercised before Part 2) changes
  to ANY across children: fstrim keeps working volume-wide when at least one replica
  can reclaim.
- Dispatch converts per child: children whose device supports UNMAP get the real
  discard; children that do not get WRITE_ZEROES over the same range. WRITE_ZEROES
  always succeeds (native offload where available; SPDK bdev-layer emulation
  otherwise), so there is no error path, no child retire, no flap.
- Why write zeros instead of skipping: a skipped child keeps stale data where its
  peers read zeros. Reads round-robin across children, so the divergence is
  immediately observable; and the incapable child remains a valid rebuild source, so
  a later rebuild resurrects deleted data onto fresh replicas. Converging content is
  the correctness fix; the only cost is I/O on the child that could not reclaim
  anyway (an LVM thick LV is fully allocated by definition, so nothing gets fatter).
- Defense in depth for the retire hazard: an -ENOTSUP unmap completion must not
  fault the child (map it to the existing invalid-opcode no-retire path). With
  conversion in place this should be unreachable; keep it as a guard, and bound the
  nexus resubmit counter (currently unbounded) so no future error class can loop.

### 3. Bound and advertise sizes honestly

- Set `bdev->max_unmap` / `max_unmap_segments` (and `max_write_zeroes`) in the aio
  and uring modules so the SPDK bdev layer splits large ops; target 32 MiB per
  segment. This bounds worker-thread occupancy per op and fixes the currently
  unsplit emulated WRITE_ZEROES path as well.
- NVMf: set the subsystem's max_discard_size so the host's discard_max_bytes stops
  reading as ~2 TiB. Requires a public setter in SPDK (the field exists but is
  JSON-RPC-only today) and fixing the dmrsl advertisement unit bug (dmrsl is
  computed as kib << 1, i.e. 512 B units, while enforcement divides by the real
  block size, which is inconsistent on 4K-block namespaces).
- Granularity: advertising via physical_block_size is rejected (it also claims
  NAWUPF write atomicity and shifts io_min; nothing in the fleet supports a
  physical block size other than 512/4K). The correct carrier is NPDG/NPDA only,
  which requires SPDK to grow a discard-granularity concept on spdk_bdev, decoupled
  from phys_blocklen. Until then, sub-granularity trims are mitigated at the
  filesystem: mkfs alignment to the backing granularity (volblocksize / chunk size)
  via csi-node parameters.

### 4. Thin WRITE_ZEROES on discard-reads-zeros devices

- On zvols and thin LVs, a freed block reads back zeros (verified for both; for the
  blobstore the lvol layer itself guarantees it). For such devices, WRITE_ZEROES can
  be satisfied by BLKDISCARD, freeing space instead of allocating it.
- Discoverability: there is no runtime signal (the kernel's discard_zeroes_data is a
  hardcoded 0; NVMe DLFEAT is usually 0 and SPDK never sets it; nothing survives dm
  stacking). But io-engine created these devices, so it knows by construction.
  Plumb a `discard_zeroes=true` hint on the aio/uring bdev URI (next to
  `fallocate=true`), set by the ZFS backend for zvols (OEP 4278) and by the
  LVM backend for thin LVs (once OEP 4279's dm-thin phase lands).
- With the hint, the module sets its write-zeroes op to BLKDISCARD. Sub-granularity
  edges are not a concern at the chosen 32 MiB segmenting and cluster-aligned
  callers; if exactness is ever required the op can zero-write the partial edges
  (bounded at 2x granularity) around a discarded interior.

### 5. Part 1 coupling: rebuild hole propagation, destination-capability driven

- A rebuild must leave the destination readable-identical to the source AND, where
  the destination supports it, as thin as the source. The destination chooses the op
  by its own guarantee:
  - zeros-after-unmap guaranteed (blobstore cluster release, zvol, thin LV; known
    by construction, the same knowledge as the item-4 hint): UNMAP. This is the
    parent OEP's "cluster release during rebuild": it converges content and releases
    the space, including space held by stale data on a partial-rebuild destination.
  - no such guarantee: WRITE_ZEROES, which is always available (native or emulated)
    and converges content; the destination simply stays thick, as it was.
  A bare UNMAP is never used where zeros-after-unmap is not guaranteed (read-back
  would be undefined and the replicas would diverge).
- Source-side allocation truth: the blobstore already answers via the
  UNWRITTEN_READ_FAIL read option (used today only by the snapshot rebuild); the
  nexus rebuild adopts it for blobstore sources. aio-backed sources (zvol/LV) have
  no allocation query (no io-flags path in bdev_aio; block devices do not answer
  SEEK_HOLE), so they degrade to full copy until a backend-specific query exists --
  documented limitation, out of scope here.
- Destination-side: skipping unallocated segments is only safe on a fresh
  destination. For partial rebuilds the destination must actively converge (
  WRITE_ZEROES the segment) rather than skip, or the region retains stale data.

## Graduation Criteria

- Blobstore path enabled end to end: fstrim on an LVS volume releases clusters and reaches the base device.
- A mixed-capability volume (one non-discard child) trims without disabling unmap volume-wide and without retiring the child.
- Host-visible discard_max_bytes bounded (32 MiB target) and enforced consistently on 512 B and 4K namespaces.
- WRITE_ZEROES on a discard-reads-zeros replica (zvol, thin LV) does not allocate space.
- Nexus rebuild from a blobstore source leaves destination allocation state matching the source.

## Testing

- Extend the aio_fallocate integration suite added by Part 2: per-op independent
  gating (discard-only device advertises UNMAP but not native WRITE_ZEROES),
  discard_zeroes hint behavior, segment splitting at max_unmap.
- Add a uring twin of that suite (no test exercises uring unmap), including both
  loop-probe outcomes asserted from the module's NOTICELOG.
- Nexus mixed-capability: any-child advertisement, per-child conversion, and a
  regression test that an incapable child is not retired by a trim (extends
  nexus_child_retire.rs).
- Rebuild: extend nexus_thin_rebuild.rs to assert destination allocation state
  matches the source after rebuild (not just data), for blobstore sources.
- BDD: fstrim-over-NVMf end-to-end reclaim for zvol and LVM-thin replicas; negative
  case for sub-granularity trims until NPDG lands.
- SPDK C: upstream has no unit tests for bdev_aio/bdev_uring; add functional
  coverage via the extended io-engine tests rather than new C harnesses.

## Decided positions

1. Advertise ANY, converge with WRITE_ZEROES on incapable children (content
   convergence beats skip; cost bounded and paid only where reclaim was impossible).
2. 32 MiB segmenting via bdev max_unmap/max_write_zeroes; NVMf max_discard_size
   follows once the SPDK setter exists.
3. physical_block_size stays 512/4K; granularity goes NPDG/NPDA-only (SPDK change)
   plus mkfs alignment in the interim.
4. discard_zeroes is a backend-set hint, not runtime-probed (no reliable runtime
   signal exists; the backends know by construction). Thick LVM never sets it; a
   probe for foreign devices is possible (scratch LV write/discard/read) but
   deferred until a backend needs it.
5. Rebuild hole propagation is destination-capability driven: UNMAP where the
   destination guarantees zeros-after-unmap (releasing space, per the parent OEP's
   cluster-release-during-rebuild), WRITE_ZEROES otherwise; never a bare UNMAP
   without the zeros guarantee, and never skip-write on a partial rebuild.

## Open items to settle during review

1. `--bs-cluster-unmap` default: flip to on after benchmarking, or keep opt-in?
2. Node-level flag default: enabled (probe-driven, admin opts out) or disabled
   (explicit opt-in), and its interaction with the existing fallocate URI opt-in.
3. Whether the NVMf max_discard_size setter + dmrsl unit fix goes upstream to SPDK
   first or is carried on the fork.
4. Sizing of the aio offload: one worker thread today; whether 32 MiB segments make
   a small pool of workers worthwhile under trim storms.

## Implementation History

- 30/07/2026: initial draft (provisional). Builds on the in-review OEP 4074 Part 2 changes.
