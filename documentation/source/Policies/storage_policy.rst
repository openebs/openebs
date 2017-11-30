
Storage Policies
==================
You can now define policies based on the type of application at the storage-class level. Following are some of the properties that can be customized at the default level in the openebs-storageclasses.yaml file.

* openebs.io/jiva-replica-count
* openebs.io/jiva-replica-image
* openebs.io/jiva-controller-image
* openebs.io/storage-pool
* openebs.io/volume-monitor 

Replica Count Policy
----------------------
You can specify the jiva replica count using the *openebs.io/jiva-replica-count* property. In the following example, the jiva-replica-count is specified as 1. Hence, a single replica is created.  
::

    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        name: openebs-standalone
    provisioner: openebs.io/provisioner-iscsi
    parameters:
        openebs.io/jiva-replica-count: "1"
    
Replica Image Policy
----------------------
You can specify the jiva replica image using the *openebs.io/jiva-replica-image* property.

**Note:**

Jiva replica image is a docker image.
::

    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        name: mysql
    provisioner: openebs.io/provisioner-iscsi
    parameters:
        openebs.io/jiva-replica-count: "1"
        openebs.io/capacity: "1G"
        openebs.io/jiva-replica-image: "openebs/jiva:0.4.0"
  
Controller Image Policy
---------------------------
You can specify the jiva controller image using the *openebs.io/jiva-controller-image* property.

**Note:**

Jiva controller image is a docker image.
::

    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        name: mysql
    provisioner: openebs.io/provisioner-iscsi
    parameters:
        openebs.io/jiva-replica-count: "1"
        openebs.io/capacity: "1G"
        openebs.io/jiva-controller-image: "openebs/jiva:0.4.0"

Storage Pool Policy
--------------------
You can specify the Storage Pool policy using the *openebs.io/storage-pool* property. A storage pool provides a persistent path for an OpenEBS volume. It can be a directory on a:

* host-os or 
* mounted disk

You must define the storage pool as a Kubernetes Custom Resource (CR) before using it as a Storage Pool policy.

Following is a sample Kubernetes custom resource definition for a storage pool.

::

    apiVersion: openebs.io/v1alpha1
    kind: StoragePool
    metadata:
        name: sp-hostdir
        type: hostdir
    spec:
        path: "/var/openebs" 

This storage pool custom resource can now be used as follows:
::

    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        name: openebs-percona
    provisioner: openebs.io/provisioner-iscsi
    parameters:
        pool: hostdir-var
        openebs.io/jiva-replica-count: "1"
        openebs.io/capacity: "2G"
        openebs.io/jiva-replica-image: "openebs/jiva:0.4.0"
        openebs.io/storage-pool: "sp-hostdir"

Volume Monitoring Policy
-----------------------------
You can specify the Volume Monitoring policy using *openebs.io/volume-monitor* property.

The following Kubernetes storage class sample uses the Volume Monitoring policy.
::

    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        name: sc-percona-monitor
    provisioner: openebs.io/provisioner-iscsi
    parameters:
        openebs.io/jiva-replica-image: "openebs/jiva:0.4.0"
        openebs.io/volume-monitor: "true" 
