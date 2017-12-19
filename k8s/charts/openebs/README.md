# OpenEBS

**It is based on Helm community chart [openebs](https://github.com/openebs/openebs/tree/master/k8s/charts/openebs)**

[OpenEBS](http://openebs.io/) is a cloud-native storage solution built with the goal of providing containerized storage for containers. Using OpenEBS, a developer can seamlessly get persistent storage for stateful applications on Kubernetes with ease.

## Introduction

This chart bootstraps a [OpenEBS](https://github.com/openebs/openebs) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
- Kubernetes 1.7.5+ with RBAC enabled
- iSCSI PV support in the underlying infrastructure

## Installing the Chart 

The command deploys OpenEBS on the Kubernetes cluster with the release name `openebs` and the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation:

```bash
$ helm install tc/openebs --name openebs --namespace=openebs
```

## Unistalling the Chart
List 
```
helm ls --all
```

Note the `openebs` from above command.
To uninstall/delete the `openebs` deployment:
```bash
$ helm delete openebs
```

## Configuration

The following tables lists the configurable parameters of the OpenEBS chart and their default values.

| Parameter               | Description                        | Default                                                    |
| ----------------------- | ---------------------------------- | ---------------------------------------------------------- |
| `rbacEnable`            | Enable RBAC Resources              | `true`                                                     |
| `image.pullPolicy`      | Container pull policy              | `IfNotPresent`                                             |
| `apiserver.image`       | Docker Image for API Server        | `openebs/m-apiserver`                                      |
| `apiserver.tag`         | Docker Image Tag for API Server    | `0.5.0`                                                    |
| `provisioner.image`     | Docker Image for Provisioner       | `openebs/openebs-k8s-provisioner`                          |
| `provisioner.tag`       | Docker Image Tag for Provisioner   | `0.5.0`                                                    |
| `jiva.image`            | Docker Image for Jiva              | `openebs/jiva:0.5.0`                                       |
| `jiva.tag`              | Number of Jiva Replicas            | `2`                                                        |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install tc/openebs --name openebs -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)
