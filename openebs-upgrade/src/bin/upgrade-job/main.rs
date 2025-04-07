use clap::Parser;
use cli_args::CliArgs;
use color_eyre::eyre::{Result, WrapErr};
use openebs_upgrade::{
    validate_and_upgrade, DataPlaneUpgrader, HelmCommandConfig, HelmUpgradeConfig,
};
use upgrade::events::event_recorder::EventRecorder;
use utils::{
    print_package_info,
    tracing_telemetry::{FmtLayer, TracingTelemetry},
};

mod cli_args;

#[tokio::main]
async fn main() -> Result<()> {
    print_package_info!();
    color_eyre::install()?;
    let cli_args = CliArgs::parse();

    TracingTelemetry::builder()
        .with_writer(FmtLayer::Stdout)
        .with_style(cli_args.fmt_style)
        .with_colours(cli_args.ansi_colors)
        .with_tracing_tags(cli_args.tracing_tags.clone())
        .init("upgrade-job");

    let helm_upgrade_config = HelmUpgradeConfig {
        release_name: cli_args.release_name,
        namespace: cli_args.namespace.clone(),
        chart_dir: cli_args.chart_dir,
        skip_upgrade_path_validation: cli_args.skip_upgrade_path_validation,
        helm_command_config: HelmCommandConfig {
            args_set: cli_args.helm_args_set,
            args_set_file: cli_args.helm_args_set_file,
            storage_driver: cli_args.helm_storage_driver,
        },
    };

    let data_plane_upgrader = if cli_args.skip_data_plane_restart {
        None
    } else {
        Some(DataPlaneUpgrader {
            namespace: cli_args.namespace.clone(),
            rest_endpoint: cli_args.rest_endpoint,
        })
    };

    let mut event_recorder = EventRecorder::builder()
        .with_pod_name(cli_args.pod_name)
        .with_namespace(cli_args.namespace)
        .build()
        .await?;

    validate_and_upgrade(
        helm_upgrade_config,
        data_plane_upgrader,
        Some(&mut event_recorder),
    )
    .await
    .wrap_err("Upgrade failed")
}
