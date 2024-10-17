use crate::cli_utils::CliArgs;
use clap::Parser;
use plugin::ExecuteOperation;

/// LocalPV Hostpath operations.
#[derive(Parser, Debug)]
pub enum Operations {
    /// Gets localpv-hostpath resources.
    #[clap(subcommand)]
    Get(HosthpathGet),
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(hostpathget) => {
                hostpathget.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

#[derive(clap::Subcommand, Debug)]
pub enum HosthpathGet {
    /// Gets a specific localpv-hostpath volume.
    Volume(GetVolumeArg),
    /// Lists all localpv-hostpath volumes.
    Volumes(GetVolumesArg),
}

/// Argument used when getting a hostpath volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeArg {
    /// Volume id of the volume.
    volume: String,
}

/// Argument used when listing localpv-hostpath volumes.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumesArg {
    /// Lists localpv-hostpath volumes from a specific node if set.
    node_id: Option<String>,
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for HosthpathGet {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            HosthpathGet::Volume(_volume_arg) => {
                todo!("Implementation pending for this command")
            }
            HosthpathGet::Volumes(_volumes_arg) => {
                todo!("Implementation pending for this command")
            }
        }
    }
}

/// Error for localpv-hostpath stem.
pub enum Error {
    Generic(anyhow::Error),
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
