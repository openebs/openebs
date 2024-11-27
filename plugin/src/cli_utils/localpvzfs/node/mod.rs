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
pub(crate) async fn zpools(cli_args: &CliArgs, args: &GetZpoolsArg) -> Result<(), Error> {
    let client = Client::try_default()
        .await
        .map_err(|err| Error::Kube { source: err })?;
    let zfs_nodes = if let Some(node_id) = &args.node_id {
        vec![zfs_node(cli_args, node_id, client)
            .await
            .map_err(|err| Error::Kube { source: err })?]
    } else {
        zfs_nodes(cli_args, client)
            .await
            .map_err(|err| Error::Kube { source: err })?
    };
    let records = ZfsPoolRecord::from(zfs_nodes);
    print_table(&cli_args.output, records);
    Ok(())
}

/// Gets a specific lvmnode from k8s cluster.
async fn zfs_node(
    cli_args: &CliArgs,
    node_id: &str,
    client: Client,
) -> Result<ZfsNode, kube::Error> {
    let api: Api<ZfsNode> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    api.get(node_id).await
}

/// Lists all lvmnodes from the cluster.
async fn zfs_nodes(cli_args: &CliArgs, client: Client) -> Result<Vec<ZfsNode>, kube::Error> {
    let lp = ListParams::default();
    let api: Api<ZfsNode> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    let zfs_nodes = api.list(&lp).await?.items;
    Ok(zfs_nodes)
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
