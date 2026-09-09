use super::{ApiTarget, Error};

use kube::Client;
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use std::collections::BTreeMap;

/// Version prefix of the api served by the rawfile-localpv api-server.
const API_VERSION: &str = "v1";

/// Value of the `status` field of a kubernetes `Status` error response.
/// A body which is not a kubernetes `Status` - such as the api-server's own
/// `{"detail": ...}` - fails to deserialize, and is reconstructed by kube with the
/// http status line in this field instead. That is how an error raised by the
/// kube-apiserver is told apart from one raised by the rawfile-localpv api-server.
const K8S_FAILURE_STATUS: &str = "Failure";

/// Status codes with which the kube-apiserver proxy reports that it could not reach the
/// backing service.
const UNREACHABLE_CODES: [u16; 4] = [500, 502, 503, 504];

/// A client for the rawfile-localpv api-server.
/// The api-server is only exposed in-cluster, through the controller service, so requests are
/// issued against the kube-apiserver service proxy:
/// `/api/v1/namespaces/{namespace}/services/{service}:{port}/proxy/{path}`.
pub(crate) struct ApiClient {
    client: Client,
    target: ApiTarget,
}

impl ApiClient {
    /// Returns a new `Self` for the service described by the cli args.
    pub(crate) fn new(client: Client, cli_args: &super::CliArgs) -> Self {
        Self {
            client,
            target: ApiTarget::from(cli_args),
        }
    }

    /// Lists all nodes known to the api-server.
    pub(crate) async fn nodes(&self) -> Result<Vec<Node>, Error> {
        self.get(&["nodes"]).await
    }

    /// Gets a single node, `None` if no such node is known to the api-server.
    pub(crate) async fn node(&self, node: &str) -> Result<Option<Node>, Error> {
        self.get_opt(&["nodes", node]).await
    }

    /// Lists the volumes of the given pool of the given node.
    /// `None` if the node is unknown to the api-server or cannot be reached by it.
    pub(crate) async fn volumes(
        &self,
        node: &str,
        pool: &str,
    ) -> Result<Option<Vec<VolumeStat>>, Error> {
        self.get_opt(&["nodes", node, pool]).await
    }

    /// Gets a single volume of the given pool of the given node.
    pub(crate) async fn volume(
        &self,
        node: &str,
        pool: &str,
        volume: &str,
    ) -> Result<Option<VolumeStat>, Error> {
        self.get_opt(&["nodes", node, pool, volume]).await
    }

    /// Lists the tasks of the given node, keyed by task id.
    /// `None` if the node is unknown to the api-server or cannot be reached by it.
    pub(crate) async fn tasks(&self, node: &str) -> Result<Option<BTreeMap<String, Task>>, Error> {
        self.get_opt(&["nodes", node, "tasks"]).await
    }

    /// Gets a single task of the given node.
    pub(crate) async fn task(&self, node: &str, task: &str) -> Result<Option<Task>, Error> {
        self.get_opt(&["nodes", node, "tasks", task]).await
    }

    /// The kube-apiserver service proxy path for the given api-server path segments.
    fn path(&self, segments: &[&str]) -> Result<String, Error> {
        validate_path_segment(&self.target.namespace)?;
        validate_path_segment(&self.target.service)?;
        let mut path = format!(
            "/api/v1/namespaces/{namespace}/services/{service}:{port}/proxy/{API_VERSION}",
            namespace = self.target.namespace,
            service = self.target.service,
            port = self.target.port
        );
        for segment in segments {
            validate_path_segment(segment)?;
            path.push('/');
            path.push_str(segment);
        }
        Ok(path)
    }

    /// Gets the given api-server path and deserializes the json response body.
    async fn get<T: DeserializeOwned>(&self, segments: &[&str]) -> Result<T, Error> {
        self.send(&self.path(segments)?)
            .await
            .map_err(|source| self.request_error(source))
    }

    /// As [`Self::get`], but maps a `404` raised by the api-server to `None`.
    async fn get_opt<T: DeserializeOwned>(&self, segments: &[&str]) -> Result<Option<T>, Error> {
        match self.send(&self.path(segments)?).await {
            Ok(found) => Ok(Some(found)),
            Err(source) if is_resource_not_found(&source) => Ok(None),
            Err(source) => Err(self.request_error(source)),
        }
    }

    /// Sends a `GET` for the given kube-apiserver path.
    /// The path is relative: the base uri and the authentication are applied by the client.
    async fn send<T: DeserializeOwned>(&self, path: &str) -> Result<T, kube::Error> {
        let request = http::Request::builder()
            .method(http::Method::GET)
            .uri(path)
            .header(http::header::ACCEPT, "application/json")
            .body(Vec::new())
            .map_err(kube::Error::HttpError)?;
        self.client.request::<T>(request).await
    }

    /// Converts a failed request into an [`Error`], separating the failures which mean the
    /// api-server could not be reached at all from the ones it answered with.
    fn request_error(&self, source: kube::Error) -> Error {
        let unreachable = match &source {
            kube::Error::Api(response) => {
                // Only the kube-apiserver can tell us that the service is missing or that it
                // could not be reached; a status raised by the api-server itself is a real answer.
                response.status == K8S_FAILURE_STATUS
                    && (response.code == 404 || UNREACHABLE_CODES.contains(&response.code))
            }
            kube::Error::Service(_) | kube::Error::HyperError(_) => true,
            _ => false,
        };
        let target = self.target.clone();
        if unreachable {
            Error::Unreachable { target, source }
        } else {
            Error::Request { target, source }
        }
    }
}

/// Whether the error is a `404` raised by the rawfile-localpv api-server, meaning the requested
/// node, volume or task does not exist.
fn is_resource_not_found(error: &kube::Error) -> bool {
    matches!(
        error,
        kube::Error::Api(response) if response.code == 404 && response.status != K8S_FAILURE_STATUS
    )
}

/// Rejects a path segment which would alter the request rather than fail it, since names are
/// interpolated into the request path.
fn validate_path_segment(segment: &str) -> Result<(), Error> {
    if segment.is_empty()
        || segment.contains(['/', '?', '#', '%', ':'])
        || segment.contains(char::is_whitespace)
    {
        return Err(Error::InvalidName {
            name: segment.to_string(),
        });
    }
    Ok(())
}

/// A node running the rawfile-localpv node-plugin, as reported by the api-server.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct Node {
    /// Name of the kubernetes node.
    pub(crate) name: String,
    /// Ip address of the node-plugin.
    pub(crate) ip: String,
    /// Stats of the storage pools of the node, keyed by pool name.
    /// `None` if the api-server could not collect them from the node.
    #[serde(default)]
    pub(crate) pools_stat: Option<BTreeMap<String, PoolStat>>,
    /// Whether the node-plugin is reachable by the api-server.
    pub(crate) online: bool,
}

/// Stats of a single storage pool of a node.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct PoolStat {
    /// Capacity kept free on the pool, as configured.
    pub(crate) reserved_capacity: String,
    /// Mount path of the pool on the node.
    pub(crate) path: String,
    /// How `reserved_capacity` is interpreted, viz percentage, absolute.
    pub(crate) reserved_capacity_mode: String,
    /// Total capacity of the pool, in bytes.
    pub(crate) capacity: u64,
    /// Whether the filesystem backing the pool supports copy on write.
    pub(crate) copy_on_write_supported: bool,
}

/// Stats of a single rawfile volume.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct VolumeStat {
    /// Name of the volume, which is the name of its persistent volume.
    pub(crate) name: String,
    /// Requested size of the volume, in bytes.
    pub(crate) size: u64,
    /// Whether the volume is a copy on write clone.
    pub(crate) copy_on_write: bool,
    /// Whether the backing image file is sparse.
    pub(crate) thin_provision: bool,
    /// Whether the volume is ready to be used.
    pub(crate) ready: bool,
    /// Unix timestamp at which the volume was deleted, if it was.
    #[serde(default)]
    pub(crate) deleted_at: Option<f64>,
    /// Unix timestamp at which the deleted volume is to be garbage collected, if it is.
    #[serde(default)]
    pub(crate) gc_at: Option<f64>,
    /// Unix timestamp at which the volume was created.
    #[serde(default)]
    pub(crate) created_at: Option<f64>,
    /// Whether the filesystem of the volume is frozen.
    pub(crate) freezefs: bool,
    /// Name of the pool hosting the volume.
    pub(crate) storage_pool: String,
    /// Path of the image file backing the volume.
    pub(crate) img_file: String,
    /// Bytes used within the volume.
    pub(crate) used: u64,
    /// Apparent size of the backing image file, in bytes.
    pub(crate) logical_size: u64,
    /// Bytes the backing image file occupies on the pool.
    pub(crate) physical_size: u64,
}

/// A task queued on the node-plugin of a node.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct Task {
    /// Name of the task.
    pub(crate) task: String,
    /// Positional arguments of the task.
    #[serde(default)]
    pub(crate) args: Option<Vec<String>>,
    /// Keyword arguments of the task.
    #[serde(default)]
    pub(crate) kwargs: Option<BTreeMap<String, serde_json::Value>>,
    /// Number of times the task has been retried.
    #[serde(default)]
    pub(crate) retry_count: u32,
    /// State of the task.
    pub(crate) state: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The proxy path prefix built from the defaults, which the tests below hang paths off.
    const PREFIX: &str =
        "/api/v1/namespaces/openebs/services/rawfile-localpv-controller:8080/proxy/v1";

    /// An `ApiClient` cannot be built without a `kube::Client`, so the path building is
    /// exercised through the same format string with the same defaults.
    fn path(segments: &[&str]) -> Result<String, Error> {
        let mut path = format!(
            "/api/v1/namespaces/{namespace}/services/{service}:{port}/proxy/{API_VERSION}",
            namespace = super::super::DEFAULT_NAMESPACE,
            service = super::super::DEFAULT_CONTROLLER_SERVICE,
            port = super::super::DEFAULT_API_PORT
        );
        for segment in segments {
            validate_path_segment(segment)?;
            path.push('/');
            path.push_str(segment);
        }
        Ok(path)
    }

    #[test]
    fn proxy_paths() {
        assert_eq!(path(&["nodes"]).unwrap(), format!("{PREFIX}/nodes"));
        assert_eq!(
            path(&["nodes", "node-1", "default"]).unwrap(),
            format!("{PREFIX}/nodes/node-1/default")
        );
        assert_eq!(
            path(&["nodes", "node-1", "default", "pvc-abc"]).unwrap(),
            format!("{PREFIX}/nodes/node-1/default/pvc-abc")
        );
        assert_eq!(
            path(&["nodes", "node-1", "tasks", "task-1"]).unwrap(),
            format!("{PREFIX}/nodes/node-1/tasks/task-1")
        );
    }

    #[test]
    fn rejects_names_which_would_alter_the_path() {
        for name in ["", "a/b", "a?b", "a#b", "a%2fb", "a:b", "a b"] {
            assert!(
                path(&["nodes", name]).is_err(),
                "expected {name:?} to be rejected"
            );
        }
    }

    #[test]
    fn deserializes_nodes() {
        let nodes: Vec<Node> = serde_json::from_str(
            r#"[
              {
                "name": "node-1",
                "ip": "10.244.0.5",
                "online": true,
                "pools_stat": {
                  "default": {
                    "reserved_capacity": "10",
                    "path": "/var/lib/rawfile-localpv",
                    "reserved_capacity_mode": "percentage",
                    "capacity": 32210157568,
                    "copy_on_write_supported": true
                  }
                }
              },
              { "name": "node-2", "ip": "10.244.0.6", "online": false, "pools_stat": null }
            ]"#,
        )
        .expect("nodes payload should deserialize");

        assert_eq!(nodes.len(), 2);
        let pools = nodes[0].pools_stat.as_ref().expect("node-1 has pools");
        assert_eq!(pools["default"].capacity, 32210157568);
        assert_eq!(pools["default"].reserved_capacity_mode, "percentage");
        assert!(!nodes[1].online);
        assert!(nodes[1].pools_stat.is_none());
    }

    #[test]
    fn deserializes_volumes() {
        let volumes: Vec<VolumeStat> = serde_json::from_str(
            r#"[
              {
                "name": "pvc-abc",
                "size": 1073741824,
                "copy_on_write": false,
                "thin_provision": true,
                "ready": true,
                "deleted_at": 0.0,
                "gc_at": 0.0,
                "created_at": 1755000000.0,
                "freezefs": false,
                "storage_pool": "default",
                "img_file": "/var/lib/rawfile-localpv/pvc-abc",
                "used": 33554432,
                "logical_size": 1073741824,
                "physical_size": 33554432
              },
              {
                "name": "pvc-def",
                "size": 1073741824,
                "copy_on_write": false,
                "thin_provision": true,
                "ready": false,
                "freezefs": false,
                "storage_pool": "default",
                "img_file": "/var/lib/rawfile-localpv/pvc-def",
                "used": 0,
                "logical_size": 0,
                "physical_size": 0
              }
            ]"#,
        )
        .expect("volumes payload should deserialize");

        assert_eq!(volumes[0].created_at, Some(1755000000.0));
        assert_eq!(volumes[0].deleted_at, Some(0.0));
        // The timestamps are absent rather than null on an unready volume.
        assert_eq!(volumes[1].created_at, None);
        assert_eq!(volumes[1].deleted_at, None);
    }

    #[test]
    fn deserializes_tasks() {
        let tasks: BTreeMap<String, Task> = serde_json::from_str(
            r#"{
              "0f0c": {
                "task": "expand_volume",
                "args": ["pvc-abc", "2147483648"],
                "kwargs": null,
                "retry_count": 2,
                "state": "pending"
              },
              "1a2b": { "task": "gc", "args": null, "state": "running" }
            }"#,
        )
        .expect("tasks payload should deserialize");

        assert_eq!(tasks["0f0c"].retry_count, 2);
        assert_eq!(
            tasks["0f0c"].args.as_deref(),
            Some(["pvc-abc".to_string(), "2147483648".to_string()].as_slice())
        );
        // retry_count defaults, and both argument collections may be absent.
        assert_eq!(tasks["1a2b"].retry_count, 0);
        assert!(tasks["1a2b"].args.is_none());
        assert!(tasks["1a2b"].kwargs.is_none());
    }

    #[test]
    fn a_404_from_the_api_server_is_not_one_from_kubernetes() {
        // The api-server answers `{"detail": ...}`, which kube cannot parse into a `Status` and
        // reconstructs with the http status line.
        let api_server = kube::Error::Api(kube::core::ErrorResponse {
            status: "404 Not Found".into(),
            message: "{\"detail\":\"Volume not found\"}".into(),
            reason: "Failed to parse error data".into(),
            code: 404,
        });
        assert!(is_resource_not_found(&api_server));

        // The kube-apiserver answers with a `Status`, meaning the service itself is missing.
        let kube_apiserver = kube::Error::Api(kube::core::ErrorResponse {
            status: K8S_FAILURE_STATUS.into(),
            message: "services \"rawfile-localpv-controller\" not found".into(),
            reason: "NotFound".into(),
            code: 404,
        });
        assert!(!is_resource_not_found(&kube_apiserver));
    }
}
