# Using OpenEBS with K8s

This folder contains the artifacts (YAMLS, plugins, scripts, drivers etc.,), usage instructions and application examples of using OpenEBS with K8s. The artifiacts in this repository contain unreleased changes. If you are looking at deploying from a stable release, please follow the instructions at [Quick Start Guide](https://docs.openebs.io/docs/next/quickstartguide.html)

If this is your first time to Kubernetes, please go through these introductory tutorials: 
- https://www.udacity.com/course/scalable-microservices-with-kubernetes--ud615
- https://kubernetes.io/docs/tutorials/kubernetes-basics/

## Usage

### Installing OpenEBS on K8s
```
kubectl apply -f openebs-operator.yaml
```

### Creating Default Storage Pools and Storage Classes
With 0.7, node-disk-manager is installed that discovers and create Disk CRs for each non OS disk attached to the nodes. Get the list of disks using `kubectl get disks --show-labels` and update the Disk CR Names in the `openebs-storagepoolclaims.yaml`. It is recommended to specify one Disk CR per storage node.

```
kubectl apply -f openebs-cas-templates-pre-alpha.yaml
kubectl apply -f openebs-storagepools.yaml
kubectl apply -f openebs-storagepoolclaims.yaml
```

Note: This step will be optional in the near future and needs to be performed only if non-default settings are required. 

### (Optional) Enable monitoring using prometheus and grafana

Use this step if you don't already have monitoring services installed
on your k8s cluster. 

```
kubectl apply -f openebs-monitoring-pg.yaml
```

This folder also contains a sample openebs volume monitoring dashboard (openebs-pg-dashboard.json) that can be imported into your grafana. 
