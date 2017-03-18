# Kubernetes with dedicated OpenEBS Storage

This page provides the instructions to quickly setup an demo environment of Kubernetes and OpenEBS using Vagrant. 

Create a local directory (say  **demo**) and launch Kubernetes and OpenEBS VMs, using the steps below:

```
mkdir demo
cd demo
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/demo
vagrant up
```
If this is your first time with Vagrant, you can follow through our [Step-by-step Installation Tutorial for Ubuntu 16.04](./tutorial-ubuntu1604-vagrant.md).


**vagrant up** may take few minutes depending on your network speed - When vagrant up is issued for the first time, the required vagrant plugins are installed (for caching the vagrant boxes), the ubuntu-xenial box is download and the required software packages for each of the node are downloaded and installed.

The demo setup will provide you with the following machines:
- Kubernetes Master (kubemaster-01)
- Kubernetes Minion (kubeminion-01)
- OpenEBS Maya Master (omm-01)
- OpenEBS Storage Host (osh-01)


## Next Steps
- [Create a OpenEBS VSM and use it as data directory for MySQL](./run-mysql-openebs.md)
