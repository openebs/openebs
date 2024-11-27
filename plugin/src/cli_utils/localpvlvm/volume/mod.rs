use super::CliArgs;
use super::Error;
use super::{GetVolumeArg, GetVolumesArg};
pub(crate) mod types;
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{LvmVolRecord, LvmVolume, LvmVolumeObject};

use k8s_openapi::api::core::v1::PersistentVolume;
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
    let client = Client::try_default()
        .await
        .map_err(|err| Error::Kube { source: err })?;
    let volume_handle: Api<LvmVolume> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    let vol_list = lvm_volumes(volume_handle, volumes_arg)
        .await
        .map_err(|err| Error::Kube { source: err })?;
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
    let client = Client::try_default()
        .await
        .map_err(|err| Error::Kube { source: err })?;
    let volume_handle: Api<LvmVolume> = Api::namespaced(client.clone(), &cli_args.args.namespace);
    let volume = lvm_volume(volume_handle, volume_arg)
        .await
        .map_err(|err| Error::Kube { source: err })?;
    match get_lvm_vol_output(vec![volume], &client).await {
        Ok(lvol_record) => {
            print_table(&cli_args.output, lvol_record);
            Ok(())
        }
        Err(e) => Err(e),
    }
}

/// Get lvm volume cr from the k8s cluster.
async fn lvm_volume(
    volume_handle: Api<LvmVolume>,
    volume_arg: &GetVolumeArg,
) -> Result<LvmVolume, kube::Error> {
    let volume = volume_handle.get(&volume_arg.volume).await?;
    Ok(volume)
}

/// Lists lvm volume cr from the k8s cluster. Retuns volumes from specific node if node is specified.
async fn lvm_volumes(
    volume_handle: Api<LvmVolume>,
    volumes_arg: &GetVolumesArg,
) -> Result<Vec<LvmVolume>, kube::Error> {
    let lp = if let Some(node_id) = volumes_arg.node_id.clone() {
        ListParams::default().labels(format!("kubernetes.io/nodename={}", node_id).as_str())
    } else {
        ListParams::default()
    };
    Ok(volume_handle.list(&lp).await?.items)
}

/// Converts Vec<LvmVolume> into LvolRecord.
async fn get_lvm_vol_output(
    lvm_vols: Vec<LvmVolume>,
    client: &Client,
) -> Result<LvmVolRecord, Error> {
    let api: Api<PersistentVolume> = Api::<PersistentVolume>::all(client.clone());
    let mut lvm_volumes: Vec<LvmVolumeObject> = Vec::new();
    for lvm_vol in lvm_vols {
        let pv = api
            .get(
                lvm_vol
                    .meta()
                    .name
                    .as_ref()
                    .ok_or(Error::Generic {
                        source: anyhow::anyhow!("PV name missing"),
                    })?
                    .as_str(),
            )
            .await
            .map_err(|err| Error::Kube { source: err })?;
        lvm_volumes.push(LvmVolumeObject::try_from((&lvm_vol, pv))?);
    }
    Ok(LvmVolRecord::new(lvm_volumes))
}

impl GetHeaderRow for LvmVolRecord {
    fn get_header_row(&self) -> Row {
        (*LVM_VOLUME_HEADER).clone()
    }
}

impl CreateRows for LvmVolRecord {
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
