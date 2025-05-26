use crate::cli_utils::localpv::zfs::node::types::ZfsNode;
use crate::cli_utils::localpv::zfs::node::zfs_nodes;
use crate::cli_utils::localpv::zfs::volume::types::ZfsVolume;
use crate::cli_utils::localpv::zfs::volume::zfs_volumes;
use crate::cli_utils::supportability::dump::dump_dynamic_resource;
use supportability::collect::error::Error;
use supportability::collect::k8s_resources::client::{ClientSet, K8sResourceError};
use supportability::collect::k8s_resources::k8s_resource_dump::{
    create_file_and_write, get_k8s_vs_classes, get_k8s_vsnapshot_contents, K8sResourceDumperError,
};
use supportability::collect::logs::create_directory_if_not_exist;
use supportability::collect::utils::log;

use kube::Api;
use std::path::Path;

async fn dump_typed_zfs_nodes(k8s_client: &ClientSet, root_dir: &Path) -> Result<(), Error> {
    log("\t Collecting ZFS Node Resources".to_string());

    let api: Api<ZfsNode> = Api::namespaced(k8s_client.kube_client(), k8s_client.namespace());

    let result = match zfs_nodes(api).await {
        Ok(val) => val,
        Err(kube::Error::Api(ref e)) if e.code == 404 => {
            return Ok(());
        }
        Err(err) => {
            return Err(Error::K8sResourceDumperError(
                K8sResourceDumperError::K8sResourceError(K8sResourceError::ClientError(err)),
            ));
        }
    };

    if !result.is_empty() {
        create_file_and_write(
            root_dir.to_path_buf(),
            "zfs_nodes.yaml".to_string(),
            serde_yaml::to_string(&result).map_err(|e| {
                Error::K8sResourceDumperError(K8sResourceDumperError::YamlSerializationError(e))
            })?,
        )
        .map_err(K8sResourceDumperError::IOError)?;
    }

    Ok(())
}

async fn dump_typed_zfs_volumes(k8s_client: &ClientSet, root_dir: &Path) -> Result<(), Error> {
    log("\t Collecting ZFS Volume Resources".to_string());

    let api: Api<ZfsVolume> = Api::namespaced(k8s_client.kube_client(), k8s_client.namespace());

    let result = match zfs_volumes(api, None).await {
        Ok(val) => val,
        Err(kube::Error::Api(ref e)) if e.code == 404 => {
            return Ok(());
        }
        Err(err) => {
            return Err(Error::K8sResourceDumperError(
                K8sResourceDumperError::K8sResourceError(K8sResourceError::ClientError(err)),
            ));
        }
    };

    if !result.is_empty() {
        create_file_and_write(
            root_dir.to_path_buf(),
            "zfs_volumes.yaml".to_string(),
            serde_yaml::to_string(&result).map_err(|e| {
                Error::K8sResourceDumperError(K8sResourceDumperError::YamlSerializationError(e))
            })?,
        )
        .map_err(K8sResourceDumperError::IOError)?;
    }

    Ok(())
}

async fn dump_zfs_vscont_and_vs_class(
    k8s_client: &ClientSet,
    root_path: &Path,
) -> Result<(), Error> {
    let zfs_driver = "zfs.csi.openebs.io".to_string();

    // Create the root dir path
    create_directory_if_not_exist(root_path.to_path_buf())?;

    let mut errors = Vec::new();

    // Fetch all VolumeSnapshotClasses for given zfs driver
    if let Err(error) = get_k8s_vs_classes(k8s_client, root_path, zfs_driver.clone()).await {
        errors.push(error)
    }

    // Fetch all VolumeSnapshotContents for given zfs driver
    if let Err(error) = get_k8s_vsnapshot_contents(k8s_client, root_path, zfs_driver).await {
        errors.push(error)
    }

    if !errors.is_empty() {
        return Err(Error::K8sResourceDumperError(
            K8sResourceDumperError::MultipleErrors(errors),
        ));
    }
    Ok(())
}

/// Dump zfs localpv specific CRs, VolumeSnapshotContents and VolumeSnapshotClasses.
pub async fn zfs_dump(k8s_client: &ClientSet, root_dir: &Path) -> Result<(), Error> {
    log("Collecting ZFS LocalPV Specific Resources...".to_string());

    let mut errors = Vec::new();
    let mut root_dir = root_dir.to_path_buf();
    root_dir.push("zfs");
    create_directory_if_not_exist(root_dir.clone())?;

    if let Err(e) = dump_typed_zfs_nodes(k8s_client, &root_dir).await {
        errors.push(e);
    }

    if let Err(e) = dump_typed_zfs_volumes(k8s_client, &root_dir).await {
        errors.push(e);
    }

    let zfs_group = "zfs.openebs.io";

    let dynamic_resources = [
        ("ZFSSnapshot", "v1", "zfs_snaps.yaml"),
        ("ZFSRestore", "v1", "zfs_restores.yaml"),
        ("ZFSBackup", "v1", "zfs_backups.yaml"),
    ];

    for (resource, zfs_version, filename) in &dynamic_resources {
        if let Err(e) = dump_dynamic_resource(
            k8s_client,
            &root_dir,
            zfs_group,
            zfs_version,
            resource,
            filename,
        )
        .await
        {
            errors.push(e);
        }
    }

    if let Err(e) = dump_zfs_vscont_and_vs_class(k8s_client, &root_dir).await {
        errors.push(e);
    }

    if !errors.is_empty() {
        log("Failed to dump ZFS resources".to_string());
        return Err(Error::MultipleErrors(errors));
    }

    log("Completed collection of ZFS LocalPV Specific Resources".to_string());
    Ok(())
}
