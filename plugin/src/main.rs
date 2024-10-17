use clap::Parser;
use kubectl_plugin::resources;
use plugin::ExecuteOperation;
use std::{env, ops::Deref};

pub(crate) mod cli_utils;

#[derive(Parser, Debug)]
#[clap(name = utils::package_description!(), version = utils::version_info_str!())]
#[group(skip)]
struct CliArgs {
    #[clap(subcommand)]
    operations: cli_utils::Operations,

    #[clap(flatten)]
    args: cli_utils::CliArgs,
}

impl CliArgs {
    fn args() -> Self {
        CliArgs::parse()
    }
}

impl Deref for CliArgs {
    type Target = plugin::CliArgs;

    fn deref(&self) -> &Self::Target {
        &self.args
    }
}

#[tokio::main]
async fn main() {
    let cli_args = CliArgs::args();
    let _tracer_flusher = cli_args.init_tracing();
    if let Err(error) = cli_args.execute().await {
        let mut exit_code = 1;
        match error {
            cli_utils::Error::Mayastor(variants) => match variants {
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
            cli_utils::Error::LocalpvLvm(error) => match error {
                cli_utils::localpvlvm::Error::Generic(error) => eprintln!("{error}"),
            },
            cli_utils::Error::LocalpvZfs(error) => match error {
                cli_utils::localpvzfs::Error::Generic(error) => eprintln!("{error}"),
            },
            cli_utils::Error::Hostpath(error) => match error {
                cli_utils::localpvhostpath::Error::Generic(error) => eprintln!("{error}"),
            },
            cli_utils::Error::ClusterInfo(error) => match error {
                cli_utils::clusterinfo::Error::Generic(error) => eprintln!("{error}"),
            },
            cli_utils::Error::Generic(error) => eprintln!("{error}"),
        }
        std::process::exit(exit_code);
    }
}

impl CliArgs {
    async fn execute(self) -> Result<(), cli_utils::Error> {
        tokio::select! {
            shutdown = shutdown::Shutdown::wait_sig() => {
                Err(anyhow::anyhow!("Interrupted by {shutdown:?}").into())
            },
            done = self.operations.execute(&self.args) => {
                done
            }
        }
    }
}
