use k8s_openapi::api::core::v1::Pod;
use upgrade::{helm::chart::HelmValuesCollection, upgrade_data_plane::upgrade_data_plane};
use url::Url;
pub struct DataPlaneUpgrader {
    pub namespace: String,
    pub rest_endpoint: Url,
}

impl DataPlaneUpgrader {
    pub async fn run(
        self,
        final_values: Box<dyn HelmValuesCollection>,
        latest_io_engine_ctrl_rev_hash: String,
        yet_to_upgrade_io_engine_label: String,
        yet_to_upgrade_io_engine_pods: Vec<Pod>,
    ) -> upgrade::common::error::Result<()> {
        upgrade_data_plane(
            self.namespace,
            self.rest_endpoint.to_string(),
            latest_io_engine_ctrl_rev_hash,
            final_values.ha_is_enabled(),
            yet_to_upgrade_io_engine_label,
            yet_to_upgrade_io_engine_pods,
        )
        .await
    }
}
