use clap::Parser;
use plugin::ExecuteOperation;
use crate::cli_utils::CliArgs;

#[derive(Parser, Debug)]
pub(crate) enum Operations {
    // Getter for localpv-hostpath resources
    #[clap(subcommand)]
    Get(HosthpathGetter)
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(hostpathgetter) => {
                hostpathgetter.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

#[derive(clap::Subcommand, Debug)]
pub(crate) enum HosthpathGetter {
    /// Gets a specific localpv-hostpath volume
    Volume(GetVolumeArgs),
    /// Lists localpv-hostpath volume
    Volumes(GetVolumesArgs),
}

/// Arguments used when getting a hostpath volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeArgs {
    volume: String
}

/// Arguments used when listing hostpath volumes
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumesArgs {
    node_id: Option<String>
}


#[async_trait::async_trait(?Send)]
impl ExecuteOperation for HosthpathGetter {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            HosthpathGetter::Volume(volume_args) => {
                println!("Hostpath volume cmd reached, {}", volume_args.volume)
            },
            HosthpathGetter::Volumes(volumes_args) => {
                println!("Hostpath volumes cmd reached, {}", volumes_args.node_id.clone().unwrap_or_default())
            },
        }
        Ok(())
    }
}

/// Error for hostpath commnds.
pub(crate) enum Error {
    Generic(anyhow::Error),
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
