use crate::cli_utils::CliArgs;
use plugin::ExecuteOperation;

/// Cluster-info operations
#[derive(clap::Subcommand, Debug)]
pub enum Operations {
    /// Gets information of all installed engines.
    Get(ClusterInfoArg),
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(_cluster_info_arg) => {
                todo!("Implementation pending for this command")
            }
        }
    }
}

#[derive(Debug, Clone, clap::Args)]
pub struct ClusterInfoArg {}

/// Error for clusterinfo stem.
pub enum Error {
    Generic(anyhow::Error),
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
