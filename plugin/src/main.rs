use clap::Parser;
use plugin::ExecuteOperation;
use std::{env, ops::Deref};

pub(crate) mod cli_utils;


#[derive(Parser, Debug)]
#[clap(name = utils::package_description!(), version = utils::version_info_str!())]
#[group(skip)]
pub struct CliArgs {
    /// The operation to be performed.
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
            cli_utils::Error::RestPlugin(error) => eprintln!("{error}"),
            cli_utils::Error::RestClient(error) => {
                eprintln!("Failed to initialise the REST client. Error {error}")
            }
            cli_utils::Error::Upgrade(error) => {
                eprintln!("{error}");
                exit_code = error.into();
            }
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
