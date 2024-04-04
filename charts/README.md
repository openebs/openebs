# OpenEBS Helm Chart

[OpenEBS](https://openebs.io) helps Developers and Platform SREs easily deploy Kubernetes Stateful Workloads that require fast and highly reliable container attached storage. OpenEBS can be deployed on any Kubernetes cluster - either in cloud, on-premise (virtual or bare metal) or developer laptop (minikube).

OpenEBS Data Engines and Control Plane are implemented as micro-services, deployed as containers and orchestrated by Kubernetes itself. An added advantage of being a completely Kubernetes native solution is that administrators and developers can interact and manage OpenEBS using all the wonderful tooling that is available for Kubernetes like kubectl, Helm, Prometheus, Grafana, etc.

OpenEBS turns any storage available on the Kubernetes worker nodes into local or distributed Kubernetes Persistent Volumes.
* Local Volumes are accessible only from a single node in the cluster. Pods using Local Volume have to be scheduled on the node where volume is provisioned. Local Volumes are typically preferred for distributed workloads like Cassandra, MongoDB, Elastic, etc that are distributed in nature and have high availability built into them. Depending on the type of storage attached to your Kubernetes worker nodes, you can select from different flavors of Dynamic Local PV - Hostpath, LVM, or ZFS.
* Replicated Volumes as the name suggests, are those that have their data synchronously replicated to multiple nodes. Volumes can sustain node failures. The replication also can be setup across availability zones helping applications move across availability zones. Depending on the type of storage attached to your Kubernetes worker nodes and application performance requirements, you can select Mayastor.

## Documentation and user guides

You can run OpenEBS on any Kubernetes 1.23 and above cluster in a matter of minutes. See the [Quickstart Guide to OpenEBS](https://openebs.io/) for detailed instructions.

## Getting started

### Dependencies

OpenEBS helm chart is an umbrella chart that pulls together engine specific charts. The engine charts are included as dependencies.

| Repository | Name | Version |
|------------|------|---------|
| https://openebs.github.io/dynamic-localpv-provisioner | localpv-provisioner | 4.0.0 |
| https://openebs.github.io/lvm-localpv | lvm-localpv | 1.5.1 |
| https://openebs.github.io/mayastor-extensions | mayastor | 2.6.0 |
| https://openebs.github.io/zfs-localpv | zfs-localpv | 2.5.1 |

```bash
openebs
├── (default) LocalPV HostPath
├── (default) LocalPV LVM
├── (default) LocalPV ZFS
└── (default) Mayastor (replicated)
```

### Prerequisites

- Kubernetes 1.23 and above with RBAC enabled
- Depending on the engine and type of platform, you may have to customize the values or run additional pre-requisites. Refer to [documentation](https://openebs.io).

### Setup Helm Repository

Before installing OpenEBS Helm charts, you need to add the [OpenEBS Helm repository](https://openebs.github.io/charts) to your Helm client.

```bash
helm repo add openebs https://openebs.github.io/openebs
helm repo update
```

### Installing OpenEBS

```bash
helm install --name `<RELEASE NAME>` --namespace openebs openebs/openebs --create-namespace
```

Examples:
- Assuming the release will be called openebs, the command would be:
  ```bash
  helm install --name openebs --namespace openebs openebs/openebs --create-namespace
  ```

### To uninstall/delete instance with release name

```bash
helm ls --all
helm delete `<RELEASE NAME>`
```

> **Tip**: Prior to deleting the helm chart, make sure all the storage volumes and pools are deleted.

## Configuration

The following table lists the common configurable parameters of the OpenEBS chart and their default values. For a full list of configurable parameters check out the [values.yaml](../charts/values.yaml).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| localpv-provisioner.rbac.create | bool | `true` |  |
| lvm-localpv.crds.csi.volumeSnapshots.enabled | bool | `false` | Enable this if zfs chart installation is disabled. |
| lvm-localpv.crds.csi.volumeSnapshots.keep | bool | `true` | Disable this to uninstall crds on chart uninstallation. |
| lvm-localpv.crds.lvmLocalPv.enabled | bool | `true` | For upgrades from previous lvm localpv installation this needs to be disabled. |
| lvm-localpv.enabled | bool | `true` |  |
| mayastor.crds.csi.volumeSnapshots.enabled | bool | `false` | Enable this if zfs chart installation is disabled. For upgrades from previous mayastor installation this needs to be disabled. |
| mayastor.crds.csi.volumeSnapshots.keep | bool | `true` | Disable this to uninstall crds on chart uninstallation. |
| mayastor.crds.jaeger.enabled | bool | `true` | For upgrades from 2.5 mayastor chart this needs to be disabled. |
| mayastor.crds.jaeger.keep | bool | `true` | Disable this to uninstall crds on chart uninstallation. |
| mayastor.csi.node.initContainers.enabled | bool | `true` |  |
| mayastor.enabled | bool | `true` |  |
| mayastor.localpv-provisioner.enabled | bool | `false` |  |
| release.version | string | `"4.0.0"` |  |
| zfs-localpv.crds.csi.volumeSnapshots.enabled | bool | `true` | Default installation of the openebs unified chart will install crds from zfs depenendency chart. |
| zfs-localpv.crds.csi.volumeSnapshots.keep | bool | `true` | Disable this to uninstall crds on chart uninstallation. |
| zfs-localpv.crds.zfsLocalPv.enabled | bool | `true` | For upgrades from previous zfs localpv installation this needs to be disabled. |
| zfs-localpv.enabled | bool | `true` |  |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
helm install --name `<RELEASE NAME>` -f values.yaml --namespace openebs openebs/openebs --create-namespace
```

> **Tip**: You can use the default [values.yaml](values.yaml)