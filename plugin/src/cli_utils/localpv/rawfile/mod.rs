use plugin::{resources::utils::OutputFormat, ExecuteOperation};

use clap::Parser;
use snafu::Snafu;

pub(crate) mod api;
pub(crate) mod node;
pub(crate) mod task;
pub(crate) mod volume;

/// Name of the service exposing the rawfile-localpv api-server, as installed by the
/// rawfile-localpv helm chart.
pub const DEFAULT_CONTROLLER_SERVICE: &str = "rawfile-localpv-controller";

/// Namespace the rawfile-localpv api-server is looked for in, unless one is specified.
pub const DEFAULT_NAMESPACE: &str = "openebs";

/// Port the api-server is served on by the controller service.
pub const DEFAULT_API_PORT: u16 = 8080;

/// Placeholder for a table cell with no content.
pub(crate) const NO_CONTENT: &str = "<none>";

/// LocalPV rawfile operations.
#[derive(Parser, Debug)]
pub enum Operations {
    /// Gets localpv-rawfile resources.
    #[clap(subcommand)]
    Get(RawfileGet),
}

#[derive(Parser, Debug)]
pub struct Rawfile {
    /// LocalPV rawfile operations.
    #[command(subcommand)]
    pub ops: Operations,
    /// LocalPV rawfile cli args.
    #[command(flatten)]
    pub cli_args: CliArgs,
}

#[derive(Parser, Debug)]
#[group(skip)]
pub struct CliArgs {
    /// The Output, viz yaml, json.
    #[clap(global = true, default_value = OutputFormat::None.as_ref(), short, long)]
    pub output: OutputFormat,

    /// Name of the service exposing the rawfile-localpv api-server.
    #[clap(global = true, long, default_value = DEFAULT_CONTROLLER_SERVICE)]
    pub service: String,

    /// Port of the api-server on the service.
    #[clap(global = true, long, default_value_t = DEFAULT_API_PORT)]
    pub port: u16,

    #[clap(skip)]
    pub ctx: crate::cli_utils::K8sCtxArgs,
}

impl CliArgs {
    /// The namespace the api-server is looked for in.
    /// Unlike the other engines, which fall back to the namespace of the current context, this
    /// falls back to [`DEFAULT_NAMESPACE`], where the rawfile-localpv chart installs the service.
    pub(crate) fn namespace(&self) -> String {
        self.ctx
            .namespace
            .clone()
            .unwrap_or_else(|| DEFAULT_NAMESPACE.to_string())
    }
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(rawfileget) => {
                rawfileget.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

/// Get commands for localpv-rawfile.
#[derive(clap::Subcommand, Debug)]
pub enum RawfileGet {
    /// Lists all nodes known to the localpv-rawfile api-server.
    Nodes,
    /// Gets a specific localpv-rawfile node.
    Node(GetNodeArg),
    /// Lists all localpv-rawfile storage pools. Filters from specific node if node is passed.
    Pools(GetPoolsArg),
    /// Lists all localpv-rawfile volumes. Filters from specific node and pool if passed.
    Volumes(GetVolumesArg),
    /// Gets a specific localpv-rawfile volume.
    Volume(GetVolumeArg),
    /// Lists all localpv-rawfile tasks. Filters from specific node if node is passed.
    Tasks(GetTasksArg),
    /// Gets a specific localpv-rawfile task.
    Task(GetTaskArg),
}

/// Argument used when getting a rawfile node.
#[derive(Debug, Clone, clap::Args)]
pub struct GetNodeArg {
    /// Name of the node.
    node: String,
}

/// Argument used when listing rawfile storage pools.
#[derive(Debug, Clone, clap::Args)]
pub struct GetPoolsArg {
    /// Lists storage pools from a specific node if set.
    node: Option<String>,
}

/// Arguments used when listing rawfile volumes.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumesArg {
    /// Lists volumes from a specific node if set.
    node: Option<String>,

    /// Lists volumes from a specific storage pool if set.
    #[clap(long)]
    pool: Option<String>,
}

/// Arguments used when getting a rawfile volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeArg {
    /// Name of the volume, which is the name of its persistent volume.
    volume: String,

    /// Node hosting the volume. Looked up on all nodes if unset.
    #[clap(long)]
    node: Option<String>,

    /// Storage pool hosting the volume. Looked up on all pools if unset.
    #[clap(long)]
    pool: Option<String>,
}

/// Argument used when listing rawfile tasks.
#[derive(Debug, Clone, clap::Args)]
pub struct GetTasksArg {
    /// Lists tasks from a specific node if set.
    node: Option<String>,
}

/// Arguments used when getting a rawfile task.
#[derive(Debug, Clone, clap::Args)]
pub struct GetTaskArg {
    /// Id of the task.
    task_id: String,

    /// Node the task is queued on. Looked up on all nodes if unset.
    #[clap(long)]
    node: Option<String>,
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for RawfileGet {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        let client = cli_args
            .ctx
            .client()
            .await
            .map_err(|source| Error::Generic { source })?;
        let api = api::ApiClient::new(client, cli_args);
        match self {
            RawfileGet::Nodes => {
                node::nodes(cli_args, &api).await?;
            }
            RawfileGet::Node(node_arg) => {
                node::node(cli_args, node_arg, &api).await?;
            }
            RawfileGet::Pools(pools_arg) => {
                node::pools(cli_args, pools_arg, &api).await?;
            }
            RawfileGet::Volumes(volumes_arg) => {
                volume::volumes(cli_args, volumes_arg, &api).await?;
            }
            RawfileGet::Volume(volume_arg) => {
                volume::volume(cli_args, volume_arg, &api).await?;
            }
            RawfileGet::Tasks(tasks_arg) => {
                task::tasks(cli_args, tasks_arg, &api).await?;
            }
            RawfileGet::Task(task_arg) => {
                task::task(cli_args, task_arg, &api).await?;
            }
        }
        Ok(())
    }
}

/// Formats a unix timestamp as reported by the api-server into an rfc3339 timestamp.
pub(crate) fn adjust_time(timestamp: Option<f64>) -> String {
    // The api-server reports an unset timestamp as zero rather than as null.
    let Some(seconds) = timestamp.filter(|seconds| *seconds > 0.0) else {
        return NO_CONTENT.to_string();
    };
    match std::time::Duration::try_from_secs_f64(seconds)
        .ok()
        .and_then(|elapsed| std::time::UNIX_EPOCH.checked_add(elapsed))
    {
        Some(time) => humantime::format_rfc3339_seconds(time).to_string(),
        None => NO_CONTENT.to_string(),
    }
}

/// Formats a flag for a table cell.
pub(crate) fn yes_no(flag: bool) -> &'static str {
    if flag {
        "Yes"
    } else {
        "No"
    }
}

/// The service the localpv-rawfile api-server was looked for on.
#[derive(Debug, Clone)]
pub struct ApiTarget {
    /// Namespace of the service.
    pub namespace: String,
    /// Name of the service.
    pub service: String,
    /// Port of the api-server on the service.
    pub port: u16,
}

impl std::fmt::Display for ApiTarget {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}/{}:{}", self.namespace, self.service, self.port)
    }
}

impl From<&CliArgs> for ApiTarget {
    fn from(cli_args: &CliArgs) -> Self {
        Self {
            namespace: cli_args.namespace(),
            service: cli_args.service.clone(),
            port: cli_args.port,
        }
    }
}

/// Error for localpv-rawfile stem.
#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display("{source}"))]
    Generic { source: anyhow::Error },
    #[snafu(display("{resource} '{name}' not found"))]
    NotFound { resource: String, name: String },
    #[snafu(display(
        "The localpv-rawfile api-server at {target} could not be reached: {source}\n\
        Check that the rawfile-localpv chart is installed there with \
        capabilities.apiServer.enabled=true, that --service and --port match its service, and \
        that you may 'get services/proxy' in that namespace."
    ))]
    Unreachable {
        target: ApiTarget,
        source: kube::Error,
    },
    #[snafu(display("Request to the localpv-rawfile api-server at {target} failed: {source}"))]
    Request {
        target: ApiTarget,
        source: kube::Error,
    },
    #[snafu(display("'{name}' is not a valid name"))]
    InvalidName { name: String },
}
