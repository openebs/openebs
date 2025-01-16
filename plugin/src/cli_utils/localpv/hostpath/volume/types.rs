use super::Error;
use anyhow::anyhow;
use k8s_openapi::api::core::v1::PersistentVolume;
use kube::ResourceExt;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub(crate) struct HostPathVolume {
    // Name of the hostpath volume.
    name: String,
    // Status of volume pvc.
    status: String,
    // Node hosting the hostpath volume.
    node: String,
    /// Mountpath on the node.
    path: String,
    // Name of the pvc object associated with volume.
    pvc_name: String,
    // Access mode for the volume.
    access_mode: Vec<String>,
    // Storage class name associated hostpath volume.
    sc_name: String,
    // Volume mode, Block or FS.
    volume_mode: String,
    // Capacity of the volume.
    capacity: String,
}

impl HostPathVolume {
    /// Returns name of hostpath volume.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns node hosting the hostpath volume.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns capacity of the hostpath volume.
    pub(crate) fn capacity(&self) -> &String {
        &self.capacity
    }

    /// Returns hostpath volume status.
    pub(crate) fn status(&self) -> &String {
        &self.status
    }

    /// Returns hostpath volume status.
    pub(crate) fn path(&self) -> &String {
        &self.path
    }

    /// Returns PVC name associated with hostpath volume.
    pub(crate) fn pvc_name(&self) -> &String {
        &self.pvc_name
    }

    /// Returns storage class name for the hostpath volume.
    pub(crate) fn sc_name(&self) -> &String {
        &self.sc_name
    }
}

/// A record containing a collection of hostpath volume.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct HostPathVolumeRecord {
    /// A vector of host path volume.
    volumes: Vec<HostPathVolume>,
}

impl HostPathVolumeRecord {
    /// Constructs HostPathVolumeRecord object.
    pub(crate) fn new(volumes: Vec<HostPathVolume>) -> Self {
        Self { volumes }
    }

    /// Returns volume list present in the HostPathVolumeRecord.
    pub(crate) fn volumes(&self) -> &Vec<HostPathVolume> {
        &self.volumes
    }
}

impl TryFrom<PersistentVolume> for HostPathVolume {
    type Error = Error;
    fn try_from(value: PersistentVolume) -> Result<Self, Self::Error> {
        let spec = value.spec.as_ref().ok_or_else(|| Error::Generic {
            source: anyhow!("PV node affinity not found"),
        })?;
        Ok(Self {
            name: value.name_unchecked(),
            status: value
                .status
                .as_ref()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("PV status not present"),
                })?
                .phase
                .clone()
                .unwrap_or_default(),
            node: spec
                .node_affinity
                .as_ref()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("PV node affinity not found"),
                })?
                .required
                .as_ref()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("Node selector not found"),
                })?
                .node_selector_terms
                .first()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("PV node selector not found"),
                })?
                .match_expressions
                .clone()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("PV node affinity match expression not found"),
                })?
                .first()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("PV node affinity match expression element not found"),
                })?
                .values
                .as_ref()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("PV node affinity string array not found"),
                })?
                .first()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("PV node affinity string element not found"),
                })?
                .clone(),
            path: spec
                .local
                .clone()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("Local path entry not found for the PV"),
                })?
                .path,
            pvc_name: spec
                .claim_ref
                .clone()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("Claimref not found for the PV"),
                })?
                .name
                .unwrap_or_default(),
            access_mode: spec.access_modes.clone().unwrap_or_default(),
            sc_name: spec
                .storage_class_name
                .clone()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("Storage class not present for the PV"),
                })?,
            volume_mode: spec.volume_mode.clone().unwrap_or_default(),
            capacity: spec
                .capacity
                .clone()
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("Capacity not found for the PV"),
                })?
                .get("storage")
                .ok_or_else(|| Error::Generic {
                    source: anyhow!("Capacity key not found in the Map"),
                })?
                .0
                .clone(),
        })
    }
}
