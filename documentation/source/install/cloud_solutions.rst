.. _Setup:

.. _here: https://portal.aws.amazon.com/gp/aws/developer/registration/index.html

*****************
Cloud Solutions
*****************

Amazon Cloud
=============

Setting up OpenEBS with Kubernetes on Amazon Web Services
----------------------------------------------------------

This section provides instructions to set up a Kubernetes cluster on Amazon Web Services (AWS) and to have OpenEBS running in hyper converged mode.

Prerequisites
^^^^^^^^^^^^^
Perform the following procedure to setup the prerequisites for AWS.

1.  Signup for AWS `here`_.
      If you already have an AWS account, skip the above step.
2.  Start your browser.
3.  Open **AWS Management Console**.
4.  Select **IAM** under **Security, Identity & Compliance**.
5.  Under **Dashboard** in the left pane, click **Users**.
6.  Click **Add user**. 
7.  In the **User name** field, enter the name of the user you want to create. For example, *openebsuser*.
8.  Select **Access type** as **Programmatic access**.
9.  Click **Next: Permissions**.
10. Select **Attach existing policies directly**.
11. In the **Search Box**, enter *IAMFullAccess* and select the listed permission.
12. Click **Next: Review**.
13. Click **Create user**.

A *openebsuser* user will be created and an Access key ID and a Secret access key will be assigned as in the following example.
::

     User              Access key ID             Secret access key
     openebsuser     AKIAI3MRLHNGUEXAMPLE      udxZi33tvSptXCky31kEt4KLRS6LSMMsmEXAMPLE

**Note:**

 Note down the *Access key ID* and the *Secret access key* as AWS will not display it again.

kops, terraform and awscli
--------------------------
 
OpenEBS has created a script that does most of the work for you. Download the *oebs-cloud.sh* script file using the following commands.
::

    $ mkdir -p openebs
    $ cd openebs
    $ wget https://raw.githubusercontent.com/openebs/openebs/master/e2e/terraform/oebs-cloud.sh
    $ chmod +x oebs-cloud.sh

The list of operations performed by the *oebs-cloud.sh* script are as follows:
::

    $ ./oebs-cloud.sh
    Usage : 
       oebs-cloud.sh --setup-local-env
       oebs-cloud.sh --create-cluster-config [--ami-vm-os=[ubuntu|coreos]]
       oebs-cloud.sh --list-aws-instances
       oebs-cloud.sh --ssh-aws-ec2  [  ipaddress |=ipaddress]
       oebs-cloud.sh --help

    Sets Up OpenEBS On AWS

     -h|--help                       Displays this help and exits.
     --setup-local-env               Sets up, AWSCLI, Terraform and KOPS.
     --create-cluster-config         Generates a terraform file (.tf) and Passwordless SSH
     --ami-vm-os                     The OS to be used for the Amazon Machine Image.
                                     Defaults to Ubuntu.
     --list-aws-instances            Outputs the list of AWS instances in the cluster.
     --ssh-aws-ec2                   SSH to Amazon EC2 instance with Public IP Address.

Running the following command allows you to install the required tools on your workstation.
::

    $ ./oebs-cloud.sh --setup-local-env

The following tools are installed.

* awscli
* kops >= 1.6.2
* terraform >= 0.9.11

Updating the .profile File
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The tools **awscli** and **kops** require the AWS credentials to access AWS services.

* Use the credentials that were generated earlier for the user *openebsuser*.
* Add path */usr/local/bin* to the PATH environment variable.

::

    $ vim ~/.profile

    # Add the AWS credentials as environment variables in .profile
    export AWS_ACCESS_KEY_ID=<access key>
    export AWS_SECRET_ACCESS_KEY=<secret key>

    # Add /usr/local/bin to PATH
    PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

    $ source ~/.profile

Creating the Cluster Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* You must generate a terraform file (.tf) that will later spawn -

     * One Master
     * Two Nodes

* Run the following command in a terminal.

::

    $ ./oebs-cloud.sh --create-cluster-config

Running *--create-cluster-config* command without any arguments defaults to **Ubuntu**. You can also run *--create-cluster-config* command with *--ami-vm-os=ubuntu* or *--ami-vm-os=coreos* commands and the following occurs.  

* A *kubernetes.tf* terraform file is generated in the same directory.

* Passwordless SSH connection between the local workstation and the remote EC2 instances is established.

**Note:**
      - The script uses *t2.micro* instance for the worker nodes, which must be well within the **Amazon     Free Tier** limits.
      - For process intensive containers you may have to modify the script to use *m3.large* instances,      which could be charged.

Creating a Cluster on AWS using Terraform
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Run the following command to verify successful installation of terraform.

  ::

     $ terraform
     Usage: terraform [--version] [--help] <command> [args]

     The available commands for execution are listed below. The most common and useful 
     commands are shown first,followed by less common or more advanced commands. If you 
     are just getting started with Terraform, use the common commands. For other commands, 
     read the help and documentation before using them.

     Common commands: 

       apply              Builds or changes infrastructure
       console            Interactive console for Terraform interpolations
     # ...

* Run the *terraform init* command to initialize terraform.
* Run the *terraform plan* command from the directory where the generated terraform file (.tf) is placed.

    * Terraform outputs a chunk of JSON data containing changes that would be applied on AWS.
    * *terraform plan* command verifies your terraform files (.tf) and displays errors that it encountered.
    * Fix these errors and verify again with the *terraform plan* command before running the terraform *apply* command.
* Run the command *terraform apply* to initiate infrastructure creation.

List AWS EC2 Instances
^^^^^^^^^^^^^^^^^^^^^^
From your workstation, run the following command to list the AWS EC2 instances created.
::

   $ ./oebs-cloud.sh --list-aws-instances

   Node                             Private IP Address   Public IP Address    
   nodes.openebs.k8s.local          172.20.36.126        54.90.239.23         
   nodes.openebs.k8s.local          172.20.37.115        34.24.169.116       
   masters.openebs.k8s.local        172.20.53.140        34.202.205.27 


SSH to the Kubernetes Node
^^^^^^^^^^^^^^^^^^^^^^^^^^
From your workstation, run the following commands to connect to the EC2 instance running the Kubernetes Master.

**For Ubuntu**
::

  $ ./oebs-cloud.sh --ssh-aws-ec2
  Welcome to Ubuntu 16.04 LTS (GNU/Linux 4.4.0-93-generic x86_64)
  ubuntu@ip-172-20-53-140 ~ $

**For CoreOS**
::

  $ ./oebs-cloud.sh --ssh-aws-ec2
  Container Linux by CoreOS stable (1465.6.0)
  core@ip-172-20-53-140 ~ $

Running *--ssh-aws-ec2* command without any arguments, by default, connects you to the Kubernetes Master. 

You can also run *--ssh-aws-ec2* command as *--ssh-aws-ec2=ipaddress*, where *ipaddress* is the public IP Address of the AWS EC2 instance.

If you want to connect with the Kubernetes minion, run *--ssh-aws-ec2=ipaddress*, where *ipaddress* is the public IP Address of the AWS EC2 instance.

You should now be running inside the AWS EC2 instance.

Deploying OpenEBS on AWS
^^^^^^^^^^^^^^^^^^^^^^^^^^ 
Kubernetes must be running on the EC2 instances while deploying OpenEBS. Verify if a Kubernetes cluster is created.

**For Ubuntu** 
::

     ubuntu@ip-172-20-53-140:~$ kubectl get nodes 
     NAME                            STATUS    AGE       VERSION 
     ip-172-20-36-126.ec2.internal   Ready     1m        v1.7.2 
     ip-172-20-37-115.ec2.internal   Ready     1m        v1.7.2 		 
     ip-172-20-53-140.ec2.internal   Ready     3m        v1.7.2 

OpenEBS is deployed by the time you log in to Amazon Web Services (AWS).
::

   ubuntu@ip-172-20-53-140:~$ kubectl get pods
   NAME                      READY     STATUS    RESTARTS   AGE
   maya-apiserver-h714w      1/1       Running   0          12m
   openebs-provisioner-5e6ij 1/1       Running   0          9m

**For CoreOS**
::

    core@ip-172-20-53-140:~$ kubectl get nodes 
    NAME                            STATUS    AGE       VERSION 
    ip-172-20-36-126.ec2.internal   Ready     1m        v1.7.2 
    ip-172-20-37-115.ec2.internal   Ready     1m        v1.7.2 
    ip-172-20-53-140.ec2.internal   Ready     3m        v1.7.2

OpenEBS is deployed by the time you log in to Amazon Web Services (AWS).
::

    core@ip-172-20-53-140:~$ kubectl get pods
    NAME                      READY     STATUS    RESTARTS   AGE
    maya-apiserver-h714w      1/1       Running   0          12m
    openebs-provisioner-5e6ij 1/1       Running   0          9m


Google Cloud
=============
Setting up OpenEBS with Kubernetes on Google Kubernetes Engine
--------------------------------------------------------------
This section, provides detailed instructions on how to setup and use OpenEBS in Google Kubernetes Engine (GKE). This section uses a three node Kubernetes cluster.

1. Preparing your Kubernetes Cluster
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
You can either use an existing Kubernetes cluster or create a new one. 
To create a new cluster, go to **Google Cloud Platform** -> **Kubernetes Engine** -> **Create Kubernetes Cluster**. 

Minimum requirements for Kubernetes cluster are as follows:

* Machine Type - (Minimum 2 vCPUs)
* Node Image - (Ubuntu)
* Size - (Minimum 3)
* Cluster Version - (1.6.4+)

**Note:**

The example commands below were run on a Kubernetes cluster *demo-openebs03* in zone *us-central1-a* with project unique ID *strong-eon-153112*. When you copy paste the command, ensure that you use the details from your project.

iSCSI Configuration
^^^^^^^^^^^^^^^^^^^^^

Go to **Google Cloud Platform** -> **Compute Engine** -> **VM instances**. The nodes displayed by default in this console are Compute Engine VMs, and you can see them in the console. The display is similar to the following screen.
 
 .. image:: ../_static/compute_engine_vms.png

Select the nodes and click SSH to see the iSCSI configuration.

**Verify that iSCSI is configured**

a. Check that initiator name is configured.
::

    ~$sudo cat /etc/iscsi/initiatorname.iscsi

    ## DO NOT EDIT OR REMOVE THIS FILE!
    ## If you remove this file, the iSCSI daemon will not start.
    ## If you change the InitiatorName, existing access control lists
    ## may reject this initiator.  The InitiatorName must be unique
    ## for each iSCSI initiator.  Do NOT duplicate iSCSI InitiatorNames.
    InitiatorName=iqn.1993-08.org.debian:01:6277ea61267f
    

b. Check if iSCSI service is running using the following commands.
:: 

  ~$sudo service open-iscsi status
  open-iscsi.service - Login to default iSCSI targets
  Loaded: loaded (/lib/systemd/system/open-iscsi.service; enabled; vendor preset: enabled)
  Active: active (exited) since Tue 2017-10-24 14:33:57 UTC; 3min 6s ago
    Docs: man:iscsiadm(8)
          man:iscsid(8)
  Main PID: 1644 (code=exited, status=0/SUCCESS)
           Tasks: 0
          Memory: 0B
             CPU: 0
          CGroup: /system.slice/open-iscsi.service
  Oct 24 14:33:57 gke-cluster-3-default-pool-8b0f2a27-5nr2 systemd[1]: Starting Login to default iSCSI targets...
  Oct 24 14:33:57 gke-cluster-3-default-pool-8b0f2a27-5nr2 iscsiadm[1640]: iscsiadm: No records found
  Oct 24 14:33:57 gke-cluster-3-default-pool-8b0f2a27-5nr2 systemd[1]: Started Login to default iSCSI targets.
c. Repeat steps a and b for the remaining nodes.

2. Run OpenEBS Operator (using Google Cloud Shell)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Before applying OpenEBS Operator, ensure that the administrator context for the cluster is set. The following procedure helps you setup the administrator context.

**Setting up Kubernetes Cluster with Administrator Privileges**

To create or modify service accounts and grant previleges, kubectl must be run with administrator previleges. The following commands help you set up and use the administrator context for Google Kubernetes Engine using the Google Cloud Shell.

a. Initialize credentials to allow kubectl to execute commands on the Kubernetes cluster.
::

    gcloud container clusters list
    gcloud container clusters get-credentials demo-openebs03 --zone us-central1-a

b. Setup the administrator context.

Create an administrator configuration context from the configuration shell using the following commands.
::

    gcloud container clusters list
    kubectl config set-context demo-openebs03 --cluster=gke_strong-eon-153112_us-central1-a_demo-openebs03 --user=cluster-admin

c. Download the latest OpenEBS files using the following commands.
::

    git clone https://github.com/openebs/openebs.git
    cd openebs/k8s

The following commands will prompt you for a username and password. Provide username as *admin*. Password for the admin can be obtained from **Google Cloud Platform** -> **Kubernetes Engine**.

Click the cluster you have created and select **Show Credentials**.

d. Apply OpenEBS Operator and add related OpenEBS Storage Classes, that can be used by developers and applications using the following commands.
::

    kubectl config use-context demo-openebs03
    kubectl apply -f openebs-operator.yaml
    kubectl apply -f openebs-storageclasses.yaml
    kubectl config use-context gke_strong-eon-153112_us-central1-a_demo-openebs03    

**Note:**

Persistent storage is created from the space available on the nodes (default host directory : */var/openebs*). Administrator is provided with additional options of consuming the storage (as outlined in *openebs-config.yaml*). These options will work hand-in-hand with the Kubernetes local storage manager once OpenEBS integrates them in future releases.

3. Running Stateful Workloads with OpenEBS Storage
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To use OpenEBS as persistent storage for your stateful workloads, set the storage class in the Persistent Volume Claim (PVC) to the OpenEBS storage class.

Get the list of storage classes using the following command. Choose the storage class that best suits your application.
::

    kubectl get sc

Some sample YAML files for stateful workloads using OpenEBS are provided in the `openebs/k8s/demo`_
        
  .. _openebs/k8s/demo: https://github.com/openebs/openebs/tree/master/k8s/demo

The *kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml* command creates the following, which can be verified using the corresponding kubectl commands.

* Launch a Jupyter Server, with the specified notebook file from github (kubectl get deployments)
* Create an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data) (kubectl get pvc) (kubectl get pv) (kubectl get pods)
* Expose the Jupyter Server to external world through the URL http://NodeIP:32424 (NodeIP is any of the nodes external IP) (kubectl get pods)

**Note:** To access the Jupyter Server over the internet, set the firewall rules to allow traffic on port 32424 in your GCP / Networking / Firewalls.




