---
oep-number: 4340
title: Per-PersistentVolume Encryption Keys for LocalPV-ZFS
authors:
  - "@rdegez"
owners:
  - "@rdegez"
editor: "@rdegez"
creation-date: 2026-10-05
last-updated: 2026-10-22
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
    - [Key Lifecycle](#key-lifecycle)
    - [Protecting the Generated Keys](#protecting-the-generated-keys)
    - [External KMS through the External Secrets Operator](#external-kms-through-the-external-secrets-operator)
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
  - [Known Limitations](#known-limitations)

## Summary

LocalPV-ZFS can encrypt volumes today only with one static key per StorageClass, read from a `keylocation` file that must exist on every node. This proposal adds **per-PersistentVolume** ZFS native encryption: each PV is encrypted with its own 32-byte key, taken from a Kubernetes Secret — either one referenced by the PVC, or one the driver generates and manages — and the key is reloaded at mount time so that encrypted volumes survive node reboots.

Keys stay in Kubernetes Secrets end to end. Integration with an external KMS is left to the [External Secrets Operator] (ESO), in both directions: pulling a user key from the KMS, and backing the generated keys up to it.

The change is additive and opt-in. With neither the new StorageClass parameter nor the PVC annotation set, behaviour is unchanged, and the existing `keylocation` mode keeps working.

## Motivation

A single key per StorageClass means:

- **No crypto-erase per volume.** Destroying one volume's key is how encrypted storage guarantees that its data is unrecoverable; with a shared key this is impossible without affecting every volume of the class.
- **A large blast radius.** A leaked or rotated key concerns every volume of the StorageClass.
- **No tenant separation.** A PVC owner cannot bring or hold the key of their own volume.
- **Node-local key files.** The key file has to be provisioned on every node, and the chart mounts it from a `hostPath` (`/home/keys` by default). Users have hit this: the default path is read-only on Talos and its contents are not kept across OS upgrades ([zfs-localpv#477]), and the key file permissions are too open ([zfs-localpv#426]).

Per-volume keys also make encryption usable by operators and StatefulSets that create PVCs on their own through `volumeClaimTemplates`, where nothing can be configured per PVC.

### Goals

- A distinct key per PV, from a user-provided Kubernetes Secret or a driver-generated and driver-managed Secret.
- Key material is never stored in the ZFSVolume CR, on the node disk or in process arguments: it is handed to `zfs` over stdin.
- A driver-managed key lives exactly as long as its data, and is protected against accidental deletion.
- Encrypted volumes survive node reboots.
- Works with the existing snapshot and clone paths.
- Fail closed: never create a plaintext volume when a key source was requested.
- Works with an external KMS through ESO, without any KMS code in the driver.
- No new Go module dependency.
- Fully backward compatible and opt-in.

### Non-Goals

- **An in-tree KMS client.** External key management is delegated to ESO; see [Alternatives](#alternatives).
- **Automated key rotation.** There is no CSI trigger for it, and an interrupted `zfs change-key` can make data unrecoverable without a two-phase protocol. A manual runbook is documented instead.
- **Re-encrypting existing data.** `zfs change-key` re-wraps the master key only.
- **Changing the key source of an existing volume.**
- **Backup and restore through Velero.** See [Known Limitations](#known-limitations): the OpenEBS Velero plugin drops the key source on restore, and the backup stream is not encrypted (raw sends are proposed separately in [zfs-localpv#774]).
- **Key formats other than hex** for the per-volume key. The existing StorageClass `keyformat` (`passphrase`/`raw`/`hex`) is unchanged.

## Current Behaviour

A StorageClass sets `encryption`, `keyformat` and `keylocation`, for example `keylocation: file:///home/keys/key`. Every volume of that class is created with the same key file, which must be present on every node; the node DaemonSet mounts the key directory from a `hostPath` (`zfsNode.encrKeysDir`). There is no notion of a key per volume, and nothing in the driver loads a key that is not available.

## Proposal

### User Stories

#### Story 1 — bring your own key

As an application owner, I create a Secret holding a key and annotate my PVC with its name. My volume is encrypted with my key; deleting the Secret (after the volume) destroys any possibility of reading the data.

#### Story 2 — zero configuration for StatefulSets and operators

As a platform operator, I publish a StorageClass with `autoCreateEncryptionKey: "true"`. Every PVC created from it — including the ones an operator or a StatefulSet creates for me — gets its own key, with nothing to configure per PVC.

#### Story 3 — keys held in our KMS

As a security officer, I want the source of truth, or a recovery copy, of every key to live in our KMS. With ESO, an `ExternalSecret` materialises a key from the KMS for a PVC, and a single `PushSecret` copies every generated key to the KMS.

### API

**StorageClass parameter** (optional, requires the existing `encryption` parameter):

| Parameter | Meaning |
|---|---|
| `autoCreateEncryptionKey: "true"` | The driver generates the key and stores it in a Secret it manages. |

**PVC annotation**: `encryption.openebs.io/secret-name: <name>` names a Secret in the PVC's namespace whose data key `key` holds 64 hex characters.

**ZFSVolume** (`VolumeInfo`, v1 and v1alpha1) gains one optional field that records where the key is — never the key itself: `encryptionKeyRef: {name, namespace}`, a Secret reference following the usual Kubernetes shape. It is optional, so existing CRs stay valid and no conversion is needed.

**PV marker**: volumes encrypted by the driver carry `openebs.io/encrypted` in the PV's `spec.csi.volumeAttributes`: `"volume"` for a per-volume key (a clone shares its source volume's key), `"storageclass"` for the StorageClass-level `keylocation`. A volume only encrypted by its pool or parent dataset is not marked, since the driver does not set that encryption up; a `"pool"` value would need the node to report the dataset's actual encryption root, and is left for later.

**Driver-managed Secret**: `zfs-enc-<volume>` in the driver namespace, immutable, labelled `encryption.openebs.io/auto-managed=true`, with two data entries: `key` (same format as a user Secret) and `volume` (the volume name, used to back the key up, see [below](#external-kms-through-the-external-secrets-operator)).

**Engine-neutral names**: the annotation, labels and break-glass annotation all use the `encryption.openebs.io/` prefix, so other engines (Mayastor, and later LVM or rawfile) can reuse the same contract, along the lines discussed in [mayastor#2027]: a key Secret referenced by a PVC annotation in the PVC's namespace, clones sharing their source's key, ESO for external KMS. The Secret contents may differ per engine (ZFS takes a 32-byte hex key for `aes-256-gcm`, SPDK's crypto vbdev takes cipher-specific keys), but the way users reference and manage the key stays the same.

### Key Sources and Precedence

The controller resolves the key source in a fixed order, so one StorageClass can serve both modes:

1. the PVC annotation (user Secret), else
2. `autoCreateEncryptionKey` (driver-managed Secret).

A warning is logged when both are set. If the annotation references a missing or invalid Secret, or if the PVC cannot be read, provisioning fails; it never falls back to a generated key.

A key can be shared on purpose: several PVCs can reference the same Secret, for example through an annotation in a StatefulSet's `volumeClaimTemplate`, which is copied to every replica's PVC. Since the driver never deletes a user Secret, sharing is safe, at the cost of per-volume crypto-erase. A generated key is always per volume.

### Provisioning (controller)

At CreateVolume the controller, which learns the PVC through the external-provisioner's `--extra-create-metadata`:

1. reads both signals: a non-boolean `autoCreateEncryptionKey` is rejected with `InvalidArgument`, and so is an annotation that is empty or does not lead to a valid Secret (see step 3); a PVC that cannot be read fails the provisioning (it is retried), since it may name its own key;
2. **fails closed**: a key source without the `encryption` parameter is rejected with `InvalidArgument`, instead of provisioning a plaintext volume; so is `encryption` with no key source at all and no legacy `keylocation`;
3. resolves the source:
   - **Secret**: validates it (present, 64 hex characters after trimming surrounding whitespace) and fails fast with `InvalidArgument` otherwise;
   - **auto**: records the reference to `zfs-enc-<volume>` only; the key itself is created by the node (see [Key Lifecycle](#key-lifecycle));
4. forces `keyformat=hex`, records the reference on the CR, and does not persist an unused legacy `keylocation`;
5. returns `openebs.io/encrypted` in the volume context: `"volume"` for a per-volume key, `"storageclass"` for the StorageClass-level `keylocation`.

The controller has read-only access to Secrets.

### Create and Mount (node)

- **Create**: the dataset is created with `keyformat=hex` and `keylocation=prompt`, the key piped to `zfs create` on stdin.
- **Mount**: `EnsureKeyLoaded` runs `zfs load-key` on the encryption root when the key is not loaded, which is what makes an encrypted volume survive a reboot (a `prompt` dataset does not load its key on pool import). "Key already loaded" is treated as success, as concurrent mounts race on a shared encryption root.
- **Zvols**: after `load-key`, udev creates `/dev/zvol/<pool>/<name>` asynchronously; mounting too early failed with ENOENT after a reboot until a later kubelet retry. The node now waits for the device node, bounded (10 s by default, `ZFS_ZVOL_DEVICE_WAIT_TIMEOUT`) and cancelled with the request context.
- **Wrong key**: a key that no longer matches its dataset fails the mount with an explicit "encryption key … is incorrect" error.

### Snapshots and Clones

Snapshots are encrypted with their volume. A clone, from a volume or from a snapshot, shares its parent's encryption root and key source; `zfs clone` needs the parent key loaded, which is not the case after a reboot until the parent is mounted, so the node loads the parent key before cloning.

The key source travels with the snapshot: the `ZFSSnapshot` CR carries a copy of its volume's spec, `encryptionKeyRef` included, and a restore takes it from there. A clone or a restore cannot pick another key: if its PVC carries a `encryption.openebs.io/secret-name` annotation naming another Secret than its source's, the controller rejects it with `InvalidArgument` instead of silently ignoring it.

### Key Lifecycle

A driver-managed key lives exactly as long as its data, so its lifecycle is owned by the node agent, the component that runs `zfs create` and `zfs destroy`:

- **Creation**: the node generates the key and stores it in the managed Secret right before `zfs create`. It is idempotent across retries, and a pre-existing Secret of that name without the managed label is never adopted.
- **Deletion**: the node deletes the Secret only after `zfs destroy` succeeded, before releasing the ZFSVolume finalizer. Since deleting a key cannot be undone, it requires positive proof that the dataset is gone: its parent dataset is available and `zfs list` reports the dataset as missing. Any other outcome, or a failed delete, keeps the finalizer and the key, and the deletion is retried.
- **Failed creation**: if the dataset cannot be created, the node deletes the key at once. The ZFSVolume of a failed volume carries no finalizer, so its deletion never reaches the destroy path; without this, a PVC deleted while its provisioning keeps failing would leave its key behind.
- **Keeping the data**: deleting a ZFSVolume whose finalizer was removed first, as [import-existing-volume.md] documents to keep a dataset, does not run `zfs destroy`, so the key is kept too and the dataset can be imported again.
- **Clones** share their parent's Secret and never create nor delete it. ZFS refuses to destroy a parent that still has clones, so the parent's key outlives them.
- **User Secrets** are never touched.

The node only deletes Secrets that carry the managed label, and only the one named after the volume it destroyed.

### Protecting the Generated Keys

The managed Secret holds the only in-cluster copy of a generated key, so it is protected two ways:

- `immutable: true` blocks an edit that would silently replace the key.
- A **ValidatingAdmissionPolicy** shipped with the chart (`admissionregistration.k8s.io/v1`, GA since Kubernetes 1.30, no webhook to run), on by default, denies deleting a Secret labelled `encryption.openebs.io/auto-managed=true` in the driver namespace to everyone but the node agent's service account — cluster-admin and the namespace controller included — and denies removing that label, which would otherwise bypass the policy:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: openebs-zfs-protect-encryption-keys
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: ["UPDATE", "DELETE"]
        resources: ["secrets"]
  matchConditions:
    # Key presence is checked before reading it: reading a missing map key is an
    # evaluation error, which failurePolicy Fail would turn into a denial.
    - name: driver-managed-key
      expression: >-
        has(oldObject.metadata.labels) &&
        'encryption.openebs.io/auto-managed' in oldObject.metadata.labels &&
        oldObject.metadata.labels['encryption.openebs.io/auto-managed'] == 'true'
    - name: protection-not-lifted
      expression: >-
        !(has(oldObject.metadata.annotations) &&
        'encryption.openebs.io/allow-key-deletion' in oldObject.metadata.annotations &&
        oldObject.metadata.annotations['encryption.openebs.io/allow-key-deletion'] == 'true')
  validations:
    - expression: >-
        request.operation != 'DELETE' ||
        request.userInfo.username == 'system:serviceaccount:<driver-namespace>:openebs-zfs-node-sa'
      message: this Secret holds the encryption key of an existing ZFS volume and cannot be deleted
    - expression: >-
        request.operation != 'UPDATE' ||
        (has(object.metadata.labels) &&
        'encryption.openebs.io/auto-managed' in object.metadata.labels &&
        object.metadata.labels['encryption.openebs.io/auto-managed'] == 'true')
      message: the auto-managed label of a driver-managed key cannot be removed
```

A `ValidatingAdmissionPolicyBinding` limits it to the driver namespace. Annotating a Secret with `encryption.openebs.io/allow-key-deletion=true` lifts the protection (break-glass). The policy guards against mistakes; it is not a security boundary against cluster administrators, who can lift it. It cannot protect user Secrets, since a policy cannot follow the PVC → Secret reference; their owner is responsible for them, and the ESO pull pattern below keeps their source of truth in the KMS.

A finalizer on the Secret was tried first and dropped: a deleted Secret stays readable while `Terminating`, but a finalizer the driver fails to clear leaves it `Terminating` forever.

### External KMS through the External Secrets Operator

The driver only reads keys from Kubernetes Secrets; [External Secrets Operator] bridges them to an external KMS (HashiCorp Vault, OpenBao, cloud KMSs, …). The documentation will cover both directions:

- **Pull (Secret mode)**: an `ExternalSecret` materialises a key held in the KMS as the Secret referenced by the PVC annotation. It must exist before the PVC, and its value must never change while the volume exists, so it uses `refreshPolicy: CreatedOnce`.
- **Push (auto mode, key escrow)**: a single `PushSecret` in the driver namespace selects the managed Secrets by label and copies each key to its own KMS entry, named after its volume. ESO applies the same remote reference to every Secret a label selector matches, so the `PushSecret` template builds a per-volume entry from the `volume` and `key` data of each Secret — this is why the volume name is repeated in the data — and `dataTo` pushes it. With `deletionPolicy: None`, the copy stays in the KMS after the volume is deleted. `deletionPolicy: Delete`, which would remove the copy together with the volume, does not work with a label selector as of ESO 2.12: each reconcile deletes the entries pushed for the other matched Secrets, so only one key stays in the KMS ([external-secrets#7123]). The docs recommend `None` until it is fixed.

```yaml
apiVersion: external-secrets.io/v1alpha1
kind: PushSecret
metadata:
  name: zfs-encryption-keys
  namespace: openebs
spec:
  refreshInterval: 1m
  deletionPolicy: None
  secretStoreRefs:
    - { kind: ClusterSecretStore, name: vault }
  selector:
    secret:
      selector:
        matchLabels:
          encryption.openebs.io/auto-managed: "true"
  template:
    templateFrom:
      - target: Data
        literal: |
          backup-{{ .volume }}: '{"key":"{{ .key }}"}'
  dataTo:
    - storeRef: { kind: ClusterSecretStore, name: vault }
      match: { regexp: "^backup-" }
      rewrite:
        - regexp: { source: "^backup-(.*)$", target: "zfs-localpv/$1" }
```

Keeping the key material out of etcd is then a matter of [etcd encryption at rest with a KMS provider](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/), the Kubernetes-native answer.

### Helm and RBAC

- Controller: its existing cluster-wide `get`/`list` on Secrets (needed by the CSI sidecars) is reused to validate user Secrets. No write access to Secrets.
- Node: `get secrets` cluster-wide (a user Secret lives in the PVC's namespace; `get` only, not `list`), and `create`/`delete` on Secrets through a Role scoped to the driver namespace, for the managed keys.
- `encryptionKeyProtection.enabled` (default `true`) renders the ValidatingAdmissionPolicy and its binding, only when the cluster serves the API. Like the chart's CRDs, they carry `helm.sh/resource-policy: keep`: `helm uninstall` leaves them in place, since the keys outlive the driver, and a later `helm install` adopts them again. The static `deploy/zfs-operator.yaml` does not include them; the docs give the two objects to apply by hand.

### Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Keys live in etcd (base64). | Documented; recommend etcd encryption at rest with a KMS provider when key custody matters. |
| A plaintext volume created by mistake. | Fail closed on any key source without `encryption`, and on `encryption` without a key source. |
| The managed Secret is the only copy of a key. | `immutable: true`, the ValidatingAdmissionPolicy, and an optional ESO `PushSecret` copy in the KMS. |
| A managed key deleted while its data still exists. | Deletion is tied to `zfs destroy` on the node, not to the ZFSVolume object, and requires `zfs list` to report the dataset as missing. |
| The driver namespace deleted, or the driver reinstalled elsewhere, while volumes use generated keys. | The admission policy, kept on `helm uninstall`, blocks the deletion; documented: back the keys up first. |
| A managed key left behind. | Deleted after `zfs destroy`, and at once when the dataset cannot be created. |
| A key that no longer matches. | Hex validation at create and at every load-key; an explicit wrong-key error instead of a bare `zfs` failure. |
| Cluster-wide Secret read. | The node gets `get` only, not `list`; the controller's existing `get`/`list` is unchanged; write rights are the node's only, namespaced to the driver namespace. |
| Reading a managed key through the API (including backup tools that copy Secrets). | Admission control cannot block reads. RBAC limits them to principals with access to Secrets in the driver namespace; cluster administrators can still read them. Keeping keys out of Secrets altogether is left to a KMS plugin (see [Alternatives](#alternatives)). |
| The KMS copy of a generated key may be missing: nothing checks that ESO pushed it, and a `PushSecret` status can report it as synced when it is not ([external-secrets#7123]). | Documented as a limitation; monitor the backup on the KMS side, not only ESO's status. A KMS plugin would store the key in the KMS before the volume is created. |
| Kubernetes < 1.30. | The chart skips the policy; the other safeguards still apply. |
| Downgrade to a release without the new field. | Documented as unsupported: structural-schema pruning would drop the field from existing CRs and make encrypted volumes unmountable. |

## Implementation Plan

Three pull requests, each building and passing the tests on its own, in this order:

1. **Secret mode** — `encryptionKeyRef` on `VolumeInfo` (v1 and v1alpha1) with deepcopy and CRD manifests; node side (create with the key on stdin, load-key at mount, zvol device wait, wrong-key error, node RBAC); controller side (annotation, validation, fail closed, PV marker); docs, including the ESO pull pattern.
2. **Auto mode** — `autoCreateEncryptionKey`; the managed Secret created and deleted by the node; the node Role; the ValidatingAdmissionPolicy; docs, including the ESO push pattern, and a StatefulSet sample.
3. **Clones** — load the parent key before `zfs clone`; docs, including the Velero limitation.

## Test Plan

- **Unit**: create-argument builders (`prompt` vs legacy file); key validation and trimming; `UsesManagedKey`; managed Secret creation (labels, immutability, `volume` entry, no owner reference, no finalizer), idempotency and refusal to adopt an unmanaged Secret; empty annotation rejected; "dataset does not exist" classification before a key is deleted; PV marker values; a clone's annotation naming another key rejected; the guards of `EnsureParentKeyLoaded`; which volume owns a managed key (own key, clone, user Secret); managed Secret removal (never an unlabelled Secret, already-gone is fine); zvol device wait (appears, times out, context cancelled).
- **Integration** (`tests/encryption_test.go`, in the existing minikube + ZFS CI, where the chart installs the admission policy): a volume with a key Secret and one in auto mode are provisioned and mounted, record their key reference and carry the PV marker; an empty annotation, a missing Secret and a StorageClass without `encryption` are rejected; generated keys are distinct, labelled, protected by the admission policy and deleted with their volume; a clone and a restore share their source's key, and are rejected when their PVC names another Secret.
- **Manual e2e** (done on a single-node Talos cluster, Kubernetes 1.33, OpenZFS 2.3.3, with a real ZFS pool): both modes on filesystem and raw block volumes; fail-closed and hardening cases; keys created by the node only; the admission policy (deletion and label removal denied to cluster-admin, unrelated Secrets unaffected, break-glass, node allowed); keys unloaded then reloaded at mount; managed key deleted after `zfs destroy`; ZFSVolume deleted without its dataset, key kept, dataset re-imported and read back; no key left behind by a failing `zfs create`; clones and snapshot restores sharing their parent's key, parent destroyed only after them, and rejected when their PVC names another key; an empty annotation rejected; the PV marker (`volume`, `storageclass`); snapshot lifecycle; **node reboot** (every volume remounted on the first attempt, no zvol ENOENT, data read back); ESO 2.12 pull with OpenBao, and push with OpenBao and OVHcloud OKMS (mTLS), every key in its own entry, kept after the volume's deletion, restored to the exact key; upgrade from the stock chart; and the Velero investigation described below.
- **Not covered by an automated test**: a PVC that cannot be read (the check sits in `CreateVolume`, which reads the PVC through the API), the deletion of the driver namespace while generated keys exist, and a ZFSVolume deleted without its dataset (covered by the manual e2e above).

## Docs

`docs/encryption.md` covering both modes, the hybrid precedence, the key lifecycle and its protection (with the break-glass and the operator-YAML note), ESO pull and push, snapshots and clones, the Velero limitation, a manual key-rotation runbook, security notes, upgrade and downgrade notes and known limitations; samples for each mode; a `CHANGELOG.md` entry.

## Graduation Criteria

- **implementable**: this OEP approved.
- **implemented**: the three phases merged with unit tests, BDD coverage of both modes and of clones, docs and a changelog entry.

## Implementation History

- 2026-07: prototype and internal review rounds on a fork.
- 2026-09: rebased onto 2.12.0-develop and re-validated end to end, including node reboots and a Velero backup/restore investigation.
- 2026-09-24: discussion opened in [zfs-localpv#772].
- 2026-09-27: maintainer go-ahead to raise an OEP, then the PRs.
- 2026-10-05: tracking issue [OEP 4340] opened, OEP submitted in [openebs#4341].
- 2026-10-13: revised after review: in-tree KMS dropped in favour of ESO, managed key tied to the dataset and created and deleted by the node, ValidatingAdmissionPolicy; re-validated end to end.
- 2026-10-15: shared keys, the ESO `deletionPolicy` limitation and the KMS plugin discussion added.
- 2026-10-22: approved by the maintainers; annotations and labels renamed to the engine-neutral `encryption.openebs.io/` prefix, PV marker values, empty annotation and clone key checks, new risks; then a full review pass of the implementation (positive proof before a key is deleted, no fallback to a generated key on an unreadable PVC, admission policy kept on `helm uninstall`); re-validated end to end.

## Drawbacks

- More configuration surface: one StorageClass parameter, one PVC annotation, one CR field, one admission policy.
- Keys live in etcd, which some users may not expect.
- The ESO push pattern relies on a `PushSecret` template, because ESO cannot yet name a remote entry after the source Secret when a label selector matches several Secrets, and it has to use `deletionPolicy: None` ([external-secrets#7123]), so the KMS copy of a destroyed volume's key is not removed automatically.

## Alternatives

- **Status quo, one key per StorageClass.** Does not provide per-volume crypto-erase, isolation or tenant keys.
- **An in-tree KMS client** (a Vault KV v2 provider was prototyped, and validated against OpenBao and OVHcloud OKMS). Dropped after review: it duplicates what ESO already covers, and maintaining KMS clients in-tree, as ceph-csi does for many backends, is a burden the project does not want to take on.
- **A gRPC KMS-plugin interface**, where the driver calls an out-of-tree plugin to get and store keys, the way the Kubernetes KMS provider works for etcd encryption. A good shape if in-driver KMS support is wanted later, and a possible follow-up OEP if there is demand. It would keep vendor neutrality (a plugin could replace ESO), and keep keys out of Secrets, and so out of etcd, altogether: generated per-volume keys stored in the KMS, created and deleted with their data as in the auto mode; user-provided keys read from it. Looking keys up by a name set on the PVC (such as `encryption.openebs.io/kms-key-name`), scoped to the PVC's namespace, would also allow shared keys; these would be created in the KMS by the user beforehand and only read by the driver, since creating a shared key on the first PVC would race when replicas are provisioned in parallel, and the driver could not know when to delete it.
- **A ceph-csi style KMS layer with data-key wrapping.** Unneeded: ZFS already wraps its master key, so a per-volume key store is enough.
- **An OwnerReference from the managed Secret to its ZFSVolume.** Deletes the key whenever the CR is deleted, including when the CR is deleted to keep the dataset; replaced by node-side deletion after `zfs destroy`.
- **A finalizer on the managed Secret.** Tried and dropped: a finalizer the driver fails to clear leaves the Secret `Terminating` forever.

## Infrastructure Needed

None.

## Known Limitations

- **Backup and restore through Velero are not supported.** Tested with Velero 1.14 and velero-plugin 3.6.0 on a Secret-mode, an auto-mode and an unencrypted control volume:
  - restore fails for the per-volume key modes, while the control volume restores intact. The plugin rebuilds the restored ZFSVolume with its vendored zfs-localpv API types (v1.6.1, 2021), which drop the key source, so `zfs recv` fails (`Cannot use 'prompt' keylocation because stdin is in use`);
  - backups are stored **in clear text**: the backup path uses a non-raw `zfs send`, which decrypts on the fly — also reported in [zfs-localpv#430], and true of the existing StorageClass encryption. Raw sends (`zfs send -w`), which keep backups encrypted, are proposed in [zfs-localpv#774]. For per-volume keys, a raw backup can only be restored with the volume's original key, which the auto mode deletes together with the volume unless it was backed up to a KMS, and the plugin must carry the key source; supporting restore therefore still needs an updated plugin, a follow-up tracked in [OEP 4340]. The restore step proposed in [zfs-localpv#774] (reloading the key from the pool's `keylocation`, then re-attaching the volume to the pool's encryption root) must also skip volumes that have their own key.
- **Driver namespace deletion** is blocked by the admission policy while managed keys exist, which is intended, including after `helm uninstall`; the break-glass annotation lifts it. Generated keys live in the driver namespace: reinstalling the driver in another namespace needs the keys moved or restored first.
- **ESO backups are not verified** by the driver, and a `PushSecret` status can be wrong ([external-secrets#7123]); monitor them on the KMS side.
- **The admission policy** is only rendered when the cluster serves the `ValidatingAdmissionPolicy` API (Kubernetes 1.30+), and is enabled by default, with `encryptionKeyProtection.enabled` to turn it off. Rendering the chart without a cluster (`helm template`, the static `deploy/zfs-operator.yaml`) leaves it out.

[External Secrets Operator]: https://external-secrets.io/
[external-secrets#7123]: https://github.com/external-secrets/external-secrets/issues/7123
[import-existing-volume.md]: https://github.com/openebs/zfs-localpv/blob/develop/docs/import-existing-volume.md
[OEP 4340]: https://github.com/openebs/openebs/issues/4340
[openebs#4341]: https://github.com/openebs/openebs/pull/4341
[mayastor#2027]: https://github.com/openebs/mayastor/issues/2027
[zfs-localpv#426]: https://github.com/openebs/zfs-localpv/issues/426
[zfs-localpv#430]: https://github.com/openebs/zfs-localpv/issues/430
[zfs-localpv#477]: https://github.com/openebs/zfs-localpv/issues/477
[zfs-localpv#772]: https://github.com/openebs/zfs-localpv/issues/772
[zfs-localpv#774]: https://github.com/openebs/zfs-localpv/issues/774
