# High Availability for OpenEBS Volume Provisioner
---
## Problems addressed:

- `openebs-provisioner` should always be available.
- `openebs-provisioner` should always be running on the specified/labeled pods. 
- If any node in cluster goes down in that scenario the pod should be assigned to other node in the cluster.
---
## Solutions for above problems: 


- Increase the `replicas` to 2 or >2 in `openebs-operator.yaml` for `openebs-provisioner` deployment. 


- We need to make sure that each node is running at least one  `openebs-provisioner` pod.  
  We need to label pods so that pods with specific labels will always be running on different nodes. 

  To do that execute: 

```
kubectl label pods openebs-provisioner-1149663462-6vbvm  provisioner=P2
kubectl label pods openebs-provisioner-1149663462-bl89g  provisioner=P1

```

To make sure that nodes are labeled: 

```
kubectl get pods --show-labels
NAME                                   READY     STATUS    RESTARTS   AGE       LABELS
maya-apiserver-1089964587-s0xgn        1/1       Running   0          37m       name=maya-apiserver,pod-template-hash=1089964587
openebs-provisioner-1149663462-6vbvm   1/1       Running   0          23m       name=openebs-provisioner,pod-template-hash=1149663462,provisioner=P2
openebs-provisioner-1149663462-bl89g   1/1       Running   0          37m       name=openebs-provisioner,pod-template-hash=1149663462,provisioner=P1

```

---

Once, we labeled the pods. If we change the `replicas` count to 5 then 5 pods will be running. If we descrease the replica count to 2 then only two pods with label P1 and P2 will be running and other 3 pods will be deleted. 

```yaml

apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: openebs-provisioner
  namespace: default
spec:
  replicas: 2
  template:
    spec:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:   #<-- Affinity selector
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                  - key: provisioner	# <-- Label key for pods
                    operator: In
                    values:
                    - P1		# <-- Label value for pod 1
                    - P2		# <-- Label value for pod 2	
              topologyKey: "kubernetes.io/hostname"
  template:
    metadata:
      labels:
        name: openebs-provisioner
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

You can change affinity selector in the Deployment spec.


|AFFINITY SELECTOR| 	REQUIREMENTS MET  |  REQUIREMENTS NOT MET | REQUIREMENTS LOST | 
|---|---|--- | --- |
|`requiredDuringSchedulingIgnoredDuringExecution`  | Runs | Fails | Keeps Running |
|`preferredDuringSchedulingIgnoredDuringExecution` |	Runs |	Runs |	Keeps Running|
|`requiredDuringSchedulingRequiredDuringExecution` (Not recommanded) |	Runs |	Fails | Fails|

---

### How `openebs-provisioner` will be Highly Available?
 
	- Kubernetes scheduler will make sure that each node has atleast one pod of `openebs-provisioner`
	- On descreasing replicas count from n (>2) to 2 will retain pods having label P1 and P2. P1 and P2 will be isolated and protected to make sure that P1 and P2 are always running. 


