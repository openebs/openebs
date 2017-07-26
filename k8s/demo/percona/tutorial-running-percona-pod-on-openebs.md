# Running percona pod on OpenEBS

This tutorial provides detailed instructions on how to run a percona-mysql application pod on OpenEBS storage in a kubernetes cluster and uses a mysql-client container to generate some load (in the form of insert & select DB queries) in order to illustrate I/O traffic on the storage. 

## Pre-requisites

Pre-requisites include the following: 

- A fully configured kubernetes cluster (versions 1.6.3 & upwards have been tested) with kube master and at least one kube minion. This maybe created on cloud platforms like GKE, on-premise virtual machines (vagrant/VMware/Hyper-V) or bare-metal boxes

  Note: 

  - It is recommended to use a 3-node cluster, with one master and two minions, as this will aid creation of storage replicas on separate  minion nodes. This is especially helpful to maintain redundancy and data availability) 

  - If you are using gcp, view the appendix in this [tutorial](https://github.com/openebs/openebs/blob/master/k8s/hyperconverged/tutorial-configure-openebs-gke.md)   for additional steps for setting cluster admin context and using it 
  
  Verify that the kubernetes cluster is in optimal state: 
  
  ```
  karthik@MayaMaster:~$ kubectl get nodes
  NAME         STATUS    AGE       VERSION
  mayahost01   Ready     5d        v1.6.3
  mayahost02   Ready     5d        v1.6.3
  mayamaster   Ready     5d        v1.6.3

  ```
  
- Sufficient resources on the minions to host the openebs storage pods & percona application pods. This includes sufficient disk space, as, in this example, physical storage for the pvolume containers shall be carved out from local storage

- iSCSI support on the minions. This is needed to be able to consume the iSCSI target exposed by the openebs volume container (i.e., VSM)
  In ubuntu, the iSCSI initiator can be installed using the procedure below : 
  
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

Download the latest OpenEBS operator files and sample percona-mysql application pod yaml on the kubemaster from the OpenEBS git repo 

```
git clone https://github.com/openebs/openebs.git
cd openebs/k8s
```

Apply the openebs-operator on the kubernetes cluster. This creates the maya api-server and openebs provisioner deployments

```
kubectl apply -f openebs-operator.yaml
```

Add the OpenEBS storage classes, that can then be used by developers to map a suitable storage profile for their apps in their respective persistent volume claims 

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
openebs-basic     openebs.io/provisioner-iscsi
openebs-jupyter   openebs.io/provisioner-iscsi
openebs-percona   openebs.io/provisioner-iscsi
```

## Step-2: Run percona-mysql pod with openebs storage

Use OpenEBS as persistent storage for the percona pod by selecting an OpenEBS storage class in the persistent volume claim. A sample percona pod yaml (with container attributes and pvc details) is available in the openebs git repo (cloned in the previous steps)

Apply the percona pod yaml 

```
cd demo/percona
kubectl apply -f demo-percona-mysql-pvc.yaml
```
Verify that the openebs storage pods, i.e., the jiva controller and jiva replicas are created and the percona pod is running succesfully

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

Note: It may take some time for pods to start as the images need to be pulled and instantiated. This is also dependent on the network speed

## Step-3: Run a database client container to generate SQL load 

To test the pod, run a mysql client container that runs a load generation script which performs simple sql queries to simulate storage traffic. 

 







