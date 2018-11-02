# Using OpenEBS Storage with Kubernetes

We have made it easy to setup an demo environment for trying OpenEBS Storage with Kubernetes Cluster. 

All you need is, **four** Ubuntu 16.04 Hosts/VMs with 8+ GB RAM and 8+ Core CPU installed with:
- VirtualBox 5.1 or above
- and ofcourse Git

Setup your local demo directory, say **demo** on those Hosts/VMs

```
mkdir demo
cd demo
git clone https://github.com/openebs/openebs.git
```

This may take few minutes depending on your network speed.

You will need two Hosts/VMs with **passwordless SSH** between them, to set up Kubernetes:
- Kubernetes Master (kubemaster-01)
- Kubernetes Minion (kubeminion-01)

On the Kubernetes Master change to the **scripts** folder and run the script to install Kubernetes Master.

```
cd openebs/k8s-demo/scripts
./setup_k8s_master.sh
```

On the Kubernetes Minion change to the **scripts** folder and run the script to install Kubernetes Minion.

```
cd openebs/k8s-demo/scripts
./setup_k8s_host.sh
```

You will need two Hosts/VMs, to set up OpenEBS:
- OpenEBS Maya Master (omm-01)
- OpenEBS Storage Host (osh-01)

On the OpenEBS Maya Master change to the **scripts** folder and run the script to install OpenEBS Maya Master.

```
cd openebs/k8s-demo/scripts
./setup_omm.sh
source ~/.profile
```

On the OpenEBS Storage Host change to the **scripts** folder and run the script to install OpenEBS Storage Host.

```
cd openebs/k8s-demo/scripts
./setup_osh.sh
source ~/.profile
```
You will have the following machines ready to use:
- Kubernetes Master (kubemaster-01)
- Kubernetes Minion (kubeminion-01)
- OpenEBS Maya Master (omm-01)
- OpenEBS Storage Host (osh-01)

## How-T0
- [Setup Passwordless SSH](./setup-passwordless-ssh.md)

## Next Steps
- [Configure a Hello-World App](../../dedicated/run-k8s-hello-world.md)
- [Configure MySQL Pod with OpenEBS Storage](../../dedicated/run-mysql-openebs.md)
