use clap::Parser;
use kubectl_plugin::resources;
use plugin::ExecuteOperation;
use std::ops::Deref;
pub(crate) mod clusterinfo;
pub(crate) mod localpvhostpath;
pub(crate) mod localpvlvm;
pub(crate) mod localpvzfs;

#[derive(Parser, Debug)]
#[group(skip)]
pub struct CliArgs {
    #[clap(flatten)]
    pub args: resources::CliArgs,
}

impl Deref for CliArgs {
    type Target = plugin::CliArgs;

    fn deref(&self) -> &Self::Target {
        &self.args
    }
}

/// Storage engines supported.
#[derive(Parser, Debug)]
pub enum Operations {
    /// Lists installed storage engines with component health.
    #[clap(subcommand)]
    ClusterInfo(clusterinfo::Operations),
    /// Mayastor specific commands.
    #[clap(subcommand)]
    Mayastor(resources::Operations),
    /// Localpv-lvm specific commands.
    #[clap(subcommand)]
    LocalpvLvm(localpvlvm::Operations),
    /// Localpv-zfs specific commands.
    #[clap(subcommand)]
    LocalpvZfs(localpvzfs::Operations),
    /// Localpv-hostpath specific commands.
    #[clap(subcommand)]
    LocalpvHostpath(localpvhostpath::Operations),
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Operations {
    type Args = CliArgs;
    type Error = Error;

    async fn execute(&self, cli_args: &CliArgs) -> Result<(), Error> {
        match self {
            Operations::ClusterInfo(cluster_info) => {
                cluster_info.execute(cli_args).await?;
            }
            Operations::Mayastor(maya_ops) => {
                resources::init_rest(&cli_args.args).await?;
                maya_ops.execute(&cli_args.args).await?;
            }
            Operations::LocalpvLvm(lvm_ops) => {
                lvm_ops.execute(cli_args).await?;
            }
            Operations::LocalpvZfs(zfs_ops) => {
                zfs_ops.execute(cli_args).await?;
            }
            Operations::LocalpvHostpath(hostpath_ops) => {
                hostpath_ops.execute(cli_args).await?;
            }
        }
        Ok(())
    }
}

/// Wrapper for all stem modules.
pub enum Error {
    /// Mayastor stem specific errors.
    Mayastor(resources::Error),
    /// Localpv-lvm stem specific errors.
    LocalpvLvm(localpvlvm::Error),
    /// Localpv-zfs stem specific errors.
    LocalpvZfs(localpvzfs::Error),
    /// Localpv-hostpath stem specific errors.
    Hostpath(localpvhostpath::Error),
    /// Cluster-info stem cmd specific errors.
    ClusterInfo(clusterinfo::Error),
    /// Plugin specific error.
    Generic(anyhow::Error),
}

impl From<resources::Error> for Error {
    fn from(value: resources::Error) -> Self {
        match value {
            resources::Error::Generic(error) => Error::Mayastor(resources::Error::Generic(error)),
            resources::Error::Upgrade(error) => Error::Mayastor(resources::Error::Upgrade(error)),
            resources::Error::RestPlugin(error) => {
                Error::Mayastor(resources::Error::RestPlugin(error))
            }
            resources::Error::RestClient(error) => {
                Error::Mayastor(resources::Error::RestClient(error))
            }
        }
    }
}

impl From<localpvlvm::Error> for Error {
    fn from(value: localpvlvm::Error) -> Self {
        match value {
            localpvlvm::Error::Generic(error) => {
                Error::LocalpvLvm(localpvlvm::Error::Generic(error))
            }
            localpvlvm::Error::Kube(error) => Error::LocalpvLvm(localpvlvm::Error::Kube(error)),
        }
    }
}

impl From<localpvzfs::Error> for Error {
    fn from(value: localpvzfs::Error) -> Self {
        match value {
            localpvzfs::Error::Generic(error) => {
                Error::LocalpvZfs(localpvzfs::Error::Generic(error))
            }
        }
    }
}

impl From<localpvhostpath::Error> for Error {
    fn from(value: localpvhostpath::Error) -> Self {
        match value {
            localpvhostpath::Error::Generic(error) => {
                Error::Hostpath(localpvhostpath::Error::Generic(error))
            }
        }
    }
}

impl From<clusterinfo::Error> for Error {
    fn from(value: clusterinfo::Error) -> Self {
        match value {
            clusterinfo::Error::Generic(error) => {
                Error::ClusterInfo(clusterinfo::Error::Generic(error))
            }
        }
    }
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
