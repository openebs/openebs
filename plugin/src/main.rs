use clap::Parser;
use kube::Client;
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

    /// Namespace where openebs is installed.
    /// If unset, defaults to the default namespace in the current context.
    #[clap(global = true, long, short = 'n')]
    namespace: Option<String>,

    #[clap(flatten)]
    args: cli_utils::CliArgs,
}

impl CliArgs {
    async fn args() -> Self {
        let mut arg = CliArgs::parse();
        if let Some(ns) = arg.namespace.clone() {
            arg.args.args.namespace = ns;
        } else {
            let client = Client::try_default().await.expect("Client init failed");
            let ns = client.default_namespace().to_string();
            arg.args.args.namespace = ns;
        }
        arg
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
    let cli_args = CliArgs::args().await;
    let _tracer_flusher = cli_args.init_tracing();
    if let Err(error) = cli_args.execute().await {
        let mut exit_code = 1;
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
