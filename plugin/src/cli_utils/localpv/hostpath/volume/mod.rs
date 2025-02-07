use super::{CliArgs, Error, GetVolumeArg, GetVolumesArg};
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
pub(crate) mod types;
use types::{HostPathVolume, HostPathVolumeRecord};

use anyhow::anyhow;
use k8s_openapi::api::core::v1::PersistentVolume;
use kube::{api::ListParams, Api, Client};
use lazy_static::lazy_static;
use prettytable::{row, Row};

lazy_static! {
    pub(crate) static ref HOSTPATH_VOLUME_HEADER: Row =
        row!["NAME", "NODE", "STATUS", "CAPACITY", "PATH", "PVC-NAME", "SC-NAME",];
}

impl CreateRows for HostPathVolumeRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.volumes()
            .iter()
            .map(|vol| {
                row![
                    vol.name(),
                    vol.node(),
                    vol.status(),
                    vol.capacity(),
                    vol.path(),
                    vol.pvc_name(),
                    vol.sc_name()
                ]
            })
            .collect()
    }
}

impl GetHeaderRow for HostPathVolumeRecord {
    fn get_header_row(&self) -> Row {
        (*HOSTPATH_VOLUME_HEADER).clone()
    }
}

/// Implementation for volume cmd.
pub(crate) async fn volume(
    cli_args: &CliArgs,
    volume_arg: &GetVolumeArg,
    client: Client,
) -> Result<(), Error> {
    let pv_handle: Api<PersistentVolume> = Api::<PersistentVolume>::all(client);
    let pv = get_pv(pv_handle, volume_arg).await?;
    match get_hostpath_volume(vec![pv], None).await {
        Ok(hostpath_record) => {
            print_table(&cli_args.output, hostpath_record);
            Ok(())
        }
        Err(e) => Err(e),
    }
}

/// Implementation for volumes cmd.
pub(crate) async fn volumes(
    cli_args: &CliArgs,
    volumes_arg: &GetVolumesArg,
    client: Client,
) -> Result<(), Error> {
    let pv_handle: Api<PersistentVolume> = Api::<PersistentVolume>::all(client);
    let pv_list = list_pv(pv_handle).await?;
    match get_hostpath_volume(pv_list, volumes_arg.node_id.clone()).await {
        Ok(hv_list) => {
            print_table(&cli_args.output, hv_list);
            Ok(())
        }
        Err(e) => Err(e),
    }
}

/// Gets a particular persistent volume from k8s. Returns error if pv is not hostpath volume.
pub(crate) async fn get_pv(
    pv_handle: Api<PersistentVolume>,
    volume_arg: &GetVolumeArg,
) -> Result<PersistentVolume, Error> {
    let pv = pv_handle
        .get(&volume_arg.volume)
        .await
        .map_err(|err| Error::Kube { source: err })?;

    if let Some(labels) = &pv.metadata.labels {
        if labels.get("openebs.io/cas-type").map(String::as_str) != Some("local-hostpath") {
            return Err(Error::Generic {
                source: anyhow!("Volume is not a hostpath volume"),
            });
        }
    } else {
        return Err(Error::Generic {
            source: anyhow!("Volume doesn't have a label. Not a hostpath volume."),
        });
    }
    Ok(pv)
}

/// Lists all localpv-hostpath pv from k8s.
async fn list_pv(pv_handle: Api<PersistentVolume>) -> Result<Vec<PersistentVolume>, Error> {
    let max_entries = 500i32;
    let mut list_param = ListParams::default()
        .labels("openebs.io/cas-type=local-hostpath")
        .limit(max_entries as u32);
    let mut vol_list = Vec::new();
    loop {
        let list = pv_handle
            .list(&list_param)
            .await
            .map_err(|err| Error::Kube { source: err })?;
        vol_list.extend(list.items);
        match list.metadata.continue_ {
            Some(token) if !token.is_empty() => list_param = list_param.continue_token(&token),
            _ => break,
        }
    }
    Ok(vol_list)
}

/// Converts list of pv into list of hostpath volume.
pub(crate) async fn get_hostpath_volume(
    pv_list: Vec<PersistentVolume>,
    node_id: Option<String>,
) -> Result<HostPathVolumeRecord, Error> {
    let mut vol_list: Vec<HostPathVolume> = Vec::new();
    for pv in pv_list {
        let hostpath_volume = HostPathVolume::try_from(pv)?;
        if let Some(node) = node_id.as_ref() {
            if node == hostpath_volume.node() {
                vol_list.push(hostpath_volume)
            } else {
                continue;
            }
        } else {
            vol_list.push(hostpath_volume)
        }
    }
    Ok(HostPathVolumeRecord::new(vol_list))
}
