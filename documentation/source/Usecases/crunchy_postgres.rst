
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
