Prerequisites
===============
Prerequisites include the following:
    
* A fully configured Kubernetes cluster (versions 1.6.3/4/6 and 1.7.0 have been tested) with kube master and at least one kube node. This maybe created on cloud platforms like GKE, on-premise virtual machines (vagrant/VMware/Hyper-V) or bare-metal boxes.

**Note:**

    * OpenEBS recommends using a 3-node cluster, with one master and two nodes. This aids in creating storage replicas on separate nodes and is helpful in maintaining redundancy and data availability.

    * If you are using gcp, view the appendix in this section for additional steps to set up cluster administration context and use it.

Verify that the Kubernetes cluster is in optimal state by using the following commands.

:: 
  
   name@Master:~$ kubectl get nodes
   NAME         STATUS    AGE       VERSION
   host01   Ready     5d        v1.6.3
   host02   Ready     5d        v1.6.3
   master   Ready     5d        v1.6.3

* Sufficient resources on the nodes to host the OpenEBS storage pods and Percona application pods - This includes sufficient disk space, in this example, physical storage for the pvolume containers will be carved out from the local storage.

* iSCSI support on the nodes - This is required for being able to consume the iSCSI target exposed by the OpenEBS volume container (that is, VSM). In ubuntu, you can install the iSCSI initiator using the following procedure.

::
  
    sudo apt-get update
    sudo apt-get install open-iscsi
    sudo service open-iscsi restart

Verify that iSCSI is configured using the following commands.

::
  
    sudo cat /etc/iscsi/initiatorname.iscsi
    sudo service open-iscsi status  

Run OpenEBS Operator
=====================
Download the latest OpenEBS operator files and sample *percona-mysql* application pod yaml on the kubemaster from the OpenEBS git repository.

::

    git clone https://github.com/openebs/openebs.git
    cd openebs/k8s

Apply openebs-operator on the Kubernetes cluster. This creates the maya api-server and openebs provisioner deployments.

::
  
    kubectl apply -f openebs-operator.yaml

Add the OpenEBS storage classes using the following command, that can then be used by developers to map a suitable storage profile for their applications in their respective persistent volume claims.    

::
  
    kubectl apply -f openebs-storageclasses.yaml


Check whether the deployments are running successfully using the following commands.

::
  
    name@Master:~$ kubectl get deployments
    NAME                                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    maya-apiserver                                  1         1         1            1           2m
    openebs-provisioner                             1         1         1            1           2m
  
::
  
    name@Master:~$ kubectl get pod
    NAME                                   READY     STATUS    RESTARTS   AGE
    maya-apiserver-1633167387-5ss2w        1/1       Running   0          24s
    openebs-provisioner-1174174075-f2ss6   1/1       Running   0          23s


Check whether the storage classes are applied successfully using the following commands.

::
  
    name@Master:~$ kubectl get sc
    NAME              TYPE
    openebs-basic     openebs.io/provisioner-iscsi
    openebs-jupyter   openebs.io/provisioner-iscsi
    openebs-percona   openebs.io/provisioner-iscsi

**See Also:**

`Setting Up OpenEBS - Overview`_.

.. _Setting Up OpenEBS - Overview: http://openebs.readthedocs.io/en/latest/install/install_overview.html

Percona DB
===========
Running Percona Pod on OpenEBS
---------------------------------
This section provides detailed instructions on how to run a *percona-mysql* application pod on OpenEBS storage in a Kubernetes cluster and uses a *mysql-client* container to generate load (in the form of insert and select DB queries) in order to illustrate input/output traffic on the storage.
    
Run percona-mysql Pod with OpenEBS Storage
--------------------------------------------
Use OpenEBS as persistent storage for the percona pod by selecting an OpenEBS storage class in the persistent volume claim. A sample percona pod yaml (with container attributes and pvc details) is available in the OpenEBS git repository (which was cloned in the previous steps).

Apply the percona pod yaml using the following commands.

::

   cd demo/percona
   kubectl apply -f demo-percona-mysql-pvc.yaml

Verify that the OpenEBS storage pods, that is, the jiva controller and jiva replicas are created and the percona pod is running successfully using the following commands.

::
 
   name@Master:~$ kubectl get pods
   NAME                                                             READY     STATUS    RESTARTS   AGE
   maya-apiserver-1633167387-5ss2w                                  1/1       Running   0          4m
   openebs-provisioner-1174174075-f2ss6                             1/1       Running   0          4m
   percona                                                          1/1       Running   0          2m
   pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc-ctrl-2825810277-rjmxh   1/1       Running   0          2m
   pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc-rep-2644468602-92lfg    1/1       Running   0          2m
   pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc-rep-2644468602-rm8mz    1/1       Running   0          2m

**Note:**

It may take some time for the pods to start as the images must be pulled and instantiated. This is also dependent on the network speed.

Run a Database Client Container to Generate SQL Load
------------------------------------------------------

To test the pod, you can run a Kubernetes job, in which a mysql client container runs a load generation script (which in turn performs simple sql queries) to simulate storage traffic. Run the following procedure on any node in the Kubernetes cluster.

Get the IP address of the percona application pod. You can obtain this by executing kubectl describe on the percona pod.

::

    name@Master:~$ kubectl describe pod percona | grep IP
    IP:             10.44.0.3

Edit the following line in sql-loadgen job yaml to pass the desired load duration and percona pod IP as arguments. In this example, the job performs sql queries on pod with IP address 10.44.0.3 for 300s.

::

    args: ["-c", "timelimit -t 300 sh MySQLLoadGenerate.sh 10.44.0.3 > /dev/null 2>&1; exit 0"]

Run the load generation job using the following command.

::

    kubectl apply -f sql-loadgen.yaml


View Performance and Storage Consumption Statistics Using mayactl
--------------------------------------------------------------------

Performance and capacity usage statistics on the OpenEBS storage volume can be viewed by executing the following *mayactl* command inside the maya-apiserver pod. 

Start an interactive bash console for the maya-apiserver container using the following command.

::
   
     kubectl exec -it maya-apiserver-1633167387-5ss2w /bin/bash

Lookup the storage volume name using the *volume list* command

::

    name@Master:~$ kubectl exec -it maya-apiserver-1633167387-5ss2w /bin/bash

    root@maya-apiserver-1633167387-5ss2w:/# maya volume list
    Name                                      Status
    pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc  Running

Get the performance and capacity usage statistics using the *volume stats* command.

::

    root@maya-apiserver-1633167387-5ss2w:/# maya volume stats pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc
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

The above command can be invoked using the *watch* command by providing a desired interval to continuously monitor statistics.

::

   watch -n 1 maya volume stats pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc

Jupyter
=========
 
Running Jupyter on OpenEBS
---------------------------

This section provides detailed instructions on how to run a jupyter pod on OpenEBS storage in a Kubernetes cluster and uses a *jupyter ui editor* to generate load in order to illustrate input/output traffic on the storage.

Run Jupyter Pod with OpenEBS Storage
--------------------------------------
Use OpenEBS as persistent storage for the jupyter pod by selecting an OpenEBS storage class in the persistent volume claim. A sample jupyter pod yaml (with container attributes and pvc details) is available in the OpenEBS git repository (which was cloned in the previous steps).
::
   name@Master:~$ cat demo-jupyter-openebs.yaml
   ..
   kind: PersistentVolumeClaim
   apiVersion: v1
   metadata:
     name: jupyter-data-vol-claim
   spec:
     storageClassName: openebs-jupyter
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 5G
    ..

Apply the jupyter pod yaml using the following command.

::

   name@Master:~$ kubectl apply -f demo-jupyter-openebs.yaml
   deployment "jupyter-server" created
   persistentvolumeclaim "jupyter-data-vol-claim" created
   service "jupyter-service" created

The above command creates the following, which can be verified using the corresponding kubectl commands.

- Launches a Jupyter Server, with the specified notebook file from github (kubectl get deployments)
- Creates an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data) (kubectl get pvc) (kubectl get pv) (kubectl get pods)
- Exposes the Jupyter Server to external world via the http://<NodeIP>:32424 (NodeIP is any of the nodes external IP) (kubectl get pods)   

Verify that the OpenEBS storage pods, that is, the jiva controller and jiva replicas are created and the jupyter pod is running successfully using the following commands.

::
 
   name@Master:~$ kubectl get pods
   NAME                                                             READY     STATUS    RESTARTS   AGE
   jupyter-server-2764185079-s371g                                  1/1       Running   0          13m
   maya-apiserver-1633167387-845fd                                  1/1       Running   0          15d
   openebs-provisioner-1174174075-c78sj                             1/1       Running   1          15d
   pvc-5467cfe7-a29e-11e7-b4df-000c298ff5fc-ctrl-2903536303-75h3j   1/1       Running   0          13m
   pvc-5467cfe7-a29e-11e7-b4df-000c298ff5fc-rep-2383373508-bh0d3    1/1       Running   0          13m
   pvc-5467cfe7-a29e-11e7-b4df-000c298ff5fc-rep-2383373508-s1kzz    1/1       Running   0          13m

**Note:**

It may take some time for the pods to start as the images must be pulled and instantiated. This is also dependent on the network speed.

The jupyter server dashboard can be accessed on the Kubernetes node port as in the following screen.

.. image:: https://raw.githubusercontent.com/openebs/openebs/master/documentation/source/_static/Jupyter.png

Crunchy Postgres
=================
 
Running Crunchy Postgres on OpenEBS
------------------------------------

The following steps bring up a postgresql stateful set with one master and one replica on OpenEBS storage. This example uses centos-based postgresql containers from crunchy data to illustrate the same.  

Download the files to your host, which has access to kubectl using the following commands.
::
  
  cd $HOME
  git clone https://github.com/openebs/openebs.git
  cd openebs/k8s/demo/crunchy-postgres

The size of the OpenEBS persistent storage volume is 400M by default. You can edit the size in the storage class section of the *set.json* specification file.
::
  
  cat set.json
  ..
  "volumeClaimTemplates": [
  {
  "metadata": {
  "name": "pgdata"
  },
  "spec": {
  "accessModes": [
  "ReadWriteOnce"
  ],
  "storageClassName": "openebs-basic",
  "resources": {
  "requests": {
  "storage": "400M"
  }
  }
  }
  }
  ..

Run the StatefulSet using the following command. The files are available with default images and credentials (*set.json*). The following command will automatically create the OpenEBS volumes required for master and replica postgresql containers.
::
  
  ./run.sh

Volume details can be inspected using the following standard kubectl commands.
::
    
    kubectl get pvc
    kubectl get pv

References
------------

The k8s spec files are based on the files provided by `CrunchyData StatefulSet with Dynamic Provisioner`_.

.. _CrunchyData StatefulSet with Dynamic Provisioner: https://github.com/CrunchyData/crunchy-containers/tree/master/examples/kube/statefulset-dyn

Kubernetes Blog for running `Clustered PostgreSQL using StatefulSet`_.

.. _Clustered PostgreSQL using StatefulSet: http://blog.kubernetes.io/2017/02/postgresql-clusters-kubernetes-statefulsets.html
