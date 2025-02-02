use plugin::ExecuteOperation;
pub(crate) mod node;
pub(crate) mod volume;

use clap::Parser;
use kube::Client;
use plugin::resources::utils::OutputFormat;
use snafu::Snafu;

/// LocalPV zfs operations.
#[derive(Parser, Debug)]
pub enum Operations {
    /// Gets localpv-zfs resources.
    #[clap(subcommand)]
    Get(ZfsGet),
}

#[derive(Parser, Debug)]
pub struct Zfs {
    /// LocalPV zfs operations.
    #[command(subcommand)]
    pub ops: Operations,
    /// LocalPV zfs cli args.
    #[command(flatten)]
    pub cli_args: CliArgs,
}

#[derive(Parser, Debug)]
#[group(skip)]
pub struct CliArgs {
    /// Kubernetes namespace of localpv-zfs services.
    #[clap(skip)]
    pub namespace: String,

    /// The Output, viz yaml, json.
    #[clap(global = true, default_value = OutputFormat::None.as_ref(), short, long)]
    pub output: OutputFormat,
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

/// Get commands for localpv-zfs.
#[derive(clap::Subcommand, Debug)]
pub enum ZfsGet {
    /// Gets a specific localpv-zfs volume.
    Volume(GetVolumeArg),
    /// Lists all localpv-zfs volumes. Filters from specific node if node_id is passed.
    Volumes(GetVolumesArg),
    /// Lists all localpv-zfs zpools. Filters from specific node if node_id is passed.
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

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        let client = Client::try_default()
            .await
            .map_err(|err| Error::Kube { source: err })?;
        match self {
            ZfsGet::Volume(volume_arg) => {
                volume::volume(cli_args, volume_arg, client).await?;
            }
            ZfsGet::Volumes(volumes_arg) => {
                volume::volumes(cli_args, volumes_arg, client).await?;
            }
            ZfsGet::Zpools(zpools_arg) => {
                node::zpools(cli_args, zpools_arg, client).await?;
            }
        }
        Ok(())
    }
}

/// Error for localpv-zfs stem.
#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display("{source}"))]
    Generic { source: anyhow::Error },
    #[snafu(display("{source}"))]
    Kube { source: kube::Error },
}
