use crate::cli_utils::CliArgs;
use clap::Parser;
use plugin::ExecuteOperation;
use snafu::Snafu;

/// LocalPV zfs operations.
#[derive(Parser, Debug)]
pub enum Operations {
    /// Gets localpv-zfs resources.
    #[clap(subcommand)]
    Get(ZfsGet),
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(zfsget) => {
                zfsget.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

#[derive(clap::Subcommand, Debug)]
pub enum ZfsGet {
    /// Gets a specific localpv-zfs volume.
    Volume(GetVolumeArg),
    /// Lists all localpv-zfs volumes.
    Volumes(GetVolumesArg),
    /// Lists all localpv-zfs zpools.
    Zpools(GetZpoolsArg),
}

/// Argument used when getting a zfs volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeArg {
    /// Volume id of the volume.
    volume: String,
}

/// Argument used when listing zfs volumes.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumesArg {
    /// Lists zfs volumes from a specific node if set.
    node_id: Option<String>,
}

/// Arguments used when listing zfs pools.
#[derive(Debug, Clone, clap::Args)]
pub struct GetZpoolsArg {
    /// Lists zfs pool from a specific node if set.
    node_id: Option<String>,
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for ZfsGet {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            ZfsGet::Volume(_volume_arg) => {
                let _ = dummy_construct();
                todo!("Implementation pending for this command")
            }
            ZfsGet::Volumes(_volumes_arg) => {
                todo!("Implementation pending for this command")
            }
            ZfsGet::Zpools(_zpools_arg) => {
                todo!("Implementation pending for this command")
            }
        }
    }
}

/// Temporary function to fix warning as snafu variant is not getting constructed.
fn dummy_construct() -> Result<(), Error> {
    Err(Error::Generic {
        source: anyhow::anyhow!("dummy"),
    })
}

/// Error for localpv-zfs stem.
#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display("Generic error: {}", source))]
    Generic { source: anyhow::Error },
}
