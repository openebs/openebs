.. _Getting-Started:

OpenEBS Introduction
====================
OpenEBS is a cloud native storage solution built with the goal of providing containerized storage for containers. Using OpenEBS, a developer can seamlessly get the persistent storage for stateful applications with ease, much of which is automated, while using the popular orchestration platforms such as Kubernetes.

Persistent storage presents significant challenges to the developer interfacing with stateful applications such as databases. While a developer can get the initial needs of persistent storage using Docker volume plug-in, Kubernetes stateful sets and so on, there is lots more to the storage needs of an application than just the connectivity. 

**Note:**

OpenEBS integration support is provided only for Kubernetes. 

A DevOps developer gets the following from the OpenEBS solution.

- OpenEBS operator yaml file that installs the OpenEBS components onto a k8s cluster
- A set of yaml files containing configuration examples of how to use OpenEBS storage classes 
- A CLI for monitoring the persistent volume and its replicas

Using the above tools, a developer can easily provision the persistent storage from the hostdir of the minion node. Much of the tasks for the developer are automated by the OpenEBS storage class, including, scheduling the volume and replicas on k8s minions, connectivity to the container via a mount point.

Components 
-------------
This section includes OpenEBS components.

OpenEBS platform contains the following main components:

  * Maya - The helper storage orchestration engine that aids the kubernetes orchestration of storage volumes
  * Jiva - A docker image that is used to spin the storage volume containers on Kubernetes nodes

Maya
^^^^^
OpenEBS orchestration does not pre-empt or overwrite the Kubernetes orchestration system. It rather fills the storage orchestration gaps left behind by Kubernetes. For example, in OpenEBS, storage volume provisioning workflow is handled by Kubernetes. Just like other Kubernetes storage incubators, OpenEBS provides a new storage incubator called "OpenEBS". This incubator will have a storage class called "OpenEBS-storageclass". Internally, openebs-storageclass interacts with Maya to decide on which node a given volume must be provisioned, when it must be augmented automatically in capacity and so on. Maya also helps in data protection operations such as taking snapshots, restoring from snapshots and so on.

Jiva
^^^^^
Jiva is the docker container image for storage volume containers. In OpenEBS, the storage volumes are containerized. Each volume will have atleast one storage controller and a storage replica, each of which will be a Jiva container. The functionality embedded into the Jiva image includes the following:

* iSCSI target
* Block replication controller (if the container is a controller)
* Block storage handler (if the container is a replica)

**See Also:**

Changelog_
          .. _Changelog: http://openebs.readthedocs.io/en/latest/release_notes/releasenotes.html


