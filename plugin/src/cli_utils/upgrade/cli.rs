use crate::{
    cli_utils::upgrade::{
        apply_upgrade, delete_upgrade_resources,
        k8s::{helm_release_name, upgrade_job_completed, upgrade_name_concat, upgrade_status},
        upgrade_preflight_check,
    },
    console_logger,
};
use upgrade::common::kube::client::client;

use anyhow::Result;
use clap::{Parser, Subcommand};
use plugin::ExecuteOperation;
use std::path::PathBuf;

/// Arguments common to all upgrade commands.
#[derive(Debug, Parser)]
pub struct UpgradeCommonArgs {
    #[arg(skip)]
    pub namespace: String,

    #[arg(skip)]
    pub kubeconfig: Option<PathBuf>,

    /// Helm release name for the openebs helm chart.
    #[arg(long, short)]
    pub release_name: Option<String>,

    /// Specify the container registry for the upgrade-job image.
    #[arg(long)]
    pub registry: Option<String>,

    /// Allow upgrade from stable versions to unstable versions. This is implied when the
    /// '--skip-upgrade-path-validation-for-unsupported-version' option is used.
    #[arg(long, hide = true, default_value_t = false)]
    pub allow_unstable: bool,

    /// Display all the validations output but will not execute upgrade.
    #[arg(long, short, default_value_t = false)]
    pub dry_run: bool,

    /// If set then upgrade will skip the io-engine pods restart.
    #[arg(long, default_value_t = false)]
    pub skip_data_plane_restart: bool,

    /// If set then it will continue with upgrade without validating singla replica volume.
    #[arg(long, default_value_t = false)]
    pub skip_single_replica_volume_validation: bool,

    /// If set then upgrade will skip the replica rebuild in progress validation.
    #[arg(long, default_value_t = false)]
    pub skip_replica_rebuild: bool,

    /// If set then upgrade will skip the cordoned node validation.
    #[arg(long, default_value_t = false)]
    pub skip_cordoned_node_validation: bool,

    /// Upgrade to an unsupported version.
    #[arg(hide = true, long, default_value_t = false)]
    pub skip_upgrade_path_validation_for_unsupported_version: bool,

    /// The set values on the command line.
    /// (can specify multiple or separate values with commas: key1=val1,key2=val2).
    #[arg(long)]
    pub set: Vec<String>,

    /// The set values from respective files specified via the command line
    /// (can specify multiple or separate values with commas: key1=path1,key2=path2).
    #[arg(long)]
    pub set_file: Vec<String>,

    /// This is the helm storage driver, e.g. secret, configmap, memory, etc.
    #[arg(env = "HELM_DRIVER", default_value = "")]
    pub helm_storage_driver: String,
}

/// Upgrade OpenEBS.
#[derive(Debug, Parser)]
pub struct Upgrade {
    #[command(flatten)]
    pub cli_args: UpgradeCommonArgs,

    #[command(subcommand)]
    pub subcommand: Option<UpgradeSubcommand>,
}

#[derive(Debug, Subcommand)]
pub enum UpgradeSubcommand {
    /// Fetch the status of an ongoing upgrade.
    Status,
    /// Delete upgrade resources.
    Delete {
        /// Forcibly delete upgrade resources.
        #[arg(short, long, default_value_t = false)]
        force: bool,
    },
}

impl Upgrade {
    pub async fn execute(&self) -> Result<()> {
        match &self.subcommand {
            Some(subcommand) => subcommand.execute(&self.cli_args).await,
            None => {
                let release_name = match &self.cli_args.release_name {
                    Some(name) => name.clone(),
                    None => {
                        helm_release_name(
                            self.cli_args.namespace.as_str(),
                            self.cli_args.helm_storage_driver.as_str(),
                        )
                        .await?
                    }
                };

                upgrade_preflight_check(&self.cli_args, release_name.as_str()).await?;
                apply_upgrade(&self.cli_args, release_name.as_str()).await
            }
        }
    }
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for UpgradeSubcommand {
    type Args = UpgradeCommonArgs;
    type Error = anyhow::Error;

    async fn execute(&self, cli_args: &Self::Args) -> std::result::Result<(), Self::Error> {
        match self {
            // Perform a get status.
            Self::Status => {
                upgrade_status::get_upgrade_status(
                    cli_args.namespace.as_str(),
                    cli_args.release_name.clone(),
                    cli_args.helm_storage_driver.clone(),
                )
                .await
            }
            Self::Delete { force } => {
                let release_name = match cli_args.release_name.as_deref() {
                    Some(name) => name.to_string(),
                    None => {
                        helm_release_name(
                            cli_args.namespace.as_str(),
                            cli_args.helm_storage_driver.as_str(),
                        )
                        .await?
                    }
                };
                let job_name = upgrade_name_concat(release_name.as_str(), "upgrade");

                if upgrade_job_completed(cli_args.namespace.as_str(), job_name.as_str()).await?
                    || *force
                {
                    delete_upgrade_resources(
                        release_name.as_str(),
                        cli_args.namespace.as_str(),
                        client().await?,
                    )
                    .await?;
                    return Ok(());
                }

                console_logger::error("Error","Can't delete an incomplete upgrade job. Please try with `--force` flag to forcefully remove upgrade resources");
                Ok(())
            }
        }
    }
}
