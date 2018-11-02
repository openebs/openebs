# Running mongodb statefulset on OpenEBS 

This tutorial provides detailed instructions to perform the following tasks : 

- Run a mongodb statefulset on OpenEBS storage in a Kubernetes cluster 
- Generate standard OLTP load on mongodb using a custom sysbench tool 
- Test the data replication across the mongodb instances.

## Prerequisites

Prerequisites include the following:

- A fully configured Kubernetes cluster (versions 1.9.7+ have been tested)

  Note: _OpenEBS recommends using at least a 3-node cluster_

    ```
    test@Master:~$ kubectl get nodes
    NAME                                        STATUS    ROLES     AGE       VERSION
    gke-kmova-helm-default-pool-6b1e777c-8gdf   Ready     <none>    17h       v1.9.7-gke.6
    gke-kmova-helm-default-pool-6b1e777c-fwgp   Ready     <none>    17h       v1.9.7-gke.6
    gke-kmova-helm-default-pool-6b1e777c-m07h   Ready     <none>    17h       v1.9.7-gke.6
    ```
    
- Sufficient resources on the nodes to host the OpenEBS storage pods and application pods. This includes sufficient disk space, 
  as, in this example, physical storage for the volume containers will be carved out from the local storage
  
- iSCSI support on the nodes. This is required to consume the iSCSI target exposed by the OpenEBS volume container. 
In ubuntu, the iSCSI initiator can be installed using the following procedure :

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
- Install the following dependent packages to run mongodb-integrated sysbench I/O tool on any one of the Kubernetes nodes
  
  ```
  sudo apt-get install <packagename>:

  make
  libsasl2-dev
  libssl-dev
  libmongoc-dev
  libbson-dev
  ```

## Step-1: Run OpenEBS Operator

Download the latest OpenEBS operator files and sample mongodb statefulset specification yaml on the Kubernetes master 
from the OpenEBS git repository.

```
git clone https://github.com/openebs/openebs.git
cd openebs/k8s
```

Apply the openebs-operator.yml on the Kubernetes cluster. This creates the maya api-server and OpenEBS provisioner deployments.
  
```
kubectl apply -f openebs-operator.yaml
```

Check whether the deployments are running successfully.

```
test@Master:~$ kubectl get pods -n openebs
```

## Step-2: Deploy the mongo-statefulset with OpenEBS storage

Use OpenEBS as persistent storage for the mongodb statefulset by selecting an OpenEBS storage class in the persistent volume claim. 
A sample mongodb statefulset yaml (with container attributes and pvc details) is available in the openebs git repository.

The number of replicas in the statefulset can be modified as required. This example makes use of 1 replica. The replica count
can be edited in the statefulset specification : 

```
---
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
 name: mongo
spec:
 serviceName: "mongo"
 replicas: 2
 template:
   metadata:
     labels:
       role: mongo
       environment: test
.
.
```

Apply the mongo-statefulset yaml : 

```
test@Master:~$ kubectl apply -f mongo-statefulset.yml
service "mongo" created
statefulset "mongo" created
```

Verify that the mongodb replicas, the mongo headless service and openebs persistent volumes comprising the controller and replica pods 
are successfully deployed and are in "Running" state.

```
test@Master:~$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
mongo-0                                                          2/2       Running   0          2m
mongo-1                                                          2/2       Running   0          2m
mongo-2                                                          2/2       Running   0          1m
openebs-provisioner-1149663462-5pdcq                             1/1       Running   0          8m
pvc-0d39583c-bad7-11e7-869d-000c298ff5fc-ctrl-4109100951-v2ndc   1/1       Running   0          2m
pvc-0d39583c-bad7-11e7-869d-000c298ff5fc-rep-1655873671-50f8z    1/1       Running   0          2m
pvc-21da76b6-bad7-11e7-869d-000c298ff5fc-ctrl-2618026111-z5hzt   1/1       Running   0          2m
pvc-21da76b6-bad7-11e7-869d-000c298ff5fc-rep-187343257-9w46n     1/1       Running   0          2m
pvc-3a9ca1ec-bad7-11e7-869d-000c298ff5fc-ctrl-2347166037-vsc2t   1/1       Running   0          1m
pvc-3a9ca1ec-bad7-11e7-869d-000c298ff5fc-rep-849715916-3w1c7     1/1       Running   0          1m

test@Master:~$ kubectl get svc
NAME                                                CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
mongo                                               None             <none>        27017/TCP           3m
pvc-0d39583c-bad7-11e7-869d-000c298ff5fc-ctrl-svc   10.105.60.71     <none>        3260/TCP,9501/TCP   3m
pvc-21da76b6-bad7-11e7-869d-000c298ff5fc-ctrl-svc   10.105.178.143   <none>        3260/TCP,9501/TCP   2m
pvc-3a9ca1ec-bad7-11e7-869d-000c298ff5fc-ctrl-svc   10.110.104.42    <none>        3260/TCP,9501/TCP   1m

```

Note : It may take some time for pods to start as the images need to be pulled and instantiated. This is also dependent 
on the network speed.

## Step-3 Generate load on the mongodb instance 

In this example, we will be using a custom-built sysbench framework integrated with support for OLTP tests mongodb via lua scripts. 
Sysbench is a multi-purpose benchmarking tool capable of running DB benchmarks as well as regular raw/file device I/O.

### Sysbench Installation Steps :

- Download the appropriate branch of Percona-Lab's sysbench fork with support for mongodb integration on the Kubernetes nodes into
which the sysbench dependencies are installed (refer the prerequisites)

  ```
  git clone -b dev-mongodb-support-1.0 https://github.com/Percona-Lab/sysbench.git
  ```
  
- Enter the sysbench local repository and perform the following commands in the given order :

  ```
  cd sysbench
  
  ./autogen.sh
  ./configure
  make
  ```
  Note : In case of errors where some header files belonging to the libbson/libmongoc packages are not found, update the include 
  path (One workaround for this is to place all header files inside libbson-1.0 and libmongoc-1.0 into /usr/include)
  
### Execute the sysbench benchmark 
  
- Identify the primary mongodb instance name OR its IP (In the current statefulset specification YAML, "mongo-0" is always
  configured as the primary instance that takes client I/O)
  
- Trigger the sysbench command using the following command to :
   
  - prepare the database, add the collections
  - Perform the benchmark run
    
  Note : Replace the mongo-url param based on the appropriate IP which can be obtained by ```kubectl describe pod mongo-0 | grep IP```
    
  ```
  test@Host02:~/sysbench$ ./sysbench/sysbench --mongo-write-concern=1 --mongo-url="mongodb://10.44.0.3" --mongo-database-name=sbtest --test=./sysbench/tests/mongodb/oltp.lua --oltp_table_size=100 --oltp_tables_count=10 --num-threads=10 --rand-type=pareto --report-interval=10 --max-requests=0 --max-time=600 --oltp-point-selects=10 --oltp-simple-ranges=1 --oltp-sum-ranges=1 --oltp-order-ranges=1 --oltp-distinct-ranges=1 --oltp-index-updates=1 --oltp-non-index-updates=1 --oltp-inserts=1 run
  ```
  The parameters used for the sysbench can be modified based on system capability and storage definition to obtain realistic benchmark figures.
    
  The benchmark output displayed is similar to the following : 
    
  ```
  sysbench 1.0:  multi-threaded system evaluation benchmark

  Running the test with following options: 
  Number of threads: 10
  Report intermediate results every 10 second(s)
  Initializing random number generator from current time


  Initializing worker threads...

  setting write concern to 1
  Threads started!

  [  10s] threads: 10, tps: 56.60, reads: 171.50, writes: 170.40, response time: 316.14ms (95%), errors: 0.00, reconnects:  0.00
  [  20s] threads: 10, tps: 74.70, reads: 222.90, writes: 223.50, response time: 196.30ms (95%), errors: 0.00, reconnects:  0.00
  [  30s] threads: 10, tps: 76.00, reads: 227.70, writes: 228.00, response time: 196.71ms (95%), errors: 0.00, reconnects:  0.00
  [  40s] threads: 10, tps: 79.60, reads: 239.70, writes: 238.80, response time: 329.08ms (95%), errors: 0.00, reconnects:  0.00
  :
  :
  OLTP test statistics:
    queries performed:
        read:                            154189
        write:                           154122
        other:                           51374
        total:                           359685
    transactions:                        51374  (85.61 per sec.)
    read/write requests:                 308311 (513.79 per sec.)
    other operations:                    51374  (85.61 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

  General statistics:
      total time:                          600.0703s
      total number of events:              51374
      total time taken by event execution: 6000.1853s
      response time:
           min:                                 26.11ms
           avg:                                116.79ms
           max:                               2388.03ms
           approx.  95 percentile:             224.00ms

  Threads fairness:
      events (avg/stddev):           5137.4000/21.50
      execution time (avg/stddev):   600.0185/0.02
  ```
- While the benchmark is in progress, performance and capacity usage statistics on the OpenEBS storage volume can be viewed via mayactl
  commands that must be executed on the maya-apiserver pod.
  
  Take an interactive bash session into the maya-apiserver pod container 
  
  ```
  test@Master:~$ kubectl exec -it maya-apiserver-1089964587-x5q15 /bin/bash
  root@maya-apiserver-1089964587-x5q15:/#
  ```
  
  Obtain the list of OpenEBS persistent volumes created by the mongodb statefulset application YAML.
  
  ```
  root@maya-apiserver-1089964587-x5q15:/# maya volume list
  Name                                      Status
  pvc-0d39583c-bad7-11e7-869d-000c298ff5fc  Running
  pvc-21da76b6-bad7-11e7-869d-000c298ff5fc  Running
  ```
  
  View usage and I/O metrics for the required volume via the stats command 
  
  ```
  root@maya-apiserver-1089964587-x5q15:/# maya volume stats pvc-0d39583c-bad7-11e7-869d-000c298ff5fc
  IQN     : iqn.2016-09.com.openebs.jiva:pvc-0d39583c-bad7-11e7-869d-000c298ff5fc
  Volume  : pvc-0d39583c-bad7-11e7-869d-000c298ff5fc
  Portal  : 10.105.60.71:3260
  Size    : 5G

       Replica|   Status|   DataUpdateIndex|
              |         |                  |
     10.44.0.2|   Online|              4341|
     10.36.0.3|   Online|              4340|

  ----------- Performance Stats -----------

     r/s|   w/s|   r(MB/s)|   w(MB/s)|   rLat(ms)|   wLat(ms)|
       0|    14|     0.000|    14.000|      0.000|     71.325|

  ------------ Capacity Stats -------------

     Logical(GB)|   Used(GB)|
           0.214|      0.205|
  ```
     
  ### Verify mongodb replication
  
  - Login into the primary instance of the mongodb statefulset via the in-built mongo shell and verify creation of the 
  "sbtest" test database created by sysbench in the previous steps.
  
    ```
    test@Master:~$ kubectl exec -it mongo-0 /bin/bash
    root@mongo-0:/# mongo

    MongoDB shell version v3.4.9
    connecting to: mongodb://127.0.0.1:27017
    MongoDB server version: 3.4.9
    :
    rs0:PRIMARY> show dbs
    admin   0.000GB
    local   0.006GB
    sbtest  0.001GB
    ```
  - Run the replication status command on the master/primary instance of the statefulset. In the output, verify that the values 
  (timestamps) for the "optimeDate" on both members are *almost* the same
  
    ```
       rs0:PRIMARY> rs.status()
    {
      "set" : "rs0",
      "date" : ISODate("2017-10-23T07:26:36.679Z"),
      "myState" : 1,
      "term" : NumberLong(1),
      "heartbeatIntervalMillis" : NumberLong(2000),
      "optimes" : {
              "lastCommittedOpTime" : {
                      "ts" : Timestamp(1508743595, 51),
                      "t" : NumberLong(1)
              },
              "appliedOpTime" : {
                      "ts" : Timestamp(1508743596, 40),
                      "t" : NumberLong(1)
              },
              "durableOpTime" : {
                      "ts" : Timestamp(1508743595, 71),
                      "t" : NumberLong(1)
              }
      },
      "members" : [
              {
                      "_id" : 0,
                      "name" : "10.44.0.3:27017",
                      "health" : 1,
                      "state" : 1,
                      "stateStr" : "PRIMARY",
                      "uptime" : 243903,
                      "optime" : {
                              "ts" : Timestamp(1508743596, 40),
                              "t" : NumberLong(1)
                      },
                      "optimeDate" : ISODate("2017-10-23T07:26:36Z"),
                      "electionTime" : Timestamp(1508499738, 2),
                      "electionDate" : ISODate("2017-10-20T11:42:18Z"),
                      "configVersion" : 5,
                      "self" : true
              },
              {
                      "_id" : 1,
                      "name" : "10.36.0.6:27017",
                      "health" : 1,
                      "state" : 2,
                      "stateStr" : "SECONDARY",
                      "uptime" : 243756,
                      "optime" : {
                              "ts" : Timestamp(1508743595, 51),
                              "t" : NumberLong(1)
                      },
                      "optimeDurable" : {
                              "ts" : Timestamp(1508743595, 34),
                              "t" : NumberLong(1)
                      },
                      "optimeDate" : ISODate("2017-10-23T07:26:35Z"),
                      "optimeDurableDate" : ISODate("2017-10-23T07:26:35Z"),
                      "lastHeartbeat" : ISODate("2017-10-23T07:26:35.534Z"),
                      "lastHeartbeatRecv" : ISODate("2017-10-23T07:26:34.894Z"),
                      "pingMs" : NumberLong(6),
                      "syncingTo" : "10.44.0.3:27017",
                      "configVersion" : 5
              },
              {
                      "_id" : 2,
                      "name" : "10.44.0.7:27017",
                      "health" : 1,
                      "state" : 2,
                      "stateStr" : "SECONDARY",
                      "uptime" : 243700,
                      "optime" : {
                              "ts" : Timestamp(1508743595, 104),
                              "t" : NumberLong(1)
                      },
                      "optimeDurable" : {
                              "ts" : Timestamp(1508743595, 34),
                              "t" : NumberLong(1)
                      },
                      "optimeDate" : ISODate("2017-10-23T07:26:35Z"),
                      "optimeDurableDate" : ISODate("2017-10-23T07:26:35Z"),
                      "lastHeartbeat" : ISODate("2017-10-23T07:26:35.949Z"),
                      "lastHeartbeatRecv" : ISODate("2017-10-23T07:26:35.949Z"),
                      "pingMs" : NumberLong(0),
                      "syncingTo" : "10.44.0.3:27017",
                      "configVersion" : 5
              }
      ],
      "ok" : 1
    }
    ```
  - You could further confirm the presence of the DB with the same size on the secondary instances (for example, mongo-1).
  
    Note : By default, the dbs cannot be viewed on the secondary instance via the show dbs command, unless we set the slave context.
    
    ```
    rs0:SECONDARY> rs.slaveOk()

    rs0:SECONDARY> show dbs
    admin   0.000GB
    local   0.005GB
    sbtest  0.001GB
    ```
   
  - The time lag between the mongodb instances can be found via the following command, which can be executed on either instance.
  
    ```
    rs0:SECONDARY> rs.printSlaveReplicationInfo()
    source: 10.36.0.6:27017
         syncedTo: Mon Oct 23 2017 07:28:27 GMT+0000 (UTC)
         0 secs (0 hrs) behind the primary
    source: 10.44.0.7:27017
         syncedTo: Mon Oct 23 2017 07:28:27 GMT+0000 (UTC)
         0 secs (0 hrs) behind the primary
    ```
  

   

