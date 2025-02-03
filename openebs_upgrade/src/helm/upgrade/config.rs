use crate::{
    constants::{UMBRELLA_CHART_NAME, UMBRELLA_CHART_VERSION_LOWERBOUND},
    error::{
        ByteVectorToString, DowngradeNotSupported, FailedHelmReleaseClientBuild,
        FailedToGetLocalChartVersion, InvalidChartStatus, InvalidChartVersion, InvalidHelmChart,
        InvalidHelmVersion, MalformedHelmChartDir, ParseSemverVersion, Result,
    },
    helm::{metadata::HelmChartMetadata, upgrade::upgrader::UmbrellaUpgrader},
    utils::{check_path, exec_tokio_command, flatten_task},
};
use semver::Version;
use snafu::{ensure, ResultExt};
use std::{fs::Metadata, path::PathBuf};
use tokio::{spawn, try_join};
use tracing::debug;
use upgrade::{
    helm::{client::HelmReleaseClient, upgrade::HelmUpgrader},
    upgrade_path::version_from_chart_yaml_file,
};

#[derive(Clone, Debug)]
pub struct HelmUpgradeConfig {
    pub release_name: String,
    pub namespace: String,
    pub chart_dir: PathBuf,
    pub skip_upgrade_path_validation: bool,
    pub helm_command_config: HelmCommandConfig,
}

#[derive(Clone, Debug)]
pub struct HelmCommandConfig {
    pub args_set: Option<String>,
    pub args_set_file: Option<String>,
    pub storage_driver: String,
}

impl HelmUpgradeConfig {
    pub async fn validate_and_build_helm_upgrader(self) -> Result<impl HelmUpgrader> {
        let chart_metadata = HelmChartMetadata::new(
            self.release_name.as_str(),
            self.namespace.as_str(),
            self.helm_command_config.storage_driver.as_str(),
        )
        .await?;

        self.validate_inputs(chart_metadata.clone()).await?;

        let source_version = chart_metadata.version;
        let target_version = version_from_chart_yaml_file(self.chart_dir.clone())
            .context(FailedToGetLocalChartVersion)?;
        if !self.skip_upgrade_path_validation {
            ensure!(
                target_version.ge(&source_version),
                DowngradeNotSupported {
                    source_version,
                    target_version
                }
            );
        }

        Ok(UmbrellaUpgrader {
            chart_dir: self.chart_dir,
            release_name: self.release_name,
            client: HelmReleaseClient::builder()
                .with_namespace(self.namespace)
                .with_storage_driver(self.helm_command_config.storage_driver)
                .build()
                .context(FailedHelmReleaseClientBuild)?,
            helm_upgrade_extra_args: [
                self.helm_command_config
                    .args_set
                    .map(|val| ["--set".to_string(), val]),
                self.helm_command_config
                    .args_set_file
                    .map(|val| ["--set-file".to_string(), val]),
                Some(["--atomic", "--reset-then-reuse-values"].map(ToString::to_string)),
            ]
            .into_iter()
            // Drop the None, unwrap the Some.
            .flatten()
            // Flatten the [String;2] into individual Strings.
            .flatten()
            .collect(),
            source_version,
            target_version,
        })
    }

    async fn validate_inputs(&self, chart_metadata: HelmChartMetadata) -> Result<()> {
        let helm_version_check = spawn(check_helm_v3_14_in_path());
        let helm_release_check = spawn(check_helm_release(chart_metadata));
        let helm_chart_dir_check = spawn(check_helm_chart_dir(self.chart_dir.clone()));

        try_join!(
            flatten_task(helm_version_check),
            flatten_task(helm_release_check),
            flatten_task(helm_chart_dir_check)
        )?;

        Ok(())
    }
}

/// Checks to see if helm exists in PATH and if it is v3.14 or newer.
async fn check_helm_v3_14_in_path() -> Result<()> {
    let command: &str = "helm";
    let args: &[&str; 2] = &["version", "--short"];
    debug!(%command, ?args, "Executing helm command to see if helm exists in PATH");
    let output = exec_tokio_command(
        command.to_string(),
        args.iter().map(ToString::to_string).collect(),
        None,
    )
    .await?;
    debug!(
        status = %output.status,
        stdout = ?output.stdout,
        stderr = ?output.stderr,
        "Executing helm command to see if helm exists in PATH: command succeeded"
    );

    let three_dot_fourteen = Version::new(3, 14, 0);
    let stdout = String::from_utf8(output.stdout).context(ByteVectorToString)?;
    let helm_v = Version::parse(stdout.as_str()).context(ParseSemverVersion { version: stdout })?;

    /* This check passes for v3.15.0-rc.1, etc. This is fine because the --reset-then-reuse-values
     * option would be included in the build. The bar is at 3.14.0, even though v3.14.0-rc.1 could
     * also have the flag. We're assuming we're dealing with stable helm versions.
     */
    ensure!(
        helm_v.ge(&three_dot_fourteen),
        InvalidHelmVersion {
            version: helm_v.to_string(),
            required_version: ">=3.14.0"
        }
    );

    Ok(())
}

/// Validates the input helm release.
///
/// Checks to see if the input helm release...
/// - is of the right helm chart
/// - is in the right version range
/// - is in 'deployed' state
async fn check_helm_release(chart_metadata: HelmChartMetadata) -> Result<()> {
    ensure!(
        chart_metadata.chart.eq(UMBRELLA_CHART_NAME),
        InvalidHelmChart {
            chart_name: chart_metadata.chart
        }
    );
    ensure!(
        chart_metadata
            .version
            .ge(&UMBRELLA_CHART_VERSION_LOWERBOUND),
        InvalidChartVersion {
            chart_version: chart_metadata.version
        }
    );
    ensure!(
        chart_metadata.status.eq("deployed"),
        InvalidChartStatus {
            chart_status: chart_metadata.status
        }
    );

    Ok(())
}

async fn check_helm_chart_dir(path: PathBuf) -> Result<()> {
    try_join!(
        chart_is_valid(path.join("charts/crds")),
        chart_is_valid(path)
    )?;

    Ok(())
}

async fn chart_is_valid(path: PathBuf) -> Result<()> {
    let res = try_join!(
        check_path(path.as_path(), Metadata::is_dir),
        check_path(path.join("Chart.yaml"), Metadata::is_file),
        check_path(path.join("templates"), Metadata::is_dir),
        check_path(path.join("values.yaml"), Metadata::is_file)
    )?;
    ensure!(
        res.0 && res.1 && res.2 && res.3,
        MalformedHelmChartDir { path }
    );

    Ok(())
}
