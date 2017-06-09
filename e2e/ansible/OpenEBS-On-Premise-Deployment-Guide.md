# OpenEBS-On-Premise-Deployment-Guide
-------------------------------------

This guide provides detailed instructions to perform the on-premise deployment of OpenEBS. The end goal of these steps is to have a functional : 

- Kubernetes cluster (K8s master & K8s minions/host) configured with the OpenEBS iSCSI flexvol driver, 
- OpenEBS maya master 
- OpenEBS storage Hosts

Depending on your need, you can either setup only the Kubernetes cluster or the OpenEBS cluster or both. The number of nodes in each
category is configurable.

The Kubernetes cluster is setup, in this framework using "kubeadm"

## Running the setup on Ubuntu 16.04
------------------------------------

The following instructions have been verified on:

- Baremetal & VMware virtual machines installed with Ubuntu server 16.04 64 bit 
- Ubuntu 16.04 64 bit Vagrant VMs running on Windows 10 (Vagrant (>=1.9.1), VirtualBox 5.1)

### Pre-Requisites

- At least 3 linux machines of above type, i.e., either VMs or bare-metal, if deploying the setup in a hyperconverged mode 
  (with K8s as well as OpenEBS residing on the same machines) OR 5 linux machines (with K8s and OpenEBS running on separate machines)
  
- The above instruction assumes a minimal setup with a test-harness, K8s/OpenEBS master and a single K8s minion/OpenEBS node. 
  The masters and nodes can be scaled if the user so desires

- All linux machines are required to have : 
  
  - Basic development packages (dpkg-dev,gcc,g++,libc6-dev,make)
  - Python2.7-minimal 
  - SSH services enabled
  
- The machine used as test-harness is required to have these additionally :
  
  - Git
  - Ansible (version >= 2.3)
 
- The deployment can be performed by both root as well as non-root users. In case of the latter, ensure that the users are part
  of the sudo group. This is needed to run certain operations which require root privileges
   
  
### Download

Setup the local working directory where the ansible code will be downloaded. Perform a git clone of the openebs repository, and navigate to ```e2e/ansible```

```
testuser@OpenEBSClient:~$ git clone https://github.com/openebs/openebs.git
testuser@OpenEBSClient:~$ ls
openebs
testuser@OpenEBSClient:~$ cd openebs/e2e/ansible/
testuser@OpenEBSClient:~/openebs/e2e/ansible$ ls
ansible.cfg  files      playbooks  pre-requisites.yml  roles          setup-openebs.yml
ci.yml       inventory  plugins    README.md           run-tests.yml  Vagrantfile
testuser@OpenEBSClient:~/openebs/e2e/ansible$
```
### Setup environment for OpenEBS installation 

- Setup environment variables for the usernames and passwords of all the boxes which have been brought up in the previous steps 
  on the test-harness (this machine will be interchangeably used with the term 'localhost'). Ensure that these are setup in the
  ```.profile``` of the localhost user which will be running the ansible code/playbooks, i.e., the ansible_user.

- Edit the ```inventory/machines.in``` file to place the latest HostCode, IP, username variable, password variable for all the boxes 
  setup, as shown in the example below (Ensure that the notes in the .in file are followed)
  
  ```
  testuser@OpenEBSClient:~/openebs/e2e/ansible$ cat inventory/machines.in
  mayamaster,20.10.49.11,MACHINES_USER_NAME,MACHINES_USER_PASSWORD
  mayahost,20.10.49.13,USER_NAME,USER_PASSWORD
  ```
  
- Edit the global variables file ```inventory/group_vars/all.yml``` to reflect the desired storage volume properties and network CIDR
  that will be used by the maya api server to allot the IP for the volume containers (This is needed when performing the setup
  validation through application deployment)
  
- Execute the pre-requisites.yml ansible playbook to generate the ansible inventory, i.e., 'hosts' file from the data provided in the 
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
### OpenEBS Installation

- Execute the setup-openebs ansible playbook to create the Kubernetes and OpenEBS clusters. This playbook installs the requisite
  package dependencies on the machines, updates the configuration files on the boxes and sets it up to serve applications.
  
  ```
  testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-openebs.yml 
  ```
- verify that the Kubernetes & OpenEBS cluster are up with the nodes having joined the masters.

  Check status of the maya-master, which, in the current example is running the m-api server
  
  ```
  karthik@MayaMaster:~$ maya omm-status
  Name               Address      Port  Status  Leader  Protocol  Build  Datacenter  Region
  MayaMaster.global  20.10.49.11  4648  alive   true    2         0.5.5  dc1         global
  ```
  Check status of the OpenEBS-storage nodes which have registered with the maya-master
  
  ```
  karthik@MayaMaster:~$ maya osh-status
  ID        DC   Name        Class   Drain  Status
  564dfe3c  dc1  MayaHost01  <none>  false  ready
  564dd2e3  dc1  MayaHost02  <none>  false  ready
  ```
  
  Check status of the Kubernetes minions on the kubernetes master
  
  ```
  karthik@MayaMaster:~$ kubectl get nodes
  NAME         STATUS    AGE       VERSION
  mayahost01   Ready     2d        v1.6.3
  mayahost02   Ready     2d        v1.6.3
  mayamaster   Ready     2d        v1.6.3
  ```
  
### Test the OpenEBS setup

- Test the openebs setup installed using the above steps by deploying a sample application pod

- Edit the ansible/run-tests.yml to run either the test-k8s-mysql-pod or test-k8s-percona-mysql-pod testcase and execute 
  the playbook

  ```
  ciuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook run-tests.yml
  ```
- Verify that the pod is deployed on the Kubernetes minion, by executing the this command on the Kubernetes master :

  ```
  karthik@MayaMaster:~$ kubectl get pod
  NAME      READY     STATUS    RESTARTS   AGE
  percona   1/1       Running   0          2m
  ```
- More details about the pod, execute the command ``` kubectl desribe pod <pod name> ```

- Verify that the storage volume is receiving I/O by checking the increments to DataUpdateIndex in the output of the stats 
  command issued on the maya-master : 

  ``` 
  karthik@MayaMaster:~$ maya vsm-stats demo-vsm1-vol1
  ------------------------------------

  IQN: iqn.2016-09.com.openebs.jiva:demo-vsm1-vol1
  Volume: demo-vsm1-vol1
  Portal: 20.10.49.44
  Size: 5G

  Replica         Status      DataUpdateIndex
  20.10.49.68     Online      2408
  20.10.49.53     Online      2408
  ------------------------------------
  ```
  
  ## Tips & Gotchas
  
  - Use the -v flag while running the playbooks to enable verbose output & logging. Increase the number of 'v's to increase the
    verbosity
    
  - Sometimes, the minions take time to join the Kubernetes master. This could be caused due to slow internet or less resources
    on the box. The time could range between a few seconds to a few minutes
    
  - As with minions above, the OpenEBS volume containers (Jiva containers) may take some time to get initialized (could involve 
    a docker pull) before they are ready to serve I/O. Any pod deployment (which uses the openebs iscsi flexvol driver) done while 
    this is still in process is seen to get queued and resume once the storage is ready
    
    







