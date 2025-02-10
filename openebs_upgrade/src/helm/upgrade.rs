use crate::{
    constants::{
        DS_CONTROLLER_REVISION_HASH_LABEL_KEY, IO_ENGINE_LABEL, PARTIAL_REBUILD_DISABLE_EXTENTS,
        UMBRELLA_CHART_NAME,
    },
    helm::data_plane_upgrader::DataPlaneUpgrader,
};
use futures::TryFutureExt;
use semver::Version;
use snafu::ensure;
use upgrade::{
    common::{error::PartialRebuildNotAllowed, kube::client as KubeClient},
    events::event_recorder::EventRecorder,
    helm::chart::HelmValuesCollection,
    helm::upgrade::HelmUpgrader,
};

pub mod config;
pub mod upgrader;

pub async fn upgrade(
    helm_upgrader: Box<dyn HelmUpgrader>,
    data_plane_upgrader: Option<DataPlaneUpgrader>,
    mut ev: Option<&mut EventRecorder>,
) -> upgrade::common::error::Result<()> {
    let source_version = helm_upgrader.source_version();
    let target_version = helm_upgrader.target_version();
    if let Some(ref mut event_recorder) = ev {
        event_recorder.set_source_version(source_version.to_string());
        event_recorder.set_target_version(target_version.to_string());
    }

    let run_helm_upgrade = helm_upgrader
        .dry_run()
        .or_else(|error| async {
            if let Some(ref event_recorder) = ev {
                event_recorder
                    .publish_fatal(&error, "FailedHelmUpgradeDryRun")
                    .await;
            }
            Err(error)
        })
        .await?;

    if let Some(ref event_recorder) = ev {
        event_recorder
            .publish_normal("Upgrading helm chart...", "HelmUpgrade")
            .await?;
    }

    let final_values = run_helm_upgrade
        .or_else(|error| async {
            if let Some(ref event_recorder) = ev {
                event_recorder
                    .publish_fatal(&error, "FailedHelmUpgrade")
                    .await;
            }
            Err(error)
        })
        .await?;

    if let Some(upgrader) = data_plane_upgrader {
        mayastor_data_plane_upgrade(upgrader, final_values, &source_version, ev.as_deref()).await?;
    }

    if let Some(ref event_recorder) = ev {
        event_recorder
            .publish_normal("Upgrade successful", "Success")
            .await?;
    }

    Ok(())
}

async fn mayastor_data_plane_upgrade(
    data_plane_upgrader: DataPlaneUpgrader,
    final_values: Box<dyn HelmValuesCollection>,
    source_version: &Version,
    ev: Option<&EventRecorder>,
) -> upgrade::common::error::Result<()> {
    if !final_values.mayastor_is_enabled() {
        if let Some(event_recorder) = ev {
            event_recorder
                .publish_normal(
                    "Data-plane upgrade not required, Mayastor not enabled",
                    "DataPlaneUpgradeNotRequired",
                )
                .await?;
        }
        return Ok(());
    }

    mayastor_partial_rebuild_check(source_version, final_values.partial_rebuild_is_enabled())?;

    let latest_io_engine_ctrl_rev_hash = KubeClient::latest_controller_revision_hash(
        data_plane_upgrader.namespace.clone(),
        Some(IO_ENGINE_LABEL.to_string()),
        None,
        DS_CONTROLLER_REVISION_HASH_LABEL_KEY.to_string(),
    )
    .await?;
    let yet_to_upgrade_io_engine_label = format!(
        "{IO_ENGINE_LABEL},{DS_CONTROLLER_REVISION_HASH_LABEL_KEY}!={latest}",
        latest = latest_io_engine_ctrl_rev_hash.as_str()
    );
    let yet_to_upgrade_io_engine_pods = KubeClient::list_pods(
        data_plane_upgrader.namespace.clone(),
        Some(yet_to_upgrade_io_engine_label.clone()),
        None,
    )
    .await?;

    if let Some(event_recorder) = ev {
        event_recorder
            .publish_normal("Upgrading Mayastor data-plane...", "DataPlaneUpgrade")
            .await?;
    }

    data_plane_upgrader
        .run(
            final_values,
            latest_io_engine_ctrl_rev_hash,
            yet_to_upgrade_io_engine_label,
            yet_to_upgrade_io_engine_pods,
        )
        .or_else(|error| async {
            if let Some(event_recorder) = ev {
                event_recorder
                    .publish_fatal(&error, "FailedDataPlaneUpgrade")
                    .await;
            }
            Err(error)
        })
        .await?;

    if let Some(event_recorder) = ev {
        event_recorder
            .publish_normal("Upgraded Mayastor data-plane", "DataPlaneUpgrade")
            .await?;
    }

    Ok(())
}

fn mayastor_partial_rebuild_check(
    source_version: &Version,
    partial_rebuild_is_enabled: bool,
) -> upgrade::common::error::Result<()> {
    ensure!(
        !(source_version.ge(&PARTIAL_REBUILD_DISABLE_EXTENTS.0)
            && source_version.le(&PARTIAL_REBUILD_DISABLE_EXTENTS.1)
            && partial_rebuild_is_enabled),
        PartialRebuildNotAllowed {
            chart_name: UMBRELLA_CHART_NAME.to_string(),
            lower_extent: PARTIAL_REBUILD_DISABLE_EXTENTS.0.to_string(),
            upper_extent: PARTIAL_REBUILD_DISABLE_EXTENTS.1.to_string(),
        }
    );

    Ok(())
}
