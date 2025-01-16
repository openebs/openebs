use k8s_openapi::NamespaceResourceScope;
use kube::{api::ObjectMeta, Resource, ResourceExt};
use serde::{Deserialize, Serialize};
use std::borrow::Cow;

impl Resource for LvmNode {
    type DynamicType = ();

    fn kind(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("LVMNode")
    }

    fn group(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("local.openebs.io")
    }

    fn version(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("v1alpha1")
    }

    fn plural(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("lvmnodes")
    }

    fn meta(&self) -> &ObjectMeta {
        &self.metadata
    }

    fn meta_mut(&mut self) -> &mut ObjectMeta {
        &mut self.metadata
    }

    type Scope = NamespaceResourceScope;
}

/// LVMNode struct mirroring the crd.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct LvmNode {
    #[serde(alias = "apiVersion")]
    api_version: String,
    kind: String,
    metadata: ObjectMeta,
    #[serde(alias = "volumeGroups")]
    volume_groups: Vec<VolumeGroup>,
}

/// Lvm Volume group.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct VolumeGroup {
    #[serde(alias = "allocationPolicy")]
    allocation_policy: i32,
    free: String,
    #[serde(alias = "lvCount")]
    lv_count: i32,
    #[serde(alias = "maxLv")]
    max_lv: i32,
    #[serde(alias = "maxPv")]
    max_pv: i32,
    #[serde(alias = "metadataCount")]
    metadata_count: i32,
    #[serde(alias = "metadataFree")]
    metadata_free: String,
    #[serde(alias = "metadataSize")]
    metadata_size: String,
    #[serde(alias = "metadataUsedCount")]
    metadata_used_count: i32,
    #[serde(alias = "missingPvCount")]
    missing_pv_count: i32,
    name: String,
    permissions: i32,
    #[serde(alias = "pvCount")]
    pv_count: i32,
    size: String,
    #[serde(alias = "snapCount")]
    snap_count: i32,
    uuid: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct LvmVolumeGroup {
    /// Name of the Lvm VG.
    name: String,
    /// Node where VG is present.
    node: String,
    /// UUID of the VG, Maintained by LVM.
    uuid: String,
    /// Total size in the VG.
    total_size: String,
    /// Free size in the VG.
    free_size: String,
    /// Maximum number of lv allocatable. 0 if no limit configured.
    max_lv: String,
    /// Maximum number of PV which can be added on VG. 0 if no limit configured.
    max_pv: String,
    /// Number of lv hosted by VG.
    lv_count: String,
    /// Number of PV present in VG.
    pv_count: String,
    /// Number of snapshot hosted by VG.
    snap_count: String,
    /// Number of PV reported as Missing by VG.
    missing_pv_count: String,
}

/// Getter for LvmVolumeGroup.
impl LvmVolumeGroup {
    /// Returns name of the vg.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns node hosting the vg.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns total size of the vg.
    pub(crate) fn total_size(&self) -> &String {
        &self.total_size
    }

    /// Returns free size of the vg.
    pub(crate) fn free_size(&self) -> &String {
        &self.free_size
    }

    /// Returns total lv hosted by vg.
    pub(crate) fn lv_count(&self) -> &String {
        &self.lv_count
    }

    /// Returns total snapshot hosted by vg.
    pub(crate) fn snap_count(&self) -> &String {
        &self.snap_count
    }

    /// Returns number of PV present in the vg.
    pub(crate) fn pv_count(&self) -> &String {
        &self.pv_count
    }

    /// Returns lvm specific uuid of the vg.
    pub(crate) fn uuid(&self) -> &String {
        &self.uuid
    }
}

/// A record containing a collection of volumegroup.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct VolumeGroupRecord {
    /// A vector of volumegroup.
    vgs: Vec<LvmVolumeGroup>,
}

impl VolumeGroupRecord {
    /// Returns list of volumegroup.
    pub(crate) fn vgs(&self) -> &Vec<LvmVolumeGroup> {
        &self.vgs
    }
}

/// Takes collection of LvmNode and returns VolumeGroupRecord.
impl From<Vec<LvmNode>> for VolumeGroupRecord {
    fn from(nodes: Vec<LvmNode>) -> Self {
        let mut volume_group: Vec<LvmVolumeGroup> = Vec::new();
        for node in nodes {
            for vg in &node.volume_groups {
                volume_group.push(LvmVolumeGroup::from((vg, &node.name_unchecked())));
            }
        }
        Self { vgs: volume_group }
    }
}

impl From<(&VolumeGroup, &String)> for LvmVolumeGroup {
    fn from((vg, node): (&VolumeGroup, &String)) -> Self {
        Self {
            name: vg.name.clone(),
            node: node.to_string(),
            uuid: vg.uuid.clone(),
            total_size: vg.size.clone(),
            free_size: vg.free.clone(),
            max_lv: vg.max_lv.to_string(),
            max_pv: vg.max_pv.to_string(),
            lv_count: vg.lv_count.to_string(),
            pv_count: vg.pv_count.to_string(),
            snap_count: vg.snap_count.to_string(),
            missing_pv_count: vg.missing_pv_count.to_string(),
        }
    }
}
