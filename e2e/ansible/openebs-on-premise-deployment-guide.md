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
- OpenEBS installation can be performed in dedicated mode, where the kubernetes and openebs clusters are setup individually on the linux 
  boxes (same or distinct) OR in hyperconverged mode, where the openebs storage services run as pods on the kubernetes cluster itself
  
  The subsequent sections explain the installation procedure for both the dedicated and hyperconverged mode.

### OpenEBS Installation - Dedicated Mode

- Update the ```inventory/group_vars/all.yml``` with the appropriate value ("dedicated") for the key "deployment_mode" 

- Execute the setup-kubernetes ansible playbook to create the kubernetes cluster followed by the setup-openebs playbook to install the 
  maya-apiserver and openebs storage cluster. These playbooks install the requisite  dependencies on the machines, update the 
  configuration files on the boxes and sets it up to serve applications.
  
  ```
  testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-kubernetes.yml 
  ```
  ```
  testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-kubernetes.yml 
  ```
- verify that the Kubernetes & OpenEBS clusters are up with the nodes having joined the masters :

  Check status of the Kubernetes cluster
  
  ```
  karthik@KubeMaster:~$ kubectl get nodes
  NAME         STATUS    AGE       VERSION
  kubehost01   Ready     2d        v1.6.3
  kubehost02   Ready     2d        v1.6.3
  kubemaster   Ready     2d        v1.6.3
  ```

  Check status of the maya-master and OpenEBS storage nodes 
  
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
### OpenEBS Installation - Hyperconverged Mode

- Update the ```inventory/group_vars/all.yml``` with the appropriate value ("hyperconverged") for the key "deployment_mode" 

- In this mode, the openebs maya-apiserver and openebs-storage provisioner are run as deployments on the kubernetes cluster with 
  associated pods, and the kubernetes hosts act as the openebs storage hosts as well. These are setup using an openebs-operator on 
  the kubernetes cluster. The setup also involves integration of openebs storage-classes into the kubernetes cluster. These essentially 
  define the storage profile - such as size, number of replicas, type of pool atec..,and also the provisioner associated with it. 
  
  Applications can consume storage by specifying a persistent volume claim in which the storage class is an openebs-storage class.
  
- First, setup the kubernetes cluster using the setup-kubernetes playbook, followed by the setup-openebs playbook (same commands as the 
  dedicated installation explained in previous section) to deploy the openebs pods. Internally, this runs the _hyperconverged_ ansible 
  role which executes the the openebs-operator and integrates openebs-storageclasses into the kubernetes cluster 
  
- Verify that the kubernetes cluster is up using the ```kubectl get nodes``` command

- Verify that the maya-apiserver and openebs-provisioner are deployed successfully on the kubernetes cluster

  ```
  karthik@MayaMaster:~$ kubectl get deployments
  NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
  maya-apiserver        1         1         1            1           4h
  openebs-provisioner   1         1         1            1           4h
  ```
  ```
  karthik@MayaMaster:~$ kubectl get pods
  NAME                                   READY     STATUS    RESTARTS   AGE
  maya-apiserver-1633167387-v4sf1        1/1       Running   0          4h
  openebs-provisioner-1174174075-n989p   1/1       Running   0          4h
  ```
- Verify that the openebs storage-classes are applied successfully 

  ```
  karthik@MayaMaster:~$ kubectl get sc
  NAME              TYPE
  openebs-basic     openebs.io/provisioner-iscsi
  openebs-jupyter   openebs.io/provisioner-iscsi
  openebs-percona   openebs.io/provisioner-iscsi
  ```
  
### Run sample applications on the OpenEBS setup

- Test the openebs setup installed using the above steps by deploying a sample application pod

- run-dedicated-tests.yml can be used to run tests on the dedicated installation and run-hyperconverged-tests.yml on the hyperconverged 
  installation

- By default, all tests are commented in the above playbooks. Uncomment the desired test and execute the playbook. In the example shown 
  below, a percona mysql DB is deployed on a hyperconverged installation

  ```
  ciuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook run-hyperconverged-tests.yml
  ```
- Verify that the pod is deployed on the Kubernetes minion along with the openebs storage pods created as per the storage-class in the 
  persistent volume claim, by executing the this command on the Kubernetes master :

  ```
  karthik@MayaMaster:~$ kubectl get pods
  NAME                                                            READY     STATUS    RESTARTS   AGE
  maya-apiserver-1633167387-v4sf1                                 1/1       Running   0          4h
  openebs-provisioner-1174174075-n989p                            1/1       Running   0          4h
  percona                                                         1/1       Running   0          2m
  pvc-4644787a-5b1f-11e7-bf1c-000c298ff5fc-ctrl-693727538-dph14   1/1       Running   0          2m
  pvc-4644787a-5b1f-11e7-bf1c-000c298ff5fc-rep-871457607-l392p    1/1       Running   0          2m
  pvc-4644787a-5b1f-11e7-bf1c-000c298ff5fc-rep-871457607-n9m73    1/1       Running   0          2m

  ```
  
  In case of a dedicated installation, the application pod alone will be seen in the output of above command
  
- For more details about the pod, execute the command ``` kubectl describe pod <pod name> ```

- The storage volume (i.e., the persistent volume) associated with the persistent volume claim can be viewed using the vsm-list command 
  in the maya-apiserver pod
  
  ```
  karthik@MayaMaster:~$ kubectl exec maya-apiserver-1633167387-v4sf1 -c maya-apiserver -- maya vsm-list
  Name                                      Status
  pvc-a2a6d71f-5b21-11e7-bf1c-000c298ff5fc  Running
  ```
  
- Verify that the storage volume is receiving I/O by checking the increments to _DataUpdateIndex_ in the output of the vsm-stats 
  command issued in the maya-apiserver pod. Also available in the command output are some additional performance stats
  
  ```
  karthik@MayaMaster:~$ kubectl exec maya-apiserver-1633167387-v4sf1 -c maya-apiserver -- maya vsm-stats pvc-a2a6d71f-5b21-11e7-bf1c-  
  000c298ff5fc
  ------------------------------------
     IQN: iqn.2016-09.com.openebs.jiva:pvc-a2a6d71f-5b21-11e7-bf1c-000c298ff5fc
  Volume: pvc-a2a6d71f-5b21-11e7-bf1c-000c298ff5fc
  Portal: 10.104.223.35:3260
    Size: 5G

  Replica         Status      DataUpdateIndex
  10.36.0.2       Online      2857
  10.44.0.3       Online      2857
  ------------------------------------
   r/s|   w/s|   r(MB/s)|   w(MB/s)|   rLat(ms)|   wLat(ms)|   rBlk(KB)|   wBlk(KB)|
     0|     3|     0.000|     1.109|      0.000|     10.602|          0|        378|
  karthik@MayaMaster:~$
  ```
  In case of dedicated installations, the ```maya vsm-list``` and ```maya vsm-stats``` command can be executed directly on the maya 
  server host console  

  
## Tips & Gotchas
  
- Use the -v flag while running the playbooks to enable verbose output & logging. Increase the number of 'v's to increase the
  verbosity
    
- Sometimes, the minions take time to join the Kubernetes master. This could be caused due to slow internet or less resources
  on the box. The time could range between a few seconds to a few minutes
    
- As with minions above, the OpenEBS volume containers (Jiva containers) may take some time to get initialized (involves 
  a docker pull) before they are ready to serve I/O. Any pod deployment (which uses the openebs iscsi flexvol driver) done while 
  this is still in process is seen to get queued and resume once the storage is ready
    
    







