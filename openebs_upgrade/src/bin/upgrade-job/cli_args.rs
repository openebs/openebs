use clap::Parser;
use std::path::PathBuf;
use url::Url;
use utils::{
    package_description,
    tracing_telemetry::{parse_key_value, FmtStyle, KeyValue},
    version_info_str,
};

/// These are the supported cli configuration options for upgrade.
#[derive(Parser)]
#[command(name = package_description!(), version = version_info_str!())]
#[command(about = format!("Upgrades OpenEBS"), long_about = None)]
pub(crate) struct CliArgs {
    /// This is the URL for the storage REST API server.
    #[arg(short = 'e', long)]
    pub(crate) rest_endpoint: Url,

    /// This is the Kubernetes Namespace for the Helm release.
    #[arg(short, long)]
    pub(crate) namespace: String,

    /// This is the release name of the installed Helm chart.
    #[arg(long)]
    pub(crate) release_name: String,

    /// This is the Helm chart directory filepath for the core Helm chart variant.
    #[arg(long, env = "CHART_DIR", value_name = "DIR_PATH")]
    pub(crate) chart_dir: PathBuf,

    /// If not set, this skips the Kubernetes Pod restarts for the io-engine DaemonSet.
    #[arg(long, default_value_t = false)]
    pub(crate) skip_data_plane_restart: bool,

    /// If set then this skips the upgrade path validation.
    #[arg(long, default_value_t = false, hide = true)]
    pub(crate) skip_upgrade_path_validation: bool,

    /// The name of the Kubernetes Job Pod. The Job object will be used to post upgrade event.
    #[arg(env = "POD_NAME")]
    pub(crate) pod_name: String,

    /// The set values specified by the user for upgrade
    /// (can specify multiple or separate values with commas: key1=val1,key2=val2).
    #[arg(long)]
    pub(crate) helm_args_set: Option<String>,

    /// The set file values specified by the user for upgrade
    /// (can specify multiple or separate values with commas: key1=path1,key2=path2).
    #[arg(long)]
    pub(crate) helm_args_set_file: Option<String>,

    /// Formatting style to be used while logging.
    #[arg(default_value = FmtStyle::Pretty.as_ref(), short, long)]
    pub(crate) fmt_style: FmtStyle,

    /// Use ANSI colors for the logs.
    #[arg(long, default_value_t = true)]
    pub(crate) ansi_colors: bool,

    /// This is the helm storage driver, e.g. secret, configmap, memory, etc.
    #[arg(env = "HELM_DRIVER", default_value = "")]
    pub(crate) helm_storage_driver: String,

    /// Add process service tags to the traces.
    #[clap(short, long, env = "TRACING_TAGS", value_delimiter=',', value_parser = parse_key_value)]
    pub(crate) tracing_tags: Vec<KeyValue>,
}
