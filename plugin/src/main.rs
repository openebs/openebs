use kubectl_plugin::resources;
pub(crate) mod cli_utils;

use clap::Parser;
use std::{env, path::PathBuf};

#[derive(Parser, Debug)]
#[clap(name = utils::package_description!(), version = utils::version_info_str!())]
#[group(skip)]
struct CliArgs {
    #[clap(subcommand)]
    operations: cli_utils::Operations,

    /// Namespace where openebs is installed.
    /// If unset, defaults to the default namespace in the current context.
    #[clap(global = true, long, short = 'n')]
    namespace: Option<String>,

    /// Path to kubeconfig file.
    #[clap(global = true, long, short = 'k')]
    kube_config_path: Option<PathBuf>,
}

impl CliArgs {
    async fn args() -> Result<Self, anyhow::Error> {
        let mut args = CliArgs::parse();
        let ns = match args.namespace {
            Some(ref namespace) => namespace.to_string(),
            None => {
                let client = kube_proxy::client_from_kubeconfig(args.kube_config_path.clone())
                    .await
                    .map_err(|err| anyhow::anyhow!("{err}"))?;
                client.default_namespace().to_string()
            }
        };
        let path = args.kube_config_path.clone();
        match args.operations {
            cli_utils::Operations::Mayastor(ref mut operations) => {
                operations.cli_args.namespace = ns;
                operations.cli_args.kube_config_path = path
            }
            cli_utils::Operations::LocalpvLvm(ref mut operations) => {
                operations.cli_args.namespace = ns;
                operations.cli_args.kube_config_path = path
            }
            cli_utils::Operations::LocalpvZfs(ref mut operations) => {
                operations.cli_args.namespace = ns;
                operations.cli_args.kube_config_path = path
            }
            cli_utils::Operations::LocalpvHostpath(ref mut operations) => {
                operations.cli_args.namespace = ns;
                operations.cli_args.kube_config_path = path
            }
        }
        Ok(args)
    }
}

#[tokio::main]
async fn main() {
    let mut exit_code = 1;
    match CliArgs::args().await {
        Ok(cli_args) => {
            if let Err(error) = cli_args.execute().await {
                match error {
                    cli_utils::Error::Mayastor(err_variants) => match err_variants {
                        resources::Error::RestPlugin(error) => eprintln!("{error}"),
                        resources::Error::RestClient(error) => {
                            eprintln!("Failed to initialise the REST client. Error {error}")
                        }
                        resources::Error::Upgrade(error) => {
                            eprintln!("{error}");
                            exit_code = error.into();
                        }
                        resources::Error::Generic(error) => eprintln!("{error}"),
                    },
                    cli_utils::Error::LocalpvLvm(error) => eprintln!("{}", error),
                    cli_utils::Error::LocalpvZfs(error) => eprintln!("{}", error),
                    cli_utils::Error::Hostpath(error) => eprintln!("{}", error),
                    cli_utils::Error::Generic(error) => eprintln!("{}", error),
                }
                std::process::exit(exit_code);
            }
        }
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(exit_code)
        }
    }
}

impl CliArgs {
    async fn execute(self) -> Result<(), cli_utils::Error> {
        tokio::select! {
            shutdown = shutdown::Shutdown::wait_sig() => {
                Err(anyhow::anyhow!("Interrupted by {shutdown:?}").into())
            },
            done = self.operations.execute() => {
                done
            }
        }
    }
}
