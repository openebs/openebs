use super::{
    api::{ApiClient, Node},
    node::{node_pools, target_nodes},
    CliArgs, Error, GetVolumeArg, GetVolumesArg,
};
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{RawfileVolRecord, RawfileVolumeObject};

use lazy_static::lazy_static;
use prettytable::{row, Row};

pub(crate) mod types;

lazy_static! {
    pub(crate) static ref RAWFILE_VOLUME_HEADER: Row = row![
        "NAME",
        "NODE",
        "POOL",
        "STATUS",
        "SIZE",
        "USED",
        "PHYSICAL-SIZE",
        "THIN",
        "COW",
        "CREATED-AT",
    ];
}

/// Implementation for volumes cmd.
pub(crate) async fn volumes(
    cli_args: &CliArgs,
    volumes_arg: &GetVolumesArg,
    api: &ApiClient,
) -> Result<(), Error> {
    let nodes = target_nodes(api, volumes_arg.node.as_deref()).await?;
    let mut volumes = Vec::new();
    for node in &nodes {
        for pool in pool_names(node, volumes_arg.pool.as_deref()) {
            // The api-server reports nothing for a node it cannot reach.
            let Some(pool_volumes) = api.volumes(&node.name, &pool).await? else {
                eprintln!(
                    "Couldnt get volumes of localpv-rawfile pool {pool} on node: {}",
                    node.name
                );
                continue;
            };
            volumes.extend(
                pool_volumes
                    .iter()
                    .map(|volume| RawfileVolumeObject::from((node.name.as_str(), volume))),
            );
        }
    }
    print_table(&cli_args.output, RawfileVolRecord::new(volumes));
    Ok(())
}

/// Implementation for volume cmd.
pub(crate) async fn volume(
    cli_args: &CliArgs,
    volume_arg: &GetVolumeArg,
    api: &ApiClient,
) -> Result<(), Error> {
    let volume = match (&volume_arg.node, &volume_arg.pool) {
        // Both are known, so the volume can be fetched directly.
        (Some(node), Some(pool)) => api
            .volume(node, pool, &volume_arg.volume)
            .await?
            .map(|volume| RawfileVolumeObject::from((node.as_str(), &volume))),
        // Otherwise the volume has to be looked for on each pool of each candidate node.
        _ => {
            let nodes = target_nodes(api, volume_arg.node.as_deref()).await?;
            let mut found = None;
            'nodes: for node in &nodes {
                for pool in pool_names(node, volume_arg.pool.as_deref()) {
                    if let Some(volume) = api.volume(&node.name, &pool, &volume_arg.volume).await? {
                        found = Some(RawfileVolumeObject::from((node.name.as_str(), &volume)));
                        break 'nodes;
                    }
                }
            }
            found
        }
    };
    let volume = volume.ok_or_else(|| Error::NotFound {
        resource: "Volume".to_string(),
        name: volume_arg.volume.clone(),
    })?;
    print_table(&cli_args.output, RawfileVolRecord::new(vec![volume]));
    Ok(())
}

/// The pools of the node to look in, narrowed down to the requested one if there is one.
fn pool_names(node: &Node, pool: Option<&str>) -> Vec<String> {
    node_pools(node)
        .map(|(name, _)| name.clone())
        .filter(|name| pool.is_none_or(|wanted| wanted == name.as_str()))
        .collect()
}

impl GetHeaderRow for RawfileVolRecord {
    fn get_header_row(&self) -> Row {
        (*RAWFILE_VOLUME_HEADER).clone()
    }
}

impl CreateRows for RawfileVolRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.volumes()
            .iter()
            .map(|vol| {
                row![
                    vol.name(),
                    vol.node(),
                    vol.pool(),
                    vol.status(),
                    vol.size(),
                    vol.used(),
                    vol.physical_size(),
                    vol.thin(),
                    vol.copy_on_write(),
                    vol.created_at()
                ]
            })
            .collect()
    }
}
