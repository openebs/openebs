use semver::Version;
use snafu::Snafu;
use std::{collections::HashMap, path::PathBuf};

#[derive(Debug, Snafu)]
#[snafu(visibility(pub), context(suffix(false)))]
pub enum UpgradeError {
    #[snafu(display(
        "Failed to execute command (tokio): cmd={command}, args={args:?}, envs={envs:?}"
    ))]
    FailedTokioCommand {
        source: std::io::Error,
        command: String,
        args: Vec<String>,
        envs: HashMap<String, String>,
    },

    #[snafu(display(
        "Command failed: cmd={command}, args={args:?}, envs={envs:?} \
         status={status}, stdout={stdout:?}, stderr={stderr:?}",
        status = output.status,
        stdout = output.stdout,
        stderr = output.stderr
    ))]
    CommandFailed {
        command: String,
        args: Vec<String>,
        envs: HashMap<String, String>,
        output: std::process::Output,
    },

    #[snafu(display("Failed to convert Vec<u8> to String"))]
    ByteVectorToString { source: std::string::FromUtf8Error },

    #[snafu(display("Failed to parse semver version from '{version}'"))]
    ParseSemverVersion {
        source: semver::Error,
        version: String,
    },

    #[snafu(display(
        "'{version}' is an invalid helm version: required_version={required_version}"
    ))]
    InvalidHelmVersion {
        version: String,
        required_version: String,
    },

    #[snafu(display("Failed to deserialize YAML {vec:?}"))]
    FailedYamlVecDeserialize {
        source: serde_yaml::Error,
        vec: Vec<u8>,
    },

    #[snafu(display("'{chart_name}' is not a supported helm chart"))]
    InvalidHelmChart { chart_name: String },

    #[snafu(display("'{chart_version}' is not a supported helm chart version"))]
    InvalidChartVersion { chart_version: Version },

    #[snafu(display("'{chart_status}' is an invalid chart status"))]
    InvalidChartStatus { chart_status: String },

    #[snafu(display(
        "Failed to get filesystem metadata for helm chart resource at '{path}'",
        path = path.display()
    ))]
    FailedToGetChartPathMetadata {
        source: std::io::Error,
        path: PathBuf,
    },

    #[snafu(display("Helm chart directory '{path}' does not seem valid", path = path.display()))]
    MalformedHelmChartDir { path: PathBuf },

    #[snafu(display("Failed tokio task spawn/spawn_blocking"))]
    FailedTokioSpawn { source: tokio::task::JoinError },

    #[snafu(display("Failed to build HelmReleaseClient"))]
    FailedHelmReleaseClientBuild {
        source: upgrade::common::error::Error,
    },

    #[snafu(display("Failed to read helm chart version from local chart"))]
    FailedToGetLocalChartVersion {
        source: upgrade::common::error::Error,
    },

    #[snafu(display("Source version '{source_version}' is newer than target version '{target_version}', this is not supported"))]
    DowngradeNotSupported {
        source_version: Version,
        target_version: Version,
    },

    #[snafu(display("Failed upgrade"))]
    FailedUpgrade {
        source: upgrade::common::error::Error,
    },
}

pub type Result<T, E = UpgradeError> = std::result::Result<T, E>;
