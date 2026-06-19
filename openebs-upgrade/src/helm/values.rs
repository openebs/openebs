use crate::{
    constants::FOUR_DOT_O,
    error::{FailedCheckingInstallingCRDs, FailedTempFileCreation, Result},
};
use upgrade::{
    common::kube::client as KubeClient,
    helm::yaml::yq::{YamlKey, YqV4},
};

use semver::Version;
use snafu::ResultExt;
use std::{collections::HashMap, path::Path};
use tempfile::NamedTempFile;

/// Generate values file to override select helm values options.
pub(crate) async fn generate_values_file<P: AsRef<Path>>(
    chart_dir: P,
    source_version: &Version,
    target_version: &Version,
) -> Result<NamedTempFile> {
    let values_file =
        NamedTempFile::new_in(chart_dir.as_ref()).context(FailedTempFileCreation {
            path: chart_dir.as_ref().to_path_buf(),
        })?;

    if source_version.lt(&FOUR_DOT_O) && !target_version.lt(&FOUR_DOT_O) {
        safe_crd_install(values_file.path())
            .await
            .context(FailedCheckingInstallingCRDs)?;
    }

    Ok(values_file)
}

async fn safe_crd_install(path: &Path) -> upgrade::common::error::Result<()> {
    let yq = YqV4::new()?;

    let mut crds_to_helm_toggle = crd_names_to_helm_toggles()?;

    let all_crd_names: Vec<String> = KubeClient::list_crds_metadata()
        .await?
        .into_iter()
        // This unwrap should be fine, as it's done on a resource which we get from K8s api-server.
        .map(|crd| crd.metadata.name.unwrap())
        .collect();
    for (crd_set, helm_toggle) in crds_to_helm_toggle.drain() {
        // Uses an OR logical check to disable set installation, i.e. disable if
        // at least one exists. Does not make sure if all exist.
        if all_crd_names
            .iter()
            .any(|name| crd_set.contains(&name.as_str()))
        {
            yq.set_unquoted_value(helm_toggle, false, path)?;
        }
    }

    Ok(())
}

fn crd_names_to_helm_toggles() -> upgrade::common::error::Result<HashMap<Vec<&'static str>, YamlKey>>
{
    let mut crds_to_helm_toggle: HashMap<Vec<&'static str>, YamlKey> = HashMap::new();
    crds_to_helm_toggle.insert(
        vec![
            "volumesnapshotclasses.snapshot.storage.k8s.io",
            "volumesnapshotcontents.snapshot.storage.k8s.io",
            "volumesnapshots.snapshot.storage.k8s.io",
        ],
        YamlKey::try_from(".openebs-crds.csi.volumeSnapshots.enabled")?,
    );
    crds_to_helm_toggle.insert(
        vec!["jaegers.jaegertracing.io"],
        YamlKey::try_from(".mayastor.crds.jaeger.enabled")?,
    );
    crds_to_helm_toggle.insert(
        vec![
            "zfsvolumes.zfs.openebs.io",
            "zfsnodes.zfs.openebs.io",
            "zfsbackups.zfs.openebs.io",
            "zfsrestores.zfs.openebs.io",
            "zfssnapshots.zfs.openebs.io",
        ],
        YamlKey::try_from(".zfs-localpv.crds.zfsLocalPv.enabled")?,
    );
    crds_to_helm_toggle.insert(
        vec![
            "lvmvolumes.local.openebs.io",
            "lvmnodes.local.openebs.io",
            "lvmsnapshots.local.openebs.io",
        ],
        YamlKey::try_from(".lvm-localpv.crds.lvmLocalPv.enabled")?,
    );

    Ok(crds_to_helm_toggle)
}

#[cfg(test)]
mod tests {
    use super::crd_names_to_helm_toggles;

    #[test]
    fn lvm_crd_detection_uses_local_openebs_group() {
        let mappings = crd_names_to_helm_toggles().expect("crd toggle mappings should build");

        assert!(mappings
            .keys()
            .any(|names| names.contains(&"lvmvolumes.local.openebs.io")
                && names.contains(&"lvmnodes.local.openebs.io")
                && names.contains(&"lvmsnapshots.local.openebs.io")));
    }
}
