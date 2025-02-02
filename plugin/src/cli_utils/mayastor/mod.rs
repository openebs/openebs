use kubectl_plugin::resources;

use clap::Parser;

/// Mayastor operations.
#[derive(Parser, Debug)]
pub struct Mayastor {
    /// Mayastor cli operations.
    #[command(subcommand)]
    pub ops: resources::Operations,
    /// Mayastor cli args.
    #[command(flatten)]
    pub cli_args: resources::CliArgs,
}
