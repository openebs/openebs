pub(crate) mod types;
use super::CliArgs;
use super::Error;
use super::GetVolumeGroupsArg;
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{LvmNode, VolumeGroupRecord};

use kube::{api::ListParams, Api, Client};
use lazy_static::lazy_static;
use prettytable::{row, Row};

lazy_static! {
    static ref VOLUME_GROUP_HEADER: Row = row![
        "NAME",
        "NODE",
        "UUID",
        "TOTAL-SIZE",
        "FREE-SIZE",
        "LV-COUNT",
        "PV-COUNT",
        "SNAP-COUNT",
    ];
}

/// Implementation for volume-groups cmd.
pub(crate) async fn volume_groups(
    cli_args: &CliArgs,
    args: &GetVolumeGroupsArg,
) -> Result<(), Error> {
    let lvm_nodes = if let Some(node_id) = &args.node_id {
        let lvmnode = get_lvm_node(cli_args, node_id).await?;
        vec![lvmnode]
    } else {
        list_lvm_nodes(cli_args).await?
    };
    let records = VolumeGroupRecord::from(lvm_nodes);
    print_table(&cli_args.output, records);
    Ok(())
}

/// Gets a specific lvmnode from k8s cluster.
async fn get_lvm_node(cli_args: &CliArgs, node_id: &str) -> Result<LvmNode, kube::Error> {
    let client = Client::try_default().await?;
    let api: Api<LvmNode> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    api.get(node_id).await
}

/// Lists all lvmnodes from the cluster.
async fn list_lvm_nodes(cli_args: &CliArgs) -> Result<Vec<LvmNode>, kube::Error> {
    let client = Client::try_default().await?;
    let lp = ListParams::default();
    let api: Api<LvmNode> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    let lvm_nodes = api.list(&lp).await?.items;
    Ok(lvm_nodes)
}

impl GetHeaderRow for VolumeGroupRecord {
    fn get_header_row(&self) -> Row {
        (*VOLUME_GROUP_HEADER).clone()
    }
}

impl CreateRows for VolumeGroupRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.vgs()
            .iter()
            .map(|vg| {
                row![
                    vg.name(),
                    vg.node(),
                    vg.uuid(),
                    vg.total_size(),
                    vg.free_size(),
                    vg.lv_count(),
                    vg.pv_count(),
                    vg.snap_count(),
                ]
            })
            .collect()
    }
}
