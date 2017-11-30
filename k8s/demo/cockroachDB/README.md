# CockroachDB

This document demonstrates the deployment of CockroachDB as a StatefulSet in a Kubernetes cluster. The user will be able to spawn a CockroachDB StatefulSet that will use OpenEBS as its persistent storage.

## Deploy as a StatefulSet

Deploying CockroachDB as a StatefulSet provides the following benefits:

- Stable unique network identifiers.
- Stable persistent storage.
- Ordered graceful deployment and scaling.
- Ordered graceful deletion and termination.

## Deploy CockroachDB with Persistent Storage

Before getting started check the status of the cluster:

```bash
ubuntu@kubemaster:~kubectl get nodes
NAME            STATUS    AGE       VERSION
kubemaster      Ready     3d        v1.8.2
kubeminion-01   Ready     3d        v1.8.2
kubeminion-02   Ready     3d        v1.8.2

```

Download and Apply the CockroachDB YAMLs from OpenEBS repository:

```bash

ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/cockroachDB/cockroachdb-sc.yaml
ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/cockroachDB/cockroachdb-sts.yaml
ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/cockroachDB/cockroachdb-svc.yaml

ubuntu@kubemaster:~kubectl apply -f cockroachdb-sc.yaml
ubuntu@kubemaster:~kubectl apply -f cockroachdb-sts.yml
ubuntu@kubemaster:~kubectl apply -f cockroachdb-svc.yml
```

Get the status of running pods:

```bash
ubuntu@kubemaster:~$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
cockroachdb-0                                                    1/1       Running   0          22h
cockroachdb-1                                                    1/1       Running   0          21h
cockroachdb-2                                                    1/1       Running   0          21h
maya-apiserver-5f744bdcbc-q5lbb                                  1/1       Running   0          22h
openebs-provisioner-6fd9458d96-spvws                             1/1       Running   0          22h
pvc-42e9cafc-d4d7-11e7-8d7b-000c29119159-ctrl-6c8654f6f9-4m7jb   2/2       Running   0          21h
pvc-42e9cafc-d4d7-11e7-8d7b-000c29119159-rep-7c89c65dd4-p4l6w    1/1       Running   0          21h
pvc-42e9cafc-d4d7-11e7-8d7b-000c29119159-rep-7c89c65dd4-wmwl2    1/1       Running   0          21h
pvc-7005a715-d4d7-11e7-8d7b-000c29119159-ctrl-7944b78f8f-r575t   2/2       Running   0          21h
pvc-7005a715-d4d7-11e7-8d7b-000c29119159-rep-84746c8dbf-glrhq    1/1       Running   0          21h
pvc-7005a715-d4d7-11e7-8d7b-000c29119159-rep-84746c8dbf-l6zlr    1/1       Running   0          21h
pvc-ef78ba18-d4d6-11e7-8d7b-000c29119159-ctrl-78f6c95f87-w8tgq   2/2       Running   0          22h
pvc-ef78ba18-d4d6-11e7-8d7b-000c29119159-rep-649d9fd578-rxthz    1/1       Running   0          22h
pvc-ef78ba18-d4d6-11e7-8d7b-000c29119159-rep-649d9fd578-wp6xc    1/1       Running   0          22h

```

Get the status of running StatefulSet:

```bash
ubuntu@kubemaster:~$ kubectl get statefulset
NAME          DESIRED   CURRENT   AGE
cockroachdb   3         3         22h

```

Get the status of underlying persistent volume being used by CockroachDB StatefulSet:

```bash
ubuntu@kubemaster:~$ kubectl get pvc
NAME                    STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
datadir-cockroachdb-0   Bound     pvc-ef78ba18-d4d6-11e7-8d7b-000c29119159   10Gi       RWO            openebs-cockroachdb   22h
datadir-cockroachdb-1   Bound     pvc-42e9cafc-d4d7-11e7-8d7b-000c29119159   10Gi       RWO            openebs-cockroachdb   22h
datadir-cockroachdb-2   Bound     pvc-7005a715-d4d7-11e7-8d7b-000c29119159   10Gi       RWO            openebs-cockroachdb   22h

```

Get the status of the services:

```bash
ubuntu@kubemaster:~kubectl get svc
NAME                                                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
cockroachdb                                         ClusterIP   None             <none>        26257/TCP,8080/TCP   22h
cockroachdb-public                                  ClusterIP   10.98.208.2      <none>        26257/TCP,8080/TCP   22h
kubernetes                                          ClusterIP   10.96.0.1        <none>        443/TCP              20d
maya-apiserver-service                              ClusterIP   10.98.148.4      <none>        5656/TCP             22h
pvc-42e9cafc-d4d7-11e7-8d7b-000c29119159-ctrl-svc   ClusterIP   10.96.109.197    <none>        3260/TCP,9501/TCP    22h
pvc-7005a715-d4d7-11e7-8d7b-000c29119159-ctrl-svc   ClusterIP   10.105.222.30    <none>        3260/TCP,9501/TCP    22h
pvc-ef78ba18-d4d6-11e7-8d7b-000c29119159-ctrl-svc   ClusterIP   10.110.107.240   <none>        3260/TCP,9501/TCP    22h

```

## Test your Database

### Use the built-in SQL Client

1. Launch a temporary interactive pod and start the built-in SQL client inside it:

```bash
ubuntu@kubemaster:~kubectl run cockroachdb -it --image=cockroachdb/cockroach --rm --restart=Never -- sql --insecure --host=cockroachdb-public
```

2. Run some basic CockroachDB SQL statements:

```sql
> CREATE DATABASE bank;

> CREATE TABLE bank.accounts (id INT PRIMARY KEY, balance DECIMAL);

> INSERT INTO bank.accounts VALUES (1, 1000.50);

> SELECT * FROM bank.accounts;

+----+---------+
| id | balance |
+----+---------+
|  1 |  1000.5 |
+----+---------+
(1 row)

```

3. Exit the SQL shell:

```sql
>\q
```

### Use a Load Generator

1. Download and Apply the CockroachDB load generator from OpenEBS repository:

```bash

ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/cockroachDB/cockroachdb-lg.yaml

ubuntu@kubemaster:~kubectl apply -f cockroachdb-lg.yaml
```

2. Get the status of the job.

```bash
ubuntu@kubemaster:~kubectl get jobs
NAME            DESIRED   SUCCESSFUL      AGE
cockroachdb-lg     1         0            2m
```

3. This is a Kubernetes Job YAML which creates a database called _test_ with a table called _kv_ containing random k:v pairs.

4. The Kubernetes Job will run for a duration of 5 minutes, which is a configurable value in the YAML.

5. Launch a temporary interactive pod and start the built-in SQL client inside it:

```bash
ubuntu@kubemaster:~kubectl run cockroachdb -it --image=cockroachdb/cockroach --rm --restart=Never -- sql --insecure --host=cockroachdb-public
```

6. Set the default database as _test_ and display the contents of the _kv_ table.

```sql
> SHOW DATABASES;
+--------------------+
|      Database      |
+--------------------+
| crdb_internal      |
| information_schema |
| pg_catalog         |
| system             |
| test               |
+--------------------+
(5 rows)

Time: 7.084556ms

> SET DATABASE=test;
SET

Time: 6.169867ms

test> SELECT * FROM test.kv LIMIT 10;
+----------------------+--------+
|          k           |   v    |
+----------------------+--------+
| -9223282596810038725 | "\x85" |
| -9223116438301212725 | "\xb4" |
| -9222613679950113217 | *      |
| -9222209701222264670 | G      |
| -9222188216226059435 | j      |
| -9221992469291086418 | y      |
| -9221747069894991943 | "\x82" |
| -9221352569080615127 | "\x1e" |
| -9221294188251221564 | "\xe3" |
| -9220587135773113226 | "\x94" |
+----------------------+--------+
(10 rows)

Time: 98.004199ms

test> SELECT COUNT(*) FROM test.kv;
+----------+
| count(*) |
+----------+
|    59814 |
+----------+
(1 row)

Time: 438.68592ms

```

7. Exit the SQL shell:

```sql
>\q
```