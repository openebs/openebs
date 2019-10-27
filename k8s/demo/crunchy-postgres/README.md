# Running Crunchy-Postgres with OpenEBS

This tutorial provides detailed instructions to run a PostgreSQL StatefulSet with OpenEBS storage and perform 
simple database operations to verify successful deployment. 

## Crunchy-Postgres 

The postgres container used in the StatefulSet is sourced from [CrunchyData](https://github.com/CrunchyData/crunchy-containers). CrunchyData provides cloud agnostic PostgreSQL container technology that is designed for production 
workloads with cloud native High Availability, Disaster Recovery, and monitoring.  

## Prerequisite

A fully configured (preferably, multi-node) Kubernetes cluster configured with the OpenEBS operator and OpenEBS
storage classes.

```
test@Master:~/crunchy-postgres$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
maya-apiserver-2245240594-ktfs2                                  1/1       Running   0          3h
openebs-provisioner-4230626287-t8pn9                             1/1       Running   0          3h
```

## Deploy the Crunchy-Postgres StatefulSet with OpenEBS Storage

The StatefulSet specification JSONs are available at OpenEBS/k8s/demo/crunchy-postgres. 

The number of replicas in the StatefulSet can be modified in the *set.json* file. This example uses 2 replicas, 
which includes one master and one slave. The Postgres pods are configured as primary/master or as replica/slave by 
a startup script which decides the role based on ordinality assigned to the pod.

```
{
  "apiVersion": "apps/v1beta1",
  "kind": "StatefulSet",
  "metadata": {
    "name": "pgset"
  },
  "spec": {
    "serviceName": "pgset",
    "replicas": 2,
    "template": {
      "metadata": {
        "labels": {
          "app": "pgset"
        }
      },
:
```

Execute the following commands: 

```
test@Master:~$ cd openebs/k8s/demo/crunchy-postgres/

test@Master:~/openebs/k8s/demo/crunchy-postgres$  ls -ltr
total 32
-rw-rw-r-- 1 test test  300 Nov 14 16:27 set-service.json
-rw-rw-r-- 1 test test   97 Nov 14 16:27 set-sa.json
-rw-rw-r-- 1 test test  558 Nov 14 16:27 set-replica-service.json
-rw-rw-r-- 1 test test  555 Nov 14 16:27 set-master-service.json
-rw-rw-r-- 1 test test 1879 Nov 14 16:27 set.json
-rwxrwxr-x 1 test test 1403 Nov 14 16:27 run.sh
-rw-rw-r-- 1 test test 1292 Nov 14 16:27 README.md
-rwxrwxr-x 1 test test  799 Nov 14 16:27 cleanup.sh
```

```
test@Master:~/crunchy-postgres$ ./run.sh
+++ dirname ./run.sh
++ cd .
++ pwd
+ DIR=/home/test/openebs/k8s/demo/crunchy-postgres
+ kubectl create -f /home/test/openebs/k8s/demo/crunchy-postgres/set-sa.json
serviceaccount "pgset-sa" created
+ kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts
clusterrolebinding "permissive-binding" created
+ kubectl create -f /home/test/openebs/k8s/demo/crunchy-postgres/set-service.json
service "pgset" created
+ kubectl create -f /home/test/openebs/k8s/demo/crunchy-postgres/set-primary-service.json
service "pgset-primary" created
+ kubectl create -f /home/test/openebs/k8s/demo/crunchy-postgres/set-replica-service.json
service "pgset-replica" created
+ kubectl create -f /home/test/openebs/k8s/demo/crunchy-postgres/set.json
statefulset "pgset" created
```

Verify that all the OpenEBS persistent volumes are created and the Crunchy-Postgres services and pods are running. 

```
test@Master:~/crunchy-postgres$ kubectl get statefulsets
NAME      DESIRED   CURRENT   AGE
pgset     2         2         15m

test@Master:~/crunchy-postgres$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
maya-apiserver-2245240594-ktfs2                                  1/1       Running   0          3h
openebs-provisioner-4230626287-t8pn9                             1/1       Running   0          3h
pgset-0                                                          1/1       Running   0          3m
pgset-1                                                          1/1       Running   0          3m
pvc-17e21bd3-c948-11e7-a157-000c298ff5fc-ctrl-3572426415-n8ctb   1/1       Running   0          3m
pvc-17e21bd3-c948-11e7-a157-000c298ff5fc-rep-3113668378-9437w    1/1       Running   0          3m
pvc-17e21bd3-c948-11e7-a157-000c298ff5fc-rep-3113668378-xnt12    1/1       Running   0          3m
pvc-1e96a86b-c948-11e7-a157-000c298ff5fc-ctrl-2773298268-x3dlb   1/1       Running   0          3m
pvc-1e96a86b-c948-11e7-a157-000c298ff5fc-rep-723453814-hpkw3     1/1       Running   0          3m
pvc-1e96a86b-c948-11e7-a157-000c298ff5fc-rep-723453814-tpjqm     1/1       Running   0          3m

test@Master:~/crunchy-postgres$ kubectl get svc
NAME                                                CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
kubernetes                                          10.96.0.1        <none>        443/TCP             4h
maya-apiserver-service                              10.98.249.191    <none>        5656/TCP            3h
pgset                                               None             <none>        5432/TCP            14m
pgset-primary                                       10.104.32.113    <none>        5432/TCP            14m
pgset-replica                                       10.99.40.69      <none>        5432/TCP            14m
pvc-17e21bd3-c948-11e7-a157-000c298ff5fc-ctrl-svc   10.111.243.121   <none>        3260/TCP,9501/TCP   14m
pvc-1e96a86b-c948-11e7-a157-000c298ff5fc-ctrl-svc   10.102.138.94    <none>        3260/TCP,9501/TCP   13m


test@Master:~/crunchy-postgres$ kubectl get clusterrolebinding permissive-binding
NAME                 AGE
permissive-binding   15m
test@Master:~/crunchy-postgres$
```

Note: It may take some time for the pods to start as the images must be pulled and instantiated. This is also
dependent on the network speed.


## Verify Successful Crunchy-Postgres Deployment

The verification procedure can be carried out using the following steps: 

- Check cluster replication status between the Postgres primary and replica
- Create a table in the default database as Postgres user "testuser" on the primary
- Check data synchronization on the replica for the table you have created
- Verify that table is not created on the replica

### Step-1: Install the PostgreSQL-Client

Install the PostgreSQL Client Utility (psql) on any of the Kubernetes machines to perform database operations 
from the command line. 

```
sudo apt-get install postgresql-client
```

### Step-2: Verify Cluster Replication Status on Crunchy-Postgres Cluster

Identify the IP Address of the primary (pgset-0) pod or the service (pgset-primary) and execute the following
query:

```
test@Master:~$ psql -h 10.47.0.3 -U testuser postgres -c 'select * from pg_stat_replication'

 pid | usesysid |   usename   | application_name | client_addr | client_hostname | client_port |         backend_start         | backend_xmin |   state   | sent_lsn  | write_lsn | flush_lsn | replay_lsn | write_lag | flush_lag | replay_lag | sync_priority | sync_state
-----+----------+-------------+------------------+-------------+-----------------+-------------+-------------------------------+--------------+-----------+-----------+-----------+-----------+------------+-----------+-----------+------------+---------------+------------
  94 |    16391 | primaryuser | pgset-1          | 10.44.0.0   |                 |       60460 | 2017-11-14 09:29:21.990782-05 |              | streaming | 0/3014278 | 0/3014278 | 0/3014278 | 0/3014278  |           |           |            |             0 | async
(1 row)
```

The replica should be registered for "asynchronous" replication. 

### Step-3: Create a Table with Test Content on the Default Database 

These queries should be executed on the primary.

```
test@Master:~$ psql -h 10.47.0.3 -U testuser postgres -c 'create table foo(id int)'
Password for user testuser:
CREATE TABLE
```
```
test@Master:~/crunchy-postgres$ psql -h 10.47.0.3 -U testuser postgres -c 'insert into foo values (1)'
Password for user testuser:
INSERT 0 1
```

### Step-4: Verify Data Synchronization on Replica

Identify the IP Address of the replica (pgset-1) pod or the service (pgset-replica) and execute the following
command: 

```
test@Master:~$ psql -h 10.44.0.6 -U testuser postgres -c 'table foo'
Password for user testuser:
 id
----
  1
(1 row)
```

Verify that the table content is replicated successfully.

### Step-5: Verify Database Write Restricted on Replica

Attempt to create a new table on the replica, and verify that the creation is unsuccessful.

```
test@Master:~$ psql -h 10.44.0.6 -U testuser postgres -c 'create table bar(id int)'
Password for user testuser:
ERROR:  cannot execute CREATE TABLE in a read-only transaction
```


