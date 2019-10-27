This directory hosts the Vagrantfiles and configuration scripts required for creating vagrant boxes (sandboxes) with specific versions of kubernetes, openebs etc., 

The directory/file structure is organized as follows:

```
|---Vagrantfile  ( Creates the box. Refers to the scripts under boxes  )
|
|---boxes ( configuration scripts for install and pre-packaging required s/w )
|
|---tests ( contains the Vagrantfiles, that will test the box functionality. )
|
```

The configuration scripts under the boxes will typically perform the following:
- Start with a Base Operating System (like Ubuntu 16.04 box) 
- Download the required packages (like kuberentes, docker, kubeadm )
- Download the required docker images that will be later used by kubeadm for configuring the cluster
- Download the post-vm boot configuration scripts
- Download the demo yaml spec files. 

OpenEBS repository also hosts (in different directory), the scripts required for post-vm initialization tasks like calling "kubeadm join" with required parameters. Similarly, the sample k8s pod specs are also provided. These scripts and specs are pre-packaged into spec files into setup and demo directories respectively. 

- configuration scripts are at [k8s/lib/scripts](https://github.com/openebs/openebs/tree/master/k8s/lib/scripts)
- demo yaml files are at [k8s/demo/specs](https://github.com/openebs/openebs/tree/master/k8s/demo/specs)

