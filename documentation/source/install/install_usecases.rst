  
 **********************
 Usecases - Percona DB
 **********************

Running Percona Pod on OpenEBS
===============================
This section provides detailed instructions on how to run a *percona-mysql* application pod on OpenEBS storage in a Kubernetes cluster and uses a *mysql-client* container to generate load (in the form of insert and select DB queries) in order to illustrate input/output traffic on the storage.

Prerequisites
-------------
Prerequisites include the following:
    
* A fully configured Kubernetes cluster (versions 1.6.3/4/6 and 1.7.0 have been tested) with kube master and at least one kube minion. This maybe created on cloud platforms like GKE, on-premise virtual machines (vagrant/VMware/Hyper-V) or bare-metal boxes.

**Note:**

    * OpenEBS recommends using a 3-node cluster, with one master and two minions. This aids in creating storage replicas on separate minion nodes and is helpful in maintaining redundancy and data availability.

    * If you are using gcp, view the appendix in this section for additional steps to set up cluster administration context and use it.

Verify that the Kubernetes cluster is in optimal state by using the following commands.

:: 
  
   name@MayaMaster:~$ kubectl get nodes
   NAME         STATUS    AGE       VERSION
   mayahost01   Ready     5d        v1.6.3
   mayahost02   Ready     5d        v1.6.3
   mayamaster   Ready     5d        v1.6.3

* Sufficient resources on the minions to host the OpenEBS storage pods and Percona application pods - This includes sufficient disk space, in this example, physical storage for the pvolume containers will be carved out from the local storage.

* iSCSI support on the minions - This is required for being able to consume the iSCSI target exposed by the OpenEBS volume container (that is, VSM). In ubuntu, you can install the iSCSI initiator using the following procedure.

::
  
    sudo apt-get update
    sudo apt-get install open-iscsi
    sudo service open-iscsi restart

Verify that iSCSI is configured using the following commands.

::
  
    sudo cat /etc/iscsi/initiatorname.iscsi
    sudo service open-iscsi status  

Run OpenEBS Operator
--------------------
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
  
    name@MayaMaster:~$ kubectl get deployments
    NAME                                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    maya-apiserver                                  1         1         1            1           2m
    openebs-provisioner                             1         1         1            1           2m
  
::
  
    name@MayaMaster:~$ kubectl get pod
    NAME                                   READY     STATUS    RESTARTS   AGE
    maya-apiserver-1633167387-5ss2w        1/1       Running   0          24s
    openebs-provisioner-1174174075-f2ss6   1/1       Running   0          23s


Check whether the storage classes are applied successfully using the following commands.

::
  
    name@MayaMaster:~$ kubectl get sc
    NAME              TYPE
    openebs-basic     openebs.io/provisioner-iscsi
    openebs-jupyter   openebs.io/provisioner-iscsi
    openebs-percona   openebs.io/provisioner-iscsi

    
Run percona-mysql Pod with OpenEBS Storage
------------------------------------------
Use OpenEBS as persistent storage for the percona pod by selecting an OpenEBS storage class in the persistent volume claim. A sample percona pod yaml (with container attributes and pvc details) is available in the OpenEBS git repository (which was cloned in the previous steps).

Apply the percona pod yaml using the following commands.

::

   cd demo/percona
   kubectl apply -f demo-percona-mysql-pvc.yaml

Verify that the OpenEBS storage pods, that is, the jiva controller and jiva replicas are created and the percona pod is running succesfully using the following commands.

::
 
   name@MayaMaster:~$ kubectl get pods
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
----------------------------------------------------

To test the pod, you can run a Kubernetes job, in which a mysql client container runs a load generation script (which in turn performs simple sql queries) to simulate storage traffic. Run the following procedure on any node in the Kubernetes cluster.

Get the IP address of the percona application pod. You can obtain this by executing kubectl describe on the percona pod.

::

    name@MayaMaster:~$ kubectl describe pod percona | grep IP
    IP:             10.44.0.3

Edit the following line in sql-loadgen job yaml to pass the desired load duration and percona pod IP as arguments. In this example, the job performs sql queries on pod with IP address 10.44.0.3 for 300s.

::

    args: ["-c", "timelimit -t 300 sh MySQLLoadGenerate.sh 10.44.0.3 > /dev/null 2>&1; exit 0"]

Run the load generation job using the following command.

::

    kubectl apply -f sql-loadgen.yaml


View Performance and Storage Consumption Statistics Using mayactl
-----------------------------------------------------------------

Performance and capacity usage statistics on the OpenEBS storage volume can be viewed by executing the following *mayactl* command inside the maya-apiserver pod. 

Start an interactive bash console for the maya-apiserver container using the following command.

::
   
     kubectl exec -it maya-apiserver-1633167387-5ss2w /bin/bash

Lookup the storage volume name using the *vsm-list* command

::

    name@MayaMaster:~$ kubectl exec -it maya-apiserver-1633167387-5ss2w /bin/bash

    root@maya-apiserver-1633167387-5ss2w:/# maya vsm-list
    Name                                      Status
    pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc  Running

Get the performance and capacity usage statistics using the *vsm-stats* command.

::

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

The above command can be invoked using the *watch* command by providing a desired interval to continuously monitor statistics.

::

   watch -n 1 maya vsm-stats pvc-016e9a68-71c1-11e7-9fea-000c298ff5fc

