# Customizing the Vagrantfile

By default, 5 VMs will be created with the following CPU/Memory configuration. 

Kubernetes Master requires 2G RAM and 2 CPU
Kubernetes Minion, OpenEBS Master and OpenEBS Host are configured with 1GB RAM and 1 CPU. 

Depending on your system configuration, you can edit the Vagrantfile or pass the modified files as environment files to specify:

(a) Number of Nodes under each category:

- Kubernetes Minion hosts ( KH_NODES) 
- OpenEBS Maya Master ( MM_NODES )
- OpenEBS Storage Host ( MH_NODES )

A value of 0 for the above variables will skip the installation of that type. For example, to install only Kubernetes you can run the following command:

```
ubuntu-host:~/demo-folder/openebs/k8s/demo$ MH_NODES=0 MM_NODES=0 vagrant status
Current machine states:

kubemaster-01             not created (virtualbox)
kubeminion-01             not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

(b) RAM and CPU for Kubernetes Master ( KM_MEM and KM_CPUS)

(c) RAM and CPU for OpenEBS Maya Master ( M_MEM and M_CPUS)

(c) RAM and CPU for OpenEBS Storage Host or Kubernetes Minion ( H_MEM and H_CPUS)
