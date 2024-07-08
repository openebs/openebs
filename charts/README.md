# OpenEBS Helm Repository

<img width="200" align="right" alt="OpenEBS Logo" src="https://raw.githubusercontent.com/cncf/artwork/master/projects/openebs/stacked/color/openebs-stacked-color.png" xmlns="http://www.w3.org/1999/html">

[OpenEBS](https://openebs.io) helps Developers and Platform SREs easily deploy Kubernetes Stateful Workloads that require fast and highly reliable container attached storage. OpenEBS can be deployed on any Kubernetes cluster - either in cloud, on-premise (virtual or bare metal) or developer system (minikube).

OpenEBS Data Engines and Control Plane are implemented as micro-services, deployed as containers and orchestrated by Kubernetes itself. An added advantage of being a completely Kubernetes native solution is that administrators and developers can interact and manage OpenEBS using all the wonderful tooling that is available for Kubernetes like kubectl, Helm, Prometheus, Grafana, etc.

OpenEBS turns any storage available on the Kubernetes worker nodes into local or distributed Kubernetes Persistent Volumes.

#### Local PV

Local Volumes are accessible only from a single node in the cluster. Pods using Local Volume have to be scheduled on the node where volume is provisioned. Local Volumes are typically preferred for distributed workloads like Cassandra, MongoDB, Elastic, etc that are distributed in nature and have high availability built into them. Depending on the type of storage attached to the Kubernetes worker, OpenEBS offers different flavors of Local PV - Hostpath, LVM and ZFS.

#### Replicated PV

Replicated Volumes as the name suggests, are those that have their data synchronously replicated to multiple nodes. Volumes can sustain node failures. The replication also can be setup across availability zones helping applications move across availability zones. OpenEBS offers Replicated PV Mayastor as an replicated storage solution, which provides high availability and high performance.

## Documentation and user guides

OpenEBS can run on any Kubernetes 1.23+ cluster in a matter of minutes. See the [Quickstart Guide to OpenEBS](https://openebs.io/docs/quickstart-guide/installation) for detailed instructions.

## Getting started

### How to customize OpenEBS Helm chart?

OpenEBS Helm chart is a unified Helm chart that pulls together engine specific charts. The engine charts are included as [dependencies](https://github.com/openebs/openebs/tree/HEAD/charts/Chart.yaml).

```bash
openebs
├── (default) Local PV HostPath
├── (default) Local PV LVM
├── (default) Local PV ZFS
└── (default) Replicated PV Mayastor
```

### Prerequisites

- [Local PV Hostpath Prerequisites](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-hostpath/hostpath-installation#prerequisites)
- [Local PV LVM Prerequisites](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-lvm/lvm-installation#prerequisites)
- [Local PV ZFS Prerequisites](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-zfs/zfs-installation#prerequisites)
- [Replicated PV Mayastor Prerequisites](https://openebs.io/docs/user-guides/replicated-storage-user-guide/replicated-pv-mayastor/rs-installation#prerequisites)

### Setup Helm Repository

Before installing OpenEBS Helm chart, the [OpenEBS Helm repository](https://openebs.github.io/openebs) needs to be added to the Helm client.

#### Setup Helm repository

```bash
helm repo add openebs https://openebs.github.io/openebs
helm repo update
```

#### Install OpenEBS Helm chart with default values.

```bash
helm install openebs --namespace openebs openebs/openebs --create-namespace
```

The above commands will install OpenEBS LocalPV Hostpath, OpenEBS LocalPV LVM, OpenEBS LocalPV ZFS and OpenEBS Mayastor components in openebs namespace with chart name as openebs. 

Replicated PV Mayastor can be excluded during the installation with the following command:

```bash
helm install openebs --namespace openebs openebs/openebs --set engines.replicated.mayastor.enabled=false --create-namespace
```

To view the chart and get the following output.

```bash
helm ls -n openebs 

NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
openebs openebs         1               2024-07-07 09:13:00.903321318 +0000 UTC deployed        openebs-4.1.0   4.1.0
```

As a next step [verify the installation](https://openebs.io/docs/quickstart-guide/installation#verifying-openebs-installation) and do the [post installation](https://openebs.io/docs/quickstart-guide/installation#post-installation-considerations) steps.

For more details on customizing and installing OpenEBS please see the [chart values](https://github.com/openebs/openebs/tree/HEAD/charts/README.md).

### To uninstall/delete instance with release name

```bash
helm ls --all
helm delete `<RELEASE NAME>` -n `<RELEASE NAMESPACE>`
```

> **Tip**: Prior to deleting the Helm chart, make sure all the storage volumes and pools are deleted.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
|  | openebs-crds | 4.1.0 |
| https://openebs.github.io/dynamic-localpv-provisioner | localpv-provisioner | 4.1.0 |
| https://openebs.github.io/lvm-localpv | lvm-localpv | 1.6.0 |
| https://openebs.github.io/mayastor-extensions | mayastor | 2.7.0 |
| https://openebs.github.io/zfs-localpv | zfs-localpv | 2.6.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| engines.local.lvm.enabled | bool | `true` |  |
| engines.local.zfs.enabled | bool | `true` |  |
| engines.replicated.mayastor.enabled | bool | `true` |  |
| localpv-provisioner.rbac.create | bool | `true` |  |
| lvm-localpv.crds.csi.volumeSnapshots.enabled | bool | `false` |  |
| lvm-localpv.crds.lvmLocalPv.enabled | bool | `true` |  |
| mayastor.crds.csi.volumeSnapshots.enabled | bool | `false` |  |
| mayastor.csi.node.initContainers.enabled | bool | `true` |  |
| mayastor.etcd.clusterDomain | string | `"cluster.local"` | Kubernetes Cluster Domain |
| mayastor.localpv-provisioner.enabled | bool | `false` |  |
| openebs-crds.csi.volumeSnapshots.enabled | bool | `true` |  |
| openebs-crds.csi.volumeSnapshots.keep | bool | `true` |  |
| preUpgradeHook | object | `{"image":{"pullPolicy":"IfNotPresent","registry":"docker.io","repo":"bitnami/kubectl","tag":"1.25.15"}}` | Configuration options for pre-upgrade helm hook job. |
| preUpgradeHook.image.pullPolicy | string | `"IfNotPresent"` | The imagePullPolicy for the container |
| preUpgradeHook.image.registry | string | `"docker.io"` | The container image registry URL for the hook job |
| preUpgradeHook.image.repo | string | `"bitnami/kubectl"` | The container repository for the hook job |
| preUpgradeHook.image.tag | string | `"1.25.15"` | The container image tag for the hook job |
| release.version | string | `"4.1.0"` |  |
| zfs-localpv.crds.csi.volumeSnapshots.enabled | bool | `false` |  |
| zfs-localpv.crds.zfsLocalPv.enabled | bool | `true` |  |
