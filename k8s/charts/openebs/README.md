
## Prerequisites
- Kubernetes 1.7.5+ with RBAC enabled
- iSCSI PV support in the underlying infrastructure

## Installing OpenEBS 
```
helm repo add openebs-charts https://openebs.github.io/charts/
helm repo update
helm install openebs-charts/openebs
```

## Installing OpenEBS from Chart codebase
```
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/charts/openebs/
helm install --name openebs .
```

## Unistalling OpenEBS from Chart codebase
```
helm ls --all
# Note the openebs-chart-name from above command
helm del --purge <openebs-chart-name>
```

## Configuration

The following tables lists the configurable parameters of the OpenEBS chart and their default values.

| Parameter                            | Description                                   | Default                           |
| ------------------------------------ | --------------------------------------------- | --------------------------------- |
| `rbacEnable`                         | Enable RBAC Resources                         | `true`                            |
| `image.pullPolicy`                   | Container pull policy                         | `IfNotPresent`                    |
| `apiserver.image`                    | Docker Image for API Server                   | `openebs/m-apiserver`             |
| `apiserver.imageTag`                 | Docker Image Tag for API Server               | `0.5.2`                           |
| `apiserver.replicas`                 | Number of API Server Replicas                 | `2`                               |
| `apiserver.antiAffinity.enabled`     | Enable anti-affinity for API Server Replicas  | `true`                           |
| `apiserver.antiAffinity.type`        | Anti-affinity type for API Server             | `Hard`                           |
| `provisioner.image`                  | Docker Image for Provisioner                  | `openebs/openebs-k8s-provisioner` |
| `provisioner.imageTag`               | Docker Image Tag for Provisioner              | `0.5.2`                           |
| `provisioner.replicas`               | Number of Provisioner Replicas                | `2`                               |
| `provisioner.antiAffinity.enabled`   | Enable anti-affinity for API Server Replicas  | `true`                           |
| `provisioner.antiAffinity.type`      | Anti-affinity type for Provisioner            | `Hard`                           |
| `jiva.image`                         | Docker Image for Jiva                         | `openebs/jiva`                    |
| `jiva.imageTag`                      | Docker Image Tag for Jiva                     | `0.5.2`                           |
| `jiva.replicas`                      | Number of Jiva Replicas                       | `2`                               |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install --name openebs -f values.yaml openebs-charts/openebs
```

> **Tip**: You can use the default [values.yaml](values.yaml)
