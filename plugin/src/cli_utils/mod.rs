use kubectl_plugin::resources;
use localpv::{hostpath, lvm, rawfile, zfs};
use plugin::{init_tracing_with_jaeger, ExecuteOperation};
use supportability::DumpArgs;
use upgrade::cli::Upgrade;

use clap::Parser;

pub mod localpv;
pub(crate) mod mayastor;
pub mod supportability;
pub mod upgrade;

/// Arguments specifying where openebs is installed.
#[derive(Default, Debug, clap::Parser, Clone)]
pub struct K8sCtxArgs {
    /// Namespace where openebs is installed.
    /// If unset, defaults to the default namespace in the current context.
    #[clap(global = true, long, short = 'n')]
    pub namespace: Option<String>,

    /// Path to kubeconfig file.
    #[clap(global = true, long, short = 'k')]
    pub kubeconfig: Option<std::path::PathBuf>,

    /// Kubernetes context to use.
    /// If unset, defaults to the current context.
    #[clap(global = true, long)]
    pub context: Option<String>,
}
impl K8sCtxArgs {
    /// Get the [`kube::Client`] based on the specified args.
    pub async fn client(&self) -> anyhow::Result<kube::Client> {
        let opts = kube_proxy::kubeconfig_options_from_context(self.context.clone());
        let mut config = kube_proxy::config_from_kubeconfig(self.kubeconfig.clone(), opts).await?;
        if let Some(namespace) = &self.namespace {
            config.default_namespace = namespace.clone();
        }
        kube::Client::try_from(config).map_err(Into::into)
    }
    /// Get the specified namespace or the default namespace.
    pub async fn namespace(&self) -> anyhow::Result<String> {
        match &self.namespace {
            Some(namespace) => Ok(namespace.to_string()),
            None => {
                let client = self.client().await?;
                Ok(client.default_namespace().to_string())
            }
        }
    }
}
impl From<K8sCtxArgs> for ::supportability::KubeConfigArgs {
    fn from(value: K8sCtxArgs) -> Self {
        Self {
            path: value.kubeconfig,
            opts: kube::config::KubeConfigOptions {
                context: value.context,
                ..Default::default()
            },
        }
    }
}

/// Storage engines supported.
#[allow(clippy::large_enum_variant)]
#[derive(Parser, Debug)]
pub enum Operations {
    Mayastor(mayastor::Mayastor),
    LocalpvLvm(lvm::Lvm),
    LocalpvZfs(zfs::Zfs),
    LocalpvHostpath(hostpath::Hostpath),
    LocalpvRawfile(rawfile::Rawfile),
    Upgrade(Upgrade),
    Dump(DumpArgs),
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
            Operations::LocalpvRawfile(rawfile) => {
                rawfile.ops.execute(&rawfile.cli_args).await?;
            }
            Operations::Upgrade(upgrade) => upgrade.execute().await?,
            Operations::Dump(args) => {
                args.execute().await?;
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
    /// Localpv-rawfile stem specific errors.
    LocalpvRawfile(rawfile::Error),
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

impl From<rawfile::Error> for Error {
    fn from(err: rawfile::Error) -> Self {
        Error::LocalpvRawfile(err)
    }
}

impl From<anyhow::Error> for Error {
    fn from(e: anyhow::Error) -> Self {
        Error::Generic(e)
    }
}
