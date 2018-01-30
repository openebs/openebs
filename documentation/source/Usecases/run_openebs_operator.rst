Running OpenEBS Operator
=========================

Prerequisites
--------------
Prerequisites include the following:
    
* A fully configured Kubernetes cluster (versions 1.6.3/4/6 and 1.7.0, and 1.7.5 have been tested) with Kubernetes master and at least one Kubernetes node. This can be created on cloud platforms like Google Cloud Engine, on-premise virtual machines (vagrant/VMware/Hyper-V) or Baremetal boxes.

  **Note:**

    - OpenEBS recommends using a 3-node cluster, with one master and two nodes. This aids in creating storage replicas on separate nodes and is helpful in maintaining redundancy and data availability.
    ::
    
        test@Master:~$ kubectl get nodes
          NAME     STATUS    AGE       VERSION
          host01   Ready     18h       v1.6.3
          host02   Ready     18h       v1.6.3
          master   Ready     18h       v1.6.3

    - If you are using gcp, view the appendix in this section for additional steps to set up cluster administration context and use it.

Verify that the Kubernetes cluster is in optimal state by using the following commands.
:: 
  
   name@Master:~$ kubectl get nodes
   NAME         STATUS    AGE       VERSION
   host01   Ready     5d        v1.6.3
   host02   Ready     5d        v1.6.3
   master   Ready     5d        v1.6.3

* Sufficient resources on the nodes to host the OpenEBS storage pods and Percona application pods. This includes sufficient disk space. In this example, physical storage for the pvolume containers will be created from the local storage.

* iSCSI support on the nodes is required to consume the iSCSI target exposed by the OpenEBS volume container. In ubuntu, you can install the iSCSI initiator using the following procedure.

::
  
    sudo apt-get update
    sudo apt-get install open-iscsi
    sudo service open-iscsi restart

Verify that iSCSI is configured using the following commands.

::
  
    sudo cat /etc/iscsi/initiatorname.iscsi
    sudo service open-iscsi status  

* Install the following dependent packages to run mongodb-integrated Sysbench input/output tool on any one of the Kubernetes nodes.
  ::

    sudo apt-get install <packagename>:

    make
    libsasl2-dev
    libssl-dev
    libmongoc-dev
    libbson-dev
    automake
    libmysqlclient-dev
    libtool

The following commands help you run OpenEBS Operator.

Download the latest OpenEBS operator files and sample *percona-mysql* application pod yaml/MongoDB StatefulSet specification yaml on the Kubernetes master from the OpenEBS git repository.

::

    git clone https://github.com/openebs/openebs.git
    cd openebs/k8s

Apply the openebs-operator.yaml file on the Kubernetes cluster. This creates the maya api-server and OpenEBS provisioner deployments.

::
  
    kubectl apply -f openebs-operator.yaml

Add the OpenEBS storage classes using the following command. This can be used by developers to map a suitable storage profile for their applications in their respective persistent volume claims.    

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
  
    test@Master:~$ kubectl get sc
    NAME                 TYPE
    openebs-cassandra    openebs.io/provisioner-iscsi
    openebs-es-data-sc   openebs.io/provisioner-iscsi
    openebs-jupyter      openebs.io/provisioner-iscsi
    openebs-kafka        openebs.io/provisioner-iscsi
    openebs-mongodb      openebs.io/provisioner-iscsi
    openebs-percona      openebs.io/provisioner-iscsi
    openebs-redis        openebs.io/provisioner-iscsi
    openebs-standalone   openebs.io/provisioner-iscsi
    openebs-standard     openebs.io/provisioner-iscsi
    openebs-zk           openebs.io/provisioner-iscsi

**See Also:**

`Setting Up OpenEBS - Overview`_.

.. _Setting Up OpenEBS - Overview: http://openebs.readthedocs.io/en/latest/install/install_overview.html
