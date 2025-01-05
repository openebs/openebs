use super::CliArgs;
use super::Error;
use super::{GetVolumeArg, GetVolumesArg};
pub(crate) mod types;
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{LvmVolRecord, LvmVolume, LvmVolumeObject};

use k8s_openapi::api::core::v1::PersistentVolume;
use kube::ResourceExt;
use kube::{api::ListParams, Api, Client};
use lazy_static::lazy_static;
use prettytable::{row, Row};

lazy_static! {
    pub(crate) static ref LVM_VOLUME_HEADER: Row =
        row!["NAME", "NODE", "STATUS", "CAPACITY", "VOLGROUP", "PVC-NAME", "SC-NAME",];
}

/// Implementation for volumes cmd.
pub(crate) async fn volumes(
    cli_args: &CliArgs,
    volumes_arg: &GetVolumesArg,
    client: Client,
) -> Result<(), Error> {
    let volume_handle: Api<LvmVolume> = Api::namespaced(client.clone(), &cli_args.namespace);
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
pub(crate) async fn volume(
    cli_args: &CliArgs,
    volume_arg: &GetVolumeArg,
    client: Client,
) -> Result<(), Error> {
    let volume_handle: Api<LvmVolume> = Api::namespaced(client.clone(), &cli_args.namespace);
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
    let max_entries = 500i32;
    let mut lp: ListParams = if let Some(node_id) = &volumes_arg.node_id {
        ListParams::default()
            .labels(format!("kubernetes.io/nodename={}", node_id).as_str())
            .limit(max_entries as u32)
    } else {
        ListParams::default().limit(max_entries as u32)
    };
    let mut vol_list = Vec::new();
    loop {
        let list = volume_handle.list(&lp).await?;
        vol_list.extend(list.items);
        match list.metadata.continue_ {
            Some(token) if !token.is_empty() => {
                lp = lp.continue_token(&token);
            }
            _ => break,
        }
    }
    Ok(vol_list)
}

/// Converts Vec<LvmVolume> into LvolRecord.
async fn get_lvm_vol_output(
    lvm_vols: Vec<LvmVolume>,
    client: &Client,
) -> Result<LvmVolRecord, Error> {
    let api: Api<PersistentVolume> = Api::<PersistentVolume>::all(client.clone());

    let pvs = list_pv(api).await?;

    let mut lvm_volumes: Vec<LvmVolumeObject> = Vec::with_capacity(lvm_vols.len());
    for lvm_vol in lvm_vols {
        let lvm_vol_name = lvm_vol.name_unchecked();

        // Find the matching PV
        let pv = pvs.iter().find(|pv| pv.name_unchecked() == lvm_vol_name);

        if let Some(pv) = pv {
            lvm_volumes.push(LvmVolumeObject::try_from((&lvm_vol, pv.clone()))?);
        } else {
            eprintln!("Couldnt find PV for LVM volume: {lvm_vol_name}");
        }
    }

    Ok(LvmVolRecord::new(lvm_volumes))
}

/// Lists all pv from k8s.
async fn list_pv(pv_handle: Api<PersistentVolume>) -> Result<Vec<PersistentVolume>, Error> {
    let max_entries = 500i32;
    let mut list_param = ListParams::default().limit(max_entries as u32);
    let mut vol_list = Vec::new();
    loop {
        let list = pv_handle
            .list(&list_param)
            .await
            .map_err(|err| Error::Kube { source: err })?;
        vol_list.extend(list.items);
        match list.metadata.continue_ {
            Some(token) => list_param = list_param.continue_token(&token),
            None => break,
        }
    }
    Ok(vol_list)
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
