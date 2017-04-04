# Running vdbench tests on Kubernetes Cluster with OpenEBS Storage

In this example, we will have run vdbench pod with OpenEBS Storage. 

### Prerequisites

Verify that your Kubernetes and OpenEBS Cluster machines are up and running.

```
ubuntu-host:~/$ vagrant status
Current machine states:

kubemaster-01             running (virtualbox)
kubeminion-01             running (virtualbox)
omm-01                    running (virtualbox)
osh-01                    running (virtualbox)
osh-02                    running (virtualbox)
```

Verify the status of the Kubernetes Nodes
```
ubuntu-host:~/$ vagrant ssh kubemaster-01
ubuntu@kubemaster-01:~$ kubectl get nodes
NAME            STATUS         AGE
kubemaster-01   Ready,master   56m
kubeminion-01   Ready          51m
ubuntu@kubemaster-01:~$ 

ubuntu@kubemaster-01:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE
kube-system   dummy-2088944543-9m94d                  1/1       Running   0          56m
kube-system   etcd-kubemaster-01                      1/1       Running   0          55m
kube-system   kube-apiserver-kubemaster-01            1/1       Running   0          56m
kube-system   kube-controller-manager-kubemaster-01   1/1       Running   0          55m
kube-system   kube-discovery-1769846148-sstmc         1/1       Running   0          56m
kube-system   kube-dns-2924299975-s779z               4/4       Running   0          56m
kube-system   kube-proxy-40xr6                        1/1       Running   0          52m
kube-system   kube-proxy-k7x46                        1/1       Running   0          55m
kube-system   kube-scheduler-kubemaster-01            1/1       Running   0          56m
kube-system   weave-net-2qw1g                         2/2       Running   0          55m
kube-system   weave-net-c577k                         2/2       Running   0          52m
ubuntu@kubemaster-01:~$ 

```

Verify the status of the OpenEBS Nodes
```
ubuntu-host:~/$ vagrant ssh omm-01
...snipped...
ubuntu@omm-01:~$ maya omm-status
Name           Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
omm-01.global  172.28.128.4  4648  alive   true    2         0.5.5  dc1         global

m-apiserver listening at http://172.28.128.4:5656
ubuntu@omm-01:~$ maya osh-status
ID        DC   Name    Class   Drain  Status
e57020e9  dc1  osh-02  <none>  false  ready
b6789013  dc1  osh-01  <none>  false  ready
ubuntu@omm-01:~$ 
```
*Note the m-apiserver listening URL. You will need to provide this in the vdbench pod yaml spec*

### Configure the K8s VDbench Pod to use the OpenEBS Volume

```
ubuntu-host:~/$ vagrant ssh kubemaster-01
ubuntu@kubemaster-01:~$ cd demo/k8s/spec/
ubuntu@kubemaster-01:~/demo/k8s/spec$ cat demo-vdbench-openebs-plugin.yaml 
---
apiVersion: v1
kind: Pod
metadata:
  name: tests-vdbench
  labels:
    name: tests-vdbench
spec:
  containers:
  - resources:
      limits:
        cpu: 0.5
    name: tests-vdbench
    image: openebs/tests-vdbench
    volumeMounts:
    - mountPath: /datadir1
      name: demo-vsm1-vol1
  volumes:
  - name: demo-vsm1-vol1
    flexVolume:
      driver: "openebs/openebs-iscsi"
      options:
        name: "demo-vsm1-vol1"
        openebsApiUrl: "http://172.28.128.4:5656/latest"
        size: "5G"
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```
The yaml ships with an default address for the openebsApiUrl. Modify this with the correct address, noted in the previous step. 


Start the VDBench pod
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl create -f demo-vdbench-openebs-plugin.yaml
pod "tests-vdbench" created
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl get pods
NAME           READY     STATUS              RESTARTS   AGE
tests-vdbench   0/1       ContainerCreating   0          24s
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

Once the volume is mounted and database is initialized, the pod status turns to running. When the first volume is launched, the openebs volume images are downloaded and there may be a bit of delay due to slow network. 

```
ubuntu@kubemaster-01:~$ kubectl get pods
NAME           READY     STATUS    RESTARTS   AGE
tests-vdbench   1/1       Running   0          9m
ubuntu@kubemaster-01:~$ 
```

You can check on the output by runnin the following command:
```
ubuntu@kubemaster-01:~$ kubectl logs -f tests-vdbench
```

