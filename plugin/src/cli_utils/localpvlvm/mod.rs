use crate::cli_utils::CliArgs;
use clap::Parser;
use plugin::ExecuteOperation;

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

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            LvmGet::Volume(_volume_arg) => {
                todo!("Implementation pending for this command")
            }
            LvmGet::Volumes(_volumes_arg) => {
                todo!("Implementation pending for this command")
            }
            LvmGet::VolumeGroups(_volume_groups_arg) => {
                todo!("Implementation pending for this command")
            }
        }
    }
}

/// Error for localpv-lvm stem.
pub enum Error {
    Generic(anyhow::Error),
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
