use upgrade::{
    common::rest_client::RestClientSet, helm::chart::HelmValuesCollection,
    upgrade_data_plane::upgrade_data_plane,
};

use k8s_openapi::api::core::v1::Pod;
use std::path::PathBuf;
use url::Url;

/// Instances of this type can upgrade the mayastor data plane.
pub struct DataPlaneUpgrader {
    pub namespace: String,
    pub release_name: String,
    /// If not set, it is derived from the release name and the TLS mode discovered from the
    /// api-rest pods.
    pub rest_endpoint: Option<Url>,
    pub jwt: Option<PathBuf>,
    pub tls_ca_file: Option<PathBuf>,
    pub tls_cert_file: Option<PathBuf>,
    pub tls_key_file: Option<PathBuf>,
}

impl DataPlaneUpgrader {
    /// Run Mayastor data-plane upgrade.
    pub async fn run(
        self,
        final_values: Box<dyn HelmValuesCollection>,
        latest_io_engine_ctrl_rev_hash: String,
        yet_to_upgrade_io_engine_label: String,
        yet_to_upgrade_io_engine_pods: Vec<Pod>,
    ) -> upgrade::common::error::Result<()> {
        // The api-rest TLS configuration may have changed as part of the helm upgrade, so
        // the REST client is (re)built here, after the control-plane has been upgraded.
        let rest_client = RestClientSet::discover(
            &self.namespace,
            &self.release_name,
            self.rest_endpoint.map(|url| url.to_string()),
            &self.jwt,
            self.tls_ca_file.as_ref(),
            self.tls_cert_file.as_ref(),
            self.tls_key_file.as_ref(),
        )
        .await?;

        upgrade_data_plane(
            self.namespace,
            rest_client,
            latest_io_engine_ctrl_rev_hash,
            final_values.ha_is_enabled(),
            yet_to_upgrade_io_engine_label,
            yet_to_upgrade_io_engine_pods,
        )
        .await
    }
}
