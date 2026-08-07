---
oep-number: 4268
title: Pool Pattern based Volume Provisioning for LocalPV-ZFS
authors:
  - "@krishnaGajabi"
owners:
  - "@krishnaGajabi"
editor: "@krishnaGajabi"
creation-date: 2026-07-14
last-updated: 2026-08-07
status: implementable
---

# Pool Pattern (`poolpattern`) based Volume Provisioning

## Table of Contents

- [Pool Pattern (`poolpattern`) based Volume Provisioning](#pool-pattern-poolpattern-based-volume-provisioning)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
  - [Current Behaviour](#current-behaviour)
  - [Proposal](#proposal)
    - [StorageClass API](#storageclass-api)
    - [Pool Resolution and Scheduling](#pool-resolution-and-scheduling)
    - [Capacity Tracking](#capacity-tracking)
    - [Clone / Snapshot Paths](#clone--snapshot-paths)
    - [Validation](#validation)
  - [Implementation Plan](#implementation-plan)
  - [Test Plan](#test-plan)
  - [Docs](#docs)
  - [Resolved Decisions](#resolved-decisions)

## Summary

This proposal adds a `poolpattern` StorageClass parameter to LocalPV-ZFS. It is a
regular expression that selects the ZFS pool to provision into at CreateVolume
time, as an alternative to the existing fixed `poolname` parameter. This mirrors
the `vgpattern` feature in [lvm-localpv](https://github.com/openebs/lvm-localpv),
where `poolname`/`poolpattern` are the ZFS analogs of `volgroup`/`vgpattern`
(a ZFS **pool** is the analog of an LVM **volume group**).

## Motivation

Today an administrator must name one exact pool per StorageClass. When pools are
named inconsistently across nodes (e.g. `zfspv-pool-a`, `zfspv-pool-b`), or when
new pools are added, the StorageClass cannot target them without editing. A regex
lets one StorageClass span a family of pools and lets the driver choose among the
matching pools per node.

## Current Behaviour

`CreateZFSVolume` ([pkg/driver/controller.go](../pkg/driver/controller.go)):

1. Reads `poolname` from the (case-insensitive) SC parameters.
2. `getNodeMap(scheduler, pool)` ([pkg/driver/schd_helper.go](../pkg/driver/schd_helper.go))
   builds a `node -> weight` map for that single pool by scanning all `ZFSVolume`
   CRs — `VolumeWeighted` counts volumes, `CapacityWeighted` sums their capacity.
   These are the only two algorithms today, and both weigh a node by what has
   already been provisioned into its pool, never by what is left in it.
   Note that `CapacityWeighted` therefore reflects only the volumes *this driver*
   has provisioned into the pool, not the zpool's real on-disk usage; any data in
   the pool that did not come through the driver is invisible to the weight. There
   is also no free-capacity fit check on this path today. This OEP changes both,
   and adds a third algorithm that weighs by free space.
3. `schd.Scheduler(req, nmap)` (`github.com/openebs/lib-csi/pkg/scheduler`) filters
   nodes by topology and returns them ordered least-loaded-first. It only orders
   **nodes**; the pool is uniform across the returned list.
4. A single `ZFSVolume` is built with the fixed `poolname` and provisioning is tried
   on each node in order. The resolved pool is stored in `ZFSVolume.Spec.PoolName`
   and returned to CSI in the volume context (`zfs.PoolNameKey`).

Key facts the design relies on:

* `ZFSNode` CRs ([pkg/apis/openebs.io/zfs/v1/zfsnode.go](https://github.com/openebs/zfs-localpv/blob/develop/pkg/apis/openebs.io/zfs/v1/zfsnode.go))
  already advertise every pool on each node with `Free`/`Used` capacity — this is
  the authoritative list of pools to match a pattern against (a matching pool may
  have zero volumes yet, so `ZFSVolume` list alone is insufficient).
* No CRD changes are needed: StorageClass parameters are free-form, and the resolved
  concrete pool is already persisted per-volume in `ZFSVolume.Spec.PoolName`.
* The node plugin reads the pool from the `ZFSVolume` CR, so no node-side changes.

## Proposal

### StorageClass API

Add one parameter, `poolpattern`, a Go regular expression (RE2, unanchored — users
anchor with `^...$` if desired). **Exactly one** of `poolname` / `poolpattern` must be
set:

* Both set → CreateVolume fails with `InvalidArgument` (rejected, not silently
  preferring one).
* Neither set → CreateVolume fails with `InvalidArgument`.

Rejecting the both-set case is deliberately stricter than a "one wins" precedence: an
ambiguous StorageClass is a configuration error, and failing it surfaces the mistake
instead of silently ignoring the other parameter.

```yaml
parameters:
  poolpattern: "zfspv-pool.*"   # regex; pool chosen by the scheduler among matches
```

### Pool Resolution and Scheduling

Scheduling reads the `ZFSNode` CRs (each node's `Pools` carry `Free`/`Used`) rather
than the `ZFSVolume` list. Pool names are matched against the **pool root**: a
`poolname` may be a `pool/dataset` path (e.g. `zpool/k8s/localpv`) while `ZFSNode`
advertises only pool-level names, so the root is parsed off before matching, the
same way `GetCapacity` already splits it. `poolpattern` therefore matches pool roots
(it selects among pools, not child datasets).

Both cases fold into a single `*regexp.Regexp` so the helpers have one matching path:
`poolpattern` compiles the user regex directly, while `poolname` compiles as an
**anchored, quoted exact match** — `^` + `regexp.QuoteMeta(poolname)` + `$`. The quoting
is required for correctness: legal ZFS pool names contain regex metacharacters (`.`,
`:`), so an unescaped `tank.prod` would also match `tankXprod` and select the wrong pool.

Scheduling then has two independent inputs, and they play **different roles** because of
how `lib-csi`'s `Scheduler` behaves. `schd.Scheduler(req, nmap)` derives its candidate
node set from the **cluster topology** (`getNodeList`), *not* from `nmap`; `nmap` only
re-orders that set, and any topology-eligible node **absent** from `nmap` is treated as
least-loaded and sorted to the **front** of the list. Consequently the weight map can
only *order* nodes, never *exclude* them — a node dropped from `nmap` is promoted, not
removed — so suitability filtering must be applied by the controller to the scheduler's
output, not by omission from the weight map.

* **Weight map — ordering only** (`nmap[node] += ...`), including every node that has a
  matching pool so the order is never distorted:
  * `CapacityWeighted` (**default**) → `+= pool.Used`, the pool's real on-disk usage from
    the `ZFSNode` CR.
  * `VolumeWeighted` → count of `ZFSVolume`s whose pool root matches (`ZFSNode` carries
    no volume count, so this one consults the `ZFSVolume` list; its `Spec.PoolName` is
    parsed to the root before matching, like every other match).
  * `SpaceWeighted` (**new**) → the `Free` capacity of the node's roomiest matching pool
    (`maxFree`), *inverted* into a weight: `math.MaxInt64 - maxFree`. See below.
* **Suitable-node set — filtering**, for space-reserving volumes only, computed once in
  the controller via `getSuitableNodes(pattern, size)`: a node is *suitable* iff the
  largest `Free` among its matching pools (`maxFree`) is `> size` (a **single** pool must
  hold the whole reservation — `Free` is not summed across pools). The controller then
  **intersects the scheduler's ordered output with this set**, dropping nodes that cannot
  fit while preserving the weighted order of the survivors. This intersection is the only
  step that actually removes a node from consideration.

**The `SpaceWeighted` algorithm.** `VolumeWeighted` and `CapacityWeighted` both order by
what has already been put *into* a pool; neither says anything about what is *left*. A node
with a small, untouched pool therefore outranks a node with a large, moderately used one,
even though the latter has far more room for the volume. `SpaceWeighted` orders by the free
capacity of the node's roomiest matching pool instead — the same pool `resolvePool` would
place the volume in, so the metric matches where the volume actually lands. It is the ZFS
analog of lvm-localpv's [`SpaceWeighted`](https://github.com/openebs/lvm-localpv/blob/develop/pkg/driver/schd_helper.go),
and it applies to `poolname` and `poolpattern` alike.

Two properties of it are load-bearing:

* **The weight is inverted.** `lib-csi`'s `Scheduler` sorts *ascending* and prefers the
  least-weighted node, so free capacity — where more is better — has to be flipped to be
  usable as a weight at all: `nmap[node] = math.MaxInt64 - maxFree`. Overflow is not a
  concern (`Free` is non-negative).
* **A node whose matching pool is full keeps its entry** (weight `math.MaxInt64`, i.e. last),
  rather than being dropped from the map. This is a deliberate divergence from lvm-localpv,
  whose `getSpaceWeightedMap` omits such nodes and folds the fit check into the weight map.
  Under `lib-csi` semantics omission does not exclude a node — it promotes it to the front
  (see above) — so omitting the full nodes would order the *emptiest* pools first and the
  *fullest* pools even earlier, inverting the intent of the algorithm. Deciding whether a
  volume fits stays the job of the suitability intersection, exactly as for the other two
  algorithms; the weight maps remain pure ordering functions.

Free capacity is taken as the node's **largest** matching pool, not the sum of its matching
pools, consistent with `getSuitableNodes` and `resolvePool`: a volume lives in one pool and
can only use that pool's space. All three share a single `maxFreePool` helper so the three
uses of "the node's roomiest matching pool" cannot drift apart.

`SpaceWeighted` is **opt-in** via `scheduler: "SpaceWeighted"`; `CapacityWeighted` remains
the default (see [Resolved Decisions](#resolved-decisions)).

Whether a volume reserves space (and so must pass the fit filter) is volume-type
dependent in ZFS, unlike LVM's single flag — the helper `reservesSpace` encodes it:

* **zvol** (`fstype` `ext4`/`xfs`/`btrfs`, `zfs create -V`): the driver sets no
  reservation itself; ZFS's own default gives a non-sparse zvol a `refreservation`
  (≈ volsize, sometimes larger due to metadata/parity). `thinprovision: "yes"` adds
  `-s` (sparse), which suppresses it. `quotatype` does not apply to zvols. Reserves
  if `thinprovision != "yes"`.
* **dataset** (`fstype` `zfs`, `zfs create`): always gets a size *limit*
  (`quota` by default, `refquota` when `quotatype: "refquota"`) — a cap, not a
  reservation. A reservation is added **on top only** when `thinprovision: "no"`
  (`reservation`, or `refreservation` under `quotatype: "refquota"`). Reserves iff
  `thinprovision == "no"`.

Only a reservation/refreservation makes `zfs create` fail when the pool lacks space;
a plain quota/refquota limit does not. So `reservesSpace` returns
`thinprovision == "no" || (isZvol && thinprovision != "yes")`. Volumes that do not
reserve (thin zvols, quota-only datasets) bypass the fit filter, since their create
succeeds regardless of free space. Because a zvol's `refreservation` can slightly
exceed volsize, the `maxFree > size` check is best-effort (matching lvm-localpv).

Both the `Used`-based weight and the suitability filter apply to the fixed-`poolname`
path as well as `poolpattern` (see the compatibility note in [Resolved
Decisions](#resolved-decisions) — this changes the existing path's behaviour on upgrade).

**Concrete pool resolution.** zfs-localpv resolves the pool in the controller and
stores it in `ZFSVolume.Spec.PoolName` (see [Current Behaviour](#current-behaviour));
the node agent does no matching. So in `poolpattern` mode, after `schd.Scheduler`
orders the nodes and the suitability intersection has run, the provisioning loop resolves
the concrete pool **per candidate node** via `resolvePool` — the matching pool on *that*
node with the largest `Free` — and builds the `ZFSVolume` with `WithPoolName(thatPool)`.
Because the pool is always taken from the chosen node's own `ZFSNode.Pools`, a node can
never be paired with a pool that is not on it. For a reserving volume every remaining
node already has a fitting matching pool (the intersection guaranteed it), so `resolvePool`
returns non-empty; for a non-reserving volume no intersection ran, so `resolvePool` returns
`""` for any front-loaded node that has no matching pool at all and the loop skips it.

`lib-csi` is not modified — it continues to order nodes; the suitability filter and
concrete pool selection stay in this repo.

**Fail-fast on insufficient capacity.** For a space-reserving (thick) volume, if no
node has a matching pool with `Free > size`, `CreateVolume` must fail **immediately**
rather than attempt provisioning on nodes it knows cannot satisfy the reservation. The
trigger is the **suitability intersection going empty**, *not* an empty `schd.Scheduler`
result — the scheduler returns empty only when there are no topology-eligible nodes at
all ([lib-csi `Scheduler`](https://github.com/openebs/lib-csi/blob/v0.11.0/pkg/scheduler/scheduler.go)),
never because nothing fits. So the controller, for a reserving volume, computes the
suitable set, intersects it with the ordered node list, and if the result is empty
replaces today's generic `codes.Internal, "scheduler failed, node list is empty"`
([controller.go:292](https://github.com/openebs/zfs-localpv/blob/develop/pkg/driver/controller.go#L292)) with a capacity-aware verdict:

* **Some** matching pool exists but none fits (`matched`) → `codes.ResourceExhausted`
  with the requested size and pattern in the message. This is the CSI-idiomatic signal
  for insufficient capacity: external-provisioner surfaces it as a `ProvisioningFailed`
  event and retries with backoff, and under `WaitForFirstConsumer` + storage-capacity
  tracking it lets the scheduler re-evaluate and place the pod on a node that
  `GetCapacity` reports as having room.
* **No** pool matches the pattern anywhere (`!matched`) → `codes.FailedPrecondition`
  (a misconfigured StorageClass — a bad pattern will never succeed, so retrying is
  pointless), naming the pattern.

`getSuitableNodes` returns `matched` (whether the pattern matched any pool, fit aside) so
the controller can tell these two apart. An empty `schd.Scheduler` result (no
topology-eligible node) retains the existing generic handling for both reserving and
non-reserving volumes. Non-reserving volumes are never fit-filtered, so they never take
the capacity fail-fast path.

The controller already extracts `fstype`, `thinprovision`, `scheduler`, `quotatype`
and the pool parameters as locals (there is no `VolumeParams` bundle in this repo,
matching the existing per-parameter style). It computes `reserves := reservesSpace(vtype,
thinprovision)` **once** and uses it solely to decide whether to apply the suitability
filter — the weight maps stay pure ordering functions with no fit logic, and
`getNodeMap` is a thin dispatcher over the scheduler algorithm:

```go
// reservesSpace reports whether the volume gets a ZFS reservation and so must fit in Free.
// zvol (fstype != "zfs") reserves unless thin; dataset reserves only when thinprovision == "no".
func reservesSpace(vtype, thinProvision string) bool

// getSuitableNodes returns the set of nodes with a matching pool whose Free > size, and
// `matched` = whether ANY pool matched the pattern (fit aside). The controller intersects
// `suitable` with the scheduler's ordered output for reserving volumes, and uses `matched`
// to pick ResourceExhausted (matched, none fit) vs FailedPrecondition (no match).
func getSuitableNodes(pattern *regexp.Regexp, size int64) (suitable map[string]bool, matched bool, err error)

// weight maps — ordering only, include every node with a matching pool, no fit logic.
func getVolumeWeightedMap(pattern *regexp.Regexp) (map[string]int64, error)
func getCapacityWeightedMap(pattern *regexp.Regexp) (map[string]int64, error)

// getSpaceWeightedMap weighs a node by the Free capacity of its roomiest matching pool,
// inverted (math.MaxInt64 - maxFree) so that lib-csi's ascending sort yields most-free-first.
// A node with a full matching pool still gets an entry (weight math.MaxInt64), so that it
// sorts last instead of being promoted to the front as an unweighted node.
func getSpaceWeightedMap(pattern *regexp.Regexp) (map[string]int64, error)

// dispatch only — switch on scheduler, forward the pattern; CapacityWeighted when unset
// or unrecognised.
func getNodeMap(scheduler string, pattern *regexp.Regexp) (map[string]int64, error)

// maxFreePool returns the matching pool on the node with the largest Free, and that Free
// ("" when nothing matches). Single definition of "the node's roomiest matching pool",
// shared by resolvePool, getSuitableNodes and getSpaceWeightedMap.
func maxFreePool(pools []apis.Pool, pattern *regexp.Regexp) (string, int64)

// resolvePool returns the matching pool on `node` with the largest Free (the pool behind
// that node's maxFree), or "" if no pool on the node matches the pattern.
func resolvePool(node string, pattern *regexp.Regexp) (string, error)
```

Sketch of the controller flow (reserving volume):

```go
reserves := reservesSpace(vtype, thinprovision)
nmap, _ := getNodeMap(schld, pattern)          // ordering
ordered := schd.Scheduler(req, nmap)           // all topology nodes, weighted order
if len(ordered) == 0 { /* generic Internal — no topology-eligible node */ }
if reserves {
    suitable, matched, _ := getSuitableNodes(pattern, size)
    ordered = filterKeep(ordered, suitable)    // preserve order, drop unfit
    if len(ordered) == 0 {
        if matched { /* ResourceExhausted */ } else { /* FailedPrecondition */ }
    }
}
for _, node := range ordered {
    pool, _ := resolvePool(node, pattern)
    if pool == "" { continue }                 // non-reserving path: skip non-matching nodes
    // build ZFSVolume with WithPoolName(pool); try provision
}
```

`CreateZFSVolume` returns the resolved pool (new return value) so `CreateVolume`
can set the response context (`PoolNameKey`) and log line correctly in pattern mode.

### Capacity Tracking

`GetCapacity` ([controller.go:978](https://github.com/openebs/zfs-localpv/blob/develop/pkg/driver/controller.go#L978)) backs the
CSI storage-capacity feature (`feature.storageCapacity`, enabled by default) and
today matches pools by exact `poolname`, reporting the largest matching pool's
`Free`. It is extended to accept `poolpattern` as well: when the pattern is set, it
matches pool roots by regex and reports the maximum `Free` across all matching pools
(still a max, per the max-volume-size semantics the function already documents). A
pattern SC would otherwise report zero capacity and block capacity-aware scheduling.

### Clone / Snapshot Paths

**A clone's pool is never resolved — it is inherited from the source, and the
clone/snapshot paths are never scheduled or pool-selected.** Both `CreateVolClone`
([controller.go:392](https://github.com/openebs/zfs-localpv/blob/develop/pkg/driver/controller.go#L392))
and `CreateSnapClone` ([controller.go:449](https://github.com/openebs/zfs-localpv/blob/develop/pkg/driver/controller.go#L449))
copy the **entire source `Spec`** into the new `ZFSVolume` (`volObj.Spec = vol.Spec` /
`= snap.Spec`), so `Spec.PoolName` is already the source's pool before anything else runs;
the node-agent then executes `zfs clone <sourcepool>/<snap> <sourcepool>/<clone>`. This is
also a ZFS hard constraint — a clone must live in the same pool as its origin snapshot, it
cannot cross pools. **`getNodeMap`, `getSuitableNodes`, and `resolvePool` therefore must
not run on these paths.** (An implementation that mistakenly routes a pattern-mode clone
through normal scheduling could have `resolvePool` pick a *different* matching pool by
`maxFree`, breaking the clone — so this is called out deliberately.)

The only thing the `poolname`/`poolpattern` parameter drives here is a **sanity-check
guard** — *"does the pool this SC declares cover where the clone will actually go (the
source's pool)?"*:

```go
if vol.Spec.PoolName != pool { /* reject: cloning outside the SC's pool */ }   // :368 / :429
```

This guard is the **one functional change** the clone/snapshot paths need. Under a
`poolpattern` SC the `poolname` parameter is empty (only `poolpattern` is set — see
[StorageClass API](#storageclass-api)), so `source.Spec.PoolName != ""` is always true and
the guard rejects **every** clone/restore today. Fix:

* `poolname` set → keep the exact `source.Spec.PoolName == poolname` check.
* `poolpattern` set → require the **source pool root to match the pattern**. This is a
  **boolean validation of the source pool only** — it never selects or returns a pool
  (the clone still lands in the source's pool, per the `Spec` copy above). It rejects a
  clone whose source pool falls outside the SC's declared pattern family, mirroring the
  intent of the exact check.

Response context (`PoolNameKey`) is **not** a functional concern here or on the fresh-create
path: it is unconsumed by the driver (the node reads `Spec.PoolName` from the CR, not the
volume context — [set-only at controller.go:505](https://github.com/openebs/zfs-localpv/blob/develop/pkg/driver/controller.go#L505)),
so a clone works regardless of what the context carries. Populating it with the resolved
pool is an **optional observability improvement** so a pattern-provisioned PV's
`spec.csi.volumeAttributes` shows the chosen pool the same way a `poolname` PV does, rather
than an empty string; it is not required for correctness and may be deferred.

### Validation

In `validateVolumeCreateReq` ([controller.go:1189](https://github.com/openebs/zfs-localpv/blob/develop/pkg/driver/controller.go#1189)),
all as `codes.InvalidArgument`:

* reject when **both** `poolname` and `poolpattern` are set (ambiguous);
* reject when **neither** is set;
* reject a `poolpattern` that fails to compile.

## Implementation Plan

1. `schd_helper.go` — read the `ZFSNode` CRs (not the `ZFSVolume` list), matching on
   the pool root; `CapacityWeighted` weight becomes summed per-pool `Used`; the weight
   maps stay **ordering-only** (every node with a matching pool, no fit logic). Add
   `reservesSpace`, `getSuitableNodes(pattern, size) → (suitable, matched, err)`, and
   `resolvePool` for pattern-mode concrete pool selection, sharing one `maxFreePool`
   helper. Add the `SpaceWeighted` algorithm (`getSpaceWeightedMap`, inverted
   `maxFree`, full-pool nodes retained) and its `getNodeMap` case, leaving
   `CapacityWeighted` as the default. Fold the exact-name
   (`poolname`, compiled as `^`+`QuoteMeta`+`$`) and regex (`poolpattern`) cases into
   one `*regexp.Regexp`. `VolumeWeighted` still counts `ZFSVolume`s, parsing
   `Spec.PoolName` to its root before matching.
2. `controller.go` (fresh-create path) — read `poolpattern`; compute
   `reserves := reservesSpace(vtype, thinprovision)` once; build the ordering `nmap` and
   run `schd.Scheduler`; for reserving volumes **intersect** the ordered list with
   `getSuitableNodes` and, when the intersection is empty, replace the generic
   `codes.Internal` at [controller.go:292](../pkg/driver/controller.go#L292) with the
   capacity-aware fail-fast (`ResourceExhausted` when `matched`, `FailedPrecondition`
   otherwise); call `resolvePool` per candidate node in the provisioning loop.
3. `controller.go` (clone/snapshot paths) — **required:** change the guard so
   `CreateVolClone`/`CreateSnapClone` accept a source pool that matches `poolpattern`
   (keep exact `== poolname` otherwise); do **not** schedule or `resolvePool` these paths
   — the pool is inherited from the source `Spec`. **Optional (observability):** thread
   the resolved pool through `CreateZFSVolume` / `CreateVolClone` / `CreateSnapClone`
   return values into `CreateVolume`'s response-context `PoolNameKey`, so pattern PVs show
   the chosen pool; may be deferred (unconsumed by the driver).
4. `GetCapacity` — accept `poolpattern` (regex-match pool roots, max `Free` across
   matching pools) alongside the existing exact-`poolname` path.
5. `validateVolumeCreateReq` — reject both-set / neither-set + regex-compile validation.
6. Docs (see below) and samples.

## Test Plan

* Unit: pattern matching against pool roots; exact-`poolname` `QuoteMeta` anchoring
  (a `.` in a pool name must not over-match); rejection of both-set and neither-set
  (`InvalidArgument`); `Used`-based
  weighting under both existing algorithms; **`SpaceWeighted`** — that the inverted weight
  sorts most-free-first under an ascending sort, that a node's largest matching pool decides
  rather than the sum of its pools, and that a node with a *full* matching pool still gets
  an entry (weight `math.MaxInt64`) instead of being dropped and front-loaded;
  concrete max-`Free` pool selection; `reservesSpace`
  across the zvol/dataset × `yes`/`no`/unset matrix; **suitability intersection** —
  that an unsuitable node dropped from `nmap` is *not* silently promoted (guards against
  the `lib-csi` front-loading behaviour), that the survivors keep weighted order, and
  that reserving vs non-reserving volumes filter vs bypass; fail-fast codes
  (`ResourceExhausted` when a matching pool cannot fit a reserving volume,
  `FailedPrecondition` on no pattern match); `GetCapacity` under `poolpattern`; invalid
  regex.
* BDD (`tests/`, `ci/ci-test.sh`): provision with `poolpattern` across nodes with
  differently-named pools; **clone and snapshot-restore under a `poolpattern` SC**
  (regression for the empty-`poolname` clone check and the empty response-context pool).

## Docs

Update [docs/storageclasses.md](../docs/storageclasses.md) and
[docs/scheduler.md](../docs/scheduler.md); add a sample StorageClass. Both currently
document "two scheduling algorithms" and must be rewritten for **three**, covering when
`SpaceWeighted` is the right choice over the `CapacityWeighted` default (ordering by the
room a pool has left rather than by what has been written to it) and noting that
`CapacityWeighted` remains the default.

## Resolved Decisions

* **Fit filter**: **in scope for space-reserving volumes, on every scheduling
  path** — both the fixed `poolname` path and the new `poolpattern` path. A volume
  is filtered only if it will get a ZFS reservation, which in ZFS depends on both
  `thinprovision` and volume type: a zvol reserves (ZFS's default `refreservation`)
  unless `thinprovision: "yes"`, while a dataset always carries a `quota`/`refquota`
  *limit* but only gets a `reservation`/`refreservation` — and so is filtered — when
  `thinprovision: "no"` is set explicitly. For a reserving volume,
  a node is kept only if some matching pool's `Free > size` (single-pool `maxFree` —
  free is not summed across a node's pools), via the `getSuitableNodes` helper on
  the `ZFSNode`-advertised free capacity. Filtering is applied by **intersecting the
  scheduler's ordered node list with the suitable set in the controller**, not by
  omitting nodes from the weight map — `lib-csi`'s `Scheduler` ignores `nmap` for
  membership and would promote an omitted node to the front, so omission is the wrong
  lever. The `maxFree > size` test is **best-effort**: `ZFSNode.Free` is a periodic
  snapshot and two concurrent creates can both pass it, so `zfs create` remains the
  final arbiter (a losing create still fails and CSI retries). Non-reserving volumes
  (thin zvols, quota-only datasets) skip the filter entirely — their create succeeds
  regardless of free space, so gating on `Free` would wrongly leave them Pending;
  pattern matching, weighted ordering, and concrete-pool resolution all still apply.
* **Fail-fast when nothing fits**: **for a reserving volume, an empty suitability
  intersection fails the `CreateVolume` immediately** rather than attempting
  provisioning on ineligible nodes. The trigger is the intersection going empty, not an
  empty `schd.Scheduler` result (which only means "no topology-eligible node" and keeps
  the existing generic error). A matching pool that cannot fit → `codes.ResourceExhausted`
  (transient — external-provisioner retries with backoff and, with capacity tracking,
  reschedules); no pattern match at all → `codes.FailedPrecondition` (a misconfigured SC
  that retrying will never fix). Non-reserving volumes are unaffected.
* **Compatibility — existing `poolname` path changes on upgrade**: applying the
  `Used`-based `CapacityWeighted` metric and the fit filter uniformly means existing
  `poolname` StorageClasses change behaviour with no opt-in: node ordering under
  `CapacityWeighted` shifts from driver-provisioned-sum to real pool `Used`, and a
  full/absent pool now returns `ResourceExhausted`/`FailedPrecondition` instead of a
  create-failure retry. This is accepted as an improvement (the scheduler now reflects
  real capacity and fails fast instead of thrashing), but **must be called out in the
  release notes** as a behaviour change. Revisit gating behind a feature flag if field
  feedback shows the ordering change disrupts existing deployments.
* **Anchoring**: **unanchored RE2**, matching lvm-localpv's `vgpattern`
  (`regexp.MatchString` semantics). Users anchor with `^...$` when they need a full
  match. Chosen so migration between lvm-localpv and zfs-localpv behaves identically.
* **CapacityWeighted metric**: **the zpool's actual `Used` capacity from the
  `ZFSNode` CR (read via `nodebuilder`)**, *not* the summed capacity of
  driver-provisioned `ZFSVolume`s, so the scheduler orders nodes by the pool's real
  utilization including data not provisioned through this driver. Applies uniformly
  to `poolname` and `poolpattern` modes. `VolumeWeighted` is unchanged (volume count
  from the `ZFSVolume` list, since `ZFSNode` has no volume count). `Used`/`Free` on
  `ZFSNode` are refreshed periodically by the node-agent, so both the weight and the
  fit filter track real usage with the node-agent's sync latency; the fit filter
  already relies on the same source.
* **`SpaceWeighted` scheduler**: **added as a third algorithm, and opt-in —
  `CapacityWeighted` stays the default.** It weighs a node by the `Free` capacity of its
  roomiest matching pool (`maxFree`, not the sum across a node's pools — a volume lives in
  one pool), so nodes are ordered by the room a pool has *left* rather than by what has
  already been written into it, which is what the other two algorithms measure. Because
  `lib-csi` prefers the *least*-weighted node, the metric is inverted as
  `math.MaxInt64 - maxFree`, matching lvm-localpv's implementation. Two deliberate
  divergences from lvm-localpv: (1) **it is not the default** — lvm-localpv defaults to
  `SpaceWeighted`, but zfs-localpv already defaults to `CapacityWeighted` and this OEP is
  *already* changing that algorithm's metric on upgrade (see the compatibility decision
  above); silently re-ordering every existing StorageClass a second time, by a different
  axis, is one change too many for a single release. Users opt in with
  `scheduler: "SpaceWeighted"`. Revisit making it the default in a later release, once the
  `Used`-metric change has field feedback. (2) **A node whose matching pool is full keeps
  its map entry** (weight `math.MaxInt64`, sorting last) instead of being omitted as
  lvm-localpv does — under `lib-csi`, omitting a node promotes it to the front of the list
  rather than excluding it, so omission would order the fullest pools *first* and invert
  the algorithm. Deciding fit remains the suitability intersection's job, keeping every
  weight map a pure ordering function.
