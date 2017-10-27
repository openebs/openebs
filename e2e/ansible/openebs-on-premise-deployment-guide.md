# OpenEBS On Premise Deployment Guide
-------------------------------------

This guide provides detailed instructions to perform the on-premise deployment of OpenEBS. The end goal of these steps is to have a functional : 

- Kubernetes cluster (K8s master & K8s minions/host) configured with the OpenEBS iSCSI flexvol driver, 
- OpenEBS Maya master 
- OpenEBS Storage Hosts

Depending on your need, you can either setup only the Kubernetes cluster or the OpenEBS cluster or both. The number of nodes in each
category is configurable.

The Kubernetes cluster is setup, in this framework using "kubeadm"

## Running the setup on Ubuntu 16.04
------------------------------------

The following instructions have been verified on:

- Baremetal & VMware virtual machines installed with Ubuntu 16.04 64 bit 
- Ubuntu 16.04 64 bit Vagrant VMs running on Windows 10 (Vagrant (>=1.9.1), VirtualBox 5.1)

### Pre-Requisites

- At least 3 linux machines of above type, i.e., either VMs or bare-metal, if deploying the setup in a hyperconverged mode 
  (with K8s as well as OpenEBS residing on the same machines) OR 5 linux machines (with K8s and OpenEBS running on separate machines)
  
- The above instruction assumes a minimal setup with a test-harness, K8s/OpenEBS master and a single K8s minion/OpenEBS node. 
  The masters and nodes can be scaled if the user so desires

- All linux machines are required to have : 
  
  - Basic development packages (dpkg-dev,gcc,g++,libc6-dev,make,libssl-dev,sshpass)
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
testuser@OpenEBSClient:~/openebs/e2e/ansible$ ls -l
total 68
-rw-rw-r--  1 testuser testuser 14441 Jun  5 09:29 ansible.cfg
-rw-rw-r--  1 testuser testuser   470 Jun  5 09:29 ci.yml
drwxrwxr-x  2 testuser testuser  4096 Jun  5 09:29 files
drwxrwxr-x  3 testuser testuser  4096 Jun  5 10:00 inventory
drwxrwxr-x  4 testuser testuser  4096 Jun  5 09:29 playbooks
drwxrwxr-x  3 testuser testuser  4096 Jun  5 09:29 plugins
-rw-rw-r--  1 testuser testuser    57 Jun  5 09:29 pre-requisites.yml
-rw-rw-r--  1 testuser testuser  7058 Jun  5 09:29 README.md
drwxrwxr-x 17 testuser testuser  4096 Jun  5 09:29 roles
-rw-rw-r--  1 testuser testuser  1864 Jun  5 09:29 run-tests.yml
-rw-rw-r--  1 testuser testuser   379 Jun  5 09:29 setup-openebs.yml
-rw-rw-r--  1 testuser testuser  4221 Jun  5 09:29 Vagrantfile
```
### Setup Environment For OpenEBS Installation 

- Setup environment variables for the usernames and passwords of all the boxes which have been brought up in the previous steps 
  on the test-harness (this machine will be interchangeably used with the term 'localhost'). Ensure that these are setup in the
  ```.profile``` of the localhost user which will be running the ansible code/playbooks, i.e., the ansible_user.

- Ensure that the env variables setup in the previous step are available in the current user session. Perform 
```source ~/.profile``` to achieve the same and verify via ```echo $VARIABLE```

- Edit the ```inventory/machines.in``` file to place the latest HostCode, IP, username variable, password variable for all the boxes 
  setup. For more details on editing machines.in refer the [Inventory README](inventory/README.md)
  
- Edit the global variables file ```inventory/group_vars/all.yml``` to reflect the desired storage volume properties and network CIDR
  that will be used by the maya api server to allot the IP for the volume containers 
  
- Execute the pre-requisites ansible playbook to generate the ansible inventory, i.e., 'hosts' file from the data provided in the 
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

  Check status of the maya-master and OpenEBS storage nodes, which are registered with the maya-master
  
  ```
  karthik@MayaMaster:~$ maya omm-status
  Name               Address      Port  Status  Leader  Protocol  Build  Datacenter  Region
  MayaMaster.global  20.10.49.11  4648  alive   true    2         0.5.5  dc1         global
  
  m-apiserver listening at http://20.10.49.11:5656
  
  karthik@MayaMaster:~$ maya osh-status
  ID        DC   Name        Class   Drain  Status
  564dfe3c  dc1  MayaHost01  <none>  false  ready
  564dd2e3  dc1  MayaHost02  <none>  false  ready
  ```
  
  Check status of the Kubernetes cluster
  
  ```
  karthik@KubeMaster:~$ kubectl get nodes
  NAME         STATUS    AGE       VERSION
  kubehost01   Ready     2d        v1.6.3
  kubehost02   Ready     2d        v1.6.3
  kubemaster   Ready     2d        v1.6.3
  ```
  
### Run sample applications on the OpenEBS setup

- Test the openebs setup installed using the above steps by deploying a sample application pod

- Edit the ansible/run-tests.yml to run either the _test-k8s-mysql-pod_ or _test-k8s-percona-mysql-pod_ testcase and execute 
  the playbook

  ```
  ciuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook run-tests.yml
  ```
- Verify that the pod is deployed on the Kubernetes minion, by executing the this command on the Kubernetes master :

  ```
  karthik@KubeMaster:~$ kubectl get pod
  NAME      READY     STATUS    RESTARTS   AGE
  percona   1/1       Running   0          2m
  ```
- For more details about the pod, execute the command ``` kubectl describe pod <pod name> ```

- Verify that the storage volume is receiving I/O by checking the increments to _DataUpdateIndex_ in the output of the stats 
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
    
  - As with minions above, the OpenEBS volume containers (Jiva containers) may take some time to get initialized (involves 
    a docker pull) before they are ready to serve I/O. Any pod deployment (which uses the openebs iscsi flexvol driver) done while 
    this is still in process is seen to get queued and resume once the storage is ready
    
    







