use super::CliArgs;
use super::Error;
use super::{GetVolumeArg, GetVolumesArg};
pub(crate) mod types;
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{LvmVolume, LvmVolumeObject, LvolRecord};

use k8s_openapi::api::core::v1::PersistentVolume;
use kube::api::ObjectList;
use kube::Resource;
use kube::{api::ListParams, Api, Client};
use prettytable::{row, Row};

use lazy_static::lazy_static;

lazy_static! {
    pub(crate) static ref LVM_VOLUME_HEADER: Row =
        row!["NAME", "NODE", "STATUS", "CAPACITY", "VOLGROUP", "PVC-NAME", "SC-NAME",];
}

/// Implementation for volumes cmd.
pub(crate) async fn volumes(cli_args: &CliArgs, volumes_arg: &GetVolumesArg) -> Result<(), Error> {
    let client = Client::try_default().await?;
    let mut vol_list = list_lvm_volumes(cli_args, &client).await?.items;
    vol_list = if let Some(node_id) = &volumes_arg.node_id {
        vol_list
            .iter()
            .filter(|vol| vol.on_node(node_id))
            .cloned()
            .collect()
    } else {
        vol_list
    };
    match get_lvm_vol_output(vol_list, &client).await {
        Ok(lvol_record) => {
            print_table(&cli_args.output, lvol_record);
            Ok(())
        }
        Err(e) => Err(e),
    }
}

/// Implementation for volume cmd.
pub(crate) async fn volume(cli_args: &CliArgs, volume_arg: &GetVolumeArg) -> Result<(), Error> {
    let client = Client::try_default().await?;
    let api: Api<LvmVolume> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    let volume = api.get(&volume_arg.volume).await?;
    match get_lvm_vol_output(vec![volume], &client).await {
        Ok(lvol_record) => {
            print_table(&cli_args.output, lvol_record);
            Ok(())
        }
        Err(e) => Err(e),
    }
}

/// Lists lvm volume cr from the k8s cluster.
async fn list_lvm_volumes(
    cli_args: &CliArgs,
    client: &Client,
) -> Result<ObjectList<LvmVolume>, kube::Error> {
    let lp = ListParams::default();
    let api: Api<LvmVolume> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    api.list(&lp).await
}

/// Converts Vec<LvmVolume> into LvolRecord.
async fn get_lvm_vol_output(vols: Vec<LvmVolume>, client: &Client) -> Result<LvolRecord, Error> {
    let api: Api<PersistentVolume> = Api::<PersistentVolume>::all(client.clone());
    let mut vol_obj: Vec<LvmVolumeObject> = Vec::new();
    for vol in vols {
        let val = api.get(vol.meta().name.as_ref().unwrap().as_str()).await?;
        vol_obj.push(LvmVolumeObject::try_from((&vol, val))?);
    }
    Ok(LvolRecord::new(vol_obj))
}

impl GetHeaderRow for LvolRecord {
    fn get_header_row(&self) -> Row {
        (*LVM_VOLUME_HEADER).clone()
    }
}

impl CreateRows for LvolRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.volumes()
            .iter()
            .map(|vol| {
                row![
                    vol.name(),
                    vol.node(),
                    vol.status(),
                    vol.capacity(),
                    vol.vol_group(),
                    vol.pvc_name(),
                    vol.sc_name()
                ]
            })
            .collect()
    }
}
