use super::Error;
use k8s_openapi::api::core::v1::PersistentVolume;
use k8s_openapi::NamespaceResourceScope;
use kube::{api::ObjectMeta, Resource, ResourceExt};
use serde::{Deserialize, Serialize};
use std::borrow::Cow;

impl Resource for LvmVolume {
    type DynamicType = ();

    fn kind(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("LVMVolume")
    }

    fn group(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("local.openebs.io")
    }

    fn version(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("v1alpha1")
    }

    fn plural(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("lvmvolumes")
    }

    fn meta(&self) -> &ObjectMeta {
        &self.metadata
    }

    fn meta_mut(&mut self) -> &mut ObjectMeta {
        &mut self.metadata
    }

    type Scope = NamespaceResourceScope;
}

/// LVMVolume struct mirroring the crd.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct LvmVolume {
    #[serde(alias = "apiVersion")]
    api_version: String,
    kind: String,
    metadata: ObjectMeta,
    spec: LvmVolSpec,
    status: LvmVolStatus,
}

/// Spec for the LVMVolume cr.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct LvmVolSpec {
    capacity: String,
    #[serde(alias = "ownerNodeID")]
    owner_node_id: String,
    shared: String,
    #[serde(alias = "thinProvision")]
    thin_provision: String,
    #[serde(alias = "vgPattern")]
    vg_pattern: String,
    #[serde(alias = "volGroup")]
    vol_group: String,
}

/// Status for the LVMVolume cr.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct LvmVolStatus {
    /// LVM volume resource state.
    state: String,
    /// LVM volume resource error. if present.
    error: Option<String>,
}

/// Struct to construct cli result from.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct LvmVolumeObject {
    /// Name of the lvm volume.
    name: String,
    /// Namespace where the cr is created.
    namespace: String,
    /// Status of lvm volume cr.
    status: String,
    /// Node hosting the lvm volume.
    node: String,
    /// Yes if thin provisioned, No if not.
    thin: String,
    /// Capacity of the volume.
    capacity: String,
    /// Yes if volume is sharable among more then 1 pod.
    shared: String,
    /// Volume group hosting the volume.
    vol_group: String,
    /// Vg pattern used to select the vg for scheduling.
    vg_pattern: String,
    /// Name of the pvc object associated with volume.
    pvc_name: String,
    /// Access mode defined in PVC object.
    access_mode: Vec<String>,
    /// Storage class name associated with pvc.
    sc_name: String,
    /// Volume mode, Block or FS.
    volume_mode: String,
}

/// Getter implementations for LvmVolumeObject.
impl LvmVolumeObject {
    /// Returns name of lvmvolume.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns node hosting the lvmvolume.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns capacity of the lvmvolume.
    pub(crate) fn capacity(&self) -> &String {
        &self.capacity
    }

    /// Returns lvmvolume status.
    pub(crate) fn status(&self) -> &String {
        &self.status
    }

    /// Returns PVC name associated with lvmvolume.
    pub(crate) fn pvc_name(&self) -> &String {
        &self.pvc_name
    }

    /// Returns volume group hosting the lvmvolume.
    pub(crate) fn vol_group(&self) -> &String {
        &self.vol_group
    }

    /// Returns storage class name for the lvmvolume.
    pub(crate) fn sc_name(&self) -> &String {
        &self.sc_name
    }
}

/// A record containing a collection of localpv-volume.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct LvmVolRecord {
    /// A vector of lvm volume.
    volumes: Vec<LvmVolumeObject>,
}

impl LvmVolRecord {
    /// Constructs LvmVolRecord object.
    pub(crate) fn new(volumes: Vec<LvmVolumeObject>) -> Self {
        Self { volumes }
    }

    /// Returns volume list present in the LvmVolRecord.
    pub(crate) fn volumes(&self) -> &Vec<LvmVolumeObject> {
        &self.volumes
    }
}

/// Takes lvmvolume and associated PV, Returns LvmVolumeObject.
impl TryFrom<(&LvmVolume, PersistentVolume)> for LvmVolumeObject {
    type Error = Error;
    fn try_from(
        (lvm_volume, persistent_volume): (&LvmVolume, PersistentVolume),
    ) -> Result<LvmVolumeObject, Self::Error> {
        let pv_name = persistent_volume.name_any();
        let lvmvol_name = lvm_volume.name_any();
        let spec = persistent_volume
            .spec
            .as_ref()
            .ok_or_else(|| Error::Generic {
                source: anyhow::anyhow!("PersistentVolume spec missing for {}", pv_name),
            })?;
        let lvm_spec = &lvm_volume.spec;
        Ok(Self {
            name: lvm_volume.name_any(),
            namespace: lvm_volume
                .metadata
                .namespace
                .as_ref()
                .ok_or_else(|| Error::Generic {
                    source: anyhow::anyhow!("LvmVolume namespace missing for {}", lvmvol_name),
                })?
                .clone(),
            status: lvm_volume.status.state.clone(),
            node: lvm_spec.owner_node_id.clone(),
            thin: lvm_spec.thin_provision.clone(),
            capacity: lvm_volume.spec.capacity.clone(),
            shared: lvm_volume.spec.shared.clone(),
            vol_group: lvm_volume.spec.vol_group.clone(),
            vg_pattern: lvm_volume.spec.vg_pattern.clone(),
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
        })
    }
}
