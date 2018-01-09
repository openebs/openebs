**********************
On-Premise Solutions
**********************

Using Vagrant
================

Setting Up OpenEBS with Kubernetes on a Local Machine
-------------------------------------------------------
The following procedure helps you setup and use OpenEBS on a local machine:

Prerequisites:
^^^^^^^^^^^^^^^^^^^

* Vagrant (>=1.9.1)
* VirtualBox (>=5.1)
* curl / wget / git and so on, to download the Vagrant file
* Ensure virtualization is enabled at the BIOS level

**Minimum System Requirements**  

* 40GB hard disk space
* 8GB RAM
* 4 core processors

To run the Kubernetes cluster on a local machine, you need a vagrant box. Install and download Vagrant using the procedure available at https://www.vagrantup.com/intro/getting-started/install.html.

Install and download Virtualbox using the procedure available at https://www.virtualbox.org/wiki/Downloads.

Install a Vagrant Box either by downloading the vagrant file or by cloning the repository.

Installing a Vagrant Box by Downloading the Vagrantfile
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. Create a demo directory for example, k8s-demo using the following command.
   ::
      mkdir k8s-demo

2. Download OpenEBS Vagrant file using the following command.
   ::
       cd k8s-demo
       $ wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/vagrant/1.7.5/Vagrantfile

3. Bring up k8s Cluster.
   ::
      ubuntu@ubuntu:~/k8s-demo$ vagrant up

   It will bring up a three node Kubernetes cluster with one master and two nodes. 

4. SSH to kubemaster using the following command.
   ::
      ubuntu@ubuntu:~/k8s-demo$ vagrant ssh kubemaster-01

5. Run OpenEBS Operator.
   
* Download the latest OpenEBS Operator Files inside kubemaster-01 using the following commands.
  ::
    ubuntu@kubemaster-01:~$ git clone https://github.com/openebs/openebs
    ubuntu@kubemaster-01:~$ cd openebs/k8s

* Run OpenEBS Operator using the following command.
  ::
   ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-operator.yaml

* Add OpenEBS related storage classes using the following command, that can then be used by developers     or applications.
  ::
   ubuntu@kubemaster-01:~/openebs/k8s$ kubectl apply -f openebs-storageclasses.yaml

6. Run stateful workloads with OpenEBS storage.

To use OpenEBS as persistent storage for your stateful workloads, set the PVC storage class to OpenEBS storage class.

Get the list of storage classes using the following command. Choose the storage class that best suits your application.
::
    ubuntu@kubemaster-01:~$ kubectl get sc

Installing a Vagrant Box by Cloning the Repository
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. Clone the OpenEBS repository using the following command.
   ::
      git clone http://github.com/openebs/openebs.git

2. Bring up k8s Cluster.
   ::
      ubuntu@ubuntu:~$ cd openebs/k8s/vagrant/1.7.5
      ubuntu@ubuntu:~/openebs/k8s/vagrant/1.7.5$ vagrant up

Some sample yaml files for stateful workloads using OpenEBS are provided in the `openebs/k8s/demo`_.

 .. _openebs/k8s/demo: https://github.com/openebs/openebs/tree/master/k8s/demo

The *ubuntu@kubemaster-01:~$ kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml* command creates the following, which you can verify using the corresponding kubectl commands.

* Launch a Jupyter Server, with the specified notebook file from github (kubectl get deployments)
* Create an OpenEBS Volume and mount to the Jupyter Server Pod (/mnt/data) (kubectl get pvc) (kubectl get pv) (kubectl get pods)
* Expose the Jupyter Server to external world through http://NodeIP:8888 (NodeIP is any of the nodes' external IP) (kubectl get pods)

Installing Kubernetes on CentOS in Vagrant VMs
----------------------------------------------------
The following procedure helps you install Kubernetes on CentOS version 7.4 and use OpenEBS on a local machine. You will be setting up a 3 node cluster comprising of 1 Master and 2 Worker Nodes running Kubernetes 1.8.5.

Prerequisites:
^^^^^^^^^^^^^^^^
Verify that you have the following software installed on your machine:

- Vagrant (>=1.9.1)
- VirtualBox 5.1

Creating and Editing a Vagrantfile for CentOS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Run the following commands to create a Vagrantfile for CentOS.
::
    host-machine:~/mkdir k8s-demo
    host-machine:~/cd k8s-demo
    host-machine:~/k8s-demo$ vagrant init centos/7
    A `Vagrantfile` has been placed in this directory. You are now
    ready to `vagrant up` your first virtual environment! Please read
    the comments in the Vagrantfile as well as documentation on
    `vagrantup.com` for more information on using Vagrant.    

Edit the generated Vagrantfile to look similar as below:
::
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    # All Vagrant configuration is done below. The "2" in Vagrant.configure
    # configures the configuration version (we support older styles for
    # backwards compatibility). Please don't change it unless you know what
    # you're doing.
    Vagrant.configure("2") do |config|
      # The most common configuration options are documented and commented below.
      # For a complete reference, please see the online documentation at
      # https://docs.vagrantup.com.

        config.vm.box = "centos/7"

        config.vm.provider "virtualbox" do |vb|
          vb.cpus = 2
          vb.memory = "2048"
        end

        config.vm.define "master" do |vmCfg|
          vmCfg.vm.hostname = "master"
          vmCfg.vm.network "private_network", ip: "172.28.128.31"
        end

        config.vm.define "worker-01" do |vmCfg|
          vmCfg.vm.hostname = "worker-01"
          vmCfg.vm.network "private_network", ip: "172.28.128.32"
        end

        config.vm.define "worker-02" do |vmCfg|
          vmCfg.vm.hostname = "worker-02"
          vmCfg.vm.network "private_network", ip: "172.28.128.33"
        end
    end

Verifying the Vagramt VM's State
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Verify the state of Vagrant VMs. You should see an output similar as this:
::
    host-machine:~/k8s-demo$ vagrant status
    Current machine states:

    master                not created (VirtualBox)
    worker-01             not created (VirtualBox)
    worker-02             not created (VirtualBox)

    This environment represents multiple VMs. The VMs are all listed
    above with their current state. For more information about a specific
    VM, run `vagrant status NAME`.

Bringing up Vagrant VMs
^^^^^^^^^^^^^^^^^^^^^^^^^^^
Use *vagrant up* to bring up the VMs.
::
    host-machine:~/k8s-demo$ vagrant up

Verify the state of Vagrant VMs. You should see an output similar as this:
::
    host-machine:~/k8s-demo$ vagrant status
    Current machine states:

    master                running (VirtualBox)
    worker-01             running (VirtualBox)
    worker-02             running (VirtualBox)

    This environment represents multiple VMs. The VMs are all listed
    above with their current state. For more information about a specific
    VM, run `vagrant status NAME`.    

Before you begin
^^^^^^^^^^^^^^^^^^

* SSH into each of the Vagrant VMs and perform the following steps:

  - Update the /etc/hosts file. Your hosts file must look similar as below:
  ::
      For Master /etc/hosts:
      ---------------------
      172.28.128.31   master       master
      127.0.0.1   localhost

      For Worker-01 /etc/hosts:
      ------------------------
      172.28.128.32   worker-01       worker-01
      127.0.0.1   localhost

      For Worker-02 /etc/hosts:
      ------------------------
      172.28.128.33   worker-02       worker-02
      127.0.0.1   localhost
      
  - Update the /etc/resolv.conf file. Your resolv.conf file must look similar as below:
    ::
        # Generated by NetworkManager
        search domain.name
        nameserver 8.8.8.8
        
  - Disable Swap. You MUST disable swap in order for the kubelet to work properly.(For Kubernetes 1.8 and above.)
    ::
        [vagrant@master ~]$ sudo swapoff -a

  - Comment out lines containing "swap" in /etc/fstab with swap disabled.
    ::
        [vagrant@master ~]$ sudo vi /etc/fstab
        #
        # /etc/fstab
        # Created by anaconda on Sat Oct 28 11:03:00 2017
        #
        # Accessible filesystems, by reference, are maintained under '/dev/disk'
        # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
        #
        /dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
        UUID=8ffa0ee9-e1a8-4c03-acce-b65b342c6935 /boot                   xfs     defaults        0 0

        #Below line was commented as it contained swap.
        #/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0

  - On each of your vagrant machines, install Docker. Refer to the official Docker installation guides.

  - Once the docker installation is complete execute the below step to enable and start the docker service.
    ::
        sudo systemctl enable docker && sudo systemctl start docker

  - Setup Kubernetes repo details for installing Kubernetes binaries.
    ::
        sudo tee -a /etc/yum.repos.d/kubernetes.repo <<EOF >/dev/null
        [kubernetes]
        name=Kubernetes
        baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
        enabled=1
        gpgcheck=1
        repo_gpgcheck=1
        gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
        EOF
        
  - Disable SELinux. You have to do this until SELinux support is improved in the kubelet.
    ::
        # Disable SELinux by running setenforce 0
        # This is required to allow containers to access the host filesystem required by the pod networks.
        sudo setenforce 0

  - Ensure the iptables flag in sysctl configuration is set to 1.
    ::
        sudo tee -a /etc/sysctl.d/k8s.conf <<EOF >/dev/null
        net.bridge.bridge-nf-call-ip6tables = 1
        net.bridge.bridge-nf-call-iptables = 1
        EOF

  - Reload the system configuration.
    ::
        sudo sysctl --system
  
  - Install kubeadm, kubelet and kubectl.
    ::
        sudo yum install -y kubelet-1.8.5-0 kubeadm-1.8.5-0 kubectl-1.8.5-0

  - Ensure the --cgroup-driver kubelet flag is set to the same value as Docker.
    ::
        sudo sed -i -E 's/--cgroup-driver=systemd/--cgroup-driver=cgroupfs/' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

  - Execute the below step to enable and start the kubelet service.
    ::
        sudo systemctl enable kubelet && sudo systemctl start kubelet    

Create Cluster using kubeadm
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Perform the following operations on the **Master Node**.

  - Install wget.
    ::
      sudo yum install -y wget
  
  - Download and configure the JSON parser jq.
    ::
      wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
      chmod +x ./jq
      sudo mv jq /usr/bin

  - Initialize your master.
    ::
      sudo kubeadm init --apiserver-advertise-address=<vagrant_vm_ipaddress>
  
  - Configure the Kubernetes config.
    ::
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config

  - Patch kube-proxy for CNI Networks.
    ::
      kubectl -n kube-system get ds -l 'k8s-app=kube-proxy' -o json \
      | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
      | kubectl apply -f - \
      && kubectl -n kube-system delete pods -l 'k8s-app=kube-proxy'

  - Install Pod Network - Weave
    ::
      export kubever=$(kubectl version | base64 | tr -d '\n')
      kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"   

* Perform the following operations on the **Worker Nodes**.

  - Join the cluster
    ::
      sudo kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
    
  - Install ISCSI.
    ::
      sudo yum install -y iscsi-initiator-utils
  
  - Execute the below step to enable and start the iscsid service.
    ::
      sudo systemctl enable iscsid && sudo systemctl start iscsid

**Note:**
OpenEBS uses iSCSI to connect to the block volumes. So steps 2 & 3 are required to configure an initiator on the worker nodes.

Setting Up OpenEBS Volume Provisioner
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
* Download the openebs-operator.yaml and openebs-storageclasses.yaml on the Kubernetes Master.
  ::
    wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml
    wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml

* Apply the openebs-operator.yaml file on the Kubernetes cluster. This creates the maya api-server and OpenEBS provisioner deployments.
  ::
    kubectl apply -f openebs-operator.yaml

* Add the OpenEBS storage classes using the following command. This can be used by users to map a suitable storage profile for their applications in their respective persistent volume claims.
  ::
      kubectl apply -f openebs-storageclasses.yaml

* Check whether the deployments are running successfully using the following commands.
  ::
    vagrant@master:~$ kubectl get deployments
    NAME                                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    maya-apiserver                                  1         1         1            1           2m
    openebs-provisioner                             1         1         1            1           2m

* Check whether the pods are running successfully using the following commands.
  ::
    vagrant@master:~$ kubectl get pods
    NAME                                   READY     STATUS    RESTARTS   AGE
    maya-apiserver-1633167387-5ss2w        1/1       Running   0          24s
    openebs-provisioner-1174174075-f2ss6   1/1       Running   0          23s

* Check whether the storage classes are applied successfully using the following commands.
  ::
    vagrant@master:~$ kubectl get sc
    NAME                 TYPE
    openebs-cassandra    openebs.io/provisioner-iscsi
    openebs-es-data-sc   openebs.io/provisioner-iscsi
    openebs-jupyter      openebs.io/provisioner-iscsi
    openebs-kafka        openebs.io/provisioner-iscsi
    openebs-mongodb      openebs.io/provisioner-iscsi
    openebs-percona      openebs.io/provisioner-iscsi
    openebs-redis        openebs.io/provisioner-iscsi
    openebs-standalone   openebs.io/provisioner-iscsi
    openebs-standard     openebs.io/provisioner-iscsi
    openebs-zk           openebs.io/provisioner-iscsi

Running Stateful Workloads using OpenEBS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
* Some sample YAML files for stateful workloads using OpenEBS are provided here_.
.. _here: https://github.com/openebs/openebs/tree/master/k8s/demo
* For more information visit http://openebs.readthedocs.io/en/latest/


Troubleshooting
-----------------
**Issue:** Error while vagrant up.

**Workaround:** Update your virtualbox and vagrant to the latest version.

Using Ansible
===============

Setting Up OpenEBS on Ubuntu Hosts or Virtual Machines
---------------------------------------------------------
This section provides detailed instructions on how to perform the OpenEBS on-premise deployment. The objective of this procedure is to have the following functional.

* Kubernetes cluster (K8s master & K8s nodes/host) configured with the OpenEBS iSCSI flexvol driver,
* OpenEBS Maya Master
* OpenEBS Storage Hosts

Depending on your need, you can either setup only the Kubernetes cluster or the OpenEBS cluster or both. The number of nodes in each category is configurable.

The Kubernetes cluster is setup, in this framework using *kubeadm*.

Running the Setup on Ubuntu 16.04
------------------------------------
The following instructions have been verified on -

* Baremetal and VMware virtual machines installed with Ubuntu 16.04 64 bit
* Ubuntu 16.04 64 bit Vagrant VMs running on Windows 10 (Vagrant (>=1.9.1), VirtualBox 5.1)

Prerequisites:
--------------
* At least three Linux machines of either VMs or bare-metal, if deploying the setup in a hyperconverged mode (with K8s as well as OpenEBS residing on the same machines) or five Linux machines (with K8s and OpenEBS running on separate machines)

* The above instruction assumes a minimal setup with a test-harness, K8s/OpenEBS master and a single K8s node/OpenEBS node. The masters and nodes can be scaled if the user so desires

* All Linux machines must have the following:

  * Basic development packages (dpkg-dev,gcc,g++,libc6-dev,make,libssl-dev,sshpass)
  * Python2.7-minimal
  * SSH services enabled

* The machine used as test-harness must also have the following:

  * Git
  * Ansible (version >= 2.3)

* Deployment can be performed by both root as well as non-root users. In case of the latter, ensure that the users are part of the sudo group. This is required to run certain operations which require root privileges.

**Minimum System Requirements**

The Vagrant VMs (ubuntu-xenial) that are used in the on-premise installation requires a mininum of 10GB hard-disk space each (3 VMs are recommended for a hyperconverged deployment) and 1GB operating memory.

The recommended configuration for the VM host is as follows:

* 40GB Hard Disk
* 4GB RAM
* Minimum of 2 CPU cores / vCPUs (if host is a VMware/other guest box)

Download
----------
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
--------------------------------------------

* Setup environment variables for the usernames and passwords of all the machines which have been brought up in the previous steps on the test-harness (this machine will be interchangeably used with the term 'localhost'). Ensure that these are setup in the **.profile** file of the localhost user which will be running the ansible code or playbooks, that is the ansible_user.

* Ensure that the env variables setup in the previous step are available in the current user session. Perform *source ~/.profile* to achieve the same and verify through echo $VARIABLE.

* Edit the *inventory/machines.in* file to place the latest HostCode, IP, username variable, password variable for all the machines setup. For more details on editing *machines.in*, see the `Inventory README`_.
.. _Inventory README: https://github.com/openebs/openebs/blob/master/e2e/ansible/inventory/README.md

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
     testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-openebs.yml

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
---------------------------------------------

* Update the *inventory/group_vars/all.yml* with the appropriate value *hyperconverged* for the key *deployment_mode*.

* In this mode, the OpenEBS maya-apiserver and openebs-storage provisioner are run as deployments on the Kubernetes cluster with associated pods, and the Kubernetes hosts act as the OpenEBS storage hosts as well. These are setup using an openebs-operator on the Kubernetes cluster. The setup also involves integration of OpenEBS storage-classes into the Kubernetes cluster. These essentially define the storage profile such as size, number of replicas, type of pool atec, and the provisioner associated with it.

  Applications can consume storage by specifying a persistent volume claim in which the storage class is an openebs-storage class.

* Setup the Kubernetes cluster using the setup-kubernetes playbook, followed by the setup-openebs playbook to deploy the OpenEBS pods. Internally, this runs the hyperconverged ansible role which executes the openebs-operator and integrates openebs-storage classes into the Kubernetes cluster.

  * Execute the setup-kubernetes ansible playbook to create the Kubernetes cluster followed by the    setup-openebs playbook. These playbooks install the requisite dependencies on the machines, update the configuration files on the boxes and sets up Kubernetes cluster.
    ::

        testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-kubernetes.yml

        testuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook setup-openebs.yml


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
-----------------------------------------------
* Test the OpenEBS setup installed using the above procedure by deploying a sample application pod.

* *run-hyperconverged-tests.yml* can be used to run tests on the hyperconverged installation.

* By default, all tests are commented in the above playbooks. Uncomment the desired test and execute the playbook. In the example below, a percona mysql DB is deployed on a hyperconverged installation.
  ::

      ciuser@OpenEBSClient:~/openebs/e2e/ansible$ ansible-playbook run-hyperconverged-tests.yml

* Verify that the pod is deployed on the Kubernetes nodes along with the OpenEBS storage pods created as per the storage-class in the persistent volume claim, by executing the following command on the Kubernetes master.
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
------------------
* Use the -v flag while running the playbooks to enable verbose output and logging. Increase the number of 'v's to increase the verbosity.

* Sometimes, the nodes take time to join the Kubernetes master. This could be caused due to slow internet or less resources on the box. The time could range between a few seconds to a few minutes.

* With regards to the nodes above, OpenEBS volume containers (Jiva containers) may take some time to get initialized (involves a docker pull) before they are ready to input/output. Any pod deployment (which uses the openEBS iSCSI flexvol driver) while in progress, gets queued and resumes once the storage is ready.
