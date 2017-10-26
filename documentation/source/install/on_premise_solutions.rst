********************
On-Premise Solutions
********************

Using Vagrant
=============

Setting Up OpenEBS with Kubernetes on Local Machine
---------------------------------------------------
The following procedure helps you setup and use OpenEBS on a local machine:

1. Install Vagrant Box

   To run the kubernetes cluster on local machine, you need a vagrant box. If you do not have vagrant box follow the steps given `here`_.
    .. _here: https://github.com/openebs/openebs/tree/master/k8s/lib/vagrant/test/k8s/1.6#installing-kubernetes-16-and-openebs-clusters-on-ubuntu

2. Download OpenEBS Vagrant file using the following command.
::

    $ wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/vagrant/1.7.5/Vagrantfile

3. Bring up k8s Cluster.
::

    openebs@openebs:~$ cd openebs/k8s/lib/vagrant/test/k8s/1.6
    openebs@openebs:~/openebs/k8s/lib/vagrant/test/k8s/1.6$ vagrant up

It will bring up one kubemaster and two kubeminions.

4. SSH to kubemaster using the following command.
::

    openebs@openebs:~/openebs/k8s/lib/vagrant/test/k8s/1.6$ vagrant ssh kubemaster-01

5. Run OpenEBS Operator.

   * Download the latest OpenEBS Operator Files inside kubemaster-01 using the following commands.

     ::

         ubuntu@kubemaster-01:~$ git clone https://github.com/openebs/openebs
         ubuntu@kubemaster-01:~$ cd openebs/k8s

   * Run OpenEBS Operator using the following command.
     ::

         ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-operator.yaml

   * Add OpenEBS related storage classes using the following command, that can then be used by developers or applications.
     ::

         ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-storageclasses.yaml

6. Run stateful workloads with OpenEBS storage.

To use OpenEBS as persistent storage for your stateful workloads, set the storage class in the PVC to OpenEBS storage class.

Get the list of storage classes using the following command. Choose the storage class that best suits your application.
::

    ubuntu@kubemaster-01:~$ kubectl get sc


Some sample yaml files for stateful workloads using OpenEBS are provided in the `openebs/k8s/demo`_.
 .. _openebs/k8s/demo: https://github.com/openebs/openebs/tree/master/k8s/demo

The *ubuntu@kubemaster-01:~$ kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml* command creates the following, which you can verify using the corresponding kubectl commands.

* Launch a Jupyter Server, with the specified notebook file from github (kubectl get deployments)
* Create an OpenEBS Volume and mount to the Jupyter Server Pod (/mnt/data) (kubectl get pvc) (kubectl get pv) (kubectl get pods)
* Expose the Jupyter Server to external world through http://NodeIP:8888 (NodeIP is any of the minion nodes' external IP) (kubectl get pods)



Using Ansible
=============

Setting Up OpenEBS on Ubuntu Hosts or Virtual Machines
------------------------------------------------------
This section provides detailed instructions on how to perform the OpenEBS on-premise deployment. The objective of this procedure is to have the following functional.

* Kubernetes cluster (K8s master & K8s minions/host) configured with the OpenEBS iSCSI flexvol driver,
* OpenEBS Maya Master
* OpenEBS Storage Hosts

Depending on your need, you can either setup only the Kubernetes cluster or the OpenEBS cluster or both. The number of nodes in each category is configurable.

The Kubernetes cluster is setup, in this framework using *kubeadm*.

Running the Setup on Ubuntu 16.04
---------------------------------
The following instructions have been verified on -

* Baremetal and VMware virtual machines installed with Ubuntu 16.04 64 bit
* Ubuntu 16.04 64 bit Vagrant VMs running on Windows 10 (Vagrant (>=1.9.1), VirtualBox 5.1)

Prerequisites:
--------------
* At least three Linux machines of either VMs or bare-metal, if deploying the setup in a hyperconverged mode (with K8s as well as OpenEBS residing on the same machines) or five Linux machines (with K8s and OpenEBS running on separate machines)

* The above instruction assumes a minimal setup with a test-harness, K8s/OpenEBS master and a single K8s minion/OpenEBS node. The masters and nodes can be scaled if the user so desires

* All Linux machines are required to have :

  * Basic development packages (dpkg-dev,gcc,g++,libc6-dev,make,libssl-dev,sshpass)
  * Python2.7-minimal
  * SSH services enabled

* The machine used as test-harness must also have the following:

  * Git
  * Ansible (version >= 2.3)

* The deployment can be performed by both root as well as non-root users. In case of the latter, ensure that the users are part of the sudo group. This is required to run certain operations which require root privileges.

Download
--------
Setup the local working directory where the ansible code will be downloaded. Perform a git clone of the OpenEBS repository, and navigate to e2e/ansible.
::

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

Setup Environment for OpenEBS Installation
------------------------------------------
* Setup environment variables for the usernames and passwords of all the machines which have been brought up in the previous steps on the test-harness (this machine will be interchangeably used with the term 'localhost'). Ensure that these are setup in the .profile of the localhost user which will be running the ansible code or playbooks, that is the ansible_user.

* Ensure that the env variables setup in the previous step are available in the current user session. Perform source ~/.profile to achieve the same and verify through echo $VARIABLE.

* Edit the *inventory/machines.in* file to place the latest HostCode, IP, username variable, password variable for all the machines setup. For more details on editing *machines.in*, see the Inventory README.

* Edit the global variables file *inventory/group_vars/all.yml* to reflect the desired storage volume properties and network CIDR that will be used by the maya api server to allot the IP for the volume containers. Also update the ansible run-time properties to reflect the machine type (is_vagrant), whether the playbook execution needs to be recorded using the Ansible Run Analysis framework (setup_ara), whether slack notifications are needed (in case they are required, a $SLACK_TOKEN env variable needs to be setup. The token is usually the last part of the slack webhook URL which is user generated) and so on.

* (Optional) Execute the setup_ara playbook to install the ARA notification plugins and custom modules. This step will cause changes to the ansible configuration file *ansible.cfg* (though a backup will be taken at the time of execution in case you need to revert). A web URL is provided as a playbook run message at the end of the ara setup procedure, which can be used to track all the playbook run details after this point.
  ::

      testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-ara.yml

* Note that the above playbook must be run separately and not as part of any the *master* playbook run as the changes to ansible default configuration may fail to take effect dynamically

* Execute the prerequisites ansible playbook to generate the ansible inventory, that is, *hosts* file from the data provided in the *machines.in* file.
  ::

      testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook pre-requisites.yml

* Verify generation of the hosts file in the *openebs/e2e/ansible/inventory* directory. Check the *host-status.log* in the same location for details on the inventory file generation in case of any issues.
  ::

      testuser@OpenEBSClient:~/openebs/e2e/ansible/inventory$ ls -ltr hosts
      -rw-rw-r-- 1 testuser testuser 1482 Jun  5 10:00 hosts

* OpenEBS installation can be performed:

  1. in hyperconverged mode, where the OpenEBS storage services run as pods on the Kubernetes cluster itself.

  .. 2. in dedicated mode, where the Kubernetes and OpenEBS clusters are setup individually on the Linux boxes (same or distinct) OR


The subsequent section explains the installation procedure for hyperconverged mode.

.. OpenEBS Installation - Dedicated Mode
   -------------------------------------
.. * Update the *inventory/group_vars/all.yml* with the appropriate value ("dedicated") for the key "deployment_mode".

.. * Execute the setup-kubernetes ansible playbook to create the kubernetes cluster followed by the setup-openebs playbook to install the maya-apiserver and openebs storage cluster. These playbooks install the requisite dependencies on the machines, update the configuration files on the boxes and sets it up to serve applications.
  ::
     testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-kubernetes.yml
     testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-kubernetes.yml

.. * Verify that the Kubernetes and OpenEBS clusters are running with the nodes having joined the masters.

..  Check status of the Kubernetes cluster
  ::
       name@KubeMaster:~$ kubectl get nodes
       NAME         STATUS    AGE       VERSION
       kubehost01   Ready     2d        v1.6.3
       kubehost02   Ready     2d        v1.6.3
       kubemaster   Ready     2d        v1.6.3

..  Check status of the maya-master and OpenEBS storage nodes
  ::
        name@MayaMaster:~$ maya omm-status
        Name               Address      Port  Status  Leader  Protocol  Build  Datacenter  Region
        MayaMaster.global  20.10.49.11  4648  alive   true    2         0.5.5  dc1         global

..        m-apiserver listening at http://20.10.49.11:5656

..        name@MayaMaster:~$ maya osh-status
        ID        DC   Name        Class   Drain  Status
        564dfe3c  dc1  MayaHost01  <none>  false  ready
        564dd2e3  dc1  MayaHost02  <none>  false  ready

OpenEBS Installation - Hyperconverged Mode
------------------------------------------

* Update the *inventory/group_vars/all.yml* with the appropriate value *hyperconverged* for the key *deployment_mode*.

* In this mode, the OpenEBS maya-apiserver and openebs-storage provisioner are run as deployments on the Kubernetes cluster with associated pods, and the Kubernetes hosts act as the OpenEBS storage hosts as well. These are setup using an openebs-operator on the Kubernetes cluster. The setup also involves integration of OpenEBS storage-classes into the Kubernetes cluster. These essentially define the storage profile such as size, number of replicas, type of pool atec, and the provisioner associated with it.

  Applications can consume storage by specifying a persistent volume claim in which the storage class is an openebs-storage class.

* Setup the Kubernetes cluster using the setup-kubernetes playbook, followed by the setup-openebs playbook to deploy the OpenEBS pods. Internally, this runs the hyperconverged ansible role which executes the openebs-operator and integrates openebs-storage classes into the Kubernetes cluster.

  * Execute the setup-kubernetes ansible playbook to create the Kubernetes cluster followed by the    setup-openebs playbook. These playbooks install the requisite dependencies on the machines, update the configuration files on the boxes and sets up Kubernetes cluster.
    ::

        testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-kubernetes.yml
        testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-kubernetes.yml

  * Check status of the Kubernetes cluster
    ::

        name@KubeMaster:~$ kubectl get nodes
        NAME         STATUS    AGE       VERSION
        kubehost01   Ready     2d        v1.6.3
        kubehost02   Ready     2d        v1.6.3
        kubemaster   Ready     2d        v1.6.3

* Verify that the Kubernetes cluster is running using the kubectl get nodes command.

* Verify that the maya-apiserver and openebs-provisioner are deployed successfully on the Kubernetes cluster.
  ::

      name@MayaMaster:~$ kubectl get deployments
      NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
      maya-apiserver        1         1         1            1           4h
      openebs-provisioner   1         1         1            1           4h
      name@MayaMaster:~$ kubectl get pods
      NAME                                   READY     STATUS    RESTARTS   AGE
      maya-apiserver-1633167387-v4sf1        1/1       Running   0          4h
      openebs-provisioner-1174174075-n989p   1/1       Running   0          4h

* Verify that the OpenEBS storage classes are applied successfully.
  ::

      name@MayaMaster:~$ kubectl get sc
      NAME              TYPE
      openebs-basic     openebs.io/provisioner-iscsi
      openebs-jupyter   openebs.io/provisioner-iscsi
      openebs-percona   openebs.io/provisioner-iscsi

Run Sample Applications on the OpenEBS Setup
--------------------------------------------
* Test the OpenEBS setup installed using the above procedure by deploying a sample application pod.

* *run-hyperconverged-tests.yml* can be used to run tests on the hyperconverged installation.

* By default, all tests are commented in the above playbooks. Uncomment the desired test and execute the playbook. In the example below, a percona mysql DB is deployed on a hyperconverged installation.
  ::

      ciuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook run-hyperconverged-tests.yml

* Verify that the pod is deployed on the Kubernetes minion along with the OpenEBS storage pods created as per the storage-class in the persistent volume claim, by executing the following command on the Kubernetes master.
  ::

      name@MayaMaster:~$ kubectl get pods
      NAME                                                            READY     STATUS    RESTARTS   AGE
      maya-apiserver-1633167387-v4sf1                                 1/1       Running   0          4h
      openebs-provisioner-1174174075-n989p                            1/1       Running   0          4h
      percona                                                         1/1       Running   0          2m
      pvc-4644787a-5b1f-11e7-bf1c-000c298ff5fc-ctrl-693727538-dph14   1/1       Running   0          2m
      pvc-4644787a-5b1f-11e7-bf1c-000c298ff5fc-rep-871457607-l392p    1/1       Running   0          2m
      pvc-4644787a-5b1f-11e7-bf1c-000c298ff5fc-rep-871457607-n9m73    1/1       Running   0          2m

.. For dedicated installation, the application pod alone will be seen in the output when you use the previous command.

* For more details about the pod, execute the following command.
  ::

      kubectl describe pod <pod name>

* The storage volume that is the persistent volume associated with the persistent volume claim, can be viewed using the *volume list* command in the maya-apiserver pod.
  ::

      name@MayaMaster:~$ kubectl exec maya-apiserver-1633167387-v4sf1 -c maya-apiserver -- maya volume list
      Name                                      Status
      pvc-a2a6d71f-5b21-11e7-bf1c-000c298ff5fc  Running

* Verify that the storage volume is receiving input/output by checking the increments to *DataUpdateIndex* in the output of the `volume stats` command issued in the maya-apiserver pod. Some additional performance statistics are also available in the command output.
  ::

       name@MayaMaster:~$ kubectl exec maya-apiserver-1633167387-v4sf1 -c maya-apiserver -- maya volume stats pvc-a2a6d71f-5b21-11e7-bf1c-000c298ff5fc
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
      name@MayaMaster:~$

.. In case of dedicated installations, the `maya volume list` and `maya volume stats` commands can be executed directly on the maya server host console.

Tips and Gotchas
----------------
* Use the -v flag while running the playbooks to enable verbose output and logging. Increase the number of 'v's to increase the verbosity.

* Sometimes, the minions take time to join the Kubernetes master. This could be caused due to slow internet or less resources on the box. The time could range between a few seconds to a few minutes.

* As with minions above, the OpenEBS volume containers (Jiva containers) may take some time to get initialized (involves a docker pull) before they are ready to input/output. Any pod deployment (which uses the openEBS iSCSI flexvol driver) while in progress, gets queued and resumes once the storage is ready.
