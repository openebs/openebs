use crate::cli_utils::upgrade::{
    get_latest_upgrade_event,
    k8s::{helm_release_name, upgrade_name_concat},
    UpgradeEvent,
};

use anyhow::{anyhow, Result};

/// Get the upgrade status from an upgrade-job's k8s Event and print it to console.
pub async fn get_upgrade_status(
    namespace: &str,
    release_name: Option<String>,
    helm_storage_driver: String,
) -> Result<()> {
    let release_name = match release_name {
        Some(name) => name,
        None => helm_release_name(namespace, helm_storage_driver.as_str()).await?,
    };

    let events_field_selector = format!(
        "regarding.kind=Job,regarding.name={name}",
        name = upgrade_name_concat(release_name.as_str(), "upgrade")
    );

    let event = get_latest_upgrade_event(namespace, events_field_selector.as_str()).await?;

    match event.note.clone() {
        Some(data) => {
            let e: UpgradeEvent = serde_json::from_str(data.as_str())
                .map_err(|error| anyhow!("Failed to deserialize upgrade event: {error:?}"))?;
            println!("Upgrade From: {}", e.from_version);
            println!("Upgrade To: {}", e.to_version);
            println!("Upgrade Status: {}", e.message);
            Ok(())
        }
        None => Err(anyhow!("No message present in upgrade event")),
    }
}
