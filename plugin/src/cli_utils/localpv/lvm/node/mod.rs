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
    client: Client,
) -> Result<(), Error> {
    let api: Api<LvmNode> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    let lvm_nodes = if let Some(node_id) = &args.node_id {
        vec![lvm_node(api, node_id)
            .await
            .map_err(|err| Error::Kube { source: err })?]
    } else {
        lvm_nodes(api)
            .await
            .map_err(|err| Error::Kube { source: err })?
    };
    let records = VolumeGroupRecord::from(lvm_nodes);
    print_table(&cli_args.output, records);
    Ok(())
}

/// Gets a specific lvmnode from k8s cluster.
async fn lvm_node(node_handle: Api<LvmNode>, node_id: &str) -> Result<LvmNode, kube::Error> {
    node_handle.get(node_id).await
}

/// Lists all lvmnodes from the cluster.
async fn lvm_nodes(node_handle: Api<LvmNode>) -> Result<Vec<LvmNode>, kube::Error> {
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
