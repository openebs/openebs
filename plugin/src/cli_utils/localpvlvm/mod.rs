use clap::Parser;
use plugin::ExecuteOperation;
use crate::cli_utils::CliArgs;

#[derive(Parser, Debug)]
pub(crate) enum Operations {
    // Getter for localpv-lvm resources
    #[clap(subcommand)]
    Get(LvmGetter)
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Get(lvmgetter) => {
                lvmgetter.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

#[derive(clap::Subcommand, Debug)]
pub(crate) enum LvmGetter {
    /// Gets a specific localpv-lvm volume
    Volume(GetVolumeArgs),
    /// Lists localpv-lvm volume
    Volumes(GetVolumesArgs),
    /// Gets a specific localpv-lvm volumegroup
    VolumeGroup(GetVolumeGroupArgs),
    /// Lists localpv-lvm volumegroup
    VolumeGroups(GetVolumeGroupsArgs),
}

/// Arguments used when getting a lvm volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeArgs {
    volume: String
}

/// Arguments used when getting a lvm volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumesArgs {
    node_id: Option<String>
}

/// Arguments used when getting a lvm vg.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeGroupArgs {
    node_id: String
}

/// Arguments used when getting a lvm volume.
#[derive(Debug, Clone, clap::Args)]
pub struct GetVolumeGroupsArgs {
    node_id: Option<String>
}


#[async_trait::async_trait(?Send)]
impl ExecuteOperation for LvmGetter {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, _cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            LvmGetter::Volume(volume_args) => {
                println!("Lvm volume cmd reached, {}", volume_args.volume)
            },
            LvmGetter::Volumes(volumes_args) => {
                println!("Lvm volumes cmd reached, {}", volumes_args.node_id.clone().unwrap_or_default())
            },
            LvmGetter::VolumeGroup(volume_group_args) => {
                println!("Lvm volumes cmd reached, {}", volume_group_args.node_id)
            },
            LvmGetter::VolumeGroups(volume_groups_args) => {
                println!("Lvm volumes cmd reached, {}", volume_groups_args.node_id.clone().unwrap_or_default())
            }
        }
        Ok(())
    }
}

    Generic(anyhow::Error),
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
