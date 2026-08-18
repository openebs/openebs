---
oep-number: OEP 5198
title: Disk Health (SMART) Support in io-engine
authors:
  - "@susobhandey"
owners:
  - "@susobhandey"
editor: TBD
creation-date: 2026-07-02
last-updated: 2026-08-17
status: implementable
---

# Disk Health (SMART) Support in io-engine

## Table of Contents

- [Summary](#summary)
- [Motivation](#motivation)
  - [Goals](#goals)
  - [Non-Goals](#non-goals)
- [Proposal](#proposal)
  - [User Stories](#user-stories)
  - [Implementation Details](#implementation-details)
    - [Data Model](#data-model)
    - [Device Information](#device-information)
    - [SMART Attributes and Thresholds](#smart-attributes-and-thresholds)
    - [The Common Method](#the-common-method)
    - [Branch Selection](#branch-selection)
    - [Common Start and End](#common-start-and-end)
    - [Path A — smartctl (kernel-attached disks)](#path-a--smartctl-kernel-attached-disks)
    - [Path B — NVMe SMART log page (VFIO-attached NVMe)](#path-b--nvme-smart-log-page-vfio-attached-nvme)
    - [Combined Flow](#combined-flow)
    - [gRPC / Protobuf Interface](#grpc--protobuf-interface)
    - [Error Handling](#error-handling)
    - [Concurrency and Locking](#concurrency-and-locking)
    - [File-Level Changes](#file-level-changes)
    - [Runtime Requirements](#runtime-requirements)
    - [Assumptions and Dependencies](#assumptions-and-dependencies)
  - [Risks and Mitigations](#risks-and-mitigations)
- [Graduation Criteria](#graduation-criteria)
- [Implementation History](#implementation-history)
- [Drawbacks](#drawbacks)
- [Alternatives](#alternatives)
- [Infrastructure Needed](#infrastructure-needed)
- [Testing](#testing)
  - [Unit tests](#unit-tests)
  - [Hardware and integration tests](#hardware-and-integration-tests)
  - [BDD tests](#bdd-tests)

## Summary

The io-engine data plane currently has no way to report the health of the physical disks that back a Mayastor pool. Operators cannot see disk temperature, remaining life, media error counts, or vendor failure warnings for the devices io-engine has opened, which means degrading hardware is only noticed once it starts producing I/O errors.

This enhancement adds SMART (Self-Monitoring, Analysis and Reporting Technology) reporting to io-engine. A single method, `device_health()`, is added to the `BlockDevice` trait, so every device type answers the same question in its own way and callers never need to know how a disk is attached. Two implementations sit behind that method: kernel-attached disks (`aio://`, `uring://` — covering SATA, SAS, and NVMe not bound to VFIO) are read with `smartctl`, and VFIO-attached NVMe (`pcie://`) is read by issuing an NVMe `GET LOG PAGE` admin command for the SMART / Health Information log page (log ID `0x02`) through the admin-passthru path io-engine already uses for `identify`. Both paths normalise their output into one `DeviceHealth` struct.

Alongside the wear and error counters, each disk also reports the static identity of the device — model, serial number, firmware revision, capacity, and, where the transport exposes it, link speed — and, for ATA devices, the full SMART attribute table including each attribute's `value`, `worst` and `threshold`. The identity fields let an operator correlate a warning with a physical part number without a second tool, and the threshold columns are what make an attribute value interpretable: `value = 100` means nothing until you know the vendor's failure threshold for that attribute.

The results are exposed through a new `GetPoolHealth` RPC on the existing pool gRPC service, which returns one entry per backing disk. Devices that genuinely cannot report health — a virtual cloud disk with no SMART support, for example — are returned with `supported = false` rather than failing the call, so a mixed pool always produces a usable answer. No changes to SPDK source are required; the only change outside io-engine is un-commenting an opcode constant that already exists in the `spdk-rs` bindings.

## Motivation

Storage administrators running Mayastor in production need early warning of disk failure. Today the only signal is I/O failure after the fact, at which point a replica is already degraded and a rebuild is required. Every enterprise SSD and HDD already tracks the information needed to predict this — wear level, spare capacity, media errors, unsafe shutdowns, temperature — but io-engine does not surface any of it.

The complication that motivates this specific design is that **how you read health depends on how the disk is attached, not on the disk brand**:

- **Kernel-attached disks** have a `/dev` name (for example `aio:///dev/sdb` or `uring:///dev/nvme4n1`). This covers SATA, SAS, and NVMe that has not been bound to VFIO. A standard userspace tool can reach these.
- **VFIO-attached NVMe** (for example `pcie://0000:04:00.0`) has no `/dev` name at all; SPDK drives the controller directly in userspace and the kernel driver has been detached. Nothing outside the io-engine process can talk to that device.

No single mechanism reaches both classes of device. A design that only shipped one method would silently exclude a large fraction of real deployments — either the performance-oriented VFIO deployments, or the far more common kernel-attached ones. The proposal therefore standardises the *interface* and lets each device type choose its own *mechanism*.

### Goals

- Provide one common method for asking any device for its health, so callers do not branch on device type.
- Produce one normalised health result that is identical in shape for every disk type.
- Report the static identity of each disk — model, serial number, firmware revision, capacity, sector sizes, rotation rate, form factor and link speed — so a health warning can be tied to a physical part without a second tool.
- Report SMART attributes together with their `value`, `worst` and `threshold` columns, so a caller can tell whether an attribute is actually near failure rather than guessing at the vendor's scale.
- Read SATA, SAS, and kernel-attached NVMe through a single tool (`smartctl`).
- Read VFIO-attached NVMe through an NVMe SMART log page admin command.
- Expose the health of a pool's backing disks over the pool gRPC API.
- Require no changes to SPDK source.
- Degrade gracefully: a device that cannot report health returns `supported = false` instead of failing the request.

### Non-Goals

- **Health polling, history, or trend storage.** This proposal is strictly on-demand read. Periodic collection is deliberately deferred to follow-on work, for the reason given under [Alternatives](#alternatives): a cached or sampled value is misleading precisely when it matters.
- **Control-plane and CSI integration.** Surfacing health through the control plane, `kubectl mayastor`, or CSI lives in other repositories and is out of scope here.
- **Metrics, alerting, or automatic remediation.** No Prometheus exporter, no threshold-based pool eviction, no automatic replica migration on a failure prediction.
- **Changes to SPDK source.** Only an already-present opcode constant in the `spdk-rs` bindings is enabled.
- **Interpreting vendor-specific SMART attributes.** The normalised fields cover only the standard, cross-vendor values. The ATA attribute table is passed through as `smartctl` reports it — id, name, `value`, `worst`, `threshold` and raw value — but io-engine does not attempt to decode vendor-specific raw encodings or to assign meaning to non-standard attribute ids. Interpretation of those is left to the caller.
- **Health for devices other than pool-backing disks** (for example NVMe-oF targets consumed as nexus children).

## Proposal

A new `device_health()` method is added to the `BlockDevice` trait in io-engine. The default implementation returns "not supported", so every existing device type compiles unchanged and simply reports no health until it implements the method. The concrete implementation in `bdev/device.rs` inspects the device's driver and name and dispatches to one of two readers, both of which return the same `DeviceHealth` struct.

A new `GetPoolHealth` RPC on `PoolRpc` resolves a pool by name, enumerates its backing disks, calls `device_health()` on each, and returns a list of per-disk results.

```
              user asks:  GetPoolHealth(pool)
                          |
                 io-engine finds the pool
                          |
                 get the pool's disk(s)
                          |
             for each disk -> device_health()
                          |
        +-----------------+------------------+
        |                                    |
   kernel disk                          VFIO NVMe
   (aio / uring, has /dev name)         (pcie, no /dev name)
        |                                    |
   run smartctl                        read NVMe log page 0x02
   (SATA / SAS / NVMe)                 (reuse existing admin code)
        |                                    |
        +-----------------+------------------+
                          |
                    health result
                          |
              send back to the user
```

The key design decisions and their rationale:

| # | Decision | Reason |
| - | -------- | ------ |
| 1 | One `device_health()` method on the device object | Callers stay simple; each disk type decides how to read its own health |
| 2 | Use `smartctl` for kernel-attached disks | One tool covers SATA, SAS, and kernel NVMe, including vendor quirk handling we would otherwise have to reimplement |
| 3 | Use the NVMe SMART log page for VFIO NVMe | These devices have no `/dev` name, so no external tool can reach them |
| 4 | Reuse the existing NVMe admin-passthru code | No new low-level code; the same mechanism already ships for `identify` |
| 5 | Do not change SPDK source | Avoids a long external review cycle; only enables an opcode already present in the bindings |
| 6 | Per-disk `supported` flag rather than a failed call | Mixed pools and SMART-less cloud disks still return useful data |
| 7 | Report device identity alongside the counters | A wear warning is only actionable if the operator can tell which physical disk to pull; the identity is free at the point the health data is read |
| 8 | Report SMART attributes with their `value`, `worst` and `threshold` | A normalised attribute value is uninterpretable without the vendor threshold it is measured against |

### User Stories

#### Story 1

As a platform SRE running Mayastor on bare metal, I want to query the health of a pool's backing disk so that I can replace a drive that is nearing end of life *before* it fails and forces a replica rebuild. I call `GetPoolHealth` on the pool and see `percentage_used`, `available_spare_percent`, and `media_errors` for the disk, and act when wear crosses my own threshold. The same response gives me the model and serial number, so I can raise the replacement or RMA against the right part without logging on to the node to run `smartctl` myself.

#### Story 2

As a support engineer debugging a node with VFIO-attached NVMe, I want the same health information I would get from `smartctl` on a kernel-attached disk — even though the device has been detached from the kernel driver and has no `/dev` node — so that I do not have to tear down the pool and rebind the device to the kernel just to read its SMART data.

#### Story 3

As an operator with a heterogeneous cluster — some SATA, some SAS, some VFIO NVMe, some cloud virtual disks with no SMART support at all — I want a single API call per pool that returns whatever is available for each disk and clearly marks the rest as unsupported, so that my tooling does not need per-device-type logic and does not break on the disks that cannot answer.

### Implementation Details

#### Data Model

A new struct, `DeviceHealth`, is added in `io-engine/src/core/device_health.rs`. Fields are optional where a given device class does not report them.

| Field | Meaning |
| ----- | ------- |
| `critical_warning` | Vendor warning flags; `0` means good |
| `temperature_celsius` | Composite temperature in Celsius |
| `available_spare_percent` | Remaining spare capacity |
| `available_spare_threshold_percent` | Spare capacity warning level |
| `percentage_used` | Estimated life consumed |
| `data_units_read` / `data_units_written` | Volume read / written |
| `power_cycles` | Number of power cycles |
| `power_on_hours` | Hours powered on |
| `unsafe_shutdowns` | Number of unsafe shutdowns |
| `media_errors` | Media / data integrity errors |
| `num_error_log_entries` | Number of error log entries |
| `warning_temperature_threshold_celsius` | Temperature at which the device reports a warning |
| `critical_temperature_threshold_celsius` | Temperature at which the device considers itself critical |
| `info` | Static device identity — see [Device Information](#device-information) |
| `smart_attributes` | The SMART attribute table with thresholds — see [SMART Attributes and Thresholds](#smart-attributes-and-thresholds) |

Small helpers are provided alongside it, for example `is_healthy()`, which folds `critical_warning`, the SMART overall-health verdict, and any attribute whose `value` has fallen to or below its `threshold` into a single boolean.

#### Device Information

The counters above tell an operator that *a* disk is wearing out; they do not say *which* disk to pull from the shelf. A nested `DeviceInfo` struct therefore carries the static identity of the device, read from the same source as the health data in the same call, so no second tool and no second round trip is needed.

| Field | Meaning |
| ----- | ------- |
| `model_number` | Device model, for example `CT250MX500SSD1` |
| `model_family` | Vendor family from the `smartctl` drive database, where recognised |
| `serial_number` | Device serial number |
| `firmware_version` | Firmware revision |
| `wwn` | World-wide name / unique device identifier |
| `capacity_bytes` | User-addressable capacity |
| `logical_block_size` / `physical_block_size` | Sector sizes, for example 512 logical / 4096 physical |
| `rotation_rate_rpm` | Spindle speed; `0` denotes a solid-state device |
| `form_factor` | For example `2.5 inches` |
| `transport` | For example `SATA 3.3`, `SAS`, `NVMe (PCIe)` |
| `link_speed` | Negotiated current link speed, for example `6.0 Gb/s` |
| `smart_supported` / `smart_enabled` | Whether the device advertises SMART, and whether it is switched on |

Coverage differs by path, and absent fields stay absent rather than being defaulted:

- **Path A (`smartctl`)** populates every field above; this is exactly the content of the `=== START OF INFORMATION SECTION ===` block, taken from the JSON equivalents rather than the human-readable text.
- **Path B (VFIO NVMe)** populates `model_number`, `serial_number`, `firmware_version`, `wwn` and `capacity_bytes` from the Identify Controller data structure that io-engine already reads for `identify`, and reports `transport` as `NVMe (PCIe)` with `rotation_rate_rpm = 0`. `model_family` and `form_factor` have no NVMe equivalent. `link_speed` is a property of the PCIe link rather than of the controller, so it is not available from Identify and is left absent for now; surfacing it would mean reading PCI config space, which is deliberately out of scope for this proposal.

`smart_enabled` is meaningful only for ATA devices, which can have SMART switched off. NVMe has no such toggle — the SMART log page is mandatory — so both flags are reported as true on Path B.

#### SMART Attributes and Thresholds

A bare attribute value is not actionable. `Reallocated_Sector_Ct` at `value = 100` is healthy on one drive and a raw count of reallocations on another; what makes it interpretable is the vendor's `threshold` and the `worst` value seen over the device's life. The normalised counters are therefore accompanied by the attribute table itself, reported as a list of `SmartAttribute`:

| Field | Meaning |
| ----- | ------- |
| `id` | Attribute id, for example `5` (`Reallocated_Sector_Ct`) |
| `name` | Attribute name as reported, for example `Temperature_Celsius` |
| `value` | Current normalised value |
| `worst` | Worst normalised value recorded over the device's lifetime |
| `threshold` | Vendor failure threshold for this attribute |
| `raw_value` | Raw value as an integer |
| `raw_string` | Raw value as rendered by `smartctl`, retained because some vendors pack several counters into one raw field |
| `failing_now` | `value` is at or below `threshold` today |
| `failed_before` | The attribute has failed at some point in the past |

Availability again follows the device class, and the field is an empty list rather than an error when a class has no such table:

- **ATA (SATA) devices** report the full table. This is the primary consumer of this field.
- **SAS devices** have no ATA-style attribute table; the list is empty and the SCSI-specific counters — the grown defect list, and the error counter log — carry the equivalent signal.
- **NVMe devices** likewise have no attribute table; the SMART log page is a fixed structure whose fields are already normalised into `DeviceHealth` directly. NVMe's equivalents of a threshold are reported as first-class fields instead: `available_spare_threshold_percent` from the log page, and `warning_temperature_threshold_celsius` / `critical_temperature_threshold_celsius` from Identify Controller (`WCTEMP` and `CCTEMP`, converted from Kelvin).

This keeps one shape across all device classes: a caller can always read the normalised counters, and can additionally walk `smart_attributes` when the device is one that provides them.

#### The Common Method

`device_health()` is added to the `BlockDevice` trait in `io-engine/src/core/block_device.rs`. The trait-level default returns "not supported", which keeps the change additive: no existing device implementation is forced to change, and SPDK is untouched.

#### Branch Selection

Inside `device_health()`:

- Driver is `aio` or `uring` **and** the name starts with `/dev/` → **Path A** (`smartctl`).
- Driver is `nvme` (VFIO, no `/dev` name) → **Path B** (NVMe log page).
- Anything else → return "not supported".

Note that a `/dev/disk/by-path/...` name also starts with `/dev/` and therefore takes Path A; `smartctl` resolves the symlink itself, so no extra handling is needed.

#### Common Start and End

**Start (both paths).** The client calls `GetPoolHealth` with a pool name. The handler in `grpc/v1/pool.rs` resolves the pool via `finder()`, obtains the backing disk list via `pool.disks()`, looks up the `BlockDevice` for each disk, and calls `device_health()` on it.

**End (both paths).** Each call yields either a `DeviceHealth` or an error. The handler builds a `DiskHealth { disk_uri, supported, health }` — `supported = true` with the health payload on success, `supported = false` on failure or when the device reports no SMART capability. All entries are collected into a `GetPoolHealthResponse`.

#### Path A — smartctl (kernel-attached disks)

Applies to SATA, SAS, and NVMe not bound to VFIO. Code lives in `bdev/device.rs` and `core/device_health.rs`.

```
User (grpcurl / client)
   |   GetPoolHealth("pool-node-0")
   v
gRPC server: PoolRpc.GetPoolHealth            [grpc/v1/pool.rs]
   |
   v
find the pool          finder()
   |
   v
get disk list          pool.disks()   ->  "aio:///dev/sdb"
   |
   v
find the device        device_lookup("/dev/sdb")  ->  BlockDevice
   |
   v
device_health()                               [bdev/device.rs]
   |   driver is "aio" or "uring", name is /dev/...
   v
read_device_health("/dev/sdb")                [core/device_health.rs]
   |
   v
run:  smartctl --json --all /dev/sdb
   |
   v
read the JSON  ->  fill DeviceHealth
   |               (+ DeviceInfo, + SmartAttribute list)
   |
   v
back to handler  ->  DiskHealth { uri, supported, health }
   |
   v
GetPoolHealthResponse  ->  send to user
```

The JSON produced by `smartctl --json --all` is mapped as follows:

| JSON field | `DeviceHealth` field |
| ---------- | -------------------- |
| `smart_status.passed = false` | set the critical warning flag |
| `temperature.current` | temperature |
| `power_on_time.hours` | power on hours |
| `power_cycle_count` | power cycles |
| `nvme_smart_health_information_log` | all NVMe fields (kernel NVMe) |
| ATA attribute id 194 | temperature |
| ATA attribute id 5 | media errors |
| ATA attribute id 9 | power on hours |
| ATA attribute id 12 | power cycles |
| ATA attribute id 198 | error log entries |
| `scsi_grown_defect_list` | media errors (SAS) |
| `ata_smart_attributes.table[]` | `smart_attributes` — `id`, `name`, `value`, `worst`, `thresh`, `raw.value`, `raw.string`, and `when_failed` (`"now"` → `failing_now`, `"past"` → `failed_before`) |

The information-section fields map into `DeviceInfo` as follows. These are read from the JSON keys rather than by scraping the human-readable `=== START OF INFORMATION SECTION ===` block:

| JSON field | `DeviceInfo` field |
| ---------- | ------------------ |
| `model_name` | model number |
| `model_family` | model family |
| `serial_number` | serial number |
| `firmware_version` | firmware version |
| `wwn.{naa,oui,id}` | wwn (formatted) |
| `user_capacity.bytes` | capacity bytes |
| `logical_block_size` / `physical_block_size` | sector sizes |
| `rotation_rate` | rotation rate (absent or `0` → solid state) |
| `form_factor.name` | form factor |
| `sata_version.string` / `device.protocol` | transport |
| `interface_speed.current.string` | link speed |
| `smart_support.available` / `smart_support.enabled` | SMART supported / enabled |

**Constraint:** `smartctl` returns a non-zero exit code in several non-fatal situations (for example when the overall-health self-assessment has failed, which is precisely the case we care about). The implementation therefore ignores the exit code and parses the JSON, treating unparsable output — not a non-zero exit — as the failure condition.

#### Path B — NVMe SMART log page (VFIO-attached NVMe)

Applies to NVMe attached over `pcie://`. There is no `/dev` name, so the SMART / Health Information log page (log ID `0x02`) is read directly through the NVMe admin command path that io-engine already uses.

```
User (grpcurl / client)
   |   GetPoolHealth("pool-node-0")
   v
gRPC server: PoolRpc.GetPoolHealth            [grpc/v1/pool.rs]
   |
   v
find the pool          finder()
   |
   v
get disk list          pool.disks()   ->  "pcie://...."
   |
   v
find the device        device_lookup(name)  ->  BlockDevice
   |
   v
device_health()                               [bdev/device.rs]
   |   driver is "nvme"  (no /dev name)
   v
open a handle, READ ONLY
   UntypedBdevHandle::open_with_bdev(bdev, false)
   |
   v
make a 512 byte buffer (DmaBuf)
   |
   v
nvme_get_smart(buffer)                         [core/handle.rs]
   |   set opcode = GET_LOG_PAGE (0x02)
   |   set log id = 0x02 (SMART), size = 512 bytes
   v
nvme_admin(cmd, buffer)          (this code already existed)
   |
   v
spdk_bdev_nvme_admin_passthru_ro(...)   ->  ask the NVMe disk
   |   wait for the answer (completion callback)
   v
the 512 byte SMART page comes back
   |
   v
DeviceHealth::from_nvme_smart(page)  ->  fill DeviceHealth
   |
   v
nvme_identify_ctrlr()             (already implemented)
   |   4096 byte Identify Controller data
   |   MN / SN / FR / TNVMCAP  ->  DeviceInfo
   |   WCTEMP / CCTEMP        ->  temperature thresholds
   v
back to handler  ->  DiskHealth { uri, supported, health }
   |
   v
GetPoolHealthResponse  ->  send to user
```

**Log page parsing.** The SMART log page is a fixed 512-byte structure with each value at a defined offset (byte 0 is the critical warning bitmap, bytes 1–2 the composite temperature, byte 4 the available spare threshold, byte 5 the percentage used, and so on). Each field is read from its fixed offset into `DeviceHealth`. Buffers shorter than 512 bytes are rejected rather than parsed partially.

**Device identity.** The SMART log page carries counters only — it contains no model or serial number. The identity fields are therefore taken from the Identify Controller data structure via the existing `nvme_identify_ctrlr()`: model number (`MN`), serial number (`SN`), firmware revision (`FR`) and total capacity (`TNVMCAP`), all at fixed offsets in the 4096-byte response. The same structure supplies the warning and critical composite temperature thresholds (`WCTEMP`, `CCTEMP`), which are stored in Kelvin and converted to Celsius. This is a second admin command on the same read-only handle; both are issued before the handle is dropped. If the Identify call fails, the health counters are still returned and only `info` is left absent — identity is useful context, not a precondition for reporting wear.

The handle is opened **read-only** (`open_with_bdev(bdev, false)`) so that reading health cannot interfere with the pool that is already using the device, and both admin commands use the read-only passthru variant.

#### Combined Flow

```
                 GetPoolHealth (gRPC)
                        |
                 find pool + disks
                        |
                 device_health()
                        |
         +--------------+---------------+
         |                              |
   driver aio/uring               driver nvme (VFIO)
   name /dev/...                  no /dev name
         |                              |
   smartctl --json                open handle (read only)
         |                        nvme_get_smart()
   read JSON                      GET_LOG_PAGE 0x02
         |                        nvme_admin ->
         |                        spdk_bdev_nvme_admin_passthru_ro
         |                              |
         |                        read 512 byte page
         |                              |
   info + attributes            nvme_identify_ctrlr()
   from same JSON               -> info + temp thresholds
         +--------------+---------------+
                        |
              DeviceHealth (+ info, + attributes)
                        |
                    DiskHealth
                        |
              GetPoolHealthResponse -> user
```

#### gRPC / Protobuf Interface

One RPC is added to the existing `PoolRpc` service in `protobuf/v1/pool.proto`:

```protobuf
rpc GetPoolHealth (GetPoolHealthRequest) returns (GetPoolHealthResponse) {}
```

New messages:

- `GetPoolHealthRequest { name, uuid }` — pool name, with optional uuid for disambiguation.
- `DeviceInfo { ... }` — the static identity fields listed in [Device Information](#device-information).
- `SmartAttribute { id, name, value, worst, threshold, raw_value, raw_string, failing_now, failed_before }` — one per attribute, as listed in [SMART Attributes and Thresholds](#smart-attributes-and-thresholds).
- `DeviceHealth { ... }` — the fields listed in [Data Model](#data-model), including `DeviceInfo info` and `repeated SmartAttribute smart_attributes`.
- `DiskHealth { disk_uri, supported, health }` — one per backing disk.
- `GetPoolHealthResponse { repeated DiskHealth disks }`.

Fields that a device class does not report use `optional` scalars so that "absent" is distinguishable from zero on the wire — the distinction matters for exactly the values an operator acts on, since a `media_errors` of `0` and an unknown `media_errors` are very different answers. `smart_attributes` is a repeated field and is simply empty for device classes that have no attribute table.

The addition is backwards compatible: no existing message or RPC is modified, so older clients are unaffected.

#### Error Handling

If a disk cannot produce health data for any reason — `smartctl` missing from the image, the device does not implement SMART, the handle open fails, the admin command is rejected, or the output cannot be parsed — that disk's entry is returned with `supported = false` and no health payload. The overall RPC still succeeds. This is deliberate: a pool striped across a SMART-capable disk and a SMART-less cloud volume should still tell the operator what it knows about the first one.

The implementation never synthesises or defaults a health value. An absent field is absent, not zero.

#### Concurrency and Locking

Both paths are invoked from the gRPC handler, not from the I/O hot path. Path A spawns an external process and blocks only the calling task. Path B opens a **read-only** handle so it does not contend with the pool's existing use of the device, and issues a single admin command whose completion is awaited via the existing callback mechanism. Health reads are expected to be occasional — on operator demand — rather than continuous, which keeps the cost off the reactor's critical path.

#### File-Level Changes

**io-engine**

| File | Change |
| ---- | ------ |
| `core/device_health.rs` (new) | `DeviceHealth`, `DeviceInfo`, `SmartAttribute`, the `smartctl` reader, the JSON parser, the 512-byte log-page parser, the Identify Controller field extraction, unit tests |
| `core/block_device.rs` | Add `device_health()` to the `BlockDevice` trait with a default implementation |
| `core/handle.rs` | Add `nvme_get_smart()` (modelled on `nvme_identify_ctrlr`, reusing the existing `nvme_admin`) |
| `core/mod.rs` | Declare the module and re-export `DeviceHealth` |
| `bdev/device.rs` | Implement `device_health()` — `smartctl` path and VFIO log-page path |
| `grpc/v1/pool.rs` | `GetPoolHealth` handler, type conversions, `disks()` accessor |

**spdk-rs**

| File | Change |
| ---- | ------ |
| `src/nvme.rs` | Enable `GET_LOG_PAGE = 0x02` (previously commented out) |

**apis**

| File | Change |
| ---- | ------ |
| `protobuf/v1/pool.proto` | New RPC and messages |
| `src/v1.rs` | Re-export the new message names in the pool module |

#### Runtime Requirements

- `smartctl` (from `smartmontools`) must be present in the io-engine container image.
- The disk's `/dev` name must be visible inside the container.
- The container must hold the `SYS_RAWIO` capability in order to issue the underlying device commands.

#### Assumptions and Dependencies

- The pool's backing disk is already open by io-engine — that is, the pool is `Online`.
- For kernel-attached disks, the device genuinely supports SMART. Some cloud virtual disks do not; those correctly return `supported = false`.
- For VFIO NVMe, the controller responds to a standard SMART log page request. Log page `0x02` is mandatory in the NVMe specification, so this holds for any conformant device.

### Risks and Mitigations

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |
| `smartctl` missing from the image | Kernel-attached disk health cannot be read | Return `supported = false` rather than erroring; add `smartmontools` to the image as part of this change |
| Device does not implement SMART | No real values available | Return `supported = false`; never fabricate or default a value |
| Health read takes measurable time | Brief delay on a reactor core | Call health on demand only, off the I/O hot path; consider a timeout on the `smartctl` invocation |
| VFIO open path is new code | Possible surprises on real hardware | Test on real VFIO NVMe; open the handle read-only so it cannot clash with the running pool |
| `SYS_RAWIO` capability requirement | Widens the io-engine container's privileges | io-engine already runs privileged for SPDK device access, so this adds no new class of privilege; it should still be called out in deployment documentation |
| Admin passthru could in principle carry a harmful opcode | Device damage or data loss if misused | Only `GET LOG PAGE` is enabled, only log ID `0x02` is requested, and only the read-only passthru variant is used; the opcode is not exposed through any user-supplied parameter |
| Shelling out to an external binary | Process-spawn failures, parsing drift across `smartctl` versions | Parse the stable JSON output rather than human-readable text; treat parse failure as unsupported; pin the `smartmontools` version in the image |
| Health data exposed over gRPC | Serial numbers, firmware revisions and wear data become visible to any gRPC client — hardware inventory detail that was previously not obtainable through this API | The pool service is already an internal, node-local API with the same trust boundary; no new authentication surface is introduced. The identity fields are exactly what an operator needs to locate a failing disk, so the exposure is intentional rather than incidental |
| Vendor-specific attribute raw values are easy to misread | An operator or a downstream tool draws the wrong conclusion from a raw value whose encoding is vendor-defined | Report `value`, `worst` and `threshold` alongside every raw value so the normalised scale is always available; retain `raw_string` as rendered by `smartctl` rather than only the integer; do not interpret vendor encodings in io-engine |
| Attribute table enlarges the response | A pool with many disks returns a noticeably larger payload than the counters alone would | The table is a few dozen small entries per ATA disk and the RPC is on-demand rather than polled; if this becomes a problem, a request flag to omit attributes can be added compatibly |

## Graduation Criteria

**Provisional → Implementable**

- Design questions in this OEP resolved with maintainer review, in particular the reported field set: whether the `DeviceInfo` identity fields and the ATA attribute table cover what operators need, and whether anything listed should be dropped.
- Agreement that the `supported = false` degradation model is preferable to failing the RPC.
- POC demonstrating both paths on real hardware — one kernel-attached disk and one VFIO-attached NVMe device.

**Implementable → Implemented**

- `device_health()` implemented for both paths, with unit tests passing on captured fixtures for NVMe JSON, SATA attribute tables, SAS payloads, and the raw 512-byte log page.
- `GetPoolHealth` available and callable via `grpcurl`, returning counters, identity and attribute table.
- Verified on real VFIO-attached NVMe hardware, including a read-only health read while the pool is `Online` and serving I/O, with no measurable impact on pool I/O.
- BDD test for `GetPoolHealth` running in CI, including a pool mixing a SMART-capable and a SMART-less device.
- `smartmontools` present in the released image, and the `SYS_RAWIO` capability requirement documented in the user-facing docs.
- Field feedback gathered from operators on whether the normalised field set is sufficient, and the control-plane / CSI consumer work scoped even though it is delivered separately.

## Implementation History

- 2026-07-02: High-Level and Low-Level Design Documents drafted (v1.0)
- 2026-07-22: Reformatted as an OEP for community review
- 2026-07-28: Provisional OEP submitted as [openebs/openebs#4274](https://github.com/openebs/openebs/pull/4274); review by @tiagolobocastro raised device information and SMART attribute thresholds
- 2026-07-29: Device identity (`DeviceInfo`) and the SMART attribute table with thresholds added to the proposal in response to review

## Drawbacks

- **It introduces a runtime dependency on an external binary.** Path A shells out to `smartctl`, which adds `smartmontools` to the container image, adds a process-spawn to the request path, and couples correctness to the JSON output of a tool we do not control. A pure-library implementation would avoid this, at considerable cost in per-vendor quirk handling.
- **Two mechanisms mean two code paths to maintain and test.** The normalised `DeviceHealth` struct hides this from callers, but it does not remove the maintenance burden, and field coverage differs between paths in both directions: ATA devices do not report `percentage_used` or spare capacity, while NVMe devices have no attribute table and so report an empty `smart_attributes` list. A caller that wants to present a single uniform view still has to reason about which fields its hardware actually populates, and the VFIO path is additionally missing `link_speed`, `model_family` and `form_factor`.
- **The VFIO path exercises code that has not previously been used in production.** The admin-passthru mechanism ships today for `identify`, but issuing a log-page read against a device concurrently backing an online pool is new behaviour, and the blast radius of a mistake there is a live pool.
- **On its own, the feature is not yet actionable.** Without polling, history, metrics, or control-plane exposure, an operator must call the RPC manually to benefit. The value is only fully realised once the deferred follow-on work lands.
- **It widens the io-engine gRPC surface** for a feature that some deployments — for example, entirely cloud-virtual-disk-backed ones — can never use.

## Alternatives

**Use `smartctl` for everything.** Simplest to implement and maintain, single code path. Rejected because VFIO-attached NVMe devices have no `/dev` node and are detached from the kernel driver, so `smartctl` cannot reach them at all. This would exclude precisely the performance-oriented deployments most likely to care about drive wear.

**Use NVMe admin commands for everything.** Also a single code path, and no external binary dependency. Rejected because it only works for NVMe; SATA and SAS devices would be left with no health reporting, and those remain very common in Mayastor pools.

**Patch SPDK to expose a device-health abstraction.** Arguably the cleanest long-term home for this logic, and would benefit other SPDK consumers. Rejected for this proposal because it requires an upstream review cycle on a timeline we do not control, and would block the feature indefinitely. The chosen design deliberately requires no SPDK source change.

**Collect SMART data outside io-engine — a node-level DaemonSet, `node_exporter`'s smartmon collector, or similar.** Attractive because it keeps the data plane simple and reuses existing monitoring infrastructure. Rejected because such a collector cannot see VFIO-attached devices (the kernel no longer owns them), and because it has no knowledge of which disks back which Mayastor pool, so correlating a failing device with an affected pool would be left to the operator.

**Implement SMART parsing natively in Rust (`libatasmart` bindings or an equivalent crate) instead of invoking `smartctl`.** Would remove the external process and the image dependency. Rejected for the initial implementation because `smartmontools` encodes a large body of per-vendor attribute interpretation that would have to be reimplemented and maintained, and because its JSON output gives a stable machine-readable contract. This remains a reasonable follow-up if the process-spawn cost or image size proves problematic.

**Read health eagerly at pool import and cache it.** Would make the RPC cheap and constant-time. Rejected because health values are exactly the ones that change over time; a cached value is misleading precisely when it matters. On-demand reads with optional polling added later is the safer ordering.

## Infrastructure Needed

- **Container image change:** `smartmontools` must be added to the io-engine image build (Nix/Dockerfile) so that `smartctl` is available at runtime.
- **Capability and device-visibility review:** confirmation from the deployment/Helm owners that `SYS_RAWIO` and host `/dev` visibility are acceptable and correctly set in the shipped manifests.
- **CI hardware access:** the hardware-dependent tests need runners with (a) a real SATA or SAS disk, (b) a kernel-attached NVMe device, and (c) an NVMe device that can be bound to VFIO. Only the parsing tests can run on standard CI runners.
- **Cross-repository coordination:** changes span `io-engine`, `spdk-rs`, and `apis`, so the PRs will need to land in a coordinated order.

## Testing

### Unit tests

No hardware required; these run on standard CI runners against captured fixtures.

- Parse a captured NVMe `smartctl --json` payload and assert every mapped field.
- Parse a captured SATA attribute table and assert the mapped ATA attribute IDs (194, 5, 9, 12, 198).
- Parse a captured SAS payload and assert `scsi_grown_defect_list` maps to media errors.
- Parse a synthetic 512-byte NVMe SMART log page and assert every field offset.
- A log page shorter than 512 bytes is rejected rather than partially parsed.
- A failed SMART overall-health status maps to "not healthy".
- Malformed or empty `smartctl` output yields "not supported", not a panic.
- A non-zero `smartctl` exit code with valid JSON is still parsed successfully.
- Parse the information section of a captured SATA payload and assert every `DeviceInfo` field, including `rotation_rate = 0` mapping to solid state and `interface_speed.current.string` mapping to link speed.
- Assert `DeviceInfo` fields absent from a payload — `model_family` for an unrecognised drive, `form_factor` for NVMe — are reported absent rather than as empty strings.
- Parse a captured `ata_smart_attributes.table` and assert `id`, `name`, `value`, `worst`, `threshold` and both raw representations for every entry.
- `when_failed = "now"` sets `failing_now`, `"past"` sets `failed_before`, and `""` sets neither.
- An attribute whose `value` is at or below its `threshold` makes `is_healthy()` false even when `critical_warning` is `0` and the overall-health verdict passed.
- A SAS payload and an NVMe payload both yield an empty `smart_attributes` list rather than an error.
- Extract `DeviceInfo` and the temperature thresholds from a synthetic 4096-byte Identify Controller buffer, asserting `MN`/`SN`/`FR` are trimmed of padding and `WCTEMP`/`CCTEMP` are converted from Kelvin.
- A failed Identify call still yields the health counters, with `info` absent.

### Hardware and integration tests

- Kernel-attached SATA or SAS disk via `aio://`.
- Kernel-attached NVMe via `uring://` and `aio://`.
- A device referenced by a `/dev/disk/by-path/...` symlink, confirming Path A selection.
- VFIO-attached NVMe via `pcie://`, including a read-only health read while the pool is `Online` and serving I/O, verifying no disruption to in-flight I/O.
- A device with no SMART support (for example a cloud virtual disk), confirming `supported = false`.
- io-engine running without `smartctl` in the image, confirming graceful degradation rather than a failed RPC.
- On a real SATA disk, cross-check the reported `DeviceInfo` and attribute table against `smartctl -a` run directly on the host, confirming the JSON mapping matches the human-readable output an operator would compare against.
- On real VFIO NVMe, cross-check `model_number`, `serial_number` and `firmware_version` against the values reported before the device was bound to VFIO.

### BDD tests

New scenarios under `tests/bdd/features/pool/health/`:

```gherkin
Feature: DiskPool health reporting

  Scenario: Health is reported for a SMART-capable disk
    Given a DiskPool backed by a SMART-capable disk
    When the pool health is requested
    Then the disk should be reported as supported
    And the response should include the device model, serial number and firmware version
    And the wear and error counters should be populated

  Scenario: A pool mixing SMART-capable and SMART-less disks still answers
    Given a DiskPool backed by one SMART-capable disk and one disk without SMART support
    When the pool health is requested
    Then the call should succeed
    And there should be one entry per backing disk
    And only the SMART-capable disk should be reported as supported

  Scenario: SMART attributes carry their thresholds
    Given a DiskPool backed by a SATA disk
    When the pool health is requested
    Then each reported SMART attribute should carry a value, worst and threshold

  Scenario: Health of an unknown pool is an error
    Given a node with no pool named "missing"
    When the pool health is requested for "missing"
    Then the call should fail with a not-found status
```

Backwards compatibility is asserted separately: an older client using the pool service is unaffected by the new RPC.
