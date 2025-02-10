use crate::{
    constants::HELM_STORAGE_DRIVER_ENV,
    error::{FailedYamlVecDeserialize, Result},
    utils::exec_tokio_command,
};
use semver::Version;
use serde::Deserialize;
use snafu::ResultExt;
use std::collections::HashMap;
use tracing::debug;

#[derive(Debug, Clone, Deserialize)]
pub struct HelmChartMetadata {
    pub chart: String,
    pub status: String,
    pub version: Version,
}

impl HelmChartMetadata {
    pub async fn new(release_name: &str, ns: &str, storage_driver: &str) -> Result<Self> {
        let command: &str = "helm";
        let args: &[&str] = &["get", "metadata", release_name, "-n", ns, "-oyaml"];
        debug!(%command, ?args, "Executing helm command to check for helm release");
        let output = exec_tokio_command(
            command.to_string(),
            args.iter().map(ToString::to_string).collect(),
            Some(HashMap::from([(
                HELM_STORAGE_DRIVER_ENV.to_string(),
                storage_driver.to_string(),
            )])),
        )
        .await?;
        debug!(
            status = %output.status,
            stdout = ?output.stdout,
            stderr = ?output.stderr,
            "Executing helm command to check for helm release: command succeeded"
        );

        serde_yaml::from_slice(output.stdout.as_slice())
            .context(FailedYamlVecDeserialize { vec: output.stdout })
    }
}
