use crate::cli_utils::localpv::{
    adjust_bytes,
    rawfile::{
        api::{Node, PoolStat},
        yes_no, NO_CONTENT,
    },
};

use serde::{Deserialize, Serialize};

/// Struct to construct cli result from.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfileNodeObject {
    /// Name of the node.
    name: String,
    /// Ip address of the node-plugin.
    ip: String,
    /// Online if the node-plugin is reachable by the api-server, Offline if not.
    status: String,
    /// Storage pools of the node.
    pools: String,
    /// Total capacity of the storage pools of the node.
    capacity: String,
}

/// Getter implementations for RawfileNodeObject.
impl RawfileNodeObject {
    /// Returns name of the node.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns ip address of the node-plugin.
    pub(crate) fn ip(&self) -> &String {
        &self.ip
    }

    /// Returns status of the node.
    pub(crate) fn status(&self) -> &String {
        &self.status
    }

    /// Returns storage pools of the node.
    pub(crate) fn pools(&self) -> &String {
        &self.pools
    }

    /// Returns total capacity of the storage pools of the node.
    pub(crate) fn capacity(&self) -> &String {
        &self.capacity
    }
}

/// Takes a node as reported by the api-server, Returns RawfileNodeObject.
impl From<&Node> for RawfileNodeObject {
    fn from(node: &Node) -> Self {
        let (pools, capacity) = match &node.pools_stat {
            // The api-server reports no pools for a node it could not collect stats from.
            None => (NO_CONTENT.to_string(), NO_CONTENT.to_string()),
            Some(pools) if pools.is_empty() => (NO_CONTENT.to_string(), adjust_bytes(0)),
            Some(pools) => (
                pools
                    .keys()
                    .map(String::as_str)
                    .collect::<Vec<_>>()
                    .join(","),
                adjust_bytes(pools.values().map(|pool| pool.capacity as u128).sum()),
            ),
        };
        Self {
            name: node.name.clone(),
            ip: node.ip.clone(),
            status: if node.online {
                "Online".to_string()
            } else {
                "Offline".to_string()
            },
            pools,
            capacity,
        }
    }
}

/// A record containing a collection of localpv-rawfile nodes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfileNodeRecord {
    /// A vector of rawfile nodes.
    nodes: Vec<RawfileNodeObject>,
}

impl RawfileNodeRecord {
    /// Constructs RawfileNodeRecord object.
    pub(crate) fn new(nodes: Vec<RawfileNodeObject>) -> Self {
        Self { nodes }
    }

    /// Returns node list present in the RawfileNodeRecord.
    pub(crate) fn nodes(&self) -> &Vec<RawfileNodeObject> {
        &self.nodes
    }
}

/// Struct to construct cli result from.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfilePoolObject {
    /// Name of the storage pool.
    name: String,
    /// Node hosting the storage pool.
    node: String,
    /// Mount path of the storage pool on the node.
    path: String,
    /// Total capacity of the storage pool.
    capacity: String,
    /// Capacity kept free on the storage pool, as configured.
    reserved: String,
    /// How the reserved capacity is interpreted, viz percentage.
    reserved_mode: String,
    /// Yes if the filesystem backing the pool supports copy on write, No if not.
    copy_on_write_supported: String,
}

/// Getter implementations for RawfilePoolObject.
impl RawfilePoolObject {
    /// Returns name of the storage pool.
    pub(crate) fn name(&self) -> &String {
        &self.name
    }

    /// Returns node hosting the storage pool.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns mount path of the storage pool.
    pub(crate) fn path(&self) -> &String {
        &self.path
    }

    /// Returns total capacity of the storage pool.
    pub(crate) fn capacity(&self) -> &String {
        &self.capacity
    }

    /// Returns capacity kept free on the storage pool.
    pub(crate) fn reserved(&self) -> &String {
        &self.reserved
    }

    /// Returns how the reserved capacity is interpreted.
    pub(crate) fn reserved_mode(&self) -> &String {
        &self.reserved_mode
    }

    /// Returns whether the storage pool supports copy on write.
    pub(crate) fn copy_on_write_supported(&self) -> &String {
        &self.copy_on_write_supported
    }
}

/// Takes a pool with its name and node, Returns RawfilePoolObject.
impl From<(&str, &str, &PoolStat)> for RawfilePoolObject {
    fn from((name, node, pool): (&str, &str, &PoolStat)) -> Self {
        Self {
            name: name.to_string(),
            node: node.to_string(),
            path: pool.path.clone(),
            capacity: adjust_bytes(pool.capacity as u128),
            reserved: pool.reserved_capacity.clone(),
            reserved_mode: pool.reserved_capacity_mode.clone(),
            copy_on_write_supported: yes_no(pool.copy_on_write_supported).to_string(),
        }
    }
}

/// A record containing a collection of localpv-rawfile storage pools.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfilePoolRecord {
    /// A vector of rawfile storage pools.
    pools: Vec<RawfilePoolObject>,
}

impl RawfilePoolRecord {
    /// Constructs RawfilePoolRecord object.
    pub(crate) fn new(pools: Vec<RawfilePoolObject>) -> Self {
        Self { pools }
    }

    /// Returns storage pool list present in the RawfilePoolRecord.
    pub(crate) fn pools(&self) -> &Vec<RawfilePoolObject> {
        &self.pools
    }
}
