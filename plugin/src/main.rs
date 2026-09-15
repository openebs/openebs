use kubectl_plugin::resources;

use clap::Parser;
use std::env;

use crate::cli_utils::K8sCtxArgs;

pub(crate) mod cli_utils;
pub mod console_logger;
pub mod constants;

#[derive(Parser, Debug)]
#[clap(name = utils::package_description!(), version = utils::version_info_string!())]
#[group(skip)]
struct CliArgs {
    #[clap(subcommand)]
    operations: cli_utils::Operations,

    #[clap(flatten)]
    ctx: K8sCtxArgs,
}

impl CliArgs {
    async fn args() -> Result<Self, anyhow::Error> {
        let mut args = CliArgs::parse();
        let ns = || args.ctx.namespace();
        match args.operations {
            cli_utils::Operations::Mayastor(ref mut operations) => {
                operations.cli_args.namespace = ns().await?;
                operations.cli_args.kubeconfig = args.ctx.kubeconfig.clone();
                operations.cli_args.context = args.ctx.context.clone();
            }
            cli_utils::Operations::LocalpvLvm(ref mut operations) => {
                operations.cli_args.ctx = args.ctx.clone();
            }
            cli_utils::Operations::LocalpvZfs(ref mut operations) => {
                operations.cli_args.ctx = args.ctx.clone();
            }
            cli_utils::Operations::LocalpvHostpath(ref mut operations) => {
                operations.cli_args.ctx = args.ctx.clone();
            }
            cli_utils::Operations::LocalpvRawfile(ref mut operations) => {
                operations.cli_args.ctx = args.ctx.clone();
            }
            cli_utils::Operations::Upgrade(ref mut upgrade_args) => {
                upgrade_args.cli_args.namespace = ns().await?;
                upgrade_args.cli_args.ctx = args.ctx.clone();
            }
            cli_utils::Operations::Dump(ref mut dump_args) => {
                dump_args.args.ctx.kubeconfig = args.ctx.clone().into();
                dump_args.args.set_namespace(ns().await?);
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
                    cli_utils::Error::LocalpvLvm(error) => eprintln!("{error}"),
                    cli_utils::Error::LocalpvZfs(error) => eprintln!("{error}"),
                    cli_utils::Error::Hostpath(error) => eprintln!("{error}"),
                    cli_utils::Error::LocalpvRawfile(error) => eprintln!("{error}"),
                    cli_utils::Error::Generic(error) => eprintln!("{error}"),
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
