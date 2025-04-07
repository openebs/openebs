use crate::{
    constants::HTTP_DATA_PAGE_SIZE,
    error::{FailedToCreateKubernetesClient, ListEventsWithLabelAndField, Result},
};
use k8s_openapi::api::events::v1::Event;
use kube::api::{Api, ListParams};
use snafu::ResultExt;
use upgrade::common::kube::client::{client, paginated_list};

/// List Kubernetes Events in a paginated manner.
pub async fn list_events(
    namespace: String,
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

    let events_api: Api<Event> = Api::namespaced(
        client().await.context(FailedToCreateKubernetesClient)?,
        namespace.as_str(),
    );

    paginated_list(events_api, &mut events, Some(list_params))
        .await
        .context(ListEventsWithLabelAndField)?;

    Ok(events)
}
