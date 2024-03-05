# OpenEBS Helm Chart

[OpenEBS](https://openebs.io) helps Developers and Platform SREs easily deploy Kubernetes Stateful Workloads that require fast and highly reliable container attached storage. OpenEBS can be deployed on any Kubernetes cluster - either in cloud, on-premise (virtual or bare metal) or developer laptop (minikube).

OpenEBS Data Engines and Control Plane are implemented as micro-services, deployed as containers and orchestrated by Kubernetes itself. An added advantage of being a completely Kubernetes native solution is that administrators and developers can interact and manage OpenEBS using all the wonderful tooling that is available for Kubernetes like kubectl, Helm, Prometheus, Grafana, etc.

OpenEBS turns any storage available on the Kubernetes worker nodes into local or distributed Kubernetes Persistent Volumes.
* Local Volumes are accessible only from a single node in the cluster. Pods using Local Volume have to be scheduled on the node where volume is provisioned. Local Volumes are typically preferred for distributed workloads like Cassandra, MongoDB, Elastic, etc that are distributed in nature and have high availability built into them. Depending on the type of storage attached to your Kubernetes worker nodes, you can select from different flavors of Dynamic Local PV - Hostpath, LVM, or ZFS.
* Replicated Volumes as the name suggests, are those that have their data synchronously replicated to multiple nodes. Volumes can sustain node failures. The replication also can be setup across availability zones helping applications move across availability zones. Depending on the type of storage attached to your Kubernetes worker nodes and application performance requirements, you can select Mayastor.

## Documentation and user guides

You can run OpenEBS on any Kubernetes 1.21+ cluster in a matter of minutes. See the [Quickstart Guide to OpenEBS](https://openebs.io/) for detailed instructions.

## Getting started

### Dependencies

OpenEBS helm chart is an umbrella chart that pulls together engine specific charts. The engine charts are included as dependencies.

| Repository | Name | Version |
|------------|------|---------|
| https://openebs.github.io/dynamic-localpv-provisioner | localpv-provisioner | 3.5.0 |
| https://openebs.github.io/lvm-localpv | lvm-localpv | 1.4.0 |
| https://openebs.github.io/mayastor-extensions | mayastor | 2.5.0 |
| https://openebs.github.io/zfs-localpv | zfs-localpv | 2.4.0 |

```bash
openebs
├── (default) LocalPV HostPath
├── (default) LocalPV LVM
├── (default) LocalPV ZFS
└── (default) Mayastor (replicated)
```

### Prerequisites

- Kubernetes 1.18+ with RBAC enabled
- Depending on the engine and type of platform, you may have to customize the values or run additional pre-requisites. Refer to [documentation](https://openebs.io).

### Setup Helm Repository

Before installing OpenEBS Helm charts, you need to add the [OpenEBS Helm repository](https://openebs.github.io/charts) to your Helm client.

```bash
helm repo add openebs https://openebs.github.io/charts
helm repo update
```

### Installing OpenEBS

```bash
helm install --name `my-release` --namespace openebs openebs/openebs --create-namespace
```

Examples:
- Assuming the release will be called openebs, the command would be:
  ```bash
  helm install --name openebs --namespace openebs openebs/openebs --create-namespace
  ```

### To uninstall/delete instance with release name

```bash
helm ls --all
helm delete `my-release`
```

> **Tip**: Prior to deleting the helm chart, make sure all the storage volumes and pools are deleted.

## Configuration

The following table lists the common configurable parameters of the OpenEBS chart and their default values. For a full list of configurable parameters check out the [values.yaml](https://github.com/openebs/charts/blob/HEAD/charts/openebs/values.yaml).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| imagePullSecrets | list | `[]` |  |
| localprovisioner.affinity | object | `{}` |  |
| localprovisioner.basePath | string | `"/var/openebs/local"` |  |
| localprovisioner.deviceClass.blockDeviceSelectors | object | `{}` |  |
| localprovisioner.deviceClass.enabled | bool | `true` |  |
| localprovisioner.deviceClass.fsType | string | `"ext4"` |  |
| localprovisioner.deviceClass.isDefaultClass | bool | `false` |  |
| localprovisioner.deviceClass.name | string | `"openebs-device"` |  |
| localprovisioner.deviceClass.nodeAffinityLabels | list | `[]` |  |
| localprovisioner.deviceClass.reclaimPolicy | string | `"Delete"` |  |
| localprovisioner.enableDeviceClass | bool | `true` |  |
| localprovisioner.enableHostpathClass | bool | `true` |  |
| localprovisioner.enableLeaderElection | bool | `true` |  |
| localprovisioner.enabled | bool | `true` |  |
| localprovisioner.healthCheck.initialDelaySeconds | int | `30` |  |
| localprovisioner.healthCheck.periodSeconds | int | `60` |  |
| localprovisioner.hostpathClass.basePath | string | `""` |  |
| localprovisioner.hostpathClass.enabled | bool | `true` |  |
| localprovisioner.hostpathClass.ext4Quota.enabled | bool | `false` |  |
| localprovisioner.hostpathClass.ext4Quota.hardLimitGrace | string | `"0%"` |  |
| localprovisioner.hostpathClass.ext4Quota.softLimitGrace | string | `"0%"` |  |
| localprovisioner.hostpathClass.isDefaultClass | bool | `false` |  |
| localprovisioner.hostpathClass.name | string | `"openebs-hostpath"` |  |
| localprovisioner.hostpathClass.nodeAffinityLabels | list | `[]` |  |
| localprovisioner.hostpathClass.reclaimPolicy | string | `"Delete"` |  |
| localprovisioner.hostpathClass.xfsQuota.enabled | bool | `false` |  |
| localprovisioner.hostpathClass.xfsQuota.hardLimitGrace | string | `"0%"` |  |
| localprovisioner.hostpathClass.xfsQuota.softLimitGrace | string | `"0%"` |  |
| localprovisioner.image | string | `"openebs/provisioner-localpv"` |  |
| localprovisioner.imageTag | string | `"3.5.0"` |  |
| localprovisioner.nodeSelector | object | `{}` |  |
| localprovisioner.replicas | int | `1` |  |
| localprovisioner.resources | object | `{}` |  |
| localprovisioner.tolerations | list | `[]` |  |
| localprovisioner.waitForBDBindTimeoutRetryCount | string | `"12"` |  |
| lvm-localpv.enabled | bool | `true` |  |
| mayastor.enabled | bool | `true` | Enable Mayastor storage engine Note: Enabling this will remove LocalPV Provisioner and NDM (default chart components). |
| mayastor.image.pullPolicy | string | `"IfNotPresent"` | ImagePullPolicy for Mayastor images |
| mayastor.image.registry | string | `"docker.io"` | Image registry to pull Mayastor product images |
| mayastor.image.repo | string | `"openebs"` | Image registry's namespace |
| mayastor.image.tag | string | `"v2.5.0"` | Release tag for Mayastor images |
| rbac.create | bool | `true` |  |
| release.version | string | `"4.0.0"` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `nil` |  |
| zfs-localpv.enabled | bool | `true` |  |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
helm install --name `my-release` -f values.yaml --namespace openebs openebs/openebs --create-namespace
```

> **Tip**: You can use the default [values.yaml](values.yaml)