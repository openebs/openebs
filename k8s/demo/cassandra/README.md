# Running Cassandra with OpenEBS

This tutorial provides detailed instructions to run a Kudo operator based Cassandra StatefulsSets with OpenEBS storage and perform some simple database operations to verify the successful deployment and it's performance benchmark.

## Introduction

Apache Cassandra is a free and open-source distributed NoSQL database management system designed to handle a large amounts of data across nodes, providing high availability with no single point of failure. It uses asynchronous masterless replication allowing low latency operations for all clients. 

OpenEBS is the most popular Open Source Container Attached Solution available for Kubernetes and is favored by many organizations for its simplicity and ease of management and it's highly flexible deployment options to meet the storage needs of any given stateful application.

Depending on the performance and high availability requirements of Cassandra, you can select to run Cassandra with the following deployment options:

For optimal performance, deploy Cassandra with OpenEBS Local PV. If you would like to use storage layer capabilities like high availability, snapshots, incremental backups and restore and so forth, you can select OpenEBS cStor. 

Whether you use OpenEBS Local PV or cStor, you can set up the Kubernetes cluster with all its nodes in a single availability zone/data center or spread across multiple zones/ data centers.


## Configuration workflow 

1. Install OpenEBS
2. Select OpenEBS storage engine
3. Configure OpenEBS LocalPV StorageClass
4. Install Kudo operator
5. Install Kudo based Cassandra
6. Verify Cassandra is up and running
7. Testing Cassandra performance on OpenEBS

### Install OpenEBS

If OpenEBS is not installed in your K8s cluster, this can be done from [here](https://docs.openebs.io/docs/next/overview.html). If OpenEBS is already installed, go to the next step.

### Select OpenEBS storage engine

A storage engine is the data plane component of the IO path of a Persistent Volume. In CAS architecture, users can choose different data planes for different application workloads based on a configuration policy. OpenEBS provides different types of storage engines and chooses the right engine that suits your type of application requirements and storage available on your Kubernetes nodes. More information can be read from [here](https://docs.openebs.io/docs/next/overview.html#openebs-storage-engines).

### Configure OpenEBS LocalPV StorageClass

In this tutorial, OpenEBS LocalPV device has been used as the storage engine for deploying Kudo Cassandra. There are 2 ways to use OpenEBS LocalPV.

- `openebs-hostpath` - Using this option, it will create Kubernetes Persistent Volumes that will store the data into OS host path directory at: /var/openebs/<cassandra-pv>/. Select this option, if you don’t have any additional block devices attached to Kubernetes nodes. You would like to customize the directory where data will be saved, create a new OpenEBS LocalPV storage class using these [instructions](https://docs.openebs.io/docs/next/uglocalpv-hostpath.html#create-storageclass). 
  
- `openebs-device` - Using this option, it will create Kubernetes Local PVs using the block devices attached to the node. Select this option when you want to dedicate a complete block device on a node to a Cassandra node. You can customize which devices will be discovered and managed by OpenEBS using the instructions [here](https://docs.openebs.io/docs/next/ugndm.html). 

### Install Kudo operator to install Cassandra 

- Make the environment to install Kudo operator using the following steps.

  ```
  $ export GOROOT=/usr/local/go
  $ export GOPATH=$HOME/gopath
  $ export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
  ```
- Choose the Kudo version. The latest version can be found [here](https://github.com/kudobuilder/kudo/releases). In the following command, selected Kudo version is v0.14.0. 
  ```
  VERSION=0.14.0
  OS=$(uname | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  wget -O kubectl-kudo https://github.com/kudobuilder/kudo/releases/download/v${VERSION}/kubectl-kudo_${VERSION}_${OS}_${ARCH}
  ```
- Change the permission
  ```
  $ chmod +x kubectl-kudo
  $ sudo mv kubectl-kudo /usr/local/bin/kubectl-kudo
  ```
- Install Cert-manager

  Before installing the KUDO operator, the cert-manager must be already installed in your cluster. If not, install the cert-manager. The instruction can be found from [here](https://cert-manager.io/docs/installation/kubernetes/#installing-with-regular-manifests). Since our K8s version is v1.16.0, we have installed cert-manager using the following command.
  ```
  $ kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager.yaml
  ```
- Install Kudo operator using a specified version. In the following command, the selected version is v0.14.0.
  ```
  $ kubectl-kudo init --version 0.14.0
  ```
  Verify Kudo controller pods status
  ```
  $ kubectl get pod -n kudo-system
  
  NAME                        READY   STATUS    RESTARTS   AGE
  kudo-controller-manager-0   1/1     Running   0          2m40s
  ```

### Install Kudo operator based Cassandra 
     
Install Kudo based Cassandra using OpenEBS storage engine. In this example, the storage class used is `openebs-device`. Before deploying Cassandra, ensure that there are enough  block devices that can be used to consume Cassandra application, by running `kubectl get bd -n openebs`.
    
```
$ export instance_name=cassandra-openebs
$ export namespace_name=cassandra
$ kubectl create ns cassandra 
$ kubectl kudo install cassandra --namespace=$namespace_name --instance $instance_name -p NODE_STORAGE_CLASS=openebs-device
```
  
### Verify Cassandra is up and running
  
- Get the Cassandra Pods, StatefulSet, Service and PVC details. It should show that StatefulSet is deployed with 3 Cassandra pods in running state and a headless service is configured. 
  ```
  $kubectl get pod,service,sts,pvc -n cassandra  
  
  NAME                                    READY   STATUS    RESTARTS   AGE
  cassandra-openebs-node-0   2/2          Running     0                4m
  cassandra-openebs-node-1   2/2          Running     0                3m2s
  cassandra-openebs-node-2   2/2          Running     0                3m24s

  NAME                         READY   AGE
  statefulset.apps/cassandra   3/3     6m35s

  NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                                        AGE
  service/cassandra-openebs-svc   ClusterIP   None         <none>        7000/TCP,7001/TCP,7199/TCP,9042/TCP,9160/TCP   6m35s
  
  NAME                                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
  var-lib-cassandra-cassandra-openebs-node-0   Bound    pvc-213f2cfb-231f-4f14-be93-69c3d1c6d5d7   20Gi       RWO            openebs-device   20m
  var-lib-cassandra-cassandra-openebs-node-1   Bound    pvc-059bf24b-3546-43f3-aa01-3a6bea640ffd   20Gi       RWO            openebs-device   19m
  var-lib-cassandra-cassandra-openebs-node-2   Bound    pvc-82367756-7a19-4f7f-9e35-65e7696f3b86   20Gi       RWO            openebs-device   18m
  ```
- Login to one of the Cassandra pod to verify the Cassandra cluster health status using the following command.
  ```
  $ kubectl exec -it cassandra-openebs-node-0 bash -n cassandra
  
  cassandra@cassandra-openebs-node-0:/$ nodetool status
  Datacenter: datacenter1
  =======================
  Status=Up/Down   |/ State=Normal/Leaving/Joining/Moving      --  Address        Load       Tokens       Owns (effective)  Host ID                               Rack
  UN  192.168.30.24  94.21 KiB  256          63.0%             73c54856-f045-48db-b0db-e6a751d005f8  rack1
  UN  192.168.93.31  75.12 KiB  256          65.3%             d48c61b7-551b-4805-b8cc-b915d039f298  rack1
  UN  192.168.56.80  75 KiB     256          71.7%             91fc4107-e447-4605-8cbf-3916f9fd8abf  rack1
  ```

- Create a Test Keyspace with Tables. Login to one of the Cassandra pod and run the following commands from a cassandra pod.
  ```
  cassandra@cassandra-openebs-node-0:/$ cqlsh <svc-name>.<namespace>.svc.cluster.local
  ```
  Example command:
  ```
  cassandra@cassandra-openebs-node-0:/$ cqlsh cassandra-openebs-svc.cassandra.svc.cluster.local
  
  Connected to cassandra-openebs at cassandra-openebs-svc.cassandra.svc.cluster.local:9042.
  [cqlsh 5.0.1 | Cassandra 3.11.6 | CQL spec 3.4.4 | Native protocol v4]
  Use HELP for help.
  cqlsh>
  ```

- Creating a Keyspace. Now, let’s create a Keyspace and add a table with some entries into it.
  ```
  cqlsh> create keyspace dev
  ... with replication = {'class':'SimpleStrategy','replication_factor':1};
  
- Creating Data Objects
  ```
  cqlsh> use dev;
  cqlsh:dev> create table emp (empid int primary key,
  ... emp_first varchar, emp_last varchar, emp_dept varchar);
  
- Inserting and Querying Data
  ```
  $ cqlsh:dev> insert into emp (empid, emp_first, emp_last, emp_dept)
  ... values (1,'fred','smith','eng');

  $ cqlsh:dev> select * from emp;
  empid | emp_dept | emp_first | emp_last
  -------+----------+-----------+----------
      1 |      eng |      fred |    smith
  (1 rows)

- Updating a data
  ```
  $ cqlsh:dev> update emp set emp_dept = 'fin' where empid = 1;
  $ cqlsh:dev> select * from emp;
  empid | emp_dept | emp_first | emp_last
  -------+----------+-----------+----------
      1 |      fin |      fred |    smith
  (1 rows)
  cqlsh:dev> exit
  ```
      
### Testing Cassandra Performance on OpenEBS
   
- Login to one of the cassandra pod and run the following sample loadgen command to write and read some entry to and from the database.
  ```
  $ kubectl exec -it cassandra-openebs-node-0 bash -n cassandra
  ```
- Get the database health status
  ```
  $ nodetool status
  Datacenter: datacenter1
  =======================
  Status=Up/Down
  |/ State=Normal/Leaving/Joining/Moving   --   Address        Load       Tokens       Owns (effective)  Host ID                               Rack
  UN  192.168.52.94  135.39 MiB  256          32.6%             68206664-b1e7-4e73-9677-14119536e42d  rack1
  UN  192.168.7.79   189.98 MiB  256          36.3%             5f6176f5-c47f-4d12-bd16-c9427baf68a0  rack1
  UN  192.168.70.87  127.46 MiB  256          31.2%             da31ba66-42dd-4c85-a212-a0cb828bbefb  rack1
  ``` 
- Go to the directory where the binary is located.
  ```
  cassandra@cassandra-openebs-node-0:/$ cd /opt/cassandra/tools/bin
  ```
- Run Write load 
  ```
  cassandra@cassandra-openebs-node-0:/opt/cassandra/tools/bin$ ./cassandra-stress write n=1000000 -rate threads=50 -node 192.168.52.94
  ```
- Run Read Load
  ```
  cassandra@cassandra-openebs-node-0:/opt/cassandra/tools/bin$ ./cassandra-stress read n=200000 -rate threads=50 -node 192.168.52.94
  ```
