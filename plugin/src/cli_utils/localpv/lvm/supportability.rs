use crate::cli_utils::localpv::lvm::node::lvm_nodes;
use crate::cli_utils::localpv::lvm::node::types::LvmNode;
use crate::cli_utils::localpv::lvm::volume::lvm_volumes;
use crate::cli_utils::localpv::lvm::volume::types::LvmVolume;
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

async fn dump_typed_lvm_nodes(k8s_client: &ClientSet, root_dir: &Path) -> Result<(), Error> {
    log("\t Collecting LVM Node Resources...".to_string());

    let api: Api<LvmNode> = Api::namespaced(k8s_client.kube_client(), k8s_client.namespace());
    let result = lvm_nodes(api).await.map_err(|error| {
        Error::K8sResourceDumperError(K8sResourceDumperError::K8sResourceError(
            K8sResourceError::ClientError(error),
        ))
    })?;

    create_file_and_write(
        root_dir.to_path_buf(),
        "lvm_nodes.yaml".to_string(),
        serde_yaml::to_string(&result).map_err(|e| {
            Error::K8sResourceDumperError(K8sResourceDumperError::YamlSerializationError(e))
        })?,
    )
    .map_err(K8sResourceDumperError::IOError)?;

    Ok(())
}

async fn dump_typed_lvm_volumes(k8s_client: &ClientSet, root_dir: &Path) -> Result<(), Error> {
    log("\t Collecting LVM Volume Resources".to_string());

    let api: Api<LvmVolume> = Api::namespaced(k8s_client.kube_client(), k8s_client.namespace());
    let result = lvm_volumes(api, None).await.map_err(|error| {
        Error::K8sResourceDumperError(K8sResourceDumperError::K8sResourceError(
            K8sResourceError::ClientError(error),
        ))
    })?;

    create_file_and_write(
        root_dir.to_path_buf(),
        "lvm_volumes.yaml".to_string(),
        serde_yaml::to_string(&result).map_err(|e| {
            Error::K8sResourceDumperError(K8sResourceDumperError::YamlSerializationError(e))
        })?,
    )
    .map_err(K8sResourceDumperError::IOError)?;

    Ok(())
}

async fn dump_lvm_vscont_and_vs_class(
    k8s_client: &ClientSet,
    root_path: &Path,
) -> Result<(), Error> {
    let lvm_driver = "local.csi.openebs.io".to_string();

    // Create the root dir path
    create_directory_if_not_exist(root_path.to_path_buf())?;

    let mut errors = Vec::new();

    // Fetch all VolumeSnapshotClasses for given lvm driver
    if let Err(error) = get_k8s_vs_classes(k8s_client, root_path, lvm_driver.clone()).await {
        errors.push(error)
    }

    // Fetch all VolumeSnapshotContents for given lvm driver
    if let Err(error) = get_k8s_vsnapshot_contents(k8s_client, root_path, lvm_driver).await {
        errors.push(error)
    }

    if !errors.is_empty() {
        return Err(Error::K8sResourceDumperError(
            K8sResourceDumperError::MultipleErrors(errors),
        ));
    }
    Ok(())
}

pub async fn lvm_dump(k8s_client: &ClientSet, root_dir: &Path) -> Result<(), Error> {
    log("Collecting LVM LocalPV Specific Resources...".to_string());
    let mut errors = Vec::new();

    let mut root_dir = root_dir.to_path_buf();
    root_dir.push("lvm");
    create_directory_if_not_exist(root_dir.clone())?;

    if let Err(e) = dump_typed_lvm_nodes(k8s_client, &root_dir).await {
        errors.push(e);
    }

    if let Err(e) = dump_typed_lvm_volumes(k8s_client, &root_dir).await {
        errors.push(e);
    }

    if let Err(e) = dump_dynamic_resource(
        k8s_client,
        &root_dir,
        "local.openebs.io",
        "v1alpha1",
        "LVMSnapshot",
        "lvm_snaps.yaml",
    )
    .await
    {
        errors.push(e);
    }

    if let Err(e) = dump_lvm_vscont_and_vs_class(k8s_client, &root_dir).await {
        errors.push(e);
    }

    if !errors.is_empty() {
        log("Failed to dump LVM resources".to_string());
        return Err(Error::MultipleErrors(errors));
    }

    log("Completed collection of LVM LocalPV Specific Resources".to_string());
    Ok(())
}
