use clap::Parser;
use plugin::ExecuteOperation;
use crate::cli_utils::CliArgs;

#[derive(Parser, Debug)]
pub(crate) enum Operations {
    // Getter for localpv-zfs resources
    #[clap(subcommand)]
    Get(ZfsGetter)
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(zfsgetter) => {
                zfsgetter.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

#[derive(clap::Subcommand, Debug)]
pub(crate) enum ZfsGetter {
    /// Gets a specific localpv-zfs volume
    Volume(GetVolumeArgs),
    /// Lists localpv-zfs volume
    Volumes(GetVolumesArgs),
    /// Gets a specific localpv-zfs zpool
    Zpool(GetZpoolArgs),
    /// Lists localpv-zfs zpools
    Zpools(GetZpoolsArgs),
}

/// Arguments used when getting a zfs volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeArgs {
    volume: String
}

/// Arguments used when listing zfs volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumesArgs {
    node_id: Option<String>
}

/// Arguments used when getting a zfs pool.
#[derive(Debug, Clone, clap::Args)]
pub struct GetZpoolArgs {
    node_id: String
}

/// Arguments used listing zfs pools
#[derive(Debug, Clone, clap::Args)]
pub struct GetZpoolsArgs {
    node_id: Option<String>
}


#[async_trait::async_trait(?Send)]
impl ExecuteOperation for ZfsGetter {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            ZfsGetter::Volume(volume_args) => {
                println!("Zfs volume cmd reached, {}", volume_args.volume)
            },
            ZfsGetter::Volumes(volumes_args) => {
                println!("Zfs volumes cmd reached, {}", volumes_args.node_id.clone().unwrap_or_default())
            },
            ZfsGetter::Zpool(zpool_args) => {
                println!("Zfs volumes cmd reached, {}", zpool_args.node_id)
            },
            ZfsGetter::Zpools(zpools_args) => {
                println!("Zfs volumes cmd reached, {}", zpools_args.node_id.clone().unwrap_or_default())
            }
        }
        Ok(())
    }
}

pub(crate) enum Error {
    Generic(anyhow::Error),
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
