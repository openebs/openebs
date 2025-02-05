use super::{CliArgs, Error, GetVolumeArg, GetVolumesArg};
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
pub(crate) mod types;
use types::{ZfsVolRecord, ZfsVolume, ZfsVolumeObject};

use k8s_openapi::api::core::v1::PersistentVolume;
use kube::ResourceExt;
use kube::{api::ListParams, Api, Client};
use lazy_static::lazy_static;
use prettytable::{row, Row};

lazy_static! {
    pub(crate) static ref ZFS_VOLUME_HEADER: Row =
        row!["NAME", "NODE", "STATUS", "CAPACITY", "POOL", "PVC-NAME", "SC-NAME",];
}

/// Implementation for volumes cmd.
pub(crate) async fn volumes(
    cli_args: &CliArgs,
    volumes_arg: &GetVolumesArg,
    client: Client,
) -> Result<(), Error> {
    let volume_handle: Api<ZfsVolume> = Api::namespaced(client.clone(), &cli_args.namespace);
    let vols = zfs_volumes(volume_handle, volumes_arg)
        .await
        .map_err(|err| Error::Kube { source: err })?;
    match get_zfs_vol_record(vols, &client).await {
        Ok(zvol_record) => {
            print_table(&cli_args.output, zvol_record);
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
    let volume_handle: Api<ZfsVolume> = Api::namespaced(client.clone(), &cli_args.namespace);
    let volume = zfs_volume(volume_handle, volume_arg)
        .await
        .map_err(|err| Error::Kube { source: err })?;
    match get_zfs_vol_record(vec![volume], &client).await {
        Ok(zvol_record) => {
            print_table(&cli_args.output, zvol_record);
            Ok(())
        }
        Err(e) => Err(e),
    }
}

/// Gets a specific zfs volume fom k8s.
async fn zfs_volume(
    volume_handle: Api<ZfsVolume>,
    volume_arg: &GetVolumeArg,
) -> Result<ZfsVolume, kube::Error> {
    let volume = volume_handle.get(&volume_arg.volume).await?;
    Ok(volume)
}

/// Lists zfsvolume cr. Filters based on node if specified.
async fn zfs_volumes(
    volume_handle: Api<ZfsVolume>,
    volumes_arg: &GetVolumesArg,
) -> Result<Vec<ZfsVolume>, kube::Error> {
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

/// Converts Vec<ZfsVolume> into ZfsRecord.
async fn get_zfs_vol_record(
    zfs_vols: Vec<ZfsVolume>,
    client: &Client,
) -> Result<ZfsVolRecord, Error> {
    let api: Api<PersistentVolume> = Api::<PersistentVolume>::all(client.clone());

    let pvs = list_pv(api).await?;
    let mut zfs_volumes: Vec<ZfsVolumeObject> = Vec::with_capacity(zfs_vols.len());
    for zfs_vol in zfs_vols {
        let zfs_vol_name = zfs_vol.name_unchecked();
        let pv = pvs.iter().find(|pv| pv.name_unchecked() == zfs_vol_name);

        if let Some(pv) = pv {
            zfs_volumes.push(ZfsVolumeObject::try_from((zfs_vol, pv.clone()))?);
        } else {
            eprintln!("Couldnt find PV for ZFS volume: {zfs_vol_name}");
        }
    }

    Ok(ZfsVolRecord::new(zfs_volumes))
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

impl GetHeaderRow for ZfsVolRecord {
    fn get_header_row(&self) -> Row {
        (*ZFS_VOLUME_HEADER).clone()
    }
}

impl CreateRows for ZfsVolRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.volumes()
            .iter()
            .map(|vol| {
                row![
                    vol.name(),
                    vol.node(),
                    vol.status(),
                    vol.capacity(),
                    vol.pool(),
                    vol.pvc_name(),
                    vol.sc_name()
                ]
            })
            .collect()
    }
}
