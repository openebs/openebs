use kubectl_plugin::resources;
use plugin::ExecuteOperation;
use clap::Parser;
use std::ops::Deref;
pub(crate) mod localpvlvm;
pub(crate) mod localpvzfs;
pub(crate) mod localpvhostpath;
pub(crate) mod clusterinfo;

#[derive(Parser, Debug)]
#[group(skip)]
pub(crate) struct CliArgs {
    #[clap(flatten)]
    args: resources::CliArgs
}

impl Deref for CliArgs {
    type Target = plugin::CliArgs;

    fn deref(&self) -> &Self::Target {
        &self.args
    }
}

/// Storage engines supported
#[derive(Parser, Debug)]
pub(crate) enum Operations {
    /// Mayastor specific commands
    #[clap(subcommand)]
    Mayastor(resources::Operations),
    /// localpv-lvm specific commands
    #[clap(subcommand)]
    LocalpvLvm(localpvlvm::Operations),
    /// localpv-zfs specific commands
    #[clap(subcommand)]
    LocalpvZfs(localpvzfs::Operations),
    /// localpv-hostpath specific commands
    #[clap(subcommand)]
    LocalpvHostpath(localpvhostpath::Operations),
    /// localpv-hostpath specific commands
    #[clap(subcommand)]
    ClusterInfo(clusterinfo::Operations),
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::Mayastor(maya_ops) => {
                resources::init_rest(&cli_args.args).await?;
                maya_ops.execute(&cli_args.args).await?;
            },
            Operations::LocalpvLvm(lvm_ops) => {
                lvm_ops.execute(&cli_args).await?;
            },
            Operations::LocalpvZfs(zfs_ops) => {
                zfs_ops.execute(&cli_args).await?;
            },
            Operations::LocalpvHostpath(hostpath_ops) => {
                hostpath_ops.execute(&cli_args).await?;
            },
            Operations::ClusterInfo(cluster_info) => {
                cluster_info.execute(&cli_args).await?;
            }
        }
        Ok(())
    }
}

/// Wrapper error for all stem commnds.
pub(crate) enum Error {
    Upgrade(upgrade::error::Error),
    RestPlugin(plugin::resources::error::Error),
    RestClient(anyhow::Error),
    Generic(anyhow::Error),
}


impl From<resources::Error> for Error {
    fn from(value: resources::Error) -> Self {
        match value {
            resources::Error::Generic(error) => Error::Generic(error),
            resources::Error::Upgrade(error) => Error::Upgrade(error),
            resources::Error::RestPlugin(error) => Error::RestPlugin(error),
            resources::Error::RestClient(error) => Error::RestClient(error),
        }
    }
}

impl From<localpvlvm::Error> for Error {
    fn from(value: localpvlvm::Error) -> Self {
        match value {
            localpvlvm::Error::Generic(error) => Error::Generic(error),
        }
    }
}

impl From<localpvzfs::Error> for Error {
    fn from(value: localpvzfs::Error) -> Self {
        match value {
            localpvzfs::Error::Generic(error) => Error::Generic(error),
        }
    }
}

impl From<localpvhostpath::Error> for Error {
    fn from(value: localpvhostpath::Error) -> Self {
        match value {
            localpvhostpath::Error::Generic(error) => Error::Generic(error),
        }
    }
}

impl From<clusterinfo::Error> for Error {
    fn from(value: clusterinfo::Error) -> Self {
        match value {
            clusterinfo::Error::Generic(error) => Error::Generic(error),
        }
    }
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
