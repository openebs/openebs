use crate::{cli_utils::upgrade::k8s::decode_decompress_data, extract_data};
use upgrade::common::kube::client::{list_configmaps, list_secrets};

use anyhow::{anyhow, Result};
use semver::Version;
use serde::Deserialize;

/// Deserialize the data out from helm storage data.
#[derive(Deserialize, Debug)]
pub struct HelmRelease {
    chart: HelmChart,
    config: Option<HelmConfigValues>,
}

#[derive(Deserialize, Debug)]
struct HelmChart {
    values: HelmValues,
    metadata: HelmChartMetadata,
}

#[derive(Deserialize, Debug)]
struct HelmChartMetadata {
    version: Version,
}

#[derive(Deserialize, Debug)]
struct HelmValues {
    mayastor: Option<HelmConfigEngineEnabled>,
    // This is made optional, because this key is absent in openebs v3.
    engines: Option<Engines>,
}

#[derive(Deserialize, Debug)]
struct Engines {
    replicated: ReplicatedEngines,
}

#[derive(Deserialize, Debug)]
struct ReplicatedEngines {
    mayastor: EngineEnabled,
}

#[derive(Deserialize, Debug)]
struct EngineEnabled {
    enabled: bool,
}

#[derive(Deserialize, Debug)]
struct HelmConfigValues {
    mayastor: Option<HelmConfigEngineEnabled>,
    engines: Option<HelmConfigValuesEngines>,
}

#[derive(Deserialize, Debug)]
struct HelmConfigValuesEngines {
    replicated: Option<HelmConfigValuesEnginesReplicated>,
}

#[derive(Deserialize, Debug)]
struct HelmConfigValuesEnginesReplicated {
    mayastor: Option<HelmConfigEngineEnabled>,
}

#[derive(Deserialize, Debug)]
struct HelmConfigEngineEnabled {
    enabled: Option<bool>,
}

impl HelmRelease {
    /// Create an instance of HelmRelease from a byte buffer of helm release info from the helm
    /// storage driver, viz. Secret, ConfigMap.
    pub fn new_from_release_data_buf(data_buf: &[u8]) -> Result<Self> {
        serde_json::from_slice(data_buf).map_err(|error| anyhow!(error))
    }

    /// Create an instance of HelmRelease from cluster information -- helm storage driver type,
    /// helm release name, kubernetes namespace of helm release.
    pub async fn new_from_cluster(
        helm_storage_driver: &str,
        release_name: &str,
        namespace: &str,
    ) -> Result<Self> {
        let release_data_buf =
            helm_release_data(helm_storage_driver, release_name, namespace).await?;
        Self::new_from_release_data_buf(&release_data_buf)
    }

    /// Returns if the Mayastor storage engine is enabled in the helm values.
    pub fn mayastor_is_enabled(&self) -> bool {
        // configs are values users have set explicitly using --set or -f.
        // values are values which ship with the chart as default
        //
        // This is the order of keys we check, when trying to determine if mayastor is enabled
        // 1. config: engines.replicated.mayastor.enabled
        // 2. config: mayastor.enabled (openebs v3)
        // 3. values: engines.replicated.mayastor.enabled
        // 4. values: mayastor.enabled (openebs v3)
        // 5. clearly the chart knows nothing of mayastor, mayastor is disabled.
        self.config
            .as_ref()
            .and_then(|cfg| cfg.engines.as_ref())
            .and_then(|eng| eng.replicated.as_ref())
            .and_then(|rep| rep.mayastor.as_ref())
            .and_then(|ms| ms.enabled)
            .unwrap_or(
                self.config
                    .as_ref()
                    .and_then(|cfg| cfg.mayastor.as_ref())
                    .and_then(|ms| ms.enabled)
                    .unwrap_or(
                        self.chart
                            .values
                            .engines
                            .as_ref()
                            .map(|eng| eng.replicated.mayastor.enabled)
                            .unwrap_or(
                                self.chart
                                    .values
                                    .mayastor
                                    .as_ref()
                                    .and_then(|ms| ms.enabled)
                                    .unwrap_or(false),
                            ),
                    ),
            )
    }

    /// Returns the chart version
    pub fn version(&self) -> &Version {
        &self.chart.metadata.version
    }
}

/// Get helm release data in a byte buffer that could be deserialized.
pub async fn helm_release_data(
    helm_storage_driver: &str,
    release_name: &str,
    namespace: &str,
) -> Result<Vec<u8>> {
    match helm_storage_driver {
        "" | "secret" | "secrets" => {
            let mut secrets = list_secrets(
                namespace.to_string(),
                Some(format!("status=deployed,name={release_name}")),
                Some("type=helm.sh/release.v1".to_string()),
            )
            .await
            .map_err(|error| anyhow!(error))?;

            let secret = match secrets.len() {
                0 => {
                    return Err(anyhow!(
                        "No helm secret found attached to release name {release_name}"
                    ))
                }
                1 => secrets.pop().unwrap(),
                _ => {
                    return Err(anyhow!(
                        "Too many helm secrets found attached to release name {release_name}"
                    ))
                }
            };
            let data_buf = extract_data!(secret)?;
            decode_decompress_data(&data_buf.0)
        }
        "configmap" | "configmaps" => {
            let mut cms = list_configmaps(
                namespace.to_string(),
                Some(format!("owner=helm,status=deployed,name={release_name}")),
                None,
            )
            .await
            .map_err(|error| anyhow!(error))?;

            let cm = match cms.len() {
                0 => {
                    return Err(anyhow!(
                        "No helm configmap found attached to release name {release_name}"
                    ))
                }
                1 => cms.pop().unwrap(),
                _ => {
                    return Err(anyhow!(
                        "Too many helm configmaps found attached to release name {release_name}"
                    ))
                }
            };

            let data_buf = extract_data!(cm)?;
            decode_decompress_data(&data_buf)
        }
        unsupported_storage_driver => Err(anyhow!(
            "'{unsupported_storage_driver}' storage driver for helm is not supported"
        )),
    }
}
