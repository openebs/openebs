# OpenEBS Helm Repository

<img width="200" align="right" alt="OpenEBS Logo" src="https://raw.githubusercontent.com/cncf/artwork/master/projects/openebs/stacked/color/openebs-stacked-color.png" xmlns="http://www.w3.org/1999/html">

[OpenEBS](https://openebs.io) helps Developers and Platform SREs easily deploy Kubernetes Stateful Workloads that require fast and highly reliable container attached storage. OpenEBS can be deployed on any Kubernetes cluster - either in cloud, on-premise (virtual or bare metal) or developer laptop (minikube).

OpenEBS Data Engines and Control Plane are implemented as micro-services, deployed as containers and orchestrated by Kubernetes itself. An added advantage of being a completely Kubernetes native solution is that administrators and developers can interact and manage OpenEBS using all the wonderful tooling that is available for Kubernetes like kubectl, Helm, Prometheus, Grafana, etc.

OpenEBS turns any storage available on the Kubernetes worker nodes into local or distributed Kubernetes Persistent Volumes.
* Local Volumes are accessible only from a single node in the cluster. Pods using Local Volume have to be scheduled on the node where volume is provisioned. Local Volumes are typically preferred for distributed workloads like Cassandra, MongoDB, Elastic, etc that are distributed in nature and have high availability built into them. Depending on the type of storage attached to your Kubernetes worker openebs offers different flavors of Local PV - Hostpath, LVM and  ZFS.
* Replicated Volumes as the name suggests, are those that have their data synchronously replicated to multiple nodes. Volumes can sustain node failures. The replication also can be setup across availability zones helping applications move across availability zones. OpenEBS offers MayaStor as an replicated storage solution, which provides high availability and high performance.

## Documentation and user guides

You can run OpenEBS on any Kubernetes 1.23+ cluster in a matter of minutes. See the [Quickstart Guide to OpenEBS](https://openebs.io/docs/quickstart-guide/installation) for detailed instructions.

## Getting started

### How to customize OpenEBS Helm chart?

OpenEBS helm chart is an umbrella chart that pulls together engine specific charts. The engine charts are included as dependencies. 
arts/openebs/Chart.yaml). 

```bash
openebs
├── (default) LocalPV HostPath
├── (default) LocalPV LVM
├── (default) LocalPV LVM
└── (default) MayaStor (replicated)
```

### Prerequisites

- [LocalPV Hostpath Prerequisites](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-hostpath/hostpath-installation#prerequisites)
- [LocalPV LVM Prerequisites](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-lvm/lvm-installation#prerequisites)
- [LocalPV ZFS Prerequisites](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-zfs/zfs-installation#prerequisites)
- [Replicated Engine Prerequisites](https://openebs.io/docs/user-guides/replicated-storage-user-guide/rs-installation#prerequisites)

### Setup Helm Repository

Before installing OpenEBS Helm charts, you need to add the [OpenEBS Helm repository](https://openebs.github.io/openebs) to your Helm client.

#### Setup helm repository

```bash
helm repo add openebs https://openebs.github.io/openebs
helm repo update
```

#### Install OpenEBS helm chart with default values.

```bash
helm install openebs --namespace openebs openebs/openebs --create-namespace
```

The above commands will install OpenEBS LocalPV Hostpath, OpenEBS LocalPV LVM, OpenEBS LocalPV ZFS and OpenEBS Mayastor components in openebs namespace and chart name as openebs. 

If you want to not install OpenEBS Mayastor which is a replicated storage engine you can use the following command.

```bash
helm install openebs --namespace openebs openebs/openebs --set mayastor.enabled=false --create-namespace
```

To view the chart and get the following output.

```bash
helm ls -n openebs 

NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
openebs openebs         1               2024-03-25 09:13:00.903321318 +0000 UTC deployed        openebs-4.0.0   4.0.0
```

As a next step [verify your installation](https://openebs.io/docs/quickstart-guide/installation#verifying-openebs-installation) and do the [post installation](https://openebs.io/docs/quickstart-guide/installation#post-installation-considerations) steps.

For more details on customizing and installing OpenEBS please see the [chart values](https://github.com/openebs/openebs/tree/HEAD/charts/README.md).

### To uninstall/delete instance with release name

```bash
helm ls --all
helm delete `<RELEASE NAME>` -n `<RELEASE NAMESPACE>`
```

> **Tip**: Prior to deleting the helm chart, make sure all the storage volumes and pools are deleted.
