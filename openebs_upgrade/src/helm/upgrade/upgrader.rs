use async_trait::async_trait;
use semver::Version;
use std::path::PathBuf;
use tracing::info;
use upgrade::helm::{
    chart::{HelmValuesCollection, UmbrellaValues},
    client::HelmReleaseClient,
    upgrade::{HelmUpgradeRunner, HelmUpgrader},
};

#[derive(Clone, Debug)]
pub struct UmbrellaUpgrader {
    pub(crate) chart_dir: PathBuf,
    pub(crate) release_name: String,
    pub(crate) client: HelmReleaseClient,
    pub(crate) helm_upgrade_extra_args: Vec<String>,
    pub(crate) source_version: Version,
    pub(crate) target_version: Version,
}

#[async_trait]
impl HelmUpgrader for UmbrellaUpgrader {
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
                        .chain(std::iter::once("--dry-run".to_string()))
                        .collect(),
                ),
            )
            .await?;
        info!("Helm upgrade dry-run succeeded!");

        // Returning HelmUpgradeRunner.
        Ok(Box::pin(async move {
            info!("Starting helm upgrade...");
            self.client
                .upgrade(
                    self.release_name.as_str(),
                    self.chart_dir,
                    Some(self.helm_upgrade_extra_args),
                )
                .await?;
            info!("Helm upgrade successful!");

            self.client
                .get_values_as_yaml::<String, String>(self.release_name, None)
                .and_then(|buf| UmbrellaValues::try_from(buf.as_slice()))
                .map(|uv| Box::new(uv) as Box<dyn HelmValuesCollection>)
        }))
    }

    fn source_version(&self) -> Version {
        self.source_version.clone()
    }

    fn target_version(&self) -> Version {
        self.target_version.clone()
    }
}
