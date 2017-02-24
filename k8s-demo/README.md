# Using OpenEBS Storage with Kubernetes

We have made it easy to setup an demo environment for trying out OpenEBS Storage with Kubernetes Cluster. All you need is an Host with 8+ GB RAM and 8+ Core CPU installed with:
- Vagrant 1.9.1 or above
- VirtualBox 5.1 or above
- and ofcourse Git

Setup your local demo directory, say $demo-folder

```
mkdir $demo-folder
cd $demo-folder
git clone https://github.com/openebs/openebs.git
cd openebs/k8s-demo
vagrant up
```

This may take few minutes depending on your network speed. The required vagrant plugins are installed (for caching the vagrant boxes), the ubuntu-xenial box is download and the required software packages for each of the node are downloaded and installed.

If this is your first time here, you can follow through our [Step-by-step Installation Tutorial for Ubuntu 16.04] (../blob/master/tutorial-ubuntu1604-vagrant.md)
