# Using OpenEBS with K8s

**_The artifacts in this repository contain unreleased changes._**

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

You can also obtain Kubernetes resource metrics via the following step:

```
kubectl apply -f openebs-kube-state-metrics.yaml
```

This folder also contains a set of dashboards that can be imported into your grafana:
- [OpenEBS Persistent Volume Dashboard](https://github.com/openebs/openebs/blob/master/k8s/openebs-pg-dashboard.json)
- [OpenEBS Storage Pool Dashboard](https://github.com/openebs/openebs/blob/master/k8s/openebs-pool-exporter.json)
- [Node Exporter Dashboard](https://github.com/openebs/openebs/blob/master/k8s/openebs-node-exporter.json)
- [Kubernetes cAdvisor Dashboard](https://github.com/openebs/openebs/blob/master/k8s/openebs-kubelet-cAdvisor.json)(metrics segregated by node)
- [Kubernetes App Metrics Dashboard](https://github.com/openebs/openebs/blob/master/k8s/openebs-kube-state-metrics.json)(metrics segregated by namespace)

### (Optional) Enable monitoring using Prometheus Operator

It is assumed that you have prometheus operator already deployed and working fine. If not done already follow instructions to do it [here](https://github.com/helm/charts/tree/master/stable/prometheus-operator#installing-the-chart).

While deploying above chart make sure the values of specified field are as follows:

```yaml
    serviceMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelector: {}
    serviceMonitorNamespaceSelector: {}
```

This makes sure that all the [`ServiceMonitor` objects](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources) from all namespaces we create further will be selected.

Now to monitor openebs related resources create following `ServiceMonitor` object in `openebs` namespace. See [openebs-servicemonitor.yaml](openebs-servicemonitor.yaml) file.

```bash
kubectl -n openebs apply -f openebs-servicemonitor.yaml
```

Find [docs here](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#servicemonitor) to read about other fields in `ServiceMonitor` object.

Now once this config is picked up by prometheus operator it will start scraping the metrics and you can start seeing them in prometheus dashboard. The metrics relevant to openebs are conveniently prefixed with `openebs*` or `latest_openebs*`.

### (Optional) Enable alerting using prometheus alert manager

If you would like to receive alerts for specific Node, Kubernetes & OpenEBS conditions, setup the alert-manager:

```
kubectl apply -f openebs-alertmanager.yaml
```

NOTE: The alert rules are currently placed into the prometheus configmag in openebs-monitoring-pg.yaml.

### (Optional) Setup Log collection using grafana loki

Use the following step (requires setup of helm client & tiller server on the server) to setup grafana loki stack on the cluster. On the grafana console, select `loki` as
the datasource and provide the appropriate URL (typically http://loki:3100)  to visualize logs.

```
helm repo add loki https://grafana.github.io/loki/charts
```
```
helm repo update
```
``` 
helm upgrade --install loki --namespace=openebs loki/loki-stack
```

NOTE: A sample template specification of the components in the loki stack can be found [here](sample-loki-templates.md) obtained as part of `helm --debug --dry-run` command.

