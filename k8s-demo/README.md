# Using OpenEBS Storage with Kubernetes

We have made it easy to setup an demo environment for trying OpenEBS Storage with Kubernetes Cluster. 

All you need is an Ubuntu 16.04 Host/VM with 8+ GB RAM and 8+ Core CPU installed with:
- Vagrant 1.9.1 or above
- VirtualBox 5.1 or above
- and ofcourse Git

Setup your local demo directory, say **demo**

```
mkdir demo
cd demo
git clone https://github.com/openebs/openebs.git
cd openebs/k8s-demo
vagrant up
```

This may take few minutes depending on your network speed. The required vagrant plugins are installed (for caching the vagrant boxes), the ubuntu-xenial box is download and the required software packages for each of the node are downloaded and installed.

You will have the following machines ready to use:
- Kubernetes Master (kubemaster-01)
- Kubernetes Minion (kubeminion-01)
- OpenEBS Maya Master (omm-01)
- OpenEBS Storage Host (osh-01)

Please refer to our [Step-by-step Installation Tutorial for Ubuntu 16.04] (./tutorial-ubuntu1604-vagrant.md), if:
- this is your first time setting up the demo
- you would like to launch multiple minion nodes or openebs storage hosts
- you would like to just setup only a Kubernetes Cluster or OpenEBS Cluster for dev/testing.

## Next Steps
- [Configure a Hello-World App](./run-k8s-hello-world.md)
- Configure MySQL Pod with OpenEBS Storage
