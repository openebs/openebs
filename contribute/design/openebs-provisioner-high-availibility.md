# High Availability for OpenEBS Volume Provisioner
---
## Problems addressed:

- `openebs-provisioner` should always be available.
- 2 `openebs-provisioner` pods should always be running in the cluster. 
- If any node in cluster goes down in that scenario the pod should be assigned to other node in the cluster.
---
## Solutions for above problems: 


- Increase the `replicas` count to 2 or >2 in `openebs-operator.yaml` for `openebs-provisioner` deployment.


Sample Deployment spec for `openebs-provisioner` looks like: 

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

## Pod Anti Affinity
Pod anti-affinity can prevent the scheduler from locating a new pod on the same node as pods with the same labels if the label selector on the new pod matches the label on the current pod. 


You can change affinity selector in the Deployment spec.


| AFFINITY SELECTOR | 	REQUIREMENTS MET  |  REQUIREMENTS NOT MET | REQUIREMENTS LOST | 
|---|---|--- | --- |
|`requiredDuringSchedulingIgnoredDuringExecution`  | Runs | Fails | Keeps Running |
|`preferredDuringSchedulingIgnoredDuringExecution` |	Runs |	Runs |	Keeps Running|
|`requiredDuringSchedulingRequiredDuringExecution` (Not recommanded) |	Runs |	Fails | Fails|


---

### How `openebs-provisioner` will be Highly Available?
 
	- Kubernetes scheduler will make sure that each node has atleast one pod of `openebs-provisioner` labeled with `name:openebs-provisioner`.

