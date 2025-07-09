use crate::constants::{upgrade_obj_suffix, UPGRADE_CONFIG_MAP_MOUNT_PATH};

use anyhow::{anyhow, Result};
use k8s_openapi::api::{
    core::v1::{ConfigMap, ServiceAccount},
    rbac::v1::{ClusterRole, ClusterRoleBinding, PolicyRule, RoleRef, Subject},
};
use kube::core::ObjectMeta;
use openapi::apis::IntoVec;
use std::{
    collections::{BTreeMap, HashMap},
    fs,
};

#[macro_export]
macro_rules! upgrade_labels {
    () => {{
        let log = constants::loki_logging_key();
        [("app", "upgrade"), (log.as_str(), "true")]
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect::<std::collections::BTreeMap<String, String>>()
    }};
}

/// Defines the upgrade job service account.
pub(crate) fn upgrade_job_service_account(
    namespace: Option<String>,
    service_account_name: String,
) -> ServiceAccount {
    ServiceAccount {
        metadata: ObjectMeta {
            labels: Some(upgrade_labels!()),
            name: Some(service_account_name),
            namespace,
            ..Default::default()
        },
        ..Default::default()
    }
}

/// Defines the upgrade job cluster role.
pub(crate) fn upgrade_job_cluster_role(
    namespace: Option<String>,
    cluster_role_name: String,
) -> ClusterRole {
    ClusterRole {
        metadata: ObjectMeta {
            labels: Some(upgrade_labels!()),
            name: Some(cluster_role_name),
            namespace,
            ..Default::default()
        },
        rules: Some(vec![
            PolicyRule {
                api_groups: Some(vec!["apiextensions.k8s.io"].into_vec()),
                resources: Some(vec!["customresourcedefinitions"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["apps"].into_vec()),
                resources: Some(
                    vec![
                        "controllerrevisions",
                        "daemonsets",
                        "replicasets",
                        "statefulsets",
                        "deployments",
                    ]
                    .into_vec(),
                ),
                verbs: vec![
                    "create",
                    "delete",
                    "deletecollection",
                    "get",
                    "list",
                    "patch",
                ]
                .into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec![""].into_vec()),
                resources: Some(vec!["serviceaccounts"].into_vec()),
                verbs: vec!["create", "get", "list", "delete", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec![""].into_vec()),
                resources: Some(vec!["pods"].into_vec()),
                verbs: vec![
                    "create",
                    "get",
                    "list",
                    "delete",
                    "patch",
                    "deletecollection",
                ]
                .into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec![""].into_vec()),
                resources: Some(vec!["nodes"].into_vec()),
                verbs: vec!["get", "list"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec![""].into_vec()),
                resources: Some(vec!["namespaces"].into_vec()),
                verbs: vec!["get"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["events.k8s.io"].into_vec()),
                resources: Some(vec!["events"].into_vec()),
                verbs: vec!["create"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec![""].into_vec()),
                resources: Some(
                    vec![
                        "secrets",
                        "persistentvolumes",
                        "persistentvolumeclaims",
                        "services",
                        "configmaps",
                    ]
                    .into_vec(),
                ),
                verbs: vec![
                    "get",
                    "list",
                    "watch",
                    "create",
                    "delete",
                    "deletecollection",
                    "patch",
                    "update",
                ]
                .into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["rbac.authorization.k8s.io"].into_vec()),
                resources: Some(vec!["roles"].into_vec()),
                verbs: vec![
                    "create", "list", "delete", "get", "patch", "escalate", "bind",
                ]
                .into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["monitoring.coreos.com"].into_vec()),
                resources: Some(vec!["prometheusrules", "podmonitors"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["networking.k8s.io"].into_vec()),
                resources: Some(vec!["networkpolicies"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["batch"].into_vec()),
                resources: Some(vec!["cronjobs", "jobs"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch", "watch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["jaegertracing.io"].into_vec()),
                resources: Some(vec!["jaegers"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["rbac.authorization.k8s.io"].into_vec()),
                resources: Some(vec!["rolebindings"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["rbac.authorization.k8s.io"].into_vec()),
                resources: Some(vec!["clusterroles"].into_vec()),
                verbs: vec![
                    "create", "list", "delete", "get", "patch", "escalate", "bind",
                ]
                .into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["rbac.authorization.k8s.io"].into_vec()),
                resources: Some(vec!["clusterrolebindings"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["storage.k8s.io"].into_vec()),
                resources: Some(vec!["storageclasses", "csidrivers"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["scheduling.k8s.io"].into_vec()),
                resources: Some(vec!["priorityclasses"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
            PolicyRule {
                api_groups: Some(vec!["policy"].into_vec()),
                resources: Some(vec!["poddisruptionbudgets"].into_vec()),
                verbs: vec!["create", "list", "delete", "get", "patch"].into_vec(),
                ..Default::default()
            },
        ]),
        ..Default::default()
    }
}

/// Defines the upgrade job cluster role binding.
pub(crate) fn upgrade_job_cluster_role_binding(
    namespace: Option<String>,
    release_name: String,
) -> ClusterRoleBinding {
    ClusterRoleBinding {
        metadata: ObjectMeta {
            labels: Some(upgrade_labels!()),
            name: Some(format!(
                "{release_name}-upgrade-role-binding-{version}",
                release_name = release_name.as_str(),
                version = upgrade_obj_suffix()
            )),
            namespace: namespace.clone(),
            ..Default::default()
        },
        role_ref: RoleRef {
            api_group: "rbac.authorization.k8s.io".to_string(),
            kind: "ClusterRole".to_string(),
            name: format!(
                "{release_name}-upgrade-role-{version}",
                release_name = release_name.as_str(),
                version = upgrade_obj_suffix()
            ),
        },
        subjects: Some(vec![Subject {
            kind: "ServiceAccount".to_string(),
            name: format!(
                "{release_name}-upgrade-service-account-{version}",
                release_name = release_name.as_str(),
                version = upgrade_obj_suffix()
            ),
            namespace,
            ..Default::default()
        }]),
    }
}

/// Creates ConfigMap structures (maps) which let you create a ConfigMap with helm set file,
/// file contents. This ConfigMap would be mounted to the upgrade-job's Pod and will be used
/// alongside a helm set-file option.
pub(crate) fn config_map_data(
    set_file_arg: &[String],
) -> Result<(BTreeMap<String, String>, HashMap<String, String>)> {
    let mut data_map = BTreeMap::new();
    let mut upgrade_map = HashMap::new();
    let mut index = 1;
    for file in set_file_arg {
        let data: Vec<_> = file.split('=').collect();
        let [_key, filepath] = data[..] else {
            return Err(anyhow!("Invalid set-file argument"));
        };
        let cm_values = fs::read_to_string(filepath).map_err(|error| anyhow!(error))?;
        // create config map key with key of set-file
        // Example : -- set-file jaeger-operator.tolerations=/root/tolerations.yaml
        // Key:value = index:content of file
        data_map.insert(index.to_string(), cm_values);
        // upgrade_map keeps a track of index to file name mapping.
        // This is used to create set fiel arguments.
        // Key:value = file absolute path:index ( example: /root/tolerations.yaml:1 )
        upgrade_map.insert(filepath.to_string(), index.to_string());
        index += 1;
    }

    Ok((data_map, upgrade_map))
}

/// Prepare the set-file arg which will be passed down to the upgrade-job.
pub(crate) fn job_set_file_args(
    set_file_arg: &[String],
    set_file_map: Option<HashMap<String, String>>,
) -> Result<Option<String>> {
    if set_file_arg.is_empty() {
        return Ok(None);
    }

    let mut helm_args_set_file = Vec::new();
    for file in set_file_arg {
        // Example : -- set-file jaeger-operator.tolerations=/root/tolerations.yaml
        // gets converted to jaeger-operator.tolerations=/upgrade-config-map/1
        let data: Vec<_> = file.split('=').collect();
        if let [key, filepath] = data[..] {
            let mapped_file = set_file_map
                .as_ref()
                .and_then(|map| map.get(filepath))
                .ok_or(anyhow!("Specified key not present"))?;
            helm_args_set_file.push(format!(
                "{key}={UPGRADE_CONFIG_MAP_MOUNT_PATH}/{mapped_file}"
            ));
        } else {
            return Err(anyhow!("Error parsing set-file argument"));
        }
    }
    Ok(Some(helm_args_set_file.join(",")))
}

/// Returns the actual ConfigMap resource from set-file data.
pub(crate) fn upgrade_configmap(
    data: BTreeMap<String, String>,
    namespace: &str,
    release_name: String,
) -> ConfigMap {
    ConfigMap {
        metadata: ObjectMeta {
            labels: Some(upgrade_labels!()),
            name: Some(format!(
                "{release_name}-upgrade-config-map-{version}",
                release_name = release_name.as_str(),
                version = upgrade_obj_suffix()
            )),
            namespace: Some(namespace.to_string()),
            ..Default::default()
        },
        data: Some(data),
        immutable: Some(true),
        ..Default::default()
    }
}
