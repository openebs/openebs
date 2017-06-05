# Openebs-on-premise-deployment-guide
-------------------------------------

This guide provides detailed instructions to perform the on-premise deployment of OpenEBS. The end goal of these steps is to have a functional : 

- kubernetes cluster (K8s master & K8s minions/host) configured with the OpenEBS iSCSI flexvol driver, 
- OpenEBS maya master 
- OpenEBS storage cluster

Depending on your need, you can either setup only the kubernetes cluster or the openebs cluster or both. The number of nodes in each
category is configurable.

The Kubernetes cluster is setup, in this framework using "kubeadm"

## Running the setup on Ubuntu 16.04
------------------------------------

The following instructions have been verified on:

- Baremetal & VMware virtual machines installed with Ubuntu server 16.04 64 bit 
- Ubuntu 16.04 64 bit Vagrant VMs running on Windows 10 (Vagrant (>=1.9.1), VirtualBox 5.1)

### Pre-Requisites

- At least 3 linux machines of above type, i.e., either VMs or bare-metal, if deploying the setup in a hyperconverged mode 
  (with K8s as well as openebs residing on the same machines) OR 5 linux machines (with k8s and openebs running on separate machines)
  
- The above instruction assumes a minimal setup with a test-harness, k8s/openebs master and a single k8s minion/openebs node. 
  The masters and nodes can be scaled if the user so desires

- All linux machines are required to have : 
  
  - Basic development packages 
  - Python2.7-minimal 
  - SSH services enabled
  
- The machine used as test-harness is required to have these additionally :
  
  - Git
  - Ansible (version >= 2.3)
 
- The deployment can be performed by both root as well as non-root users. In case of the latter, ensure that the users are part
  of the sudo group. This is needed to run certain operations which require root privileges
   
  
### Download

Setup the local working directory where the ansible code will be downloaded. Perform a git clone of the openebs repository, and navigate to e2e/ansible.

```
testuser@OpenEBSClient:~$ git clone https://github.com/openebs/openebs.git
```
### Setup environment for Ansible execution 

- Setup environment variables for the usernames and passwords of all the boxes which have been brought up in the previous steps 
  on the test-harness (this machine will be interchangeably used with the term 'localhost'). Ensure that these are setup in the
  ```.profile``` of the localhost user which will be running the ansible code/playbooks, i.e., the ansible_user.

- Navigate to the project directory : ```openebs/e2e/ansible``` 

- Edit the ```inventory/machines.in``` file to place the latest HostCode, IP, username variable, password variable for all the boxes 
  setup (Ensure that the notes in the .in file are followed) 
  
- Edit the global variables file ```inventory/group_vars/all.yml``` to reflect the desired storage volume properties and network CIDR
  that will be used by the maya api server to allot the IP for the volume containers (This is needed when performing the setup
  validation through application deployment)
  
- Execute the ansible playbook pre-requisites.yml to generate the ansible inventory, i.e., 'hosts' file from the data provided in the 
  machines.in file
  
  ```
  testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook pre-requisites.yml
  ```
- Verify the generation of the hosts file in the ```openebs/e2e/ansible/inventory``` directory. Check the host-status.log in the 
  same location for details on inventory file generation in case of any issues.
  
  ```
  testuser@OpenEBSClient:~/openebs/e2e/ansible/inventory$ ls -ltr hosts
  -rw-rw-r-- 1 testuser testuser 1482 Jun  5 10:00 hosts
  ```






