use crate::constants::{FOUR_DOT_O, FOUR_DOT_THREE, THREE_DOT_FOUR_DOT_ONE};
use upgrade::{
    common::kube::client::{delete_loki_sts, list_pods},
    helm::{
        chart::{HelmValuesCollection, UmbrellaValues},
        client::HelmReleaseClient,
        upgrade::{HelmUpgradeRunner, HelmUpgrader},
    },
    vec_to_strings,
};

use async_trait::async_trait;
use semver::Version;
use std::{iter::once as iter_once, path::PathBuf};
use tempfile::NamedTempFile;
use tracing::info;

/// Type for upgrading an umbrella chart (openebs/openebs).
#[derive(Debug)]
pub struct UmbrellaUpgrader {
    pub(crate) chart_dir: PathBuf,
    pub(crate) release_name: String,
    pub(crate) namespace: String,
    pub(crate) client: HelmReleaseClient,
    pub(crate) helm_upgrade_extra_args: Vec<String>,
    // This needs to be here for the helm upgrade commands to work.
    #[allow(dead_code)]
    pub(crate) temp_values_file: NamedTempFile,
    pub(crate) source_version: Version,
    pub(crate) target_version: Version,
}

#[async_trait]
impl HelmUpgrader for UmbrellaUpgrader {
    /// Run the helm upgrade command with `--dry-run`.
    async fn dry_run(self: Box<Self>) -> upgrade::common::error::Result<HelmUpgradeRunner> {
        info!("Running helm upgrade dry-run...");
        self.client
            .upgrade(
                self.release_name.as_str(),
                self.chart_dir.as_path(),
                Some(
                    self.helm_upgrade_extra_args
                        .iter()
                        .cloned()
                        .chain(iter_once("--dry-run".to_string()))
                        .collect(),
                ),
            )
            .await?;
        info!("Helm upgrade dry-run succeeded!");

        // Returning HelmUpgradeRunner.
        Ok(Box::pin(async move {
            // Handle move from mayastor loki-stack to umbrella loki chart.
            if self.source_version.ge(&THREE_DOT_FOUR_DOT_ONE)
                && self.source_version.lt(&FOUR_DOT_THREE)
            {
                delete_loki_sts(self.release_name.clone(), self.namespace.clone()).await?
            }

            info!("Starting helm upgrade...");
            // This is what we do for upgrades from openebs v3
            //
            // Mayastor was disabled by default for OpenEBS v3. If the chart is a v3 one and
            // there are no Etcd Pods, we disable the Etcd preUpgradeJob and perform a helm upgrade.
            // If we don't do this, the Etcd preUpgradeJob gets stuck trying to mount the Etcd
            // JWT token. After helm helm upgrade, we perform a same version upgrade to the same
            // version (target version) again with the preUpgradeJob enabled, so that future
            // upgrades with helm upgrade --reuse-values and such flags don't keep the Etcd
            // preUpgradeJob disabled. Values for disabling the engines have changed since v3, so
            // disabling mayastor in v3 won't hold in v4.
            if self.source_version.lt(&FOUR_DOT_O) && {
                let etcd_selector = format!(
                    "app.kubernetes.io/name=etcd,app.kubernetes.io/instance={}",
                    self.release_name
                );
                let etcd_pods = list_pods(self.namespace, Some(etcd_selector), None).await?;
                etcd_pods.is_empty()
            } {
                self.client
                    .upgrade(
                        self.release_name.as_str(),
                        self.chart_dir.clone(),
                        Some(
                            self.helm_upgrade_extra_args
                                .iter()
                                .cloned()
                                .chain(vec_to_strings!(
                                    "--set",
                                    "mayastor.etcd.preUpgradeJob.enabled=false"
                                ))
                                .collect(),
                        ),
                    )
                    .await?;
                self.client
                    .upgrade(
                        self.release_name.as_str(),
                        self.chart_dir,
                        Some(
                            self.helm_upgrade_extra_args
                                .into_iter()
                                .chain(vec_to_strings!(
                                    "--set",
                                    "mayastor.etcd.preUpgradeJob.enabled=false"
                                ))
                                .collect(),
                        ),
                    )
                    .await?;
            } else {
                self.client
                    .upgrade(
                        self.release_name.as_str(),
                        self.chart_dir,
                        Some(self.helm_upgrade_extra_args),
                    )
                    .await?;
            }
            info!("Helm upgrade successful!");

            self.client
                .get_values_as_yaml::<String, String>(self.release_name, None)
                .and_then(|buf| UmbrellaValues::try_from(buf.as_slice()))
                .map(|uv| Box::new(uv) as Box<dyn HelmValuesCollection>)
        }))
    }

    /// Returns the source version of the UmbrellaUpgrader.
    fn source_version(&self) -> Version {
        self.source_version.clone()
    }

    /// Returns the target version of the UmbrellaUpgrader.
    fn target_version(&self) -> Version {
        self.target_version.clone()
    }
}
