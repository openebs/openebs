
Storage Policies
==================
You can now define policies based on the type of application at the storage-class level. Following are some of the properties that can be customized at the default level in the openebs-storageclasses.yaml file.

* jiva-replica-count
* jiva-replica-image
* jiva-controller-image
* volume capacity and monitoring 

Replica Count Policy
----------------------
You can specify the number of jiva replicas you want to create. In the following example, the jiva-replica-count is specified as 1. Hence, a single replica is created.  
::

    # Define a storage classes supported by OpenEBS
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        name: openebs-standalone
    provisioner: openebs.io/provisioner-iscsi
    parameters:
        pool: hostdir-var
        openebs.io/jiva-replica-count: "1"
    size: 5G

Replica Image Policy
----------------------
You can add a replica image using the jiva-replica-image property. Specify the value in the "repo-hub-name/project-name:tag-name" format. In the following example, openebs is the repository name and jiva:0.4.0 is the project and tag name.
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
You can add a jiva controller image using the jiva-controller-image property. Specify the value in the ""repo-hub-name/project-name:tag-name" " format. In the following example, openebs is the repository name and jiva:0.4.0 is the project and tag name.
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
A storage pool provides a persistent path for an OpenEBS volume. It can be a directory on a

* host-os or 
* mounted disk

You can specify key value pair in the openebs-config.yaml file. For example, key=openebs.io which is a storage-pool name and value=<*Name of storage pool CRD object*>

::

    # Define a storage pool for launching the replicas using
    #  local directory or mounted directory from the minion nodes
    #  
    apiVersion: openebs.io/v1alpha1
    kind: StoragePool
    metadata:
        name: sp-hostdir
        type: hostdir
    spec:
        path: "/var/openebs" 

Volume Capacity and Monitoring Policy
-------------------------------------------
OpenEBS volumes are each deployed in their own set of containers, which allows flexibility to enable, disable, or customize the features. 

You can set the volume monitor to true or set it by specifying a value which is of string type. 


In the following example, a default volume is added with minimum properties.
::

    $ cat default-vol.yaml  
    kind: Volume
    apiVersion: v1
    metadata:
        name: def-vol
    # add command using curl
    curl -k -H "Content-Type: application/yaml" \
        -XPOST -d"$(cat default-vol.yaml)" \
        http://10.0.0.85:5656/latest/volumes/

You can set the volume capacity in a storage class. The following example creates a cap-new.yaml file with 1G as the volume capacity.
::

    $ cat cap-new.yaml  
    kind: Volume
    apiVersion: v1
    metadata:
        name: cap-new
    capacity: 1G
    # add command using curl
    curl -k -H "Content-Type: application/yaml" \
        -XPOST -d"$(cat cap-new.yaml)" \
        http://10.0.0.85:5656/latest/volumes/

You can add a volume with single replica. The following example creates a 1-rep-new.yaml file with replica set to 1.
::

    $ cat 1-rep-new.yaml 
    kind: Volume
    apiVersion: v1
    metadata:
        name: one-rep-new
    specs:
        - context: replica
            replicas: 1
    # add command using curl
    curl -k -H "Content-Type: application/yaml" \
        -XPOST -d"$(cat 1-rep-new.yaml)" \
        http://10.0.0.85:5656/latest/volumes/