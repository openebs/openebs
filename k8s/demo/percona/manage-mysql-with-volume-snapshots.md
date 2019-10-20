# Manage MySQL With Database Volume Snapshots

This tutorial provides instructions to create point-in-time snapshots of a MySQL instance and restore database from existing snapshots.

## Prerequisite

- A fully configured Kubernetes cluster running the Percona-MySQL deployment with OpenEBS storage class (You can use the sample
deployment specification *percona-openebs-deployment.yml* available in this directory).

```
test@Master:~$ kubectl get pods
NAME                                                             READY     STATUS              RESTARTS   AGE
maya-apiserver-3416621614-g6tmq                                  1/1       Running             1          7d
openebs-provisioner-4230626287-503dv                             1/1       Running             1          7d
percona-1869177642-x89sb                                         1/1       Running             0          2m
pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc-ctrl-3041181545-q5jzf   1/1       Running             0          2m
pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc-rep-3963308777-15g3p    1/1       Running             0          2m
pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc-rep-3963308777-dskm9    1/1       Running             0          2m
```

All the steps described should be performed on the Kubernetes master, unless specified otherwise.

## Step-1: Create a test database

- Run an interactive shell for the Percona-MySQL pod using the kubectl exec command.

  ```
  test@Master:~$ kubectl exec -it percona-1869177642-x89sb /bin/bash
  root@percona-1869177642-x89sb:/#
  ```
- Create a test database with a data record using the mysql client.

  ```
  root@percona-1869177642-x89sb:/# mysql -uroot -pk8sDem0;
  mysql: [Warning] Using a password on the command line interface can be insecure.
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 3
  Server version: 5.7.19-17 Percona Server (GPL), Release '17', Revision 'e19a6b7b73f'

  Copyright (c) 2009-2017 Percona LLC and/or its affiliates
  Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.

  Oracle is a registered trademark of Oracle Corporation and/or its
  affiliates. Other names may be trademarks of their respective
  owners.

  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

  mysql> create database testdb;
  Query OK, 1 row affected (0.00 sec)

  mysql> show databases;
  +--------------------+
  | Database           |
  +--------------------+
  | information_schema |
  | mysql              |
  | performance_schema |
  | sys                |
  | testdb             |
  +--------------------+
  5 rows in set (0.00 sec)

  mysql> use testdb;
  Database changed

  mysql> CREATE TABLE Hardware (Name VARCHAR(20),HWtype VARCHAR(20),Model VARCHAR(20));
  Query OK, 0 rows affected (0.16 sec)

  mysql>
  mysql> INSERT INTO Hardware (Name,HWtype,Model) VALUES ('TestBox','Server','DellR820');
  Query OK, 1 row affected (0.01 sec)

  mysql>
  mysql> select * from Hardware;
  +---------+--------+----------+
  | Name    | HWtype | Model    |
  +---------+--------+----------+
  | TestBox | Server | DellR820 |
  +---------+--------+----------+
  1 row in set (0.00 sec)


  mysql> exit
  Bye
  root@percona-1869177642-x89sb:/#
  root@percona-1869177642-x89sb:/# exit
  ```

## Step-2: Creating MySQL Database Volume Snapshot

- Identify the name of the MySQL data volume by executing the following mayactl command. Typically, the
OpenEBS pod names are derived from the volume name, with the string before the "ctrl" or "rep" representing the volume name.

  ```
  test@Master:~$ kubectl exec maya-apiserver-3416621614-g6tmq -c maya-apiserver -- maya volume list
  Name                                      Status
  pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc  Running
  ```
- Create the volume snapshot by executing the following mayactl command

  ```
  test@Master:~$ kubectl exec maya-apiserver-3416621614-g6tmq -c maya-apiserver -- maya snapshot create -volname pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc -snapname snap1

  Creating Snapshot of Volume : pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc
  Created Snapshot is: snap1
  ```

## Step-3: Make changes to MySQL server

- Delete the test database created in the previous steps.

  ```
  test@Master:~$ kubectl exec -it percona-1869177642-x89sb /bin/bash
  root@percona-1869177642-x89sb:/#

  root@percona-1869177642-x89sb:/# mysql -uroot -pk8sDem0;
  :
  mysql> drop database testdb;
  Query OK, 1 row affected (0.73 sec)

  mysql> show databases;
  +--------------------+
  | Database           |
  +--------------------+
  | information_schema |
  | mysql              |
  | performance_schema |
  | sys                |
  +--------------------+
  4 rows in set (0.00 sec)

  mysql> exit
  Bye
  ```

## Step-4: Restore snapshot on the OpenEBS storage volume

- Revert to snapshot created by executing the following mayactl command

  ```
  test@Master:~$ kubectl exec maya-apiserver-3416621614-g6tmq -c maya-apiserver -- maya snapshot create -volname pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc -snapname snap1
  Snapshot reverted: snap1
  ```

## Step-5: Delete the Percona pod to force reschedule and remount

- The changes caused by the snapshot restore operation on the database can be viewed only when the data volume is remounted.
This can be achieved if the pod is rescheduled. To force a reschedule, delete the pod (since Percona application has been
launched as a Kubernetes deployment, the pod will be rescheduled/recreated on either the same OR on other nodes if available).

  ```
  test@Master:~$ kubectl delete pod percona-1869177642-x89sb
  pod "percona-1869177642-x89sb" deleted
  ```
  Verify that the pod is rescheduled and has restarted successfully

  ```
  test@Master:~$ kubectl get pods
  NAME                                                             READY     STATUS              RESTARTS   AGE
  maya-apiserver-3416621614-g6tmq                                  1/1       Running             1          7d
  openebs-provisioner-4230626287-503dv                             1/1       Running             1          7d
  percona-1869177642-llgj5                                         1/1       Running             0          2m
  pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc-ctrl-3041181545-q5jzf   1/1       Running             0          2m
  pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc-rep-3963308777-15g3p    1/1       Running             0          2m
  pvc-44f45e05-c61f-11e7-a0eb-000c298ff5fc-rep-3963308777-dskm9    1/1       Running             0          2m
  ```

## Step-6: Verify successful restore of database

- Verify that the database "testdb" created before snapshot was taken is present. Read the table content to confirm successful
restore.

  ```
  test@Master:~$ kubectl exec -it percona-1869177642-llgj5 /bin/bash
  root@percona-1869177642-llgj5:/#
  ```
  ```
  root@percona-1869177642-llgj5:/# mysql -uroot -pk8sDem0;
  mysql: [Warning] Using a password on the command line interface can be insecure.
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 3
  Server version: 5.7.19-17 Percona Server (GPL), Release '17', Revision 'e19a6b7b73f'

  Copyright (c) 2009-2017 Percona LLC and/or its affiliates
  Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.

  Oracle is a registered trademark of Oracle Corporation and/or its
  affiliates. Other names may be trademarks of their respective
  owners.

  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

  mysql> show databases;
  +--------------------+
  | Database           |
  +--------------------+
  | information_schema |
  | mysql              |
  | performance_schema |
  | sys                |
  | testdb             |
  +--------------------+
  5 rows in set (0.00 sec)

  mysql> use testdb;
  Database changed

  mysql> select * from Hardware;
  +---------+--------+----------+
  | Name    | HWtype | Model    |
  +---------+--------+----------+
  | TestBox | Server | DellR820 |
  +---------+--------+----------+
  1 row in set (0.00 sec)

  mysql> exit
  Bye
  root@percona-1869177642-llgj5:/#
  root@percona-1869177642-llgj5:/# exit

## Notes

- If the above procedure is repeated with a larger database load, ensure that the ```flush tables with read lock;``` query is executed
before the snapshot is created. This will flush tables to disk and ensure there are no pending/in-flight queries. Subsequent modifications
to the database can be carried out after executing the ```unlock tables``` query.











