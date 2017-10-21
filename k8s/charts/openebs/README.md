
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
