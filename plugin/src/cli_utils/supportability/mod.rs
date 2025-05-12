use std::path::PathBuf;
use supportability::operations::SystemDumpArgs;

pub mod cli;
pub mod dump;

/// Collects state & log information of mayastor services running in the system and dump them.
#[derive(Debug, Clone, clap::Args)]
pub struct SupportArgs {
    /// Specifies the timeout value to interact with other modules of system
    #[clap(global = true, long, short, default_value = "10s")]
    timeout: humantime::Duration,

    /// Period states to collect all logs from last specified duration
    #[clap(global = true, long, short, default_value = "24h")]
    since: humantime::Duration,

    /// Endpoint of LOKI service, if left empty then it will try to parse endpoint
    /// from Loki service(K8s service resource), if the tool is unable to parse
    /// from service then logs will be collected using Kube-apiserver
    #[clap(global = true, short, long)]
    loki_endpoint: Option<String>,

    /// Endpoint of ETCD service, if left empty then will be parsed from the internal service name
    #[clap(global = true, short, long)]
    etcd_endpoint: Option<String>,

    /// Output directory path to store archive file
    #[clap(global = true, long, short = 'd', default_value = "./")]
    output_directory_path: String,

    /// Kubernetes namespace of openebs service
    #[clap(global = true, long, short = 'n', default_value = "openebs")]
    namespace: String,

    /// Path to kubeconfig file.
    #[clap(skip)]
    kubeconfig: Option<PathBuf>,

    /// The tenant id to be used to query loki logs.
    #[clap(global = true, long, default_value = "openebs")]
    tenant_id: String,

    /// Logging label selectors
    #[clap(global = true, long, default_value = "openebs.io/logging=true")]
    logging_label_selectors: String,
}

impl SupportArgs {
    /// Returns the timeout value for interacting with other modules of the system.
    pub fn timeout(&self) -> &humantime::Duration {
        &self.timeout
    }

    /// Returns the duration since which logs should be collected.
    pub fn since(&self) -> &humantime::Duration {
        &self.since
    }

    /// Returns the optional endpoint of the Loki service.
    pub fn loki_endpoint(&self) -> Option<&String> {
        self.loki_endpoint.as_ref()
    }

    /// Returns the optional endpoint of the ETCD service.
    pub fn etcd_endpoint(&self) -> Option<&String> {
        self.etcd_endpoint.as_ref()
    }

    /// Returns the output directory path where the archive file will be stored.
    pub fn output_directory_path(&self) -> &str {
        &self.output_directory_path
    }

    /// Returns the Kubernetes namespace of the openebs service.
    pub fn namespace(&self) -> &str {
        &self.namespace
    }

    /// Returns the optional path to the kubeconfig file.
    pub fn kubeconfig(&self) -> Option<&std::path::PathBuf> {
        self.kubeconfig.as_ref()
    }

    /// Returns the tenant ID used to query Loki logs.
    pub fn tenant_id(&self) -> &str {
        &self.tenant_id
    }

    /// Returns the logging label selectors used to filter logs.
    pub fn logging_label_selectors(&self) -> &str {
        &self.logging_label_selectors
    }

    /// Sets the path to the kubeconfig file used to interact with the Kube-Apiserver.
    ///
    /// # Arguments
    ///
    /// * `path` - An optional `PathBuf` representing the kubeconfig path.
    pub fn set_kube_config_path(&mut self, path: Option<std::path::PathBuf>) {
        self.kubeconfig = path;
    }

    /// Sets the namespace.
    ///
    /// # Arguments
    ///
    /// * `namespace` - The namespace to be set.
    pub fn set_namespace(&mut self, ns: String) {
        self.namespace = ns;
    }
}

/// Resources on which operation can be performed
#[derive(clap::Subcommand, Clone, Debug)]
pub(crate) enum Resource {
    /// Collects entire system information
    System(SystemDumpArgs),
}

/// Supportability - collects state & log information of services and dumps it to a tar file.
#[derive(Debug, Clone, clap::Args)]
#[clap(
    after_help = "Supportability - collects state & log information of services and dumps it to a tar file."
)]
pub struct DumpArgs {
    #[clap(flatten)]
    pub args: SupportArgs,
    #[clap(subcommand)]
    resource: Resource,
}
