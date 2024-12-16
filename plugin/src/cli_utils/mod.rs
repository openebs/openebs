use clap::Parser;
use kubectl_plugin::resources;
use plugin::ExecuteOperation;
use std::ops::Deref;
pub(crate) mod localpv;
use localpv::hostpath;
use localpv::lvm;
use localpv::zfs;

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
    /// Mayastor specific commands.
    #[clap(subcommand)]
    Mayastor(resources::Operations),
    /// Localpv-lvm specific commands.
    #[clap(subcommand)]
    LocalpvLvm(lvm::Operations),
    /// Localpv-zfs specific commands.
    #[clap(subcommand)]
    LocalpvZfs(zfs::Operations),
    /// Localpv-hostpath specific commands.
    #[clap(subcommand)]
    LocalpvHostpath(hostpath::Operations),
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

/// Wrapper error for all stem modules.
pub enum Error {
    /// Mayastor stem specific errors.
    Mayastor(resources::Error),
    /// Localpv-lvm stem specific errors.
    LocalpvLvm(lvm::Error),
    /// Localpv-zfs stem specific errors.
    LocalpvZfs(zfs::Error),
    /// Localpv-hostpath stem specific errors.
    Hostpath(hostpath::Error),
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

impl From<lvm::Error> for Error {
    fn from(err: lvm::Error) -> Self {
        Error::LocalpvLvm(err)
    }
}

impl From<zfs::Error> for Error {
    fn from(err: zfs::Error) -> Self {
        Error::LocalpvZfs(err)
    }
}

impl From<hostpath::Error> for Error {
    fn from(err: hostpath::Error) -> Self {
        Error::Hostpath(err)
    }
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
