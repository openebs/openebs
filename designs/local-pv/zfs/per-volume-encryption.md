---
oep-number: 4340
title: Per-PersistentVolume Encryption Keys for LocalPV-ZFS
authors:
  - "@rdegez"
owners:
  - "@rdegez"
editor: "@rdegez"
creation-date: 2026-10-05
last-updated: 2026-10-05
status: provisional
---

# Per-PersistentVolume Encryption Keys for LocalPV-ZFS

## Table of Contents

- [Per-PersistentVolume Encryption Keys for LocalPV-ZFS](#per-persistentvolume-encryption-keys-for-localpv-zfs)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Current Behaviour](#current-behaviour)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
    - [API](#api)
    - [Key Sources and Precedence](#key-sources-and-precedence)
    - [Provisioning (controller)](#provisioning-controller)
    - [Create and Mount (node)](#create-and-mount-node)
    - [Snapshots and Clones](#snapshots-and-clones)
    - [Deletion and Key Lifecycle](#deletion-and-key-lifecycle)
    - [KMS Abstraction and Vault Provider](#kms-abstraction-and-vault-provider)
    - [Helm and RBAC](#helm-and-rbac)
    - [Risks and Mitigations](#risks-and-mitigations)
  - [Implementation Plan](#implementation-plan)
  - [Test Plan](#test-plan)
  - [Docs](#docs)
  - [Graduation Criteria](#graduation-criteria)
  - [Implementation History](#implementation-history)
  - [Drawbacks](#drawbacks)
  - [Alternatives](#alternatives)
  - [Infrastructure Needed](#infrastructure-needed)
  - [Known Limitations and Open Questions](#known-limitations-and-open-questions)

## Summary

LocalPV-ZFS can encrypt volumes today only with one static key per StorageClass, read from a `keylocation` file that must exist on every node. This proposal adds **per-PersistentVolume** ZFS native encryption: each PV is encrypted with its own 32-byte key, taken from one of three sources — a Kubernetes Secret referenced by the PVC, a driver-generated Secret, or an external KMS (HashiCorp Vault KV v2) — and the key is reloaded at mount time so that encrypted volumes survive node reboots.

The change is additive and opt-in. With none of the new StorageClass parameters or PVC annotation set, behaviour is unchanged, and the existing `keylocation` mode keeps working. The KMS part is designed as a separate phase that can be accepted, deferred or dropped independently of the rest.

## Motivation

A single key per StorageClass means:

- **No crypto-erase per volume.** Destroying one volume's key is how encrypted storage guarantees that its data is unrecoverable; with a shared key this is impossible without affecting every volume of the class.
- **A large blast radius.** A leaked or rotated key concerns every volume of the StorageClass.
- **No tenant separation.** A PVC owner cannot bring or hold the key of their own volume.
- **Node-local key files.** The key file has to be provisioned on every node, and the chart mounts it from a `hostPath` (`/home/keys` by default). Users have hit this: the default path is read-only on Talos and its contents are not kept across OS upgrades ([zfs-localpv#477]), and the key file permissions are too open ([zfs-localpv#426]).

Per-volume keys also make encryption usable by operators and StatefulSets that create PVCs on their own through `volumeClaimTemplates`, where nothing can be configured per PVC.

### Goals

- A distinct key per PV, from a user-provided Kubernetes Secret, a driver-generated and driver-managed Secret, or a KMS backend.
- Key material is never stored in the ZFSVolume CR, on the node disk or in process arguments: it is handed to `zfs` over stdin.
- Encrypted volumes survive node reboots.
- Works with the existing snapshot and clone paths.
- Fail closed: never create a plaintext volume when a key source was requested.
- No new Go module dependency.
- Fully backward compatible and opt-in.

### Non-Goals

- **Automated key rotation.** There is no CSI trigger for it, and an interrupted `zfs change-key` can make data unrecoverable without a two-phase protocol. A manual runbook is documented instead.
- **Re-encrypting existing data.** `zfs change-key` re-wraps the master key only.
- **Changing the key source of an existing volume.**
- **Backup and restore through Velero.** See [Known Limitations](#known-limitations-and-open-questions): the OpenEBS Velero plugin drops the key source on restore, and the backup stream is not encrypted (raw sends are proposed separately in [zfs-localpv#774]).
- **Key formats other than hex** for the per-volume key. The existing StorageClass `keyformat` (`passphrase`/`raw`/`hex`) is unchanged.

## Current Behaviour

A StorageClass sets `encryption`, `keyformat` and `keylocation`, for example `keylocation: file:///home/keys/key`. Every volume of that class is created with the same key file, which must be present on every node; the node DaemonSet mounts the key directory from a `hostPath` (`zfsNode.encrKeysDir`). There is no notion of a key per volume, and nothing in the driver loads a key that is not available.

## Proposal

### User Stories

#### Story 1 — bring your own key

As an application owner, I create a Secret holding a key and annotate my PVC with its name. My volume is encrypted with my key; deleting the Secret (after the volume) destroys any possibility of reading the data.

#### Story 2 — zero configuration for StatefulSets and operators

As a platform operator, I publish a StorageClass with `autoCreateEncryptionKey: "true"`. Every PVC created from it — including the ones an operator or a StatefulSet creates for me — gets its own key, with nothing to configure per PVC.

#### Story 3 — keys out of etcd

As a security officer, I require encryption keys to live in our KMS rather than in Kubernetes Secrets (etcd). A StorageClass with `encryptionKMSID` makes the driver store one key per volume in our Vault-compatible KMS.

### API

**StorageClass parameters** (all optional, all require the existing `encryption` parameter):

| Parameter | Meaning |
|---|---|
| `autoCreateEncryptionKey: "true"` | The driver generates the key and stores it in a Secret it manages. |
| `encryptionKMSID: <id>` | The driver stores the key in the KMS backend `<id>` (phase 4). |

**PVC annotation**: `local.zfs.openebs.io/encryption-secret: <name>` names a Secret in the PVC's namespace whose data key `key` holds 64 hex characters.

**ZFSVolume** (`VolumeInfo`, v1 and v1alpha1) gains two optional fields that record where the key is — never the key itself:

- `encryptionKeyRef: {name, namespace}` — a Secret reference (Secret and auto modes), following the usual Kubernetes shape for secret references;
- `encryptionKMSID` — the KMS backend (phase 4). Mutually exclusive with `encryptionKeyRef`.

Both are optional, so existing CRs stay valid and no conversion is needed.

**PV marker**: encrypted volumes carry `openebs.io/encrypted: "true"` in the PV's `spec.csi.volumeAttributes`, a boolean marker only.

### Key Sources and Precedence

The controller resolves the key source in a fixed order, so one StorageClass can serve every mode:

1. the PVC annotation (user Secret), else
2. `encryptionKMSID` (KMS), else
3. `autoCreateEncryptionKey` (driver-managed Secret).

A warning is logged when more than one source is set.

### Provisioning (controller)

At CreateVolume the controller, which learns the PVC through the external-provisioner's `--extra-create-metadata`:

1. reads the three signals; a non-boolean `autoCreateEncryptionKey` is rejected with `InvalidArgument`;
2. **fails closed**: a key source without the `encryption` parameter is rejected with `InvalidArgument`, instead of provisioning a plaintext volume; so is `encryption` with no key source at all and no legacy `keylocation`;
3. resolves the source:
   - **Secret**: validates it (present, 64 hex characters after trimming surrounding whitespace) and fails fast with `InvalidArgument` otherwise;
   - **KMS**: generates the key and stores it in the backend before the node creates the dataset;
   - **auto**: generates the key and stores it in an **immutable** Secret `zfs-enc-<volume-id>` in the driver namespace, labelled `local.zfs.openebs.io/auto-managed=true`; idempotent across retries, and it refuses to adopt a pre-existing Secret that is not labelled as managed;
4. forces `keyformat=hex`, records the reference on the CR, and does not persist an unused legacy `keylocation`;
5. binds the auto Secret to the ZFSVolume with an **OwnerReference** (re-asserted on idempotent retries);
6. returns `openebs.io/encrypted: "true"` in the volume context.

A PVC read error is fatal only when the annotation is the only possible source.

### Create and Mount (node)

- **Create**: the dataset is created with `keyformat=hex` and `keylocation=prompt`, the key piped to `zfs create` on stdin.
- **Mount**: `EnsureKeyLoaded` runs `zfs load-key` on the encryption root when the key is not loaded, which is what makes an encrypted volume survive a reboot (a `prompt` dataset does not load its key on pool import). "Key already loaded" is treated as success, as concurrent mounts race on a shared encryption root.
- **Zvols**: after `load-key`, udev creates `/dev/zvol/<pool>/<name>` asynchronously; mounting too early failed with ENOENT after a reboot until a later kubelet retry. The node now waits for the device node, bounded (10 s by default, `ZFS_ZVOL_DEVICE_WAIT_TIMEOUT`) and cancelled with the request context.
- **Wrong key**: a key that no longer matches its dataset fails the mount with an explicit "encryption key … is incorrect" error.

### Snapshots and Clones

Snapshots are encrypted with their volume. A clone, from a volume or from a snapshot, shares its parent's encryption root and key source; `zfs clone` needs the parent key loaded, which is not the case after a reboot until the parent is mounted, so the node loads the parent key before cloning.

### Deletion and Key Lifecycle

- **auto**: the managed Secret is garbage-collected by Kubernetes through its OwnerReference whenever the ZFSVolume is deleted — normal deletion and out-of-band CR deletion alike. No finalizer, no node-side deletion code, and no `delete` RBAC.
- **KMS**: `DeleteVolumeAndKey` deletes the CR, then removes the key from the backend, best effort, so a slow KMS never blocks deletion and the key of a volume whose CR delete failed is never removed. A CreateVolume rollback uses plain `DeleteVolume` and **keeps** the key, so the provisioner's retry of the same volume reuses it instead of minting a new one.
- **Secret**: user Secrets are never touched.
- `zfs destroy` does not need the key.

### KMS Abstraction and Vault Provider

Phase 4 introduces `pkg/kms`, a small key-store abstraction — smaller than ceph-csi's since ZFS does its own key wrapping: we need a per-volume key store, not data-key wrapping.

```go
type KeyStore interface {
    GetOrCreateKey(ctx context.Context, volumeID string) (string, error)
    FetchKey(ctx context.Context, volumeID string) (string, error)
    RemoveKey(ctx context.Context, volumeID string) error
    Destroy()
}
```

The Secret reader becomes the `k8s-secret` provider, and a `vault` provider implements HashiCorp Vault KV v2 on the standard library `net/http`, storing each key at `<backend>/<keyPrefix>/<volume-id>` (defaults `secret` and `zfs-localpv`). Backends are described in a ConfigMap `openebs-zfs-kms-config` in the driver namespace, one section per KMS id, re-read on every key operation.

- **Auth**: `token` (inline — warned —, from a Secret, or `VAULT_TOKEN`), `kubernetes` (ServiceAccount JWT login), `cert` (Vault TLS-certificate login) and `mtls`, for KV endpoints that authenticate purely at the TLS layer and have no login route, such as OVHcloud OKMS. Custom CA, Vault namespaces, and an optional (warned) skip-verify.
- **Eventually consistent backends**: after storing a key, `GetOrCreateKey` waits until it reads back (bounded to 30 s), because some backends (OKMS) briefly return 404 right after a write. Strongly consistent backends never wait.
- **Rate limits**: 429 and 503 are retried in-process with capped exponential backoff and jitter (up to 8 attempts, 0.5 s to 8 s), honouring `Retry-After`, and cut short by the request context; logins retry within a 30 s budget.
- The encryption kube client uses QPS 100 / Burst 200: with client-go's defaults, client-side throttling alone added ~17 s per lookup at ~90 concurrent volumes.

### Helm and RBAC

- Controller: `get configmaps` (KMS config), and a **namespaced** Role in the driver namespace with `get`/`create`/`update` on Secrets for auto mode. The controller's existing cluster-wide `get`/`list` on Secrets is reused for validation.
- Node: `get secrets` cluster-wide (a user Secret lives in the PVC's namespace; `get` only, not `list`) and `get configmaps`.
- Optional `kms.configs` values render the KMS ConfigMap (empty by default). Auth material stays in Secrets referenced by name and is never rendered from values.

### Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Secret-backed keys live in etcd (base64). | Documented; recommend etcd encryption at rest, or the KMS mode, when key custody matters. |
| A plaintext volume created by mistake. | Fail closed on any key source without `encryption`, and on `encryption` without a key source. |
| The auto Secret is the only copy of a key. | `immutable: true` blocks corrupting edits. A manual `kubectl delete` of it while the volume lives is not blocked — a finalizer would, but it caused stuck-`Terminating` windows on every teardown and required node `delete` rights; the "do not delete" contract is documented instead. |
| A key that no longer matches. | Hex validation at create and at every load-key; an explicit wrong-key error instead of a bare `zfs` failure. |
| Cluster-wide Secret read. | `get` only, not `list`, on the node; auto-mode write rights are namespaced. |
| KMS unavailable. | Provisioning fails cleanly and is retried; mounts need the KMS, so it must be available and **persistent** (a KMS losing its data makes the volumes permanently unmountable — the same as losing any key). |
| Key removal can fail. | Best effort, logged. Under a burst of deletions OKMS answered HTTP 500 to some deletes, leaving inert keys behind; retrying idempotent requests on 5xx is a planned improvement. |
| Downgrade to a release without the new fields. | Documented as unsupported: structural-schema pruning would drop the fields from existing CRs and make encrypted volumes unmountable. |

## Implementation Plan

Four pull requests, each building and passing the tests on its own, in this order. Phases 1–3 do not contain any KMS code; phase 4 can be dropped without leftovers.

1. **Secret mode** — `encryptionKeyRef` on `VolumeInfo` (v1 and v1alpha1) with deepcopy and CRD manifests; node side (create with the key on stdin, load-key at mount, zvol device wait, wrong-key error, node RBAC); controller side (annotation, validation, fail closed, PV marker); docs.
2. **Auto mode** — `autoCreateEncryptionKey`, the immutable managed Secret, its OwnerReference, the namespaced Role; docs and a StatefulSet sample.
3. **Clones** — load the parent key before `zfs clone`; docs, including the Velero limitation.
4. **KMS** — `pkg/kms` (behaviour-neutral refactor of the Secret reader), the Vault provider, `encryptionKMSID` wiring and `DeleteVolumeAndKey`, the kube client rate limits, the optional Helm ConfigMap, docs.

## Test Plan

- **Unit** (existing): create-argument builders (`prompt` vs legacy file); key validation and trimming; `UsesManagedKey`; auto Secret creation, labelling, immutability, idempotency and refusal to adopt an unmanaged Secret (fake clientset); zvol device wait (appears, times out, context cancelled); `k8s-secret` provider; Vault provider against an `httptest` KV v2 server (get-or-create/fetch/remove, `cert` login, an mTLS server requiring the client certificate, 429 retry, context cancellation, `Retry-After`).
- **Unit** (to add): the parent-key guard of `EnsureParentKeyLoaded`.
- **BDD** (to add, in `tests/` so it runs in the existing minikube + ZFS CI): provision and mount with a user Secret and in auto mode; fail-closed and missing-Secret rejections; unique keys across StatefulSet replicas; clone of an encrypted volume. A KMS scenario would need a Vault or OpenBao container in CI (see [Infrastructure Needed](#infrastructure-needed)).
- **Manual e2e** (done, single-node cluster with a real ZFS pool): all three modes on filesystem and raw block volumes; fail-closed and hardening cases; snapshot lifecycle (source PVC deleted while snapshots exist, clone of a surviving snapshot); **node reboot** (every volume remounted on the first attempt, no zvol ENOENT, data read back); KMS against OpenBao and OVHcloud OKMS, including 90 volumes provisioned concurrently on one node (~3.5 min, against ~8.7 min without the 429 retry) and a live integration test against OKMS; upgrade from the stock chart; and the Velero investigation described below.

## Docs

A new `docs/encryption.md` covering the three modes, choosing a mode, the hybrid precedence, snapshots and clones, the Velero limitation, a manual key-rotation runbook, security notes, upgrade and downgrade notes and known limitations; samples for each mode; a `CHANGELOG.md` entry.

## Graduation Criteria

- **implementable**: this OEP approved, including a decision on whether the KMS phase is wanted in-tree.
- **implemented**: phases 1–3 (and phase 4 if accepted) merged with unit tests, BDD coverage of the Secret and auto modes and of clones, docs and a changelog entry.

## Implementation History

- 2026-07: prototype and internal review rounds on a fork.
- 2026-09: rebased onto 2.12.0-develop and re-validated end to end, including node reboots, OVHcloud OKMS, and a Velero backup/restore investigation.
- 2026-09-24: discussion opened in [zfs-localpv#772].
- 2026-09-27: maintainer go-ahead to raise an OEP, then the PRs.
- 2026-10-05: tracking issue [OEP 4340] opened.
- TBD: OEP submitted.

## Drawbacks

- More configuration surface: two StorageClass parameters, one PVC annotation, two CR fields, and a KMS ConfigMap.
- Secret-backed modes keep keys in etcd, which some users may not expect.
- The KMS phase adds an in-tree HTTP client to maintain.

## Alternatives

- **Status quo, one key per StorageClass.** Does not provide per-volume crypto-erase, isolation or tenant keys.
- **External key delivery** (external-secrets, Secrets Store CSI driver, Vault Agent writing key files on nodes). These deliver files or Secrets but cannot create a key per volume at provisioning time, nor tie its lifecycle to the volume; they could still feed the Secret mode.
- **A ceph-csi style KMS layer with data-key wrapping.** Unneeded: ZFS already wraps its master key, so a per-volume key store is enough.
- **A finalizer on the auto Secret.** Tried and dropped: it caused stuck-`Terminating` Secrets on teardown and required node `delete` rights.
- **Leaving KMS integration to external operators.** Possible; this is why phase 4 is separable.

## Infrastructure Needed

None for phases 1–3. BDD coverage of the KMS phase would need a Vault or OpenBao container in the CI job.

## Known Limitations and Open Questions

- **Backup and restore through Velero are not supported.** Tested with Velero 1.14 and velero-plugin 3.6.0 on a Secret-mode, an auto-mode, a KMS-mode and an unencrypted control volume:
  - restore fails for the three key modes, while the control volume restores intact. The plugin rebuilds the restored ZFSVolume with its vendored zfs-localpv API types (v1.6.1, 2021), which drop the key source, so `zfs recv` fails (`Cannot use 'prompt' keylocation because stdin is in use`);
  - backups are stored **in clear text**: the backup path uses a non-raw `zfs send`, which decrypts on the fly — also reported in [zfs-localpv#430], and true of the existing StorageClass encryption. Raw sends (`zfs send -w`), which keep backups encrypted, are proposed in [zfs-localpv#774]. For per-volume keys, a raw backup can only be restored with the volume's original key, which the auto and KMS modes delete together with the volume, and the plugin must carry the key source; supporting restore therefore still needs an updated plugin and key escrow or retention. The restore step proposed in [zfs-localpv#774] (reloading the key from the pool's `keylocation`, then re-attaching the volume to the pool's encryption root) must also skip volumes that have their own key.
- **Auto Secret orphan window**: the OwnerReference can only be set once the CR exists, so a controller crash between the two, never followed by a retry, leaves an ownerless (but deletable) Secret. A periodic sweep would close it.
- **Orphaned KMS key** for a PVC deleted before any PV ever bound: the key is created before provisioning and kept on rollback for the retry, and no DeleteVolume ever runs for it. Inert; removable out of band.
- **Field exclusivity** is enforced by the controller's precedence, not by CRD validation.

Questions for the maintainers:

1. Is an in-tree KMS backend (phase 4) wanted, or should external key management stay out of the driver?
2. Is the `local.zfs.openebs.io/` prefix right for the PVC annotation?
3. Raw backups are tracked in [zfs-localpv#774]; should the Velero plugin update (carrying the key source on restore) be tracked as its own issue?

[OEP 4340]: https://github.com/openebs/openebs/issues/4340
[zfs-localpv#426]: https://github.com/openebs/zfs-localpv/issues/426
[zfs-localpv#430]: https://github.com/openebs/zfs-localpv/issues/430
[zfs-localpv#477]: https://github.com/openebs/zfs-localpv/issues/477
[zfs-localpv#772]: https://github.com/openebs/zfs-localpv/issues/772
[zfs-localpv#774]: https://github.com/openebs/zfs-localpv/issues/774
