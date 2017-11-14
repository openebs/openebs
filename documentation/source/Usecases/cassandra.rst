
Cassandra
=========
Running Cassandra with OpenEBS
---------------------------------

This section provides detailed instructions to run a Cassandra StatefulSet with OpenEBS storage and perform some simple database operations to verify successful deployment.

About Cassandra
-----------------
Apache Cassandra is a free and open-source distributed NoSQL database management system. It is designed to handle large amounts of data across nodes, providing high availability with no single point of failure. It uses asynchronous masterless replication allowing low latency operations for all clients.

Prerequisite
--------------

A fully configured (preferably, multi-node) Kubernetes cluster configured with the OpenEBS operator and OpenEBS storage classes.
::

    test@Master:~$ kubectl get pods
    NAME                                                             READY     STATUS    RESTARTS   AGE
    maya-apiserver-3416621614-g6tmq                                  1/1       Running   1          8d
    openebs-provisioner-4230626287-503dv                             1/1       Running   1          8d

Deploying the Cassandra StatefulSet with OpenEBS Storage
--------------------------------------------------------------

The StatefulSet specification YAMLs are available at *OpenEBS/k8s/demo/cassandra*.

You can modify the number of replicas in the StatefulSet as required. The following example uses two replicas. 
::

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

Run the following commands.
::

    test@Master:~$ cd openebs/k8s/demo/cassandra

    test@Master:~/openebs/k8s/demo/cassandra$ ls -ltr
    total 8
    -rw-rw-r-- 1 karthik karthik  165 Oct 30 12:19 cassandra-service.yaml
    -rw-rw-r-- 1 karthik karthik 2382 Nov 11 14:09 cassandra-statefulset.yaml

::

    test@Master:~/openebs/k8s/demo/cassandra$ kubectl apply -f cassandra-service.yaml
    service "cassandra" configured

::

    test@Master:~/openebs/k8s/demo/cassandra$ kubectl apply -f cassandra-statefulset.yaml
    statefulset "cassandra" created

Verify that all the OpenEBS persistent volumes are created and the Cassandra headless service and replicas are running.
::

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

::

    test@Master:~/openebs/k8s/demo/cassandra$ kubectl get svc
    NAME                                                CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
    cassandra                                           None             <none>        9042/TCP            5h
    kubernetes                                          10.96.0.1        <none>        443/TCP             14d
    maya-apiserver-service                              10.102.92.217    <none>        5656/TCP            14d
    pvc-1c16536c-c6bc-11e7-a0eb-000c298ff5fc-ctrl-svc   10.107.177.156   <none>        3260/TCP,9501/TCP   4h
    pvc-e7d18817-c6bb-11e7-a0eb-000c298ff5fc-ctrl-svc   10.108.47.234    <none>        3260/TCP,9501/TCP   4h

**Note:**

It may take some time for the pods to start as the images must be pulled and instantiated. This is also dependent on the network speed.

Verifying Successful Cassandra Deployment
------------------------------------------

You can verify the deployment starting from listing the functional replicas to creating and deleting test data in the Cassandra database.

1. Install the Cqlsh Utility
-----------------------------

Cqlsh is a Python based utility that enables you to execute Cassandra Query Language (CQL). CQL is a declarative language that enables users to query Cassandra using semantics similar to SQL.

Install the python-minimal and python-pip apt packages (if not available) and perform a pip install of Csqlsh using the following commands.
::

    sudo apt-get install -y python-minimal python-pip 
    pip install cqlsh

**Note:**

Installing Csqlsh may take a few minutes (typically, the cassandra-driver package takes time to download and setup).

2. Verify Replica Status on Cassandra
-----------------------------------------
::

    test@Master:~$ kubectl exec cassandra-0 -- nodetool status
    Datacenter: DC1-K8Demo
    ======================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address    Load       Tokens       Owns (effective)  Host ID                               Rack
    UN  10.36.0.6  103.83 KiB  32           100.0%           e013c19d-9c6f-49cd-838e-c69eb310f88e  Rack1-K8Demo
    UN  10.44.0.3  83.1 KiB    32           100.0%           1d2e3b79-4b0b-4bf9-b435-fcfa8be8a603  Rack1-K8Demo

A status of "UN" implies Up and Normal. The "Owns" column suggests the data distribution percentage for the content placed into the Cassandra keyspaces. In the current example, a replica count of 2 is chosen due to which the data is evenly distributed and copies are maintained.

3. Create a Test Keyspace with Tables
---------------------------------------

* Identify the IP Address of any of the Cassandra replicas, for example, Cassandra-0. This is available from the output of the nodetool status command executed in the previous step.

* Login to the CQL shell using the Cqlsh utility using the following command.

::

    test@Master:~$ cqlsh 10.44.0.3 9042 --cqlversion="3.4.2"
    Connected to K8Demo at 10.44.0.3:9042.
    [cqlsh 5.0.1 | Cassandra 3.9 | CQL spec 3.4.2 | Native protocol v4]
    Use HELP for help.

    cqlsh>

* Create a keyspace with replication factor 2 using the following commands.

::

    cqlsh> create keyspace hardware with replication = { 'class' : 'SimpleStrategy' , 'replication_factor' : 2 };

    cqlsh> describe keyspaces;

    system_schema  system_auth  system  hardware  system_distributed  system_traces

* Create a table with test content and view the data using the following commands.

::

    cqlsh> use hardware;

    cqlsh:hardware> create table inventory (id uuid,Name text,HWtype text,Model text,PRIMARY KEY ((id), Name));

    cqlsh:hardware> insert into inventory (id, Name, HWType, Model) values (5132b130-ae79-11e4-ab27-0800200c9a66, 'TestBox', 'Server', 'DellR820');

    cqlsh:hardware> select * from inventory;

    id                                   | name    | hwtype | model
    ---------------------------------------+---------+--------+----------
    5132b130-ae79-11e4-ab27-0800200c9a66 | TestBox | Server | DellR820

    (1 rows) 
    
* Flush the data to ensure it is written to a disk from the memtable (memory) using the following command.

::

    test@Master:$ kubectl exec cassandra-0 -- nodetool flush hardware

4. Delete the Test Keyspace
-----------------------------

* Verify the masterless nature of Cassandra StatefulSet by deleting the keyspace from another replica, in this example, Cassandra-1.
::

    test@Master:~$ cqlsh 10.36.0.6 9042 --cqlversion="3.4.2"

    cqlsh> use hardware;
    cqlsh:hardware> select * from Inventory;

    id                                   | name    | hwtype | model
    --------------------------------------+---------+--------+----------
    5132b130-ae79-11e4-ab27-0800200c9a66 | TestBox | Server | DellR820

    (1 rows)

    cqlsh> drop keyspace hardware;

* Verify that the keyspace is deleted successfully using the following command.
::

    cqlsh> describe keyspaces

    system_traces  system_schema  system_auth  system  system_distributed