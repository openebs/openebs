use super::Error;
use k8s_openapi::api::core::v1::PersistentVolume;
use k8s_openapi::NamespaceResourceScope;
use kube::{api::ObjectMeta, Resource};
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
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    pub(crate) fn capacity(&self) -> &String {
        &self.capacity
    }

    pub(crate) fn status(&self) -> &String {
        &self.status
    }

    pub(crate) fn pvc_name(&self) -> &String {
        &self.pvc_name
    }

    pub(crate) fn vol_group(&self) -> &String {
        &self.vol_group
    }

    pub(crate) fn sc_name(&self) -> &String {
        &self.sc_name
    }
}

impl LvmVolume {
    /// Checks if lvmvolume is present on a specific node.
    pub(crate) fn on_node(&self, node_id: &String) -> bool {
        &self.spec.owner_node_id == node_id
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct LvolRecord {
    volumes: Vec<LvmVolumeObject>,
}

impl LvolRecord {
    pub(crate) fn new(volumes: Vec<LvmVolumeObject>) -> Self {
        Self { volumes }
    }

    pub(crate) fn volumes(&self) -> &Vec<LvmVolumeObject> {
        &self.volumes
    }
}

/// Takes lvmvolume and associated PV, Returns LvmVolumeObject.
impl TryFrom<(&LvmVolume, PersistentVolume)> for LvmVolumeObject {
    fn try_from(
        (lvm_volume, persistent_volume): (&LvmVolume, PersistentVolume),
    ) -> Result<LvmVolumeObject, Self::Error> {
        let spec = persistent_volume
            .spec
            .ok_or_else(|| Error::Generic(anyhow::anyhow!("PersistentVolume spec missing")))?;
        let lvm_spec = &lvm_volume.spec;
        Ok(Self {
            name: lvm_volume
                .metadata
                .name
                .as_ref()
                .ok_or_else(|| Error::Generic(anyhow::anyhow!("LvmVolume name missing")))?
                .clone(),
            namespace: lvm_volume
                .metadata
                .namespace
                .as_ref()
                .ok_or_else(|| Error::Generic(anyhow::anyhow!("LvmVolume namespace missing")))?
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
                .ok_or_else(|| Error::Generic(anyhow::anyhow!("PV claimRef missing")))?
                .name
                .unwrap_or_default(),
            access_mode: spec
                .access_modes
                .ok_or_else(|| Error::Generic(anyhow::anyhow!("PV accessmode missing")))?,
            sc_name: spec
                .storage_class_name
                .ok_or_else(|| Error::Generic(anyhow::anyhow!("PV sc name missing")))?,
            volume_mode: spec
                .volume_mode
                .ok_or_else(|| Error::Generic(anyhow::anyhow!("PV vol mode missing")))?,
        })
    }
    type Error = Error;
}
