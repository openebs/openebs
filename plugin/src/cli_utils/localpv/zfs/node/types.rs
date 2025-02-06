use super::Error;

use k8s_openapi::NamespaceResourceScope;
use kube::{api::ObjectMeta, Resource, ResourceExt};
use serde::{Deserialize, Serialize};
use std::borrow::Cow;

impl Resource for ZfsNode {
    type DynamicType = ();

    fn kind(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("ZFSNode")
    }

    fn group(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("zfs.openebs.io")
    }

    fn version(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("v1")
    }

    fn plural(_: &Self::DynamicType) -> Cow<'_, str> {
        Cow::Borrowed("zfsnodes")
    }

    fn meta(&self) -> &ObjectMeta {
        &self.metadata
    }

    fn meta_mut(&mut self) -> &mut ObjectMeta {
        &mut self.metadata
    }

    type Scope = NamespaceResourceScope;
}

/// ZFSNode struct mirroring the crd.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct ZfsNode {
    #[serde(alias = "apiVersion")]
    api_version: String,
    kind: String,
    metadata: ObjectMeta,
    #[serde(alias = "volumeGroups")]
    pools: Vec<Pool>,
}

/// Lvm Volume group.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct Pool {
    free: String,
    name: String,
    used: String,
    uuid: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct ZfsPool {
    /// Name of the Lvm VG.
    name: String,
    /// Node where VG is present.
    node: String,
    /// UUID of the VG, Maintained by LVM.
    uuid: String,
    /// Total size in the VG.
    free: String,
    /// Free size in the VG.
    used: String,
}

/// Getter for LvmVolumeGroup.
impl ZfsPool {
    /// Returns name of the vg.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns node hosting the vg.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns total size of the vg.
    pub(crate) fn free(&self) -> &String {
        &self.free
    }

    /// Returns free size of the vg.
    pub(crate) fn used(&self) -> &String {
        &self.used
    }

    /// Returns zfs specific uuid of the vg.
    pub(crate) fn uuid(&self) -> &String {
        &self.uuid
    }
}

/// A record containing a collection of zpool.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct ZfsPoolRecord {
    /// A vector of zpool.
    pools: Vec<ZfsPool>,
}

impl ZfsPoolRecord {
    pub(crate) fn pools(&self) -> &Vec<ZfsPool> {
        &self.pools
    }
}

impl TryFrom<Vec<ZfsNode>> for ZfsPoolRecord {
    type Error = Error;
    fn try_from(nodes: Vec<ZfsNode>) -> Result<Self, Error> {
        let mut pools: Vec<ZfsPool> = Vec::new();
        for node in nodes {
            for pool in &node.pools {
                pools.push(ZfsPool::try_from((pool, &node.name_unchecked()))?);
            }
        }
        Ok(Self { pools })
    }
}

impl TryFrom<(&Pool, &String)> for ZfsPool {
    type Error = Error;
    fn try_from((pool, node): (&Pool, &String)) -> Result<Self, Error> {
        Ok(Self {
            name: pool.name.clone(),
            node: node.to_string(),
            uuid: pool.uuid.clone(),
            free: pool.free.clone(),
            used: pool.used.clone(),
        })
    }
}
