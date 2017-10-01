:orphan:

*****************
Virtual Machines
*****************
Setting up OpenEBS On Premise
=============================
This section provides detailed instructions on how to perform the OpenEBS on-premise deployment. The end goal of this precedure is to have the following functional :

* Kubernetes cluster (K8s master & K8s minions/host) configured with the OpenEBS iSCSI flexvol driver,
* OpenEBS Maya master
* OpenEBS Storage Hosts

Depending on your need, you can either setup only the Kubernetes cluster or the OpenEBS cluster or both. The number of nodes in each category is configurable.

The Kubernetes cluster is setup, in this framework using "kubeadm"
