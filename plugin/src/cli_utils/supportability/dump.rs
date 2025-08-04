use supportability::collect::{
    error::Error,
    k8s_resources::{
        client::ClientSet,
        k8s_resource_dump::{create_file_and_write, K8sResourceDumperError},
    },
    utils::log,
};

use kube::{api::ListParams, core::DynamicObject};
use std::path::Path;

pub async fn dump_dynamic_resource(
    k8s_client: &ClientSet,
    root_dir: &Path,
    group: &str,
    version: &str,
    kind: &str,
    file_name: &str,
) -> Result<(), Error> {
    log(format!("\t Collecting {kind} resources"));

    let mut list_params = ListParams::default().limit(100);
    let api = match k8s_client
        .dynamic_object_api(Some(k8s_client.namespace()), group, version, kind)
        .await
    {
        Ok(api_opt) => match api_opt {
            Some(api) => api,
            None => {
                return Ok(());
            }
        },
        Err(error) => {
            return Err(Error::K8sResourceDumperError(
                K8sResourceDumperError::K8sResourceError(error),
            ));
        }
    };

    let mut all_items: Vec<DynamicObject> = Vec::new();
    loop {
        let mut result = match api.list(&list_params).await {
            Ok(val) => val,
            Err(error) => {
                log(format!(
                    "\t Encountered error while collecting {kind} objects: {error}"
                ));
                break;
            }
        };
        all_items.append(&mut result.items);
        match result.metadata.continue_ {
            Some(token) if !token.is_empty() => {
                list_params = list_params.continue_token(&token);
            }
            _ => break,
        }
    }

    if !all_items.is_empty() {
        create_file_and_write(
            root_dir.to_path_buf(),
            file_name.to_string(),
            serde_yaml::to_string(&all_items).map_err(|e| {
                Error::K8sResourceDumperError(K8sResourceDumperError::YamlSerializationError(e))
            })?,
        )
        .map_err(K8sResourceDumperError::IOError)?;
    }

    Ok(())
}
