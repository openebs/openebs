use crate::cli_utils::CliArgs;
use clap::Parser;
use plugin::ExecuteOperation;
pub(crate) mod node;
pub(crate) mod volume;

/// LocalPV lvm operations.
#[derive(Parser, Debug)]
pub enum Operations {
    /// Gets localpv-lvm resources.
    #[clap(subcommand)]
    Get(LvmGet),
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

#[derive(clap::Subcommand, Debug)]
pub enum LvmGet {
    /// Gets a specific localpv-lvm volume.
    Volume(GetVolumeArg),
    /// Lists all localpv-lvm volumes.
    Volumes(GetVolumesArg),
    /// Lists all localpv-lvm volumegroups.
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
        match self {
            LvmGet::Volume(volume_arg) => {
                volume::volume(cli_args, volume_arg).await?;
            }
            LvmGet::Volumes(volumes_arg) => {
                volume::volumes(cli_args, volumes_arg).await?;
            }
            LvmGet::VolumeGroups(volume_groups_arg) => {
                node::volume_groups(cli_args, volume_groups_arg).await?;
            }
        }
        Ok(())
    }
}

/// Error for localpv-lvm stem.
pub enum Error {
    Generic(anyhow::Error),
    Kube(kube::Error),
}

/// Converts anyhow::Error into lovalPV Error.
impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}

/// Converts kube::Error into lovalPV Error.
impl From<kube::Error> for Error {
    fn from(e: kube::Error) -> Self {
        Error::Kube(e)
    }
}
