use plugin::ExecuteOperation;
use crate::cli_utils::CliArgs;

#[derive(clap::Subcommand, Debug)]
pub(crate) enum Operations {
    // Gets informations of all installed engines
    Get(ClusterInfoArgs)
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(cluster_info_args) => {
                println!("Clusterinfo cmd reached, {}", cluster_info_args.chart)
            }
        }
        Ok(())
    }
}

/// Arguments required when getting a cluster info
#[derive(Debug, Clone, clap::Args)]
pub struct ClusterInfoArgs {
    /// Helm chart release name
    chart: String
}

/// Error for clusterinfo commands.
pub(crate) enum Error {
    Generic(anyhow::Error),
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
