.. _Getting-Started:

OpenEBS Introduction
====================
OpenEBS is a cloud native storage solution built with the goal of providing containerized storage for containers. Using OpenEBS, a developer can seamlessly get the persistent storage for stateful applications with ease, much of which is automated, while using the popular orchestration platforms such as Kubernetes.

Persistent storage presents significant challenges to the developer interfacing with stateful applications such as databases. While a developer can get the initial needs of persistent storage using Docker volume plug-in, Kubernetes stateful sets and so on, there is lots more to the storage needs of an application than just the connectivity. 

**Note:**

In the current release, the integration support is provided only for Kubernetes. 

Currently (OpenEBS 0.3 release), a DevOps developer gets the following from the OpenEBS solution

- OpenEBS operator yaml file that installs the OpenEBS components onto a k8s cluster
- A set of yaml files containing configuration examples of how to use OpenEBS storage classes 
- A CLI for monitoring the persistent volume and its replicas

Using the above tools, a developer can easily provision the persistent storage from the hostdir of the minion node. Much of the tasks for the developer are automated by the OpenEBS storage class, including, scheduling the volume and replicas on k8s minions, connectivity to the container via a mount point.

**See Also:**

Changelog_
          .. _Changelog: https://github.com/openebs/openebs/releases


