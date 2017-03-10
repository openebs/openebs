# Running MySQL on Kubernetes Cluster with OpenEBS Storage

In this example, we will run a MySQL database over an OpenEBS Storage. 

### Prerequisites

Verify that your Kubernetes and OpenEBS Cluster machines are up and running.

```
ubuntu-host:~/$ vagrant status
Current machine states:

kubemaster-01             running (virtualbox)
kubeminion-01             running (virtualbox)
omm-01                    running (virtualbox)
osh-01                    running (virtualbox)
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
omm-01.global  172.28.128.5  4648  alive   true    2         0.5.0  dc1         global
ubuntu@omm-01:~$ maya osh-status
ID        DC   Name    Class   Drain  Status
7c2943b2  dc1  osh-01  <none>  false  ready
ubuntu@omm-01:~$ 
```


### Create the volume on OpenEBS 

Similar to K8s pod, OpenEBS storage also can be specified via the spec file. A default spec file is located on the OpenEBS Maya Master under demo/maya/spec. 

```
ubuntu-host:~/$ vagrant ssh omm-01
ubuntu@omm-01:~$ cd demo/maya/spec/
ubuntu@omm-01:~/demo/maya/spec$ maya vsm-create demo-vsm.hcl 
==> Monitoring evaluation "075e3e0b"
    Evaluation triggered by job "demo-vsm1"
    Allocation "c6e12b6c" created: node "7c2943b2", group "demo-vsm1-backend-container1"
    Allocation "db8a17b4" created: node "7c2943b2", group "demo-vsm1-fe"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "075e3e0b" finished with status "complete"
ubuntu@omm-01:~/demo/maya/spec$ 
```
Check that the Frontend and the Backend Containers are running. Give this a few minutes when launching for the first time, to allow the docker image to be downloaded.

```
ubuntu-host:~/$ vagrant ssh osh-01
ubuntu@osh-01:~$ sudo docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS              PORTS               NAMES
b3197282c1c1        openebs/jiva:latest   "launch replica --..."   53 seconds ago      Up 53 seconds                           demo-vsm1-be-store1
19c2be95741b        openebs/jiva:latest   "launch controller..."   53 seconds ago      Up 53 seconds                           demo-vsm1-fe
ubuntu@osh-01:~$ 
```

### Configure the MySQL K8s Pod to use the OpenEBS Volume (via iSCSI)

```
ubuntu-host:~/$ vagrant ssh kubemaster-01
ubuntu@kubemaster-01:~$ cd demo/k8s/spec/
ubuntu@kubemaster-01:~/demo/k8s/spec$ cat demo-mysql-iscsi.yaml 
---
apiVersion: v1
kind: Pod
metadata:
  name: mysql
  labels:
    name: mysql
spec:
  containers:
  - resources:
      limits:
        cpu: 0.5
    name: mysql
    image: mysql
    env:
      - name: MYSQL_ROOT_PASSWORD
        value: k8sDem0
    ports:
      - containerPort: 3306
        name: mysql
    volumeMounts:
    - mountPath: /var/lib/mysql
      name: demo-vsm1-vol1
  volumes:
  - name: demo-vsm1-vol1
    iscsi:
      targetPortal: 172.28.128.101:3260      
      iqn: iqn.2016-09.com.openebs.jiva:demo-vsm1-vol1
      lun: 1
      fsType: ext4
      readOnly: false
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

Start the MySQL pod
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl create -f demo-mysql-iscsi.yaml 
pod "mysql" created
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl get pods
NAME      READY     STATUS              RESTARTS   AGE
mysql     0/1       ContainerCreating   0          54s
ubuntu@kubemaster-01:~/demo/k8s/spec$ 

ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl describe pod mysql

```

Check the Volume Configuration status:

```
Volumes:
  demo-vsm1-vol1:
    Type:		ISCSI (an ISCSI Disk resource that is attached to a kubelet's host machine and then exposed to the pod)
    TargetPortal:	172.28.128.101:3260
    IQN:		iqn.2016-09.com.openebs.jiva:demo-vsm1-vol1
    Lun:		1
    ISCSIInterface	default
    FSType:		ext4
    ReadOnly:		false
```

Once the volume is mounted and database is initialized, the pod status turns to running. 

```
ubuntu@kubemaster-01:~$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
mysql     1/1       Running   4          11m
ubuntu@kubemaster-01:~$ 
```

## Known Issues
If the MySQL keeps restarting check the following on the minion nodes
- service iscsid status
  (Should show the status as connected)
- sudo docker logs *mysql container id*
  (To get mysql container id, you may need to issue - sudo docker ps -a )
- If the error says, directory not empty, clear it. *mount | grep jiva*

