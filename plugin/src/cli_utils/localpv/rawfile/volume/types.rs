use crate::cli_utils::localpv::{
    adjust_bytes,
    rawfile::{adjust_time, api::VolumeStat, yes_no},
};

use serde::{Deserialize, Serialize};

/// Struct to construct cli result from.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfileVolumeObject {
    /// Name of the volume, which is the name of its persistent volume.
    name: String,
    /// Node hosting the volume.
    node: String,
    /// Storage pool hosting the volume.
    pool: String,
    /// Deleted if the volume is awaiting garbage collection, else Ready or NotReady.
    status: String,
    /// Requested size of the volume.
    size: String,
    /// Bytes used within the volume.
    used: String,
    /// Apparent size of the image file backing the volume.
    logical_size: String,
    /// Bytes the image file backing the volume occupies on the storage pool.
    physical_size: String,
    /// Yes if the backing image file is sparse, No if not.
    thin: String,
    /// Yes if the volume is a copy on write clone, No if not.
    copy_on_write: String,
    /// Yes if the filesystem of the volume is frozen, No if not.
    freezefs: String,
    /// Path of the image file backing the volume.
    img_file: String,
    /// When the volume was created.
    created_at: String,
    /// When the volume was deleted, if it was.
    deleted_at: String,
    /// When the deleted volume is to be garbage collected, if it is.
    gc_at: String,
}

/// Getter implementations for RawfileVolumeObject.
impl RawfileVolumeObject {
    /// Returns name of the volume.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns node hosting the volume.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns storage pool hosting the volume.
    pub(crate) fn pool(&self) -> &String {
        &self.pool
    }

    /// Returns status of the volume.
    pub(crate) fn status(&self) -> &String {
        &self.status
    }

    /// Returns requested size of the volume.
    pub(crate) fn size(&self) -> &String {
        &self.size
    }

    /// Returns bytes used within the volume.
    pub(crate) fn used(&self) -> &String {
        &self.used
    }

    /// Returns bytes the volume occupies on the storage pool.
    pub(crate) fn physical_size(&self) -> &String {
        &self.physical_size
    }

    /// Returns whether the backing image file is sparse.
    pub(crate) fn thin(&self) -> &String {
        &self.thin
    }

    /// Returns whether the volume is a copy on write clone.
    pub(crate) fn copy_on_write(&self) -> &String {
        &self.copy_on_write
    }

    /// Returns when the volume was created.
    pub(crate) fn created_at(&self) -> &String {
        &self.created_at
    }
}

/// Takes a volume as reported by the api-server with its node, Returns RawfileVolumeObject.
impl From<(&str, &VolumeStat)> for RawfileVolumeObject {
    fn from((node, volume): (&str, &VolumeStat)) -> Self {
        // A deleted volume is kept around until it is garbage collected.
        let deleted = volume.deleted_at.is_some_and(|deleted_at| deleted_at > 0.0);
        Self {
            name: volume.name.clone(),
            node: node.to_string(),
            pool: volume.storage_pool.clone(),
            status: match (deleted, volume.ready) {
                (true, _) => "Deleted".to_string(),
                (false, true) => "Ready".to_string(),
                (false, false) => "NotReady".to_string(),
            },
            size: adjust_bytes(volume.size as u128),
            used: adjust_bytes(volume.used as u128),
            logical_size: adjust_bytes(volume.logical_size as u128),
            physical_size: adjust_bytes(volume.physical_size as u128),
            thin: yes_no(volume.thin_provision).to_string(),
            copy_on_write: yes_no(volume.copy_on_write).to_string(),
            freezefs: yes_no(volume.freezefs).to_string(),
            img_file: volume.img_file.clone(),
            created_at: adjust_time(volume.created_at),
            deleted_at: adjust_time(volume.deleted_at),
            gc_at: adjust_time(volume.gc_at),
        }
    }
}

/// A record containing a collection of localpv-rawfile volumes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfileVolRecord {
    /// A vector of rawfile volumes.
    volumes: Vec<RawfileVolumeObject>,
}

impl RawfileVolRecord {
    /// Constructs RawfileVolRecord object.
    pub(crate) fn new(volumes: Vec<RawfileVolumeObject>) -> Self {
        Self { volumes }
    }

    /// Returns volume list present in the RawfileVolRecord.
    pub(crate) fn volumes(&self) -> &Vec<RawfileVolumeObject> {
        &self.volumes
    }
}
