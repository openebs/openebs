# High Availability for OpenEBS Volume Provisioner

## Problems addressed:

- `openebs-provisioner` should always be available.
- `openebs-provisioner` should always be running on the specified/labeled nodes. 
- If any node in cluster goes down in that scenario the pod should be assigned to other node in the cluster.
 
## Solutions for above problems: 


- Increase the `replicas` to 2 or >2 in `openebs-operator.yaml` for `openebs-provisioner`. 


- We need to make sure that each node is running at least one  `openebs-provisioner` pod.  
  We need to label nodes to assign the pods on those. 

  To do that execute: 

```
kubectl label nodes kubeminion-01  node=minion01  # For node kubeminion-01
kubectl label nodes kubeminion-02  node=minion02   # For node kubeminion-02
```

To make sure that nodes are labeled: 

```
ubuntu@kubemaster-01:~/openebs/k8s$ kubectl get nodes --show-labels

NAME            STATUS    AGE       VERSION   LABELS
kubemaster-01   Ready     4h        v1.6.3    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=kubemaster-01,node-role.kubernetes.io/master=
kubeminion-01   Ready     4h        v1.6.3    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=kubeminion-01,node=minion01
kubeminion-02   Ready     4h        v1.6.3    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=kubeminion-02,node=minion02


```


Once, we labeled the nodes we can specify these labels in the `affinity` of `openebs-provisioner` spec in `openebs-operator.yaml`

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: openebs-provisioner
  namespace: default
spec:
  replicas: 2
  template:
    metadata:
      labels:
        name: openebs-provisioner
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              matchExpressions:
                key: node			  # <-- Key of label of the node. 	
                operator: Equal
                values: ["minion01","minion02"]   # <-- Add the labels of the nodes as a value.
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

After this, kubernetes scheduler will take care of assigning pods to the specific nodes and it will make sure that pods are always available on specified nodes. 


