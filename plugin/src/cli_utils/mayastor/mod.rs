use kubectl_plugin::resources;

use clap::Parser;

/// Mayastor operations.
#[derive(Parser, Debug)]
pub(crate) struct Mayastor {
    /// Mayastor cli operations.
    #[command(subcommand)]
    pub(crate) ops: resources::Operations,
    /// Mayastor cli args.
    #[command(flatten)]
    pub(crate) cli_args: resources::CliArgs,
}
