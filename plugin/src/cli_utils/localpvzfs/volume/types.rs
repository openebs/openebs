use super::Error;
use k8s_openapi::api::core::v1::PersistentVolume;
use k8s_openapi::NamespaceResourceScope;
use kube::{api::ObjectMeta, Resource, ResourceExt};
use serde::{Deserialize, Serialize};
use std::borrow::Cow;

impl Resource for ZfsVolume {
    type DynamicType = ();

    fn kind(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("ZFSVolume")
    }

    fn group(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("zfs.openebs.io")
    }

    fn version(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("v1")
    }

    fn plural(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("zfsvolumes")
    }

    fn meta(&self) -> &ObjectMeta {
        &self.metadata
    }

    fn meta_mut(&mut self) -> &mut ObjectMeta {
        &mut self.metadata
    }

    type Scope = NamespaceResourceScope;
}

/// ZFSVolume struct mirroring the crd.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct ZfsVolume {
    #[serde(alias = "apiVersion")]
    api_version: String,
    kind: String,
    metadata: ObjectMeta,
    spec: ZfsVolSpec,
    status: ZfsVolStatus,
}

/// Spec for the ZFSVolume cr.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct ZfsVolSpec {
    /// Capacity of volume.
    capacity: String,
    /// Specifies the block-level compression algorithm to be applied.
    compression: String,
    /// Dedup on or off on the volume.
    dedup: String,
    /// Encryption on or off. This can be algorithm used also.
    encryption: Option<String>,
    /// Specifies filesystem type for the zfs volume/dataset.
    #[serde(alias = "fsType")]
    fs_type: String,
    /// Format of encryption key used if enabled.
    keyformat: Option<String>,
    /// Location for the encryption key.
    keylocation: Option<String>,
    /// Node having the zpool which hosts the volume.
    #[serde(alias = "ownerNodeID")]
    owner_node_id: String,
    /// Zpool hosting the volume.
    #[serde(alias = "poolName")]
    pool_name: String,
    /// Specifies a suggested block size for files in the filesystem.
    recordsize: String,
    /// Specifies the name of the snapshot where the volume has been cloned from.
    snapname: Option<String>,
    /// Thin provisioning on or off.
    #[serde(alias = "thinProvision")]
    thin_provision: Option<String>,
    /// Specifies the block size for the volume.
    #[serde(alias = "volblocksize")]
    vol_block_size: Option<String>,
    /// Specifies whether the volume is of type "DATASET" or "ZVOL"
    #[serde(alias = "volumeType")]
    vol_type: String,
}

/// Status for the ZFSVolume cr.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct ZfsVolStatus {
    /// State can be Pending or Ready.
    state: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct ZfsVolumeObject {
    /// Name of the zfsvolume.
    name: String,
    /// Namespace of zfsvolume cr.
    namespace: String,
    /// Node having the zpool which hosts the volume.
    node: String,
    /// Capacity of the zfsvolume.
    capacity: String,
    /// Specifies the block-level compression algorithm to be applied.
    compression: String,
    /// Dedup on or off on the volume.
    dedup: String,
    /// Encryption on or off. This can be algorithm used also.
    encryption: String,
    /// Specifies filesystem type for the zfs volume/dataset.
    fs_type: String,
    /// Format of encryption key used if enabled.
    keyformat: String,
    /// Location for the encryption key.
    keylocation: String,
    /// Zpool hosting the volume.
    pool_name: String,
    /// Specifies a suggested block size for files in the filesystem.
    recordsize: String,
    /// Specifies the name of the snapshot where the volume has been cloned from.
    snapname: String,
    /// Thin provisioning on or off.
    thin_provision: String,
    /// Specifies the block size for the volume.
    vol_block_size: String,
    /// Specifies whether the volume is of type "DATASET" or "ZVOL"
    vol_type: String,
    /// Name of pvc associated with volume.
    pvc_name: String,
    /// Name of sc associated with volume.
    sc_name: String,
    // Volume mode, Block or FS.
    volume_mode: String,
    /// access modes supported by the volume.
    access_mode: Vec<String>,
    /// Status of the volume cr.
    status: String,
}

/// Getter implementations for ZfsVolumeObject.
impl ZfsVolumeObject {
    /// Returns name of zfsvolume.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns node hosting the zfsvolume.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns capacity of the zfsvolume.
    pub(crate) fn capacity(&self) -> &String {
        &self.capacity
    }

    /// Returns zfsvolume status.
    pub(crate) fn status(&self) -> &String {
        &self.status
    }

    /// Returns PVC name associated with zfsvolume.
    pub(crate) fn pvc_name(&self) -> &String {
        &self.pvc_name
    }

    /// Returns name of the zpool hosting the zfsvolume.
    pub(crate) fn pool(&self) -> &String {
        &self.pool_name
    }

    /// Returns storage class name for the zfsvolume.
    pub(crate) fn sc_name(&self) -> &String {
        &self.sc_name
    }
}

/// A record containing a collection of localpv-zfs volume.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct ZfsVolRecord {
    /// A vector of zfs volume.
    volumes: Vec<ZfsVolumeObject>,
}

impl ZfsVolRecord {
    /// Constructs ZfsVolRecord object.
    pub(crate) fn new(volumes: Vec<ZfsVolumeObject>) -> Self {
        Self { volumes }
    }

    /// Returns volume list present in the ZfsVolRecord.
    pub(crate) fn volumes(&self) -> &Vec<ZfsVolumeObject> {
        &self.volumes
    }
}

/// Takes zfsvolume and associated PV, Returns ZfsVolumeObject.
impl TryFrom<(ZfsVolume, PersistentVolume)> for ZfsVolumeObject {
    type Error = Error;
    fn try_from(
        (zfs_volume, persistent_volume): (ZfsVolume, PersistentVolume),
    ) -> Result<ZfsVolumeObject, Error> {
        let pv_name = persistent_volume.name_any();
        let spec = persistent_volume
            .spec
            .as_ref()
            .ok_or_else(|| Error::Generic {
                source: anyhow::anyhow!("PersistentVolume spec missing for {}", pv_name),
            })?;
        Ok(Self {
            name: zfs_volume.name_any(),
            namespace: zfs_volume
                .metadata
                .namespace
                .as_ref()
                .ok_or_else(|| Error::Generic {
                    source: anyhow::anyhow!(
                        "Zfsvolume namespace missing for {}",
                        zfs_volume.name_any()
                    ),
                })?
                .clone(),
            status: zfs_volume.status.state,
            node: zfs_volume.spec.owner_node_id,
            thin_provision: zfs_volume
                .spec
                .thin_provision
                .clone()
                .unwrap_or_default()
                .to_string(),
            capacity: zfs_volume.spec.capacity,
            pvc_name: spec
                .claim_ref
                .clone()
                .ok_or_else(|| Error::Generic {
                    source: anyhow::anyhow!("PV claimRef missing for {}", pv_name),
                })?
                .name
                .unwrap_or_default(),
            access_mode: spec.access_modes.clone().ok_or_else(|| Error::Generic {
                source: anyhow::anyhow!("PV accessmode missing for {}", pv_name),
            })?,
            sc_name: spec
                .storage_class_name
                .clone()
                .ok_or_else(|| Error::Generic {
                    source: anyhow::anyhow!("PV sc name missing for {}", pv_name),
                })?,
            volume_mode: spec.volume_mode.clone().ok_or_else(|| Error::Generic {
                source: anyhow::anyhow!("PV vol mode missing for {}", pv_name),
            })?,
            compression: zfs_volume.spec.compression,
            dedup: zfs_volume.spec.dedup,
            encryption: zfs_volume.spec.encryption.unwrap_or_default(),
            fs_type: zfs_volume.spec.fs_type,
            keyformat: zfs_volume.spec.keyformat.unwrap_or_default(),
            keylocation: zfs_volume.spec.keylocation.unwrap_or_default(),
            pool_name: zfs_volume.spec.pool_name,
            recordsize: zfs_volume.spec.recordsize,
            snapname: zfs_volume.spec.snapname.unwrap_or_default(),
            vol_block_size: zfs_volume.spec.vol_block_size.unwrap_or_default(),
            vol_type: zfs_volume.spec.vol_type.clone(),
        })
    }
}
