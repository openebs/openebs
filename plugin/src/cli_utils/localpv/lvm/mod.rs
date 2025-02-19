use clap::Parser;
use plugin::ExecuteOperation;
pub(crate) mod node;
pub(crate) mod volume;
use plugin::resources::utils::OutputFormat;

use snafu::Snafu;
use std::path::PathBuf;

/// LocalPV lvm operations.
#[derive(Parser, Debug)]
pub enum Operations {
    /// Gets localpv-lvm resources.
    #[clap(subcommand)]
    Get(LvmGet),
}

#[derive(Parser, Debug)]
pub struct Lvm {
    /// Localpv lvm operations.
    #[command(subcommand)]
    pub ops: Operations,
    /// Localpv lvm cli args.
    #[command(flatten)]
    pub cli_args: CliArgs,
}

#[derive(Parser, Debug)]
#[group(skip)]
pub struct CliArgs {
    /// Kubernetes namespace of localpv-lvm service.
    #[clap(skip)]
    pub namespace: String,

    /// The Output, viz yaml, json.
    #[clap(global = true, default_value = OutputFormat::None.as_ref(), short, long)]
    pub output: OutputFormat,

    /// Path to kubeconfig file.
    #[clap(skip)]
    pub kube_config_path: Option<PathBuf>,
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(lvmget) => {
                lvmget.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

/// Get commands for localpv-lvm.
#[derive(clap::Subcommand, Debug)]
pub enum LvmGet {
    /// Gets a specific localpv-lvm volume.
    Volume(GetVolumeArg),
    /// Lists all localpv-lvm volumes. Filters from specific node if node_id is passed.
    Volumes(GetVolumesArg),
    /// Lists all localpv-lvm volumegroups. Filters from specific node if node_id is passed.
    VolumeGroups(GetVolumeGroupsArg),
}

/// Argument used when getting a lvm volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeArg {
    /// Volume id of the volume.
    volume: String,
}

/// Argument used when getting a lvm volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumesArg {
    /// Lists lvm volumes from a specific node if set.
    node_id: Option<String>,
}

/// Argument used when getting a lvm volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeGroupsArg {
    /// Lists lvm vg from a specific node if set.
    node_id: Option<String>,
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for LvmGet {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        let client = kube_proxy::client_from_kubeconfig(cli_args.kube_config_path.clone())
            .await
            .map_err(|err| Error::Generic {
                source: anyhow::anyhow!("{err}"),
            })?;
        match self {
            LvmGet::Volume(volume_arg) => {
                volume::volume(cli_args, volume_arg, client).await?;
            }
            LvmGet::Volumes(volumes_arg) => {
                volume::volumes(cli_args, volumes_arg, client).await?;
            }
            LvmGet::VolumeGroups(volume_groups_arg) => {
                node::volume_groups(cli_args, volume_groups_arg, client).await?;
            }
        }
        Ok(())
    }
}

/// Error for localpv-lvm stem.
#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display("{}", source))]
    Generic { source: anyhow::Error },
    #[snafu(display("{}", source))]
    Kube { source: kube::Error },
}
