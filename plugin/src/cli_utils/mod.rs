use kubectl_plugin::resources;
use localpv::hostpath;
use localpv::lvm;
use localpv::zfs;
pub(crate) mod localpv;
pub(crate) mod mayastor;

use clap::Parser;
use plugin::{init_tracing_with_jaeger, ExecuteOperation};

/// Storage engines supported.
#[allow(clippy::large_enum_variant)]
#[derive(Parser, Debug)]
pub enum Operations {
    Mayastor(mayastor::Mayastor),
    LocalpvLvm(lvm::Lvm),
    LocalpvZfs(zfs::Zfs),
    LocalpvHostpath(hostpath::Hostpath),
}

impl Operations {
    pub async fn execute(&self) -> Result<(), Error> {
        match self {
            Operations::Mayastor(mayastor) => {
                init_tracing_with_jaeger(mayastor.cli_args.jaeger.as_ref());
                resources::init_rest(&mayastor.cli_args).await?;
                mayastor.ops.execute(&mayastor.cli_args).await?;
            }
            Operations::LocalpvLvm(lvm) => {
                lvm.ops.execute(&lvm.cli_args).await?;
            }
            Operations::LocalpvZfs(zfs) => {
                zfs.ops.execute(&zfs.cli_args).await?;
            }
            Operations::LocalpvHostpath(hostpath) => {
                hostpath.ops.execute(&hostpath.cli_args).await?;
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
