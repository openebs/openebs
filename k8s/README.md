# Using OpenEBS with K8s

**_The artifiacts in this repository contain unreleased changes._**

If you are looking at deploying from a stable release, please follow the instructions at [Quick Start Guide](https://docs.openebs.io/docs/next/quickstartguide.html)

If this is your first time to Kubernetes, please go through these introductory tutorials: 
- https://www.udacity.com/course/scalable-microservices-with-kubernetes--ud615
- https://kubernetes.io/docs/tutorials/kubernetes-basics/

## Usage

### Installing Pre-released OpenEBS **_(at your own risk)_**
```
kubectl apply -f openebs-operator.yaml
```

The following YAML contains configuration that is required by the pre-release-features, that are currently under development. As we progress towards the release, the content in this will be either moved to openebs-operator.yaml or installed/configured via the code.
```
kubectl apply -f openebs-pre-release-features.yaml
```


### (Optional) Configuring CStor Pools and Storage Class
With 0.7, node-disk-manager is installed that discovers and create Disk CRs for each non OS disk attached to the nodes. Get the list of disks using `kubectl get disks --show-labels` and update the Disk CR Names in the `openebs-config.yaml`. It is recommended to specify one Disk CR per storage node.

```
kubectl apply -f openebs-config.yaml
```

### (Optional) Enable monitoring using prometheus and grafana

Use this step if you don't already have monitoring services installed
on your k8s cluster. 

```
kubectl apply -f openebs-monitoring-pg.yaml
```

This folder also contains a sample openebs volume monitoring dashboard (openebs-pg-dashboard.json) that can be imported into your grafana. 
