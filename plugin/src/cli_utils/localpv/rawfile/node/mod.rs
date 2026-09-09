use super::{api::ApiClient, CliArgs, Error, GetNodeArg, GetPoolsArg};
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{RawfileNodeObject, RawfileNodeRecord, RawfilePoolObject, RawfilePoolRecord};

use lazy_static::lazy_static;
use prettytable::{row, Row};

pub(crate) mod types;

lazy_static! {
    pub(crate) static ref RAWFILE_NODE_HEADER: Row =
        row!["NAME", "IP", "STATUS", "POOLS", "CAPACITY",];
    pub(crate) static ref RAWFILE_POOL_HEADER: Row = row![
        "NAME",
        "NODE",
        "PATH",
        "CAPACITY",
        "RESERVED",
        "RESERVED-MODE",
        "COW-SUPPORTED",
    ];
}

/// Implementation for nodes cmd.
pub(crate) async fn nodes(cli_args: &CliArgs, api: &ApiClient) -> Result<(), Error> {
    let nodes = api.nodes().await?;
    let nodes = nodes.iter().map(RawfileNodeObject::from).collect();
    print_table(&cli_args.output, RawfileNodeRecord::new(nodes));
    Ok(())
}

/// Implementation for node cmd.
pub(crate) async fn node(
    cli_args: &CliArgs,
    node_arg: &GetNodeArg,
    api: &ApiClient,
) -> Result<(), Error> {
    let node = api
        .node(&node_arg.node)
        .await?
        .ok_or_else(|| Error::NotFound {
            resource: "Node".to_string(),
            name: node_arg.node.clone(),
        })?;
    let nodes = vec![RawfileNodeObject::from(&node)];
    print_table(&cli_args.output, RawfileNodeRecord::new(nodes));
    Ok(())
}

/// Implementation for pools cmd.
/// The api-server has no pool endpoint of its own: the pools of a node are reported as part of
/// the node itself.
pub(crate) async fn pools(
    cli_args: &CliArgs,
    pools_arg: &GetPoolsArg,
    api: &ApiClient,
) -> Result<(), Error> {
    let nodes = target_nodes(api, pools_arg.node.as_deref()).await?;
    let mut pools = Vec::new();
    for node in &nodes {
        for (name, pool) in node_pools(node) {
            pools.push(RawfilePoolObject::from((
                name.as_str(),
                node.name.as_str(),
                pool,
            )));
        }
    }
    print_table(&cli_args.output, RawfilePoolRecord::new(pools));
    Ok(())
}

/// Lists the nodes to walk: the requested one, or all of them.
pub(crate) async fn target_nodes(
    api: &ApiClient,
    node: Option<&str>,
) -> Result<Vec<super::api::Node>, Error> {
    match node {
        Some(node) => {
            let found = api.node(node).await?.ok_or_else(|| Error::NotFound {
                resource: "Node".to_string(),
                name: node.to_string(),
            })?;
            Ok(vec![found])
        }
        None => api.nodes().await,
    }
}

/// The storage pools of a node, empty if the api-server could not collect them.
pub(crate) fn node_pools(
    node: &super::api::Node,
) -> impl Iterator<Item = (&String, &super::api::PoolStat)> {
    match &node.pools_stat {
        Some(pools) => Some(pools.iter()),
        None => {
            eprintln!(
                "Couldnt get storage pools of localpv-rawfile node: {} (node is {})",
                node.name,
                if node.online { "online" } else { "offline" }
            );
            None
        }
    }
    .into_iter()
    .flatten()
}

impl GetHeaderRow for RawfileNodeRecord {
    fn get_header_row(&self) -> Row {
        (*RAWFILE_NODE_HEADER).clone()
    }
}

impl CreateRows for RawfileNodeRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.nodes()
            .iter()
            .map(|node| {
                row![
                    node.name(),
                    node.ip(),
                    node.status(),
                    node.pools(),
                    node.capacity()
                ]
            })
            .collect()
    }
}

impl GetHeaderRow for RawfilePoolRecord {
    fn get_header_row(&self) -> Row {
        (*RAWFILE_POOL_HEADER).clone()
    }
}

impl CreateRows for RawfilePoolRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.pools()
            .iter()
            .map(|pool| {
                row![
                    pool.name(),
                    pool.node(),
                    pool.path(),
                    pool.capacity(),
                    pool.reserved(),
                    pool.reserved_mode(),
                    pool.copy_on_write_supported()
                ]
            })
            .collect()
    }
}
