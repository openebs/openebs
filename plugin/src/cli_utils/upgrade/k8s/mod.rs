use crate::constants::{upgrade_obj_suffix, HTTP_DATA_PAGE_SIZE};
use upgrade::common::kube::client::{
    client, list_configmaps, list_secrets, paginated_list, paginated_list_metadata,
};

use anyhow::{anyhow, Result};
use base64::engine::{general_purpose::STANDARD, Engine as base64_engine};
use flate2::read::GzDecoder;
use k8s_openapi::api::{batch::v1::Job, events::v1::Event};
use kube::{
    api::{Api, DeleteParams, ListParams},
    core::PartialObjectMeta,
    Resource, ResourceExt,
};
use serde::Deserialize;
use std::io::Read;

pub mod resources;
pub mod upgrade_status;

/// Pick out the release data from a Kubernetes ConfigMap or a Secret.
/// Args:
///   - source: An instance of a ConfigMap or a Secret.
///
/// Output:
///   - Returns a ByteString for a Secret and a String for a ConfigMap.
#[macro_export]
macro_rules! extract_data {
    ($source:ident) => {{
        use k8s_openapi::kind;

        let driver = kind(&$source);
        $source
            .data
            .ok_or(anyhow!("No data in helm {driver}"))?
            .into_iter()
            .find_map(|(k, v)| k.eq("release").then_some(v))
            .ok_or(anyhow!(
                "No value mapped to the 'release' key in helm {driver}"
            ))
    }};
}

/// This prepares a String with the upgrade naming constant releaseName-componentName-version.
pub fn upgrade_name_concat(release_name: &str, component_name: &str) -> String {
    format!(
        "{release_name}-{component_name}-{release_version}",
        release_version = upgrade_obj_suffix()
    )
}

/// Delete pre-existing upgrade events for this version of the upgrade-job, if any.
pub async fn delete_older_upgrade_events(
    kube_event_client: Api<Event>,
    upgrade_event_field_selector: &str,
) -> Result<()> {
    let upgrade_events_list_params = ListParams::default().fields(upgrade_event_field_selector);

    let mut events: Vec<PartialObjectMeta<Event>> = Vec::with_capacity(HTTP_DATA_PAGE_SIZE);
    paginated_list_metadata(
        kube_event_client.clone(),
        &mut events,
        Some(upgrade_events_list_params.clone()),
    )
    .await
    .map_err(|error| anyhow!(error))?;

    kube_event_client
        .delete_collection(&DeleteParams::default(), &upgrade_events_list_params)
        .await?;

    Ok(())
}

/// Decompress from G-zip2 and decode from Base64 a u8 buffer with helm release data (from a helm
/// storage driver).
pub fn decode_decompress_data(data: impl AsRef<[u8]>) -> Result<Vec<u8>> {
    let data_compressed = base64_engine::decode(&STANDARD, data).map_err(|error| anyhow!(error))?;

    let mut gzip_decoder = GzDecoder::new(&data_compressed[..]);
    let mut data: Vec<u8> = Vec::new();
    gzip_decoder
        .read_to_end(&mut data)
        .map_err(|error| anyhow!(error))?;

    Ok(data)
}

/// This is used to deserialize the data structure for helm release.
#[derive(Debug, Deserialize)]
pub struct HelmChartRelease {
    chart: Option<HelmChartReleaseChart>,
}

/// This is used to deserialize release.chart.
#[derive(Debug, Deserialize)]
pub struct HelmChartReleaseChart {
    metadata: HelmChartReleaseChartMetadata,
}

/// This is used to deserialize release.chart.metadata.
#[derive(Debug, Deserialize)]
pub struct HelmChartReleaseChartMetadata {
    name: String,
}

/// Find the helm release name for a release of the openebs/openebs chart in a given namespace.
pub async fn helm_release_name(namespace: &str, helm_storage_driver: &str) -> Result<String> {
    match helm_storage_driver {
        "" | "secret" | "secrets" => {
            let secrets = list_secrets(
                namespace.to_string(),
                Some("status=deployed".to_string()),
                Some("type=helm.sh/release.v1".to_string()),
            )
            .await
            .map_err(|error| anyhow!(error))?;

            let mut openebs_chart_secret: Option<String> = None;
            for secret in secrets.into_iter() {
                let release_name = secret.meta().clone().labels.ok_or(anyhow!("Secret '{name}' in namespace '{namespace}' doesn't have labels", name = secret.name_unchecked()))?.remove("name").ok_or(anyhow!("Failed to get the value for the label key 'name' on Secret '{name}' in namespace '{namespace}'", name = secret.name_unchecked()))?;
                let release_data_buf = extract_data!(secret)?;
                let decoded_data = decode_decompress_data(&release_data_buf.0)?;

                let release_data: HelmChartRelease =
                    serde_json::from_slice(&decoded_data).map_err(|error| anyhow!(error))?;
                let helm_chart_release_chart = release_data
                    .chart
                    .ok_or(anyhow!("Missing 'chart' value in release data"))?;
                let chart_name = helm_chart_release_chart.metadata.name.as_str();

                if chart_name.eq("openebs") {
                    if openebs_chart_secret.is_some() {
                        return Err(anyhow!("Failed to figure out the release name of the 'openebs' helm chart, there are too many 'openebs' charts installed in the '{namespace}' namespace. Consider specifying the release name as input."));
                    }
                    openebs_chart_secret = Some(release_name);
                }
            }

            openebs_chart_secret.ok_or(anyhow!("Failed to figure out the release name of the 'openebs' helm chart, there aren't any 'openebs' charts installed in the '{namespace}' namespace"))
        }
        "configmap" | "configmaps" => {
            let cms = list_configmaps(
                namespace.to_string(),
                Some("owner=helm,status=deployed".to_string()),
                None,
            )
            .await
            .map_err(|error| anyhow!(error))?;

            let mut openebs_chart_cm: Option<String> = None;
            for cm in cms.into_iter() {
                let release_name = cm.meta().clone().labels.ok_or(anyhow!("ConfigMap '{name}' in namespace '{namespace}' doesn't have labels", name = cm.name_unchecked()))?.remove("name").ok_or(anyhow!("Failed to get the value for the label key 'name' on ConfigMap '{name}' in namespace '{namespace}'", name = cm.name_unchecked()))?;
                let release_data_buf = extract_data!(cm)?;
                let decoded_data = decode_decompress_data(&release_data_buf)?;

                let release_data: HelmChartRelease =
                    serde_json::from_slice(&decoded_data).map_err(|error| anyhow!(error))?;
                let helm_chart_release_chart = release_data
                    .chart
                    .ok_or(anyhow!("Missing 'chart' value in release data"))?;
                let chart_name = helm_chart_release_chart.metadata.name.as_str();
                if chart_name.eq("openebs") {
                    if openebs_chart_cm.is_some() {
                        return Err(anyhow!("Failed to figure out the release name of the 'openebs' helm chart, there are too many 'openebs' charts installed in the '{namespace}' namespace"));
                    }
                    openebs_chart_cm = Some(release_name);
                }
            }

            openebs_chart_cm.ok_or(anyhow!("Failed to figure out the release name of the 'openebs' helm chart, there aren't any 'openebs' charts installed in the '{namespace}' namespace"))
        }
        unsupported_storage_driver => Err(anyhow!(
            "'{unsupported_storage_driver}' storage driver for helm is not supported"
        )),
    }
}

/// List kubernetes Events.
pub async fn list_events(
    namespace: &str,
    label_selector: Option<String>,
    field_selector: Option<String>,
) -> Result<Vec<Event>> {
    let mut events: Vec<Event> = Vec::with_capacity(HTTP_DATA_PAGE_SIZE);

    let mut list_params = ListParams::default().limit(HTTP_DATA_PAGE_SIZE as u32);
    if let Some(ref labels) = label_selector {
        list_params = list_params.labels(labels);
    }
    if let Some(ref fields) = field_selector {
        list_params = list_params.fields(fields);
    }

    let events_api: Api<Event> = Api::namespaced(client().await?, namespace);

    paginated_list(events_api, &mut events, Some(list_params)).await?;

    Ok(events)
}

/// Check if Job is completed.
pub async fn upgrade_job_completed(ns: &str, job_name: &str) -> Result<bool> {
    let job_client: Api<Job> = Api::namespaced(client().await?, ns);
    let maybe_job = job_client
        .get_opt(job_name)
        .await
        .map_err(|err| anyhow!("Failed to get Job '{job_name}' in '{ns}' namespace: {err}"))?;

    match maybe_job {
        Some(job) => {
            let status = job.status.as_ref().ok_or(anyhow!(
                "Job '{job_name}' in '{ns}' namespace does not have a status"
            ))?;

            let job_completed = match status.succeeded {
                None => false,
                Some(count) => count == 1,
            };
            Ok(job_completed)
        }

        None => Err(anyhow!(
            "No Job exists with the name '{job_name}' in the '{ns}' namespace."
        )),
    }
}
