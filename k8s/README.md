# Using OpenEBS with K8s

This folder contains the software components (plugins, scripts, drivers etc.,), usage instructions and application examples of using OpenEBS with K8s. 

If this is your first time to Kubernetes, please go through these introductory tutorials: 
- https://www.udacity.com/course/scalable-microservices-with-kubernetes--ud615
- https://kubernetes.io/docs/tutorials/kubernetes-basics/


## Usage

### Enable OpenEBS on K8s
```
kubectl apply -f openebs-operator.yaml
```

### Customize OpenEBS
```
kubectl apply -f openebs-config.yaml
kubectl apply -f openebs-storageclasses.yaml
```

### (Optional) Enable monitoring using prometheus and grafana

Use this step if you don't already have monitoring services installed
on your k8s cluster. 

```
kubectl apply -f openebs-monitoring-pg.yaml
```

This folder also contains a sample openebs volume monitoring dashboard (openebs-pg-dashboard.json) that can be imported into your grafana. 
