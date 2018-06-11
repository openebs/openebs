------------------------------------------------------------------------------
IMPORTANT!!

DEPRECATION NOTICE:

The support for this chart will be discontinued soon. Please plan to migrate
and use stable/openebs chart located at:
 [https://github.com/kubernetes/charts/tree/master/stable/openebs](https://github.com/kubernetes/charts/tree/master/stable/openebs)

------------------------------------------------------------------------------

## Prerequisites
- Kubernetes 1.7.5+ with RBAC enabled
- iSCSI PV support in the underlying infrastructure
- helm is installed and the tiller has admin privileges. To assign admin
  to tiller, login as admin and use the following instructions:
  ```
  kubectl -n kube-system create sa tiller
  kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
  kubectl -n kube-system patch deploy/tiller-deploy -p '{"spec": {"template": {"spec": {"serviceAccountName": "tiller"}}}}'
  kubectl -n kube-system patch deployment tiller-deploy -p '{"spec": {"template": {"spec": {"automountServiceAccountToken": true}}}}'
  ``` 
- A namespace called "openebs" is created in the Cluster for running the
  below instructions: `kubectl create namespace openebs`

## Installing OpenEBS Charts Repository 
```
helm repo add openebs-charts https://openebs.github.io/charts/
helm repo update
helm install openebs-charts/openebs --name openebs --namespace openebs
```

## Installing OpenEBS from this codebase
```
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/charts/openebs/
helm install --name openebs --namespace openebs .
```

## Verify that OpenEBS Volumes can be created
```
#Check the OpenEBS Management Pods are running
kubectl get pods -n openebs
#Create a test PVC
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/pvc.yaml
#Check the OpenEBS Volume Pods are created. 
kubectl get pods
#Delete the test volume and associated Volume Pods. 
kubectl delete -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/pvc.yaml

```

## Unistalling OpenEBS from Chart codebase
```
helm ls --all
# Note the openebs-chart-name from above command
helm del --purge <openebs-chart-name>
```

## Configuration

The following tables lists the configurable parameters of the OpenEBS chart and their default values.

| Parameter                              | Description                                   | Default                           |
| ---------------------------------------| --------------------------------------------- | --------------------------------- |
| `rbac.create`                          | Enable RBAC Resources                         | `true`                            |
| `image.pullPolicy`                     | Container pull policy                         | `IfNotPresent`                    |
| `apiserver.image`                      | Docker Image for API Server                   | `openebs/m-apiserver`             |
| `apiserver.imageTag`                   | Docker Image Tag for API Server               | `0.6.0-RC1`                       |
| `apiserver.replicas`                   | Number of API Server Replicas                 | `1`                               |
| `provisioner.image`                    | Docker Image for Provisioner                  | `openebs/openebs-k8s-provisioner` |
| `provisioner.imageTag`                 | Docker Image Tag for Provisioner              | `0.6.0-RC1`                       |
| `provisioner.replicas`                 | Number of Provisioner Replicas                | `1`                               |
| `snapshotOperator.provisioner.image`   | Docker Image for Snapshot Provisioner         | `openebs/snapshot-provisioner`    |
| `snapshotOperator.provisioner.imageTag`| Docker Image Tag for Snapshot Provisioner     | `0.6.0-RC1`                       |
| `snapshotOperator.controller.image`    | Docker Image for Snapshot Controller          | `openebs/snapshot-provisioner`    |
| `snapshotOperator.controller.imageTag` | Docker Image Tag for Snapshot Controller      | `0.6.0-RC1`                       |
| `snapshotOperator.replicas`            | Number of Snapshot Operator Replicas          | `1`                               |
| `jiva.image`                           | Docker Image for Jiva                         | `openebs/jiva`                    |
| `jiva.imageTag`                        | Docker Image Tag for Jiva                     | `0.6.0-RC2`                       |
| `jiva.replicas`                        | Number of Jiva Replicas                       | `3`                               |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install --name openebs -f values.yaml openebs-charts/openebs
```

> **Tip**: You can use the default [values.yaml](values.yaml)
