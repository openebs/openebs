# Running Cassandra with OpenEBS

This tutorial provides detailed instructions to run a Cassandra Statefulset with OpenEBS storage and perform 
some simple database operations to verify successful deployment.

## Cassandra 

Apache Cassandra is a free and open-source distributed NoSQL database management system designed to handle 
large amounts of data across nodes, providing high availability with no single point of failure. It uses
asynchronous masterless replication allowing low latency operations for all clients.

## Prerequisite 

A fully configured (preferably, multi-node) Kubernetes cluster configured with the OpenEBS operator and OpenEBS 
storage classes.

```
test@Master:~$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
maya-apiserver-3416621614-g6tmq                                  1/1       Running   1          8d
openebs-provisioner-4230626287-503dv                             1/1       Running   1          8d
```

## Deploy the Cassandra Statefulset with OpenEBS storage

The statefulset specification YAMLs are available at OpenEBS/k8s/demo/cassandra. 

The number of replicas in the Statefulset can be modified as required. This example uses 2 replicas.

```
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: cassandra
  labels:
    app: cassandra
spec:
  serviceName: cassandra
  replicas: 2
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
:
```

Execute the following commands:

```
test@Master:~$ cd openebs/k8s/demo/cassandra

test@Master:~/openebs/k8s/demo/cassandra$ ls -ltr
total 8
-rw-rw-r-- 1 test test  165 Oct 30 12:19 cassandra-service.yaml
-rw-rw-r-- 1 test test 2382 Nov 11 14:09 cassandra-statefulset.yaml
```

```
test@Master:~/openebs/k8s/demo/cassandra$ kubectl apply -f cassandra-service.yaml
service "cassandra" configured
```

```
test@Master:~/openebs/k8s/demo/cassandra$ kubectl apply -f cassandra-statefulset.yaml
statefulset "cassandra" created
```

Verify that all the OpenEBS persistent volumes are created, the Cassandra headless service and replicas 
are running:

```
test@Master:~/openebs/k8s/demo/cassandra$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
cassandra-0                                                      1/1       Running   0          4h
cassandra-1                                                      1/1       Running   0          4h
maya-apiserver-3416621614-g6tmq                                  1/1       Running   1          8d
openebs-provisioner-4230626287-503dv                             1/1       Running   1          8d
pvc-1c16536c-c6bc-11e7-a0eb-000c298ff5fc-ctrl-599202565-2kdff    1/1       Running   0          4h
pvc-1c16536c-c6bc-11e7-a0eb-000c298ff5fc-rep-3068892500-22ccd    1/1       Running   0          4h
pvc-1c16536c-c6bc-11e7-a0eb-000c298ff5fc-rep-3068892500-lhwdw    1/1       Running   0          4h
pvc-e7d18817-c6bb-11e7-a0eb-000c298ff5fc-ctrl-1103031005-8vv82   1/1       Running   0          4h
pvc-e7d18817-c6bb-11e7-a0eb-000c298ff5fc-rep-3006965094-cntx5    1/1       Running   0          4h
pvc-e7d18817-c6bb-11e7-a0eb-000c298ff5fc-rep-3006965094-mhsjt    1/1       Running   0          4h
```

```
test@Master:~/openebs/k8s/demo/cassandra$ kubectl get svc
NAME                                                CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
cassandra                                           None             <none>        9042/TCP            5h
kubernetes                                          10.96.0.1        <none>        443/TCP             14d
maya-apiserver-service                              10.102.92.217    <none>        5656/TCP            14d
pvc-1c16536c-c6bc-11e7-a0eb-000c298ff5fc-ctrl-svc   10.107.177.156   <none>        3260/TCP,9501/TCP   4h
pvc-e7d18817-c6bb-11e7-a0eb-000c298ff5fc-ctrl-svc   10.108.47.234    <none>        3260/TCP,9501/TCP   4h
```

Note: It may take some time for the pods to start as the images must be pulled and instantiated. This is also
dependent on the network speed.

## Verify successful Cassandra Deployment

The verification procedure can be carried out in a series of steps, starting from listing the functional 
replicas to by creating and deleting test data in the Cassandra database.

### Step-1: Install the Cqlsh Utility

Cqlsh is a Python based utility that enables you to execute Cassandra Query Language (CQL). CQL is a 
declarative language that enables users to query Cassandra using semantics similar to SQL. 

Install the python-minimal and python-pip apt packages (if not available) and perform a pip install of 
Csqlsh.

```
sudo apt-get install -y python-minimal python-pip 
pip install cqlsh
```

Note: Installing Csqlsh may take a few minutes (typically, the cassandra-driver package takes time to download 
and setup). 

### Step-2: Verify Replica Status on Cassandra

```
test@Master:~$ kubectl exec cassandra-0 -- nodetool status
Datacenter: DC1-K8Demo
======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address    Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.36.0.6  103.83 KiB  32           100.0%           e013c19d-9c6f-49cd-838e-c69eb310f88e  Rack1-K8Demo
UN  10.44.0.3  83.1 KiB    32           100.0%           1d2e3b79-4b0b-4bf9-b435-fcfa8be8a603  Rack1-K8Demo
```

A status of "UN" implies Up and Normal. The "Owns" column suggests the data distribution percentage for the
content placed into the Cassandra keyspaces. In the current example, we have chosen a replica count of 2 due to 
which the data is evenly distributed and copies maintained.

### Step-3: Create a Test Keyspace with Tables 

- Identify the IP address of any of the Cassandra replicas, for example, Cassandra-0. This is available from the 
output of the nodetool status command executed in the previous step.

- Login to the CQL shell using the Cqlsh utility.

  ```
  test@Master:~$ cqlsh 10.44.0.3 9042 --cqlversion="3.4.2"
  Connected to K8Demo at 10.44.0.3:9042.
  [cqlsh 5.0.1 | Cassandra 3.9 | CQL spec 3.4.2 | Native protocol v4]
  Use HELP for help.

  cqlsh>
  ```

- Create a keyspace with replication factor 2.

  ```
  cqlsh> create keyspace hardware with replication = { 'class' : 'SimpleStrategy' , 'replication_factor' : 2 };
  
  cqlsh> describe keyspaces;

  system_schema  system_auth  system  hardware  system_distributed  system_traces
  ```

- Create a table with test content and view the data.

  ```
  cqlsh> use hardware;

  cqlsh:hardware> create table inventory (id uuid,Name text,HWtype text,Model text,PRIMARY KEY ((id), Name));

  cqlsh:hardware> insert into inventory (id, Name, HWType, Model) values (5132b130-ae79-11e4-ab27-0800200c9a66, 'TestBox', 'Server', 'DellR820');

  cqlsh:hardware> select * from inventory;
  
   id                                   | name    | hwtype | model
  ---------------------------------------+---------+--------+----------
   5132b130-ae79-11e4-ab27-0800200c9a66 | TestBox | Server | DellR820
  
  (1 rows) 
  ```

- Flush the data to ensure it is written to disk from the memtable (memory).
 
  ```
  test@Master:$ kubectl exec cassandra-0 -- nodetool flush hardware
  ```

### Step-4: Delete the test keyspace

- Verify the masterless nature of Cassandra Statefulset by deleting the keyspace from another replica, 
in this example, Cassandra-1.

  ```
  test@Master:~$ cqlsh 10.36.0.6 9042 --cqlversion="3.4.2"

  cqlsh> use hardware;
  cqlsh:hardware> select * from Inventory;

   id                                   | name    | hwtype | model
  --------------------------------------+---------+--------+----------
   5132b130-ae79-11e4-ab27-0800200c9a66 | TestBox | Server | DellR820
  
  (1 rows)

  cqlsh> drop keyspace hardware;
  ```

- Verify successful deletion of keyspace.

  ```
  cqlsh> describe keyspaces

  system_traces  system_schema  system_auth  system  system_distributed
  ```

## Scale the Cassandra Statefulset

The Cassandra Statefulset can be scaled depending on resource availability using the *kubectl scale statefulset* command.

```
test@Master:~$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
cassandra-0                                                      1/1       Running   1          1d
maya-apiserver-3416621614-8q6k9                                  1/1       Running   1          1d
openebs-provisioner-4230626287-p8g1n                             1/1       Running   1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-ctrl-1165089859-rpd6p   1/1       Running   1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-rep-3111921848-cqzw4    1/1       Running   1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-rep-3111921848-p1f2b    1/1       Running   1          1d

test@Master:~$ kubectl get statefulset
NAME        DESIRED   CURRENT   AGE
cassandra   1         1         1d

test@Master:~$ kubectl scale statefulset cassandra --replicas=2
statefulset "cassandra" scaled

test@Master:~$ kubectl get pods
NAME                                                             READY     STATUS              RESTARTS   AGE
cassandra-0                                                      1/1       Running             1          1d
cassandra-1                                                      0/1       ContainerCreating   0          4s
maya-apiserver-3416621614-8q6k9                                  1/1       Running             1          1d
openebs-provisioner-4230626287-p8g1n                             1/1       Running             1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-ctrl-1165089859-rpd6p   1/1       Running             1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-rep-3111921848-cqzw4    1/1       Running             1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-rep-3111921848-p1f2b    1/1       Running             1          1d
pvc-f84a8133-e647-11e7-bc35-000c298ff5fc-ctrl-2160660239-l9bkk   1/1       Running             0          4s
pvc-f84a8133-e647-11e7-bc35-000c298ff5fc-rep-3359561965-6bcr1    1/1       Running             0          4s
pvc-f84a8133-e647-11e7-bc35-000c298ff5fc-rep-3359561965-b2ctt    1/1       Running             0          4s
```

Verify that a new OpeneBS persistent volume (PV), i.e., ctrl/replica pods are automatically created upon scaling the 
application replicas.

```
test@Master:~$ kubectl get pvc
NAME                         STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS        AGE
cassandra-data-cassandra-0   Bound     pvc-8910e033-e56b-11e7-8f29-000c298ff5fc   5G         RWO           openebs-cassandra   1d
cassandra-data-cassandra-1   Bound     pvc-f84a8133-e647-11e7-bc35-000c298ff5fc   5G         RWO           openebs-cassandra   3m
```

## Testing Cassandra Performance on OpenEBS

Performance tests on OpenEBS can be run using the Cassandra-loadgen Kubernetes job (cassandra-loadgen.yaml). Follow the steps 
shown below.

- In the loadgen job specification yaml, replace the workload details (for details on supported workloads, refer https://docs.datastax.com/en/cassandra/2.1/cassandra/tools/toolsCStress_t.html) 
  
```
---
apiVersion: batch/v1
kind: Job
metadata:
  name: cassandra-loadgen
spec:
  template:
    metadata:
      name: cassandra-loadgen
    spec:
      restartPolicy: Never
      containers:
      - name: cassandra-loadgen
        image: cassandra
        command: ["/bin/bash"]
        args: ["-c", "cassandra-stress write duration=5m no-warmup -node cassandra-0.cassandra"]
        tty: true
  ```

- Run the Cassandra loadgen Kubernetes job using *kubectl apply* command.

```
test@Master:~/openebs/k8s/demo/cassandra$ kubectl apply -f cassandra-loadgen.yaml
job "cassandra-loadgen" created
  
test@Master:~/openebs/k8s/demo/cassandra$ kubectl get pods
NAME                                                             READY     STATUS              RESTARTS   AGE
cassandra-0                                                      1/1       Running             1          1d
cassandra-1                                                      1/1       Running             0          23m
cassandra-loadgen-mhwnt                                          0/1       ContainerCreating   0          5s
maya-apiserver-3416621614-8q6k9                                  1/1       Running             1          1d
openebs-provisioner-4230626287-p8g1n                             1/1       Running             1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-ctrl-1165089859-rpd6p   1/1       Running             1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-rep-3111921848-cqzw4    1/1       Running             1          1d
pvc-8910e033-e56b-11e7-8f29-000c298ff5fc-rep-3111921848-p1f2b    1/1       Running             1          1d
pvc-f84a8133-e647-11e7-bc35-000c298ff5fc-ctrl-2160660239-l9bkk   1/1       Running             0          23m
pvc-f84a8133-e647-11e7-bc35-000c298ff5fc-rep-3359561965-6bcr1    1/1       Running             0          23m
pvc-f84a8133-e647-11e7-bc35-000c298ff5fc-rep-3359561965-b2ctt    1/1       Running             0          23m
```
- Verify that the stress tool has started running I/O using *kubectl logs* command.

```
test@Master:~/openebs/k8s/demo/cassandra$ kubectl logs -f cassandra-loadgen-mhwnt
******************** Stress Settings ********************
Command:
  Type: write
  Count: -1
  Duration: 5 MINUTES
  No Warmup: true
  Consistency Level: LOCAL_ONE
  Target Uncertainty: not applicable
  Key Size (bytes): 10
  Counter Increment Distribution: add=fixed(1)
Rate:
  Auto: true
  Min Threads: 4
  Max Threads: 1000
Population:
  Sequence: 1..1000000
  Order: ARBITRARY
  Wrap: true
Insert:
  Revisits: Uniform:  min=1,max=1000000
  Visits: Fixed:  key=1
  Row Population Ratio: Ratio: divisor=1.000000;delegate=Fixed:  key=1
  Batch Type: not batching
Columns:
  Max Columns Per Key: 5
  Column Names: [C0, C1, C2, C3, C4]
  Comparator: AsciiType
  Timestamp: null
  Variable Column Count: false
  Slice: false
  Size Distribution: Fixed:  key=34
  Count Distribution: Fixed:  key=5
Errors:
  Ignore: false
  Tries: 10
Log:
  No Summary: false
  No Settings: false
  File: null
  Interval Millis: 1000
  Level: NORMAL
Mode:
  API: JAVA_DRIVER_NATIVE
  Connection Style: CQL_PREPARED
  CQL Version: CQL3
  Protocol Version: V4
  Username: null
  Password: null
  Auth Provide Class: null
  Max Pending Per Connection: 128
  Connections Per Host: 8
  Compression: NONE
Node:
  Nodes: [10.47.0.4]
  Is White List: false
  Datacenter: null
Schema:
  Keyspace: keyspace1
  Replication Strategy: org.apache.cassandra.locator.SimpleStrategy
  Replication Strategy Pptions: {replication_factor=1}
  Table Compression: null
  Table Compaction Strategy: null
  Table Compaction Strategy Options: {}
Transport:
  factory=org.apache.cassandra.thrift.TFramedTransportFactory; truststore=null; truststore-password=null; keystore=null; keystore-password=null; ssl-protocol=TLS; ssl-alg=SunX509; store-type=JKS; ssl-ciphers=TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA;
Port:
  Native Port: 9042
  Thrift Port: 9160
  JMX Port: 7199
Send To Daemon:
  *not set*
Graph:
  File: null
  Revision: unknown
  Title: null
  Operation: WRITE
TokenRange:
  Wrap: false
  Split Factor: 1

Connected to cluster: K8Demo, max pending requests per connection 128, max connections per host 8
Datatacenter: DC1-K8Demo; Host: /10.44.0.9; Rack: Rack1-K8Demo
Datatacenter: DC1-K8Demo; Host: /10.47.0.4; Rack: Rack1-K8Demo
Created keyspaces. Sleeping 1s for propagation.
Sleeping 2s...
Thread count was not specified

Running with 4 threadCount
Running WRITE with 4 threads 5 minutes
Failed to connect over JMX; not collecting these stats
type       total ops,    op/s,    pk/s,   row/s,    mean,     med,     .95,     .99,    .999,     max,   time,   stderr, errors,  gc: #,  max ms,  sum ms,  sdv ms,      mb
total,            30,      30,      30,      30,    73.3,    33.3,   266.3,   273.2,   273.2,   273.2,    1.0,  0.00000,      0,      0,       0,       0,       0,       0
total,           164,     134,     134,     134,    31.1,    14.7,    91.9,   177.6,   197.7,   197.7,    2.0,  0.42686,      0,      0,       0,       0,       0,       0
total,           379,     215,     215,     215,    18.3,    10.9,    55.1,    64.5,    72.9,    72.9,    3.0,  0.31137,      0,      0,       0,       0,       0,       0
total,           558,     179,     179,     179,    22.4,    11.6,    67.3,    95.9,   104.0,   104.0,    4.0,  0.22588,      0,      0,       0,       0,       0,       0
total,           762,     204,     204,     204,    19.1,     7.8,    73.1,   112.1,   114.0,   114.0,    5.0,  0.18113,      0,      0,       0,       0,       0,       0
total,           835,      73,      73,      73,    54.5,    68.4,   113.1,   126.7,   133.6,   133.6,    6.0,  0.18614,      0,      0,       0,       0,       0,       0
total,           907,      72,      72,      72,    55.3,    10.6,   115.5,   194.1,   200.5,   200.5,    7.0,  0.18075,      0,      0,       0,       0,       0,       0
total,           996,      89,      89,      89,    44.8,    11.3,   101.8,   108.8,   109.3,   109.3,    8.0,  0.16982,      0,      0,       0,       0,       0,       0
total,          1066,      70,      70,      70,    57.3,    89.3,   109.6,   114.2,   115.3,   115.3,    9.0,  0.16630,      0,      0,       0,       0,       0,       0
total,          1130,      64,      64,      64,    62.0,    88.8,   110.6,   111.4,   111.9,   111.9,   10.0,  0.16387,      0,      0,       0,       0,       0,       0
total,          1195,      65,      65,      65,    63.3,    91.2,   120.9,   132.8,   133.6,   133.6,   11.0,  0.15948,      0,      0,       0,       0,       0,       0
total,          1273,      78,      78,      78,    49.8,    72.4,   103.7,   115.9,   116.1,   116.1,   12.0,  0.15172,      0,      0,       0,       0,       0,       0
total,          1354,      81,      81,      81,    49.6,     8.3,   101.8,   102.6,   102.9,   102.9,   13.0,  0.14419,      0,      0,       0,       0,       0,       0
total,          1426,      72,      72,      72,    55.2,    88.1,   103.6,   109.2,   110.1,   110.1,   14.0,  0.13889,      0,      0,       0,       0,       0,       0
```
