use crate::{
    cli_utils::upgrade::{
        helm_values::HelmRelease,
        k8s::{
            delete_older_upgrade_events, list_events,
            resources::{
                config_map_data, job_set_file_args, upgrade_configmap, upgrade_job_cluster_role,
                upgrade_job_cluster_role_binding, upgrade_job_service_account,
            },
            upgrade_name_concat,
        },
    },
    console_logger,
    constants::{get_destination_version_tag, upgrade_obj_suffix, UPGRADE_JOB_IMAGE_REPO},
    upgrade_labels,
};
use upgrade::common::kube::client::{list_pods, paginated_list_metadata};

use anyhow::{anyhow, Result};
use cli::UpgradeCommonArgs;
use k8s_openapi::{
    api::{
        batch::v1::{Job, JobSpec},
        core::v1::{
            ConfigMap, ConfigMapVolumeSource, Container, EnvVar, EnvVarSource, ExecAction,
            ObjectFieldSelector, PersistentVolumeClaim, PodSpec, PodTemplateSpec, Probe,
            ServiceAccount, Volume, VolumeMount,
        },
        events::v1::Event,
        rbac::v1::{ClusterRole, ClusterRoleBinding},
    },
    apimachinery::pkg::apis::meta::v1::ObjectMeta,
    kind,
};
use kube::{
    api::{Api, DeleteParams, PartialObjectMeta, PostParams},
    client::Client,
    Error as kubeError, ResourceExt,
};
use openapi::{clients::tower::ApiClient, models::CordonDrainState};
use openebs_upgrade::constants::HTTP_DATA_PAGE_SIZE;
use semver::Version;
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use std::{collections::HashSet, env};
use tokio::{spawn, task::JoinHandle, try_join};
use utils::version_info;

pub mod cli;
mod helm_values;
pub mod k8s;

/// This type could be used to gather container image data from several sources and
/// then reasoning among these options and picking the most appropriate values.
pub struct ImageProperties {
    pub pull_secrets: Option<Vec<k8s_openapi::api::core::v1::LocalObjectReference>>,
    pub registry: String,
    pub pull_policy: Option<String>,
}

impl ImageProperties {
    /// Create an instance of ImageProperties from an openebs/openebs helm release.
    pub async fn new_from_helm_release(
        release_name: &str,
        args: &UpgradeCommonArgs,
    ) -> Result<Self> {
        /* The strategy we use here assumes that users don't change the image name, i.e. the
         *     - image: <value>
         *       name: <value> // This one.
         * We find one of the CSI controllers from the CSI LocalPVs and Mayastor or the LocalPV
         * Provisioner.
         * Once we have found this Pod, we try to find on the containers that we know will exist
         * here. Other CSI sidecars may also exist, so we pick out our container based on container
         * name. As we know, we expect users to not change it, as it is of no use as far as a
         * container configuration is concerned. It identifies containers uniquely, and we already
         * achieve this with our names.
         * We split the 'image' of the containers we have found above based on the '/' character.
         * If the image could be split into 3 sections by splitting along '/', then we use the first
         * section as the image registry. This may not work for many case, and uses a naive
         * approach. For those cases, a user should use the `--registry <value>` option flag.
         * The same Pod's ImagePullSecrets and ImagePullPolicy sections are used to populate those
         * specific sections.
         */

        // From https://github.com/openebs/dynamic-localpv-provisioner/blob/develop/deploy/helm/charts/templates/deployment.yaml#L50
        let hostpath_localpv_image_name: String = if release_name.contains("localpv-provisioner") {
            "localpv-provisioner".to_string()
        } else {
            format!("{release_name}-localpv-provisioner")
        };
        let openebs_containers: HashSet<&str> = [
            // From https://github.com/openebs/charts/blob/main/charts/openebs/templates/localprovisioner/deployment-local-provisioner.yaml#L42
            "openebs-localpv-provisioner",
            "api-rest",
            "openebs-zfs-plugin",
            "openebs-lvm-plugin",
            hostpath_localpv_image_name.as_str(),
        ]
        .into_iter()
        .collect();

        // The 'app in <labels>' is used to pick out the CSI Controllers from the LocalPV, Mayastor
        // and the Hostpath Provisioner.
        let openebs_pod_spec = list_pods(args.namespace.clone(), Some("app in (openebs,api-rest,localpv-provisioner,openebs-zfs-controller,openebs-lvm-controller)".to_string()), None).await
            .map_err(|error| anyhow!(error))?
            .into_iter()
            .filter_map(|pod| pod.spec)
            // Find the first Pod we encounter from among the above Pods.
            .find(|pod_spec| pod_spec.containers.iter().map(|container| container.name.as_str()).any(|name| openebs_containers.contains(&name)))
            .ok_or(anyhow!("Couldn't pick out an openebs container, one of '{openebs_containers:?}', from openebs Pods"))?;

        let openebs_container = openebs_pod_spec
            .containers
            .iter()
            .find(|c| openebs_containers.contains(c.name.as_str()))
            .unwrap();
        Ok(Self {
            pull_secrets: openebs_pod_spec.image_pull_secrets,
            registry: args
                .registry
                .clone()
                .or(openebs_container.image.as_deref().and_then(|img| {
                    let parts: Vec<&str> = img.split('/').collect();
                    (parts.len() == 3).then(|| parts[0].to_owned())
                }))
                .unwrap_or("docker.io".to_owned()),
            pull_policy: openebs_container.image_pull_policy.clone(),
        })
    }
}

/// Returns a fully prepared upgrade-job object.
async fn upgrade_job(
    args: &UpgradeCommonArgs,
    release_name: &str,
    set_file: String,
) -> Result<Job> {
    let image_properties: ImageProperties =
        ImageProperties::new_from_helm_release(release_name, args).await?;
    let upgrade_image = format!(
        "{image_registry}/{UPGRADE_JOB_IMAGE_REPO}/openebs-upgrade-job:{image_tag}",
        image_registry = image_properties.registry,
        image_tag = get_destination_version_tag()
    );

    let helm_args_set = args.set.join(",");
    let mut job_args: Vec<String> = vec![
        format!("--rest-endpoint=http://{release_name}-api-rest:8081"),
        format!(
            "--namespace={namespace}",
            namespace = args.namespace.as_str()
        ),
        format!("--release-name={release_name}"),
        format!("--helm-args-set={helm_args_set}"),
        format!("--helm-args-set-file={set_file}"),
    ];
    if args.skip_data_plane_restart {
        job_args.push("--skip-data-plane-restart".to_string());
    }
    if args.skip_upgrade_path_validation_for_unsupported_version {
        job_args.push("--skip-upgrade-path-validation".to_string());
    }

    Ok(Job {
        metadata: ObjectMeta {
            labels: Some(upgrade_labels!()),
            name: Some(format!(
                "{release_name}-upgrade-{version}",
                version = upgrade_obj_suffix()
            )),
            namespace: Some(args.namespace.clone()),
            ..Default::default()
        },
        spec: Some(JobSpec {
            // Backoff for unrecoverable errors, recoverable errors are handled by the Job process
            // Investigate backoff with `kubectl -n <namespace> logs job/<job-name>`.
            // Non-recoverable errors also often emit Job event, `kubectl openebs get
            // upgrade-status` fetches the most recent Job event.
            backoff_limit: Some(6),
            template: PodTemplateSpec {
                metadata: Some(ObjectMeta {
                    labels: Some(upgrade_labels!()),
                    ..Default::default()
                }),
                spec: Some(PodSpec {
                    image_pull_secrets: image_properties.pull_secrets,
                    restart_policy: Some("OnFailure".to_string()),
                    containers: vec![Container {
                        args: Some(job_args),
                        image: Some(upgrade_image),
                        image_pull_policy: image_properties.pull_policy,
                        name: "openebs-upgrade-job".to_string(),
                        env: Some(vec![
                            EnvVar {
                                name: "RUST_LOG".to_string(),
                                value: Some(env::var("RUST_LOG").unwrap_or("info".to_string())),
                                ..Default::default()
                            },
                            EnvVar {
                                name: "POD_NAME".to_string(),
                                value_from: Some(EnvVarSource {
                                    field_ref: Some(ObjectFieldSelector {
                                        field_path: "metadata.name".to_string(),
                                        ..Default::default()
                                    }),
                                    ..Default::default()
                                }),
                                ..Default::default()
                            },
                            EnvVar {
                                // Ref: https://github.com/helm/helm/blob/main/cmd/helm/helm.go#L76
                                name: "HELM_DRIVER".to_string(),
                                value: Some(args.helm_storage_driver.clone()),
                                ..Default::default()
                            },
                        ]),
                        liveness_probe: Some(Probe {
                            exec: Some(ExecAction {
                                command: Some(vec!["pgrep".to_string(), "upgrade-job".to_string()]),
                            }),
                            initial_delay_seconds: Some(10),
                            period_seconds: Some(60),
                            ..Default::default()
                        }),
                        volume_mounts: Some(vec![VolumeMount {
                            read_only: Some(true),
                            mount_path: "/upgrade-config-map".to_string(),
                            name: "upgrade-config-map".to_string(),
                            ..Default::default()
                        }]),
                        ..Default::default()
                    }],
                    service_account_name: Some(format!(
                        "{release_name}-upgrade-service-account-{version}",
                        version = upgrade_obj_suffix()
                    )),
                    volumes: Some(vec![Volume {
                        name: "upgrade-config-map".to_string(),
                        config_map: Some(ConfigMapVolumeSource {
                            name: Some(format!(
                                "{release_name}-upgrade-config-map-{version}",
                                version = upgrade_obj_suffix()
                            )),
                            ..Default::default()
                        }),
                        ..Default::default()
                    }]),
                    ..Default::default()
                }),
            },
            ..Default::default()
        }),
        ..Default::default()
    })
}

/// Returns the first instance of upgrade-job Event that we find for this version of upgrade.
pub async fn get_latest_upgrade_event(
    namespace: &str,
    upgrade_events_field_selector: &str,
) -> Result<Event> {
    list_events(
        namespace,
        None,
        Some(upgrade_events_field_selector.to_string()),
    )
    .await?
    .into_iter()
    .filter(|e| e.reason.as_deref() == Some("OpenebsUpgrade"))
    .max_by_key(|e| e.event_time.clone())
    .ok_or_else(|| anyhow!("No upgrade event present"))
}

/// This is used to deserialize the JSON data present in an upgrade-job event.
#[derive(Clone, Deserialize)]
#[serde(rename_all(deserialize = "camelCase"))]
pub(crate) struct UpgradeEvent {
    from_version: String,
    to_version: String,
    message: String,
}

/// The initial upgrade-job Event is logged appropriately, else a failure is logged.
async fn handle_upgrade_event(
    latest_event: Event,
    release_name: &str,
    namespace: &str,
    k8s_client: Client,
) -> Result<()> {
    if let Some(action) = latest_event.action {
        if action == "Validation Failed" {
            if let Some(data) = latest_event.note {
                let ev: UpgradeEvent =
                    serde_json::from_str(data.as_str()).map_err(|err| anyhow!(err))?;
                console_logger::error("The validation for upgrade has failed, hence deleting the upgrade resources. Please re-run upgrade with valid values", ev.message.as_str());

                delete_upgrade_resources(release_name, namespace, k8s_client).await?;
            } else {
                return Err(anyhow!("Note not present in upgrade event"));
            }
        } else {
            console_logger::info("The upgrade has started\nYou can see the recent upgrade status using `kubectl openebs upgrade status` command", None);
        }
    }

    Ok(())
}

/// Log to user and error out if any rebuild in progress.
async fn rebuild_in_progress_validation(client: &ApiClient) -> Result<()> {
    if rebuild_in_progress(client).await? {
        console_logger::error("Error", "The cluster is rebuilding replica of some volumes. To skip this validation please run after some time or re-run with '--skip-replica-rebuild` flag.");
        return Err(anyhow!("Cluster is rebuilding replica of some volumes."));
    }

    Ok(())
}

/// Check for rebuild in progress.
async fn rebuild_in_progress(client: &ApiClient) -> Result<bool> {
    // The number of volumes to get per request.
    let mut starting_token = Some(0_isize);

    // The last paginated request will set the `starting_token` to `None`.
    while starting_token.is_some() {
        let vols = client
            .volumes_api()
            .get_volumes(HTTP_DATA_PAGE_SIZE as isize, None, starting_token)
            .await
            .map_err(|error| anyhow!("Failed to list Mayastor volumes: {error}"))?;
        let volumes = vols.into_body();
        starting_token = volumes.next_token;
        for volume in volumes.entries {
            if let Some(target) = &volume.state.target {
                if target
                    .children
                    .iter()
                    .any(|child| child.rebuild_progress.is_some())
                {
                    return Ok(true);
                }
            }
        }
    }
    Ok(false)
}

/// Validate if the upgrade path is a sane one.
async fn upgrade_path_validation(allow_unstable: bool, source_version: &Version) -> Result<()> {
    let destination_version = get_destination_version_tag();

    if destination_version.contains("develop") {
        console_logger::error("Error", "Upgrade failed as destination version is unsupported. Please try with `--skip-upgrade-path-validation-for-unsupported-version.");
        return Err(anyhow!(
            "The upgrade path is invalid: destination version contains develop"
        ));
    }

    let self_version_info = version_info!();
    let mut self_version: Option<Version> = None;
    if let Some(tag) = self_version_info.version_tag {
        if !tag.is_empty() {
            let tag = tag.strip_prefix('v').unwrap_or(&tag);
            if let Ok(sv) = Version::parse(tag) {
                self_version = Some(sv);
            }
        }
    }

    // Stable to unstable check.
    if !allow_unstable {
        let mut self_is_stable: bool = false;
        if let Some(ref version) = self_version {
            if version.pre.is_empty() {
                self_is_stable = true;
            }
        }
        if source_version.pre.is_empty() && !self_is_stable {
            console_logger::error(
                "Error",
                "Cannot upgrade from a stable version to an unstable version.",
            );
            return Err(anyhow!(
                "The upgrade path is invalid: stable to unstable upgrade version upgrade"
            ));
        }
    }

    // Upgrade not allowed to lower semver versions check.
    if let Some(ref version) = self_version {
        if version.lt(source_version) {
            console_logger::error("Error", "Cannot upgrade from a higher version to a lower version. If this is intentional, try again with '--skip-upgrade-path-validation-for-unsupported-version'.");
            return Err(anyhow!(
                "The upgrade path is invalid: higher to lower version upgrade"
            ));
        }
    }

    Ok(())
}

pub(crate) async fn get_pvc_from_uuid(
    uuid_list: HashSet<String>,
    k8s_client: Client,
) -> Result<Vec<String>> {
    let mut pvc_list: Vec<PartialObjectMeta<PersistentVolumeClaim>> =
        Vec::with_capacity(HTTP_DATA_PAGE_SIZE);
    paginated_list_metadata(
        Api::<PersistentVolumeClaim>::all(k8s_client),
        &mut pvc_list,
        None,
    )
    .await
    .map_err(|error| anyhow!("Failed to list PVCs: {error}"))?;
    let mut single_replica_volumes_pvc = Vec::with_capacity(HTTP_DATA_PAGE_SIZE);
    for pvc in pvc_list {
        if let Some(uuid) = pvc.metadata.uid {
            if uuid_list.contains(&uuid) {
                if let Some(pvc_name) = pvc.metadata.name {
                    single_replica_volumes_pvc.push(pvc_name);
                }
            }
        }
    }
    Ok(single_replica_volumes_pvc)
}

async fn single_volume_replica_validation(client: &ApiClient, k8s_client: Client) -> Result<()> {
    // let mut single_replica_volumes = Vec::new();
    // The number of volumes to get per request.
    let mut starting_token = Some(0_isize);
    let mut volumes = Vec::with_capacity(HTTP_DATA_PAGE_SIZE);

    // The last paginated request will set the `starting_token` to `None`.
    while starting_token.is_some() {
        let vols = client
            .volumes_api()
            .get_volumes(HTTP_DATA_PAGE_SIZE as isize, None, starting_token)
            .await
            .map_err(|error| anyhow!("Failed to list Mayastor volumes: {error}"))?;

        let v = vols.into_body();
        let single_rep_vol_ids: Vec<String> = v
            .entries
            .into_iter()
            .filter(|volume| volume.spec.num_replicas == 1)
            .map(|volume| volume.spec.uuid.to_string())
            .collect();
        volumes.extend(single_rep_vol_ids);
        starting_token = v.next_token;
    }

    if !volumes.is_empty() {
        let pvc_list = get_pvc_from_uuid(HashSet::from_iter(volumes), k8s_client)
            .await?
            .join("\n");

        let data = format!("The list below presents the single-replica volumes in the cluster. These single-replica volumes may not be accessible during upgrade. To skip this validation, please re-run with '--skip-single-replica-volume-validation` flag.\n{pvc_list}");
        console_logger::error("Error", data.as_str());
        return Err(anyhow!("Single replica volume present in cluster"));
    }
    Ok(())
}

/// Cordoned nodes logging to inform users of unavailable Mayastor nodes.
async fn already_cordoned_nodes_validation(client: &ApiClient) -> Result<()> {
    let mut cordoned_nodes_list = Vec::new();
    let nodes = client
        .nodes_api()
        .get_nodes(None)
        .await
        .map_err(|error| anyhow!("Failed to list Mayastor Nodes: {error}"))?;
    let nodelist = nodes.into_body();
    for node in nodelist {
        let node_spec = node.spec.ok_or(anyhow!("Node spec not present"))?;
        if matches!(
            node_spec.cordondrainstate,
            Some(CordonDrainState::cordonedstate(_))
        ) {
            cordoned_nodes_list.push(node.id);
        }
    }
    if !cordoned_nodes_list.is_empty() {
        let data = format!("One or more nodes in this cluster are in a Mayastor cordoned state. This implies that the storage space of DiskPools on these nodes cannot be utilized for volume replica rebuilds. Please ensure remaining storage nodes have enough available DiskPool space to accommodate volume replica rebuilds, that get triggered during the upgrade process. To skip this validation, please re-run with '--skip-cordoned-node-validation` flag. Below is a list of the Mayastor cordoned nodes:\n{cordoned_nodes}", cordoned_nodes = &cordoned_nodes_list.join("\n"));
        console_logger::error("Error", data.as_str());
        return Err(anyhow!("Nodes are in cordoned state"));
    }
    Ok(())
}

/// Pre-upgrade safety checks to account for common usage errors and data unavailability.
pub async fn upgrade_preflight_check(args: &UpgradeCommonArgs, release_name: &str) -> Result<()> {
    let helm_release = HelmRelease::new_from_cluster(
        args.helm_storage_driver.as_str(),
        release_name,
        args.namespace.as_str(),
    )
    .await?;

    if helm_release.mayastor_is_enabled() {
        console_logger::info("Volumes which make use of a single volume replica instance will be unavailable for some time during upgrade.", None);
        console_logger::info("It is recommended that you do not create new volumes which make use of only one volume replica.", None);

        let config = kube_proxy::ConfigBuilder::default_api_rest()
            .with_kube_config(args.kubeconfig.clone())
            .with_target_mod(|t| t.with_namespace(args.namespace.as_str()))
            .build()
            .await
            .map_err(|error| anyhow!("Failed to create Mayastor REST client config: {error}"))?;

        let rest_client = ApiClient::new(config);

        if !args.skip_upgrade_path_validation_for_unsupported_version {
            upgrade_path_validation(args.allow_unstable, helm_release.version()).await?;
        }

        if !args.skip_replica_rebuild {
            rebuild_in_progress_validation(&rest_client).await?;
        }

        if !args.skip_cordoned_node_validation {
            already_cordoned_nodes_validation(&rest_client).await?;
        }

        if !args.skip_single_replica_volume_validation {
            let k8s_client = kube_proxy::client_from_kubeconfig(args.kubeconfig.clone()).await?;
            single_volume_replica_validation(&rest_client, k8s_client).await?;
        }
    }

    Ok(())
}

/// Start upgrade by creating an upgrade-job and such.
pub async fn apply_upgrade(args: &UpgradeCommonArgs, release_name: &str) -> Result<()> {
    let k8s_client = kube_proxy::client_from_kubeconfig(args.kubeconfig.clone()).await?;

    let upgrade_events_field_selector = format!(
        "regarding.kind=Job,regarding.name={name}",
        name = upgrade_name_concat(release_name, "upgrade")
    );

    delete_older_upgrade_events(
        Api::namespaced(k8s_client.clone(), args.namespace.as_str()),
        upgrade_events_field_selector.as_str(),
    )
    .await?;

    create_upgrade_resources(args, release_name, k8s_client.clone()).await?;

    for _ in 0..6 {
        // wait for 10 seconds for the upgrade event to be published
        tokio::time::sleep(std::time::Duration::from_secs(10)).await;
        match get_latest_upgrade_event(
            args.namespace.as_str(),
            upgrade_events_field_selector.as_str(),
        )
        .await
        {
            Ok(latest_event) => {
                handle_upgrade_event(
                    latest_event,
                    release_name,
                    args.namespace.as_str(),
                    k8s_client,
                )
                .await?
            }
            Err(_) => continue,
        }
        break;
    }

    Ok(())
}

/// Flatten Tokio errors from spawning tasks and errors from failed (yet successfully spawn-ed)
/// tasks.
async fn joined_flatten<T>(handle: JoinHandle<Result<T>>) -> Result<T> {
    match handle.await.map_err(|err| anyhow!(err)) {
        Ok(Ok(result)) => Ok(result),
        Ok(Err(err)) => Err(err),
        Err(err) => Err(err),
    }
}

/// Create upgrade kubernetes resources.
pub async fn create_upgrade_resources(
    args: &UpgradeCommonArgs,
    release_name: &str,
    k8s_client: Client,
) -> Result<()> {
    let creation_log = |kind: &str, name: String, namespace: Option<String>| -> String {
        if let Some(namespace) = namespace {
            return format!("Created {kind} '{name}' in the '{namespace}' namespace");
        }
        format!("Created {kind} '{name}'")
    };

    let sa = upgrade_job_service_account(
        Some(args.namespace.clone()),
        upgrade_name_concat(release_name, "upgrade-service-account"),
    );
    let sa_client: Api<ServiceAccount> =
        Api::namespaced(k8s_client.clone(), args.namespace.as_str());

    let cluster_role_binding =
        upgrade_job_cluster_role_binding(Some(args.namespace.clone()), release_name.to_string());
    let cluster_role_binding_client: Api<ClusterRoleBinding> = Api::all(k8s_client.clone());

    let cluster_role = upgrade_job_cluster_role(
        Some(args.namespace.clone()),
        upgrade_name_concat(release_name, "upgrade-role"),
    );
    let cluster_role_client: Api<ClusterRole> = Api::all(k8s_client.clone());

    let cm_data = config_map_data(args.set_file.as_slice())?;
    let cm = upgrade_configmap(cm_data.0, args.namespace.as_str(), release_name.to_string());
    let cm_client: Api<ConfigMap> = Api::namespaced(k8s_client.clone(), args.namespace.as_str());

    let set_file = job_set_file_args(args.set_file.as_slice(), Some(cm_data.1))?;
    let job = upgrade_job(args, release_name, set_file.unwrap_or_default()).await?;
    let job_client: Api<Job> = Api::namespaced(k8s_client.clone(), args.namespace.as_str());

    try_join!(
        joined_flatten(spawn(idempotent_create_resource(
            sa_client,
            sa.clone(),
            Some(creation_log(
                "ServiceAccount",
                sa.name_unchecked(),
                sa.namespace()
            ))
        ))),
        joined_flatten(spawn(idempotent_create_resource(
            cluster_role_binding_client,
            cluster_role_binding.clone(),
            Some(creation_log(
                "ClusterRoleBinding",
                cluster_role_binding.name_unchecked(),
                None
            ))
        ))),
        joined_flatten(spawn(idempotent_create_resource(
            cluster_role_client,
            cluster_role.clone(),
            Some(creation_log(
                "ClusterRole",
                cluster_role.name_unchecked(),
                None
            ))
        ))),
        joined_flatten(spawn(idempotent_create_resource(
            cm_client,
            cm.clone(),
            Some(creation_log(
                "ConfigMap",
                cm.name_unchecked(),
                cm.namespace()
            ))
        ))),
        joined_flatten(spawn(idempotent_create_resource(
            job_client,
            job.clone(),
            Some(creation_log("Job", job.name_unchecked(), job.namespace()))
        ))),
    )?;

    Ok(())
}

/// Delete upgrade kubernetes resources.
pub async fn delete_upgrade_resources(
    release_name: &str,
    ns: &str,
    k8s_client: Client,
) -> Result<()> {
    let deletion_log = |kind: &str, name: String, namespace: Option<String>| -> String {
        if let Some(namespace) = namespace {
            return format!("Deleted {kind} '{name}' from the '{namespace}' namespace");
        }
        format!("Deleted {kind} '{name}'")
    };
    let version = upgrade_obj_suffix();

    let job_client: Api<Job> = Api::namespaced(k8s_client.clone(), ns);
    let job_name = format!(
        "{release_name}-upgrade-{version}",
        version = version.as_str()
    );

    let cm_client: Api<ConfigMap> = Api::namespaced(k8s_client.clone(), ns);
    let cm_name = format!(
        "{release_name}-upgrade-config-map-{version}",
        version = version.as_str()
    );

    let cluster_role_client: Api<ClusterRole> = Api::all(k8s_client.clone());
    let cluster_role_name = upgrade_name_concat(release_name, "upgrade-role");

    let cluster_role_binding_client: Api<ClusterRoleBinding> = Api::all(k8s_client.clone());
    let cluster_role_binding_name = format!(
        "{release_name}-upgrade-role-binding-{version}",
        version = version.as_str()
    );

    let sa_client: Api<ServiceAccount> = Api::namespaced(k8s_client.clone(), ns);
    let sa_name = upgrade_name_concat(release_name, "upgrade-service-account");

    try_join!(
        joined_flatten(spawn(idempotent_delete_resource(
            job_client,
            job_name.clone(),
            Some(deletion_log("Job", job_name.clone(), Some(ns.to_string())))
        ))),
        joined_flatten(spawn(idempotent_delete_resource(
            cm_client,
            cm_name.clone(),
            Some(deletion_log(
                "ConfigMap",
                cm_name.clone(),
                Some(ns.to_string())
            ))
        ))),
        joined_flatten(spawn(idempotent_delete_resource(
            cluster_role_client,
            cluster_role_name.clone(),
            Some(deletion_log("ClusterRole", cluster_role_name.clone(), None))
        ))),
        joined_flatten(spawn(idempotent_delete_resource(
            cluster_role_binding_client,
            cluster_role_binding_name.clone(),
            Some(deletion_log(
                "ClusterRoleBinding",
                cluster_role_binding_name.clone(),
                None
            ))
        ))),
        joined_flatten(spawn(idempotent_delete_resource(
            sa_client,
            sa_name.clone(),
            Some(deletion_log(
                "ServiceAccount",
                sa_name.clone(),
                Some(ns.to_string())
            ))
        ))),
    )?;

    Ok(())
}

/// Create a kubernetes resource if an object of the same doesn't already exist.
pub async fn idempotent_create_resource<K>(
    client: Api<K>,
    resource: K,
    log: Option<String>,
) -> Result<()>
where
    K: k8s_openapi::Resource
        + Clone
        + std::fmt::Debug
        + kube::Resource
        + DeserializeOwned
        + Serialize,
{
    let pp = PostParams::default();
    client
        .create(&pp, &resource)
        .await
        .map(|_| {
            if let Some(log_line) = log {
                println!("{log_line}");
            }
        })
        .or_else(|err| match err {
            kubeError::Api(response) if response.reason.eq("AlreadyExists") => {
                println!(
                    "{kind} '{name}' already exists",
                    kind = kind(&resource),
                    name = resource.name_unchecked()
                );
                Ok(())
            }
            other => Err(anyhow!(other)),
        })
}

/// Delete a kubernetes object, if an object wih the same name exists.
pub async fn idempotent_delete_resource<K>(
    client: Api<K>,
    resource_name: String,
    log: Option<String>,
) -> Result<()>
where
    K: k8s_openapi::Resource + Clone + std::fmt::Debug + kube::Resource + DeserializeOwned,
{
    let dp = DeleteParams::foreground();
    client
        .delete(resource_name.as_str(), &dp)
        .await
        .map(|_| {
            if let Some(log_line) = log {
                println!("{log_line}");
            }
        })
        .or_else(|err| match err {
            kubeError::Api(response) if response.reason.eq("NotFound") => Ok(()),
            other => Err(anyhow!(other)),
        })
}
