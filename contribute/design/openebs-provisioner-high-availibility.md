# High Availability for OpenEBS Volume Provisioner
---
## Problems addressed:

- `openebs-provisioner` runs within the Kubernetes Cluster and should always be available. If any node, currently running a openebs-provisioner goes down, the pod should be assigned to another available node in the cluster.
- One node should be running only single `openebs-provsioner` to avoid single-point-of-failure of a node. 

---
## Solutions for above problems: 

### Replica Count

- For making `openebs-provisioner` highly available, set the `replicas` to at least 2 in `openebs-operator.yaml` for `openebs-provisioner` deployment.

### Pod Anti Affinity
Pod anti-affinity can prevent the scheduler from placing a new `openebs-provsioner` pod on the node that is already running one instance of `openebs-provisioner`. 


You can change affinity selector in the Deployment spec.


| AFFINITY SELECTOR | 	REQUIREMENTS MET  |  REQUIREMENTS NOT MET | REQUIREMENTS LOST | 
|---|---|--- | --- |
|`requiredDuringSchedulingIgnoredDuringExecution`  | Runs | Fails | Keeps Running |
|`preferredDuringSchedulingIgnoredDuringExecution` |	Runs |	Runs |	Keeps Running|
|`requiredDuringSchedulingRequiredDuringExecution` (Not recommended) |	Runs |	Fails | Fails|




## Sample Deployment spec for `openebs-provisioner`

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: openebs-provisioner
  namespace: default
spec:
  replicas: 2
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:   # <-- Affinity Selector 
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: name
                      operator: In
                      values:
                      - openebs-provisioner
                topologyKey: "kubernetes.io/hostname"
  template:
    metadata:
      labels:
        name: openebs-provisioner  # <-- Default label
    spec:
      serviceAccountName: openebs-maya-operator
      containers:
      - name: openebs-provisioner
        imagePullPolicy: Always
        image: openebs/openebs-k8s-provisioner:0.4.0
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName

```

