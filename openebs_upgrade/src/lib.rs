use crate::{
    error::{FailedUpgrade, Result},
    helm::upgrade::upgrade,
};
use snafu::ResultExt;
use upgrade::events::event_recorder::EventRecorder;

pub use crate::helm::{
    data_plane_upgrader::DataPlaneUpgrader,
    upgrade::config::{HelmCommandConfig, HelmUpgradeConfig},
};

pub mod constants;
pub mod error;
pub mod helm;
pub(crate) mod utils;

pub async fn validate_and_upgrade(
    helm_upgrade_config: HelmUpgradeConfig,
    data_plane_upgrader: Option<DataPlaneUpgrader>,
    ev: Option<&mut EventRecorder>,
) -> Result<()> {
    upgrade(
        Box::new(
            helm_upgrade_config
                .validate_and_build_helm_upgrader()
                .await?,
        ),
        data_plane_upgrader,
        ev,
    )
    .await
    .context(FailedUpgrade)
}
