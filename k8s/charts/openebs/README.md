
------------------------------------------------------------------------------
IMPORTANT!!

DEPRECATION NOTICE:

The support for this chart will be discontinued soon. Please plan to migrate
and use stable/openebs chart located at:
 [https://github.com/helm/charts/tree/master/stable/openebs](https://github.com/helm/charts/tree/master/stable/openebs)

------------------------------------------------------------------------------

## Prerequisites

- Kubernetes 1.9.7+ with RBAC enabled
- iSCSI PV support in the underlying infrastructure
- Helm is installed and the Tiller has admin privileges. To assign admin
  to tiller, login as admin and use the following instructions:

  ```shell
  kubectl -n kube-system create sa tiller
  kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
  kubectl -n kube-system patch deploy/tiller-deploy -p '{"spec": {"template": {"spec": {"serviceAccountName": "tiller"}}}}'
  kubectl -n kube-system patch deployment tiller-deploy -p '{"spec": {"template": {"spec": {"automountServiceAccountToken": true}}}}'
  ```

- A namespace called "openebs" is created in the Cluster for running the
  below instructions: `kubectl create namespace openebs`

## Installing OpenEBS Charts Repository

```shell
helm repo add openebs-charts https://openebs.github.io/charts/
helm repo update
helm install openebs-charts/openebs --name openebs --namespace openebs
```

## Installing OpenEBS from this codebase

```shell
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/charts/openebs/
helm install --name openebs --namespace openebs .
```

## Verify that OpenEBS Volumes can be created

```shell
#Check the OpenEBS Management Pods are running.
kubectl get pods -n openebs
#Create a test PVC
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/pvc.yaml
#Check the OpenEBS Volume Pods are created.
kubectl get pods
#Delete the test volume and associated Volume Pods.
kubectl delete -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/pvc.yaml

```

## Unistalling OpenEBS from Chart codebase

```shell
helm ls --all
# Note the openebs-chart-name from above command
helm del --purge <openebs-chart-name>
```

## Configuration

The following table lists the configurable parameters of the OpenEBS chart and their default values.

| Parameter                               | Description                                   | Default                                   |
| ----------------------------------------| --------------------------------------------- | ----------------------------------------- |
| `rbac.create`                           | Enable RBAC Resources                         | `true`                                    |
| `image.pullPolicy`                      | Container pull policy                         | `IfNotPresent`                            |
| `apiserver.enabled`                     | Enable API Server                             | `true`                                    |
| `apiserver.image`                       | Image for API Server                          | `quay.io/openebs/m-apiserver`             |
| `apiserver.imageTag`                    | Image Tag for API Server                      | `1.4.0`                                   |
| `apiserver.replicas`                    | Number of API Server Replicas                 | `1`                                       |
| `apiserver.sparse.enabled`              | Create Sparse Pool based on Sparsefile        | `false`                                   |
| `provisioner.enabled`                   | Enable Provisioner                            | `true`                                    |
| `provisioner.image`                     | Image for Provisioner                         | `quay.io/openebs/openebs-k8s-provisioner` |
| `provisioner.imageTag`                  | Image Tag for Provisioner                     | `1.4.0`                                   |
| `provisioner.replicas`                  | Number of Provisioner Replicas                | `1`                                       |
| `localprovisioner.enabled`              | Enable localProvisioner                       | `true`                                    |
| `localprovisioner.image`                | Image for localProvisioner                    | `quay.io/openebs/provisioner-localpv`     |
| `localprovisioner.imageTag`             | Image Tag for localProvisioner                | `1.4.0`                                   |
| `localprovisioner.replicas`             | Number of localProvisioner Replicas           | `1`                                       |
| `localprovisioner.basePath`             | BasePath for hostPath volumes on Nodes        | `/var/openebs/local`                      |
| `webhook.enabled`                       | Enable admission server                       | `true`                                    |
| `webhook.image`                         | Image for admission server                    | `quay.io/openebs/admission-server`        |
| `webhook.imageTag`                      | Image Tag for admission server                | `1.4.0`                                   |
| `webhook.replicas`                      | Number of admission server Replicas           | `1`                                       |
| `snapshotOperator.enabled`              | Enable Snapshot Provisioner                   | `true`                                    |
| `snapshotOperator.provisioner.image`    | Image for Snapshot Provisioner                | `quay.io/openebs/snapshot-provisioner`    |
| `snapshotOperator.provisioner.imageTag` | Image Tag for Snapshot Provisioner            | `1.4.0`                                   |
| `snapshotOperator.controller.image`     | Image for Snapshot Controller                 | `quay.io/openebs/snapshot-controller`     |
| `snapshotOperator.controller.imageTag`  | Image Tag for Snapshot Controller             | `1.4.0`                                   |
| `snapshotOperator.replicas`             | Number of Snapshot Operator Replicas          | `1`                                       |
| `ndm.enabled`                           | Enable Node Disk Manager                      | `true`                                    |
| `ndm.image`                             | Image for Node Disk Manager                   | `quay.io/openebs/node-disk-manager-amd64` |
| `ndm.imageTag`                          | Image Tag for Node Disk Manager               | `v0.4.4`                                  |
| `ndm.sparse.path`                       | Directory where Sparse files are created      | `/var/openebs/sparse`                     |
| `ndm.sparse.size`                       | Size of the sparse file in bytes              | `10737418240`                             |
| `ndm.sparse.count`                      | Number of sparse files to be created          | `0`                                       |
| `ndm.filters.excludeVendors`            | Exclude devices with specified vendor         | `CLOUDBYT,OpenEBS`                        |
| `ndm.filters.excludePaths`              | Exclude devices with specified path patterns  | `loop,fd0,sr0,/dev/ram,/dev/dm-,/dev/md`  |
| `ndm.filters.includePaths`              | Include devices with specified path patterns  | `""`                                      |
| `ndm.filters.excludePaths`              | Exclude devices with specified path patterns  | `loop,fd0,sr0,/dev/ram,/dev/dm-,/dev/md`  |
| `ndm.probes.enableSeachest`             | Enable Seachest probe for NDM                 | `false`                                   |
| `ndmOperator.enabled`                   | Enable NDM Operator                           | `true`                                    |
| `ndmOperator.image`                     | Image for NDM Operator                        | `quay.io/openebs/node-disk-operator-amd64`|
| `ndmOperator.imageTag`                  | Image Tag for NDM Operator                    | `v0.4.4`                                  |
| `jiva.image`                            | Image for Jiva                                | `quay.io/openebs/jiva`                    |
| `jiva.imageTag`                         | Image Tag for Jiva                            | `1.4.0`                                   |
| `jiva.replicas`                         | Number of Jiva Replicas                       | `3`                                       |
| `jiva.defaultStoragePath`               | hostpath used by default Jiva StorageClass    | `/var/openebs`                            |
| `cstor.pool.image`                      | Image for cStor Pool                          | `quay.io/openebs/cstor-pool`              |
| `cstor.pool.imageTag`                   | Image Tag for cStor Pool                      | `1.4.0`                                   |
| `cstor.poolMgmt.image`                  | Image for cStor Pool  Management              | `quay.io/openebs/cstor-pool-mgmt`         |
| `cstor.poolMgmt.imageTag`               | Image Tag for cStor Pool Management           | `1.4.0`                                   |
| `cstor.target.image`                    | Image for cStor Target                        | `quay.io/openebs/cstor-istgt`             |
| `cstor.target.imageTag`                 | Image Tag for cStor Target                    | `1.4.0`                                   |
| `cstor.volumeMgmt.image`                | Image for cStor Volume  Management            | `quay.io/openebs/cstor-volume-mgmt`       |
| `cstor.volumeMgmt.imageTag`             | Image Tag for cStor Volume Management         | `1.4.0`                                   |
| `policies.monitoring.image`             | Image for Prometheus Exporter                 | `quay.io/openebs/m-exporter`              |
| `policies.monitoring.imageTag`          | Image Tag for Prometheus Exporter             | `1.4.0`                                   |
| `analytics.enabled`                     | Enable sending stats to Google Analytics      | `true`                                    |
| `analytics.pingInterval`                | Duration(hours) between sending ping stat     | `24h`                                     |
| `defaultStorageConfig.enabled`          | Enable default storage class installation     | `true`                                   |
| `HealthCheck.initialDelaySeconds`       | Delay before liveness probe is initiated      | `30`                                      |                              | 30                                                          |
| `HealthCheck.periodSeconds`             | How often to perform the liveness probe       | `60`                                      |                            | 10                                                          |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install --name openebs -f values.yaml openebs-charts/openebs
```

> **Tip**: You can use the default [values.yaml](values.yaml)
