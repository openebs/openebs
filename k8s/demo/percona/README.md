# Running percona pod on OpenEBS

This tutorial provides detailed instructions on how to run a percona-mysql 
application pod on OpenEBS storage in a kubernetes cluster and uses a mysql-client
container to generate some load (in the form of insert & select DB queries) in 
order to illustrate I/O traffic on the storage. 

## Pre-requisites

Pre-requisites include the following: 

- A fully configured kubernetes cluster (versions 1.6.3/4/6 & 1.7.0 have been 
tested) with kube master and at least one kube minion. This maybe created on 
cloud platforms like GKE, on-premise virtual machines (vagrant/VMware/Hyper-V) 
or bare-metal boxes

  Note: 

  - It is recommended to use a 3-node cluster, with one master and two minions, 
  as this will aid creation of storage replicas on separate  minion nodes. This 
  is especially helpful to maintain redundancy and data availability.

  - If you are using gcp, view the appendix in this 
  [tutorial](https://github.com/openebs/openebs/blob/master/k8s/hyperconverged/tutorial-configure-openebs-gke.md)
  for additional steps for setting cluster admin context and using it 
  
  Verify that the kubernetes cluster is in optimal state: 
  
  ```bash
  karthik@MayaMaster:~$ kubectl get nodes
  NAME         STATUS    AGE       VERSION
  mayahost01   Ready     5d        v1.6.3
  mayahost02   Ready     5d        v1.6.3
  mayamaster   Ready     5d        v1.6.3
  ```
  
- Sufficient resources on the minions to host the openebs storage pods & percona
application pods. This includes sufficient disk space, as, in this example, 
physical storage for the pvolume containers shall be carved out from local storage

- iSCSI support on the minions. This is needed to be able to consume the iSCSI 
target exposed by the openebs volume container (i.e., VSM). In ubuntu, the iSCSI
initiator can be installed using the procedure below : 
  
  ```
  sudo apt-get update
  sudo apt-get install open-iscsi
  sudo service open-iscsi restart
  ```

  Verify that iSCSI is configured: 
  
  ```
  sudo cat /etc/iscsi/initiatorname.iscsi
  sudo service open-iscsi status
  ```

## Step-1: Run OpenEBS Operator

Download the latest OpenEBS operator files and sample percona-mysql application 
pod yaml on the kubemaster from the OpenEBS git repo.

```
git clone https://github.com/openebs/openebs.git
cd openebs/k8s
```

Apply the openebs-operator on the kubernetes cluster. This creates the maya 
api-server and openebs provisioner deployments.

```
kubectl apply -f openebs-operator.yaml
```

Add the OpenEBS storage classes, that can then be used by developers to map a 
suitable storage profile for their apps in their respective persistent volume 
claims.

```
kubectl apply -f openebs-storageclasses.yaml
```

Check whether the deployments are running successfully

```
karthik@MayaMaster:~$ kubectl get deployments
NAME                                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
maya-apiserver                                  1         1         1            1           2m
openebs-provisioner                             1         1         1            1           2m

``` 

```
karthik@MayaMaster:~$ kubectl get pod
NAME                                   READY     STATUS    RESTARTS   AGE
maya-apiserver-1633167387-5ss2w        1/1       Running   0          24s
openebs-provisioner-1174174075-f2ss6   1/1       Running   0          23s
```

Check whether the storage classes are applied successfully

```
karthik@MayaMaster:~$ kubectl get sc
NAME              TYPE
openebs-standard  openebs.io/provisioner-iscsi
openebs-jupyter   openebs.io/provisioner-iscsi
openebs-percona   openebs.io/provisioner-iscsi
```

## Step-2: Run percona-mysql pod with openebs storage

Use OpenEBS as persistent storage for the percona pod by selecting an OpenEBS 
storage class in the persistent volume claim. A sample percona pod yaml (with 
container attributes and pvc details) is available in the openebs git repo (which
was cloned in the previous steps).

Apply the percona pod yaml 

```
cd demo/percona
kubectl apply -f demo-percona-mysql-pvc.yaml
```

Verify that the openebs storage pods, i.e., the jiva controller and jiva replicas
are created and the percona pod is running successfully

```
karthik@MayaMaster:~$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
maya-apiserver-1633167387-5ss2w                                  1/1       Running   0          4m
openebs-provisioner-1174174075-f2ss6                             1/1       Running   0          4m
percona                                                          1/1       Running   0          2m
pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc-ctrl-2825810277-rjmxh   1/1       Running   0          2m
pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc-rep-2644468602-92lfg    1/1       Running   0          2m
pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc-rep-2644468602-rm8mz    1/1       Running   0          2m
```

Note: It may take some time for pods to start as the images need to be pulled and
instantiated. This is also dependent on the network speed.

## Step-3: Run a database client container to generate SQL load 

To test the pod, you can run a kubernetes job, in which a mysql client container
runs a load generation script (which in turn performs simple sql queries) to 
simulate storage traffic. 

Follow the below sequence of steps to achieve this. It can be run on any node 
_in_ the kubernetes cluster. 

Get the IP address of the percona application pod. This can be obtained by executing
kubectl describe on the percona pod.

```
karthik@MayaMaster:~$ kubectl describe pod percona | grep IP
IP:             10.44.0.3
```

Edit the below line in sql-loadgen job yaml to pass the desired load duration and
percona pod IP as arguments. In this example, the job performs sql queries on pod 
with IP address 10.44.0.3 for 300s.

```
args: ["-c", "timelimit -t 300 sh MySQLLoadGenerate.sh 10.44.0.3 > /dev/null 2>&1; exit 0"]
```

Run the load generation job

```
kubectl apply -f sql-loadgen.yaml
```

## Step-4: View performance and storage consumption stats using mayactl 

Performance and capacity usage stats on the OpenEBS storage volume can be viewed
by executing the following mayactl command inside the maya-apiserver pod. Follow 
the below sequence of steps to achieve this:

Start an interactive bash console for the maya-apiserver container  

```
kubectl exec -it maya-apiserver-1633167387-5ss2w /bin/bash
```

Lookup the storage volume name using the ```vsm-list``` command

```
karthik@MayaMaster:~$ kubectl exec -it maya-apiserver-1633167387-5ss2w /bin/bash

root@maya-apiserver-1633167387-5ss2w:/# maya vsm-list
Name                                      Status
pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc  Running
```

Get the performance and capacity usage stats using the ```vsm-stats``` command.  

```
root@maya-apiserver-1633167387-5ss2w:/# maya vsm-stats pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc
------------------------------------
 IQN     : iqn.2016-09.com.openebs.jiva:pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc
 Volume  : pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc
 Portal  : 10.109.70.220:3260
 Size    : 5G

      Replica|   Status|   DataUpdateIndex|
             |         |                  |
    10.36.0.3|   Online|              4341|
    10.44.0.2|   Online|              4340|

------------ Performance Stats ----------

   r/s|   w/s|   r(MB/s)|   w(MB/s)|   rLat(ms)|   wLat(ms)|   rBlk(KB)|   wBlk(KB)|
     0|    14|     0.000|    14.000|      0.000|     71.325|          0|       1024|

------------ Capacity Stats -------------
   Logical(GB)|   Used(GB)| 
      0.074219|   0.000000|

```
The above command can be invoked with ```watch``` by providing a desired interval 
to continuously monitor stats

```
watch -n 1 maya vsm-stats pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc
```
