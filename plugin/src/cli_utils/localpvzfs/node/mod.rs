pub(crate) mod types;
use super::CliArgs;
use super::Error;
use super::GetZpoolsArg;
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{ZfsNode, ZfsPoolRecord};

use kube::{api::ListParams, Api, Client};
use lazy_static::lazy_static;
use prettytable::{row, Row};

lazy_static! {
    static ref ZPOOL_HEADER: Row = row!["NAME", "NODE", "UUID", "FREE", "USED",];
}

/// Implementation for volume-groups cmd.
pub(crate) async fn zpools(
    cli_args: &CliArgs,
    args: &GetZpoolsArg,
    client: Client,
) -> Result<(), Error> {
    let api: Api<ZfsNode> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    let zfs_nodes = if let Some(node_id) = &args.node_id {
        vec![zfs_node(api, node_id)
            .await
            .map_err(|err| Error::Kube { source: err })?]
    } else {
        zfs_nodes(api)
            .await
            .map_err(|err| Error::Kube { source: err })?
    };
    let records = ZfsPoolRecord::from(zfs_nodes);
    print_table(&cli_args.output, records);
    Ok(())
}

/// Gets a specific lvmnode from k8s cluster.
async fn zfs_node(node_handle: Api<ZfsNode>, node_id: &str) -> Result<ZfsNode, kube::Error> {
    node_handle.get(node_id).await
}

/// Lists all zfsnodes from the cluster.
async fn zfs_nodes(node_handle: Api<ZfsNode>) -> Result<Vec<ZfsNode>, kube::Error> {
    let max_entries = 500i32;
    let mut lp: ListParams = ListParams::default().limit(max_entries as u32);
    let mut node_list = Vec::new();
    loop {
        let list = node_handle.list(&lp).await?;
        node_list.extend(list.items);
        match list.metadata.continue_ {
            Some(token) if !token.is_empty() => {
                lp = lp.continue_token(&token);
            }
            _ => break,
        }
    }
    Ok(node_list)
}

impl GetHeaderRow for ZfsPoolRecord {
    fn get_header_row(&self) -> Row {
        (*ZPOOL_HEADER).clone()
    }
}

impl CreateRows for ZfsPoolRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.pools()
            .iter()
            .map(|pool| {
                row![
                    pool.name(),
                    pool.node(),
                    pool.uuid(),
                    pool.free(),
                    pool.used(),
                ]
            })
            .collect()
    }
}
