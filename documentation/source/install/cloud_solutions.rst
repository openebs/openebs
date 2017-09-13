*****************
Cloud Solutions
*****************

Amazon Cloud
=============

Setting up OpenEBS with Kubernetes on Amazon EC2 Instances
----------------------------------------------------------

This section provides instructions to set up a Kubernetes cluster on Amazon Web Services (AWS) and to have OpenEBS running in hyper converged mode.

Prerequisites:
^^^^^^^^^^^^^
Perform the following procedure to setup the prerequisites for AWS.

1.  Signup for AWS `here`_.
            .. _here: https://portal.aws.amazon.com/gp/aws/developer/registration/index.html
    If you already have an AWS account, skip the above step.
2.  Start your browser.
3.  Open **AWS Management Console**.
4.  Select **IAM** under **Security, Identity & Compliance**.
5.  Under **Dashboard** in the left pane, click **Users**.
6.  Click **Add user**. 
7.  In the **User name** textbox, enter openebsuser01 as the username.
8.  Select **Access type** as **Programmatic access**.
9.  Click **Next: Permissions**.
10. Select **Attach existing policies directly**.
11. In the search field, enter *IAMFullAccess* and select the listed permission.
12. Click **Next: Review**.
13. Click **Create user**.

A *openebsuser01* user will be created and an Access key ID and a Secret access key will be assigned as in the following example.
::
     User              Access key ID             Secret access key
     openebsuser01     AKIAI3MRLHNGUEXAMPLE      udxZi33tvSptXCky31kEt4KLRS6LSMMsmEXAMPLE

**Note:**

 Note down the *Access key ID* and the *Secret access key* as AWS will not display it again.

kops, terraform and awscli
--------------------------
 
We have created a script that does most of the work for you. Download the *oebs-cloud.sh* script file using the following commands.
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
         oebs-cloud.sh --create-cluster-config
         oebs-cloud.sh --ssh-aws-ec2

     Sets Up OpenEBS On AWS

     -h|--help                       Displays this help and exits.
     --setup-local-env               Sets up, AWSCLI, Terraform and KOPS.
     --create-cluster-config         Generates a terraform file (.tf) and Passwordless SSH
     --ssh-aws-ec2                   SSH to Kubernetes Master on EC2 instance.

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

* Use the credentials that were generated earlier for the user *openebsuser01*.
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
     * Two Minions

* Run the following command in a terminal:
::
     
     $ ./oebs-cloud.sh --create-cluster-config

* A *kubernetes.tf* terraform file is generated in the same directory.

* Passwordless SSH connection between the local workstation and the remote EC2 instances is established.

Creating a Cluster on AWS using Terraform
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Run the following command to verify successful installation of terraform.
  ::
     $ terraform
     Usage: terraform [--version] [--help] <comman> [args]

The available commands for execution are listed below. The most common and useful commands are shown first, followed by
less common or more advanced commands. If you are just getting started with Terraform, use the common commands. For
other commands, read the help and documentation before using them.

Common commands:
::
     apply              Builds or changes infrastructure
     console            Interactive console for Terraform interpolations
     # ...

* Initialize terraform using the *init* command.
* Run the *terraform plan* command from the directory where the generated terraform file (.tf) is placed.

    * Terraform outputs a chunk of JSON data containing changes that would be applied on AWS.
    * *terraform plan* command verifies your terraform files (.tf) and displays errors that it encountered.
    * Fix these errors and verify again with the *terraform plan* command before running the terraform *apply* command.
* Run the command *terraform apply* to initiate creation of the infrastructure.

SSH to the Master Node
^^^^^^^^^^^^^^^^^^^^^^
* From your workstation, run the following command to connect to the EC2 instance running the Kubernetes Master.
  ::
     $ ./oebs-cloud.sh --ssh-aws-ec2

* You should now be running inside the EC2 instance.

Deploying OpenEBS on AWS
^^^^^^^^^^^^^^^^^^^^^^^^^^
Deploying OpenEBS must have Kubernetes running on the EC2 instances. 

* Verify if Kubernetes cluster is created.
  ::
     ubuntu@ip-172-20-53-140:~$ kubectl get nodes 
     NAME                            STATUS    AGE       VERSION 
     ip-172-20-36-126.ec2.internal   Ready     1m        v1.7.0 
     ip-172-20-37-115.ec2.internal   Ready     1m        v1.7.0 
     ip-172-20-53-140.ec2.internal   Ready     3m        v1.7.0

* This will output cluster information if the cluster was already created.
* Download the *openebs-operator* and *openebs-storage-classes* YAMLs from the locations listed below:

  * wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml
  * wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml

* Use the following commands to apply *openebs-operator* and *openebs-storage-classes* to the Kubernetes cluster.

  * kubectl create -f openebs-operator.yaml
  * kubectl create -f openebs-storageclasses.yaml

You should now have a working OpenEBS deployment on AWS.

Google Cloud
=============
Setting up OpenEBS with Kubernetes on Google Container Engine
------------------------------------------------------------
This section, provides detailed instructions on how to setup and use OpenEBS in Google Container Enginer (GKE). This section uses a three node container cluster.

1. Preparing your Container Cluster

You can either use an existing container cluster or create a new one. 
To create a new cluster, go to **Google Cloud Platform** -> **Container Engine** -> **Create Container Cluster**. 

Minimum requirements for container cluster are as follows:

* Machine Type - (Minimum 2 vCPUs)
* Node Image - (container-vm)
* Size - (Minimum 3)
* Cluster Version - (1.6.4+)

**Note:**

The example commands below were run on a container cluster *demo-openebs03* in zone *us-central1-a* with project unique ID *strong-eon-153112*. When you copy paste the command, ensure that you use the details from your project.

Add iSCSI Support
-----------------

SSH into the nodes of the cluster (**Google Cloud Platform** -> **Compute Engine** -> **VM instances**) to install open-iscsi package. OpenEBS uses iSCSI to connect to the block volumes.
::
   sudo apt-get update
   sudo apt-get install open-iscsi
   sudo service open-iscsi restart

Verify that iSCSI is configured
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Check that initiator name is configured and iSCSI service is running using the following commands.
::
   sudo cat /etc/iscsi/initiatorname.iscsi
   sudo service open-iscsi status

2. Run OpenEBS Operator through Google Cloud Shell

Download the latest OpenEBS Operator files using the following commands.
::
   git clone https://github.com/openebs/openebs.git
   cd openebs/k8s

Setup the kubectl to run in admin context. See `Appendix`_ below for creating an administration context in Google Cloud Platform (GCP. The following commands will prompt you for username and password. Provide username as *admin*. Password for the admin can be obtained from **Google Cloud Platform** -> **Container Engine** -> **(cluster)** -> **Show Credentials**
::
   kubectl config use-context demo-openebs03
   kubectl apply -f openebs-operator.yaml
   kubectl config use-context gke_strong-eon-153112_us-central1-a_demo-openebs03

Add OpenEBS related storage classes, that can then be used by developers and applications using the following command.
::
   kubectl apply -f openebs-storageclasses.yaml

**Note:**

The persistent storage is carved out from the space available on the nodes (default host directory : */var/openebs*). Development is in progress to provide administrator with additional options of consuming the storage (as outlined in *openebs-config.yaml*). These are slated to work hand-in-hand with the local storage manager of Kubernetes that is due in Kubernetes 1.7/1.8.

3. Running Stateful Workloads with OpenEBS Storage

To use OpenEBS as persistent storage for your stateful workloads, set the storage class in the Persistent Volume Claim (PVC) to the OpenEBS storage class.

Get the list of storage classes using the following command. Choose the storage class that best suits your application.
::
   kubectl get sc

Some sample YAML files for stateful workloads using OpenEBS are provided in the `openebs/k8s/demo`_
        
  .. _openebs/k8s/demo: https://github.com/openebs/openebs/tree/master/k8s/demo

The *kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml* command creates the following, which can be verified using the corresponding kubectl commands.

* Launch a Jupyter Server, with the specified notebook file from github (kubectl get deployments)
* Create an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data) (kubectl get pvc) (kubectl get pv) (kubectl get pods)
* Expose the Jupyter Server to external world via the http://NodeIP:32424 (NodeIP is any of the minion nodes external IP) (kubectl get pods)

**Note:** To access the Jupyter Server over the internet, set the firewall rules to allow traffic on port 32424 in you GCP / Networking / Firewalls.

Appendix
--------

Setting Kubernetes Cluster Administration Context
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To create or modify service accounts and grant privileges, kubectl must be run with Administration privileges. The following procedure helps you setup and use the administration context for Google Container Engine through the Google Cloud Shell.

1. Initialize credentials to allow kubectl to execute commands on the container cluster.
   ::
    gcloud container clusters list
    gcloud container clusters get-credentials demo-openebs03 --zone us-central1-a

2. Setup the administration context.

* Access the credentails from **Google Cloud Platform** -> **Container Engine** -> **(cluster)** -> **Show Credentials**.
* Save the *Cluster CA Certificate* to *~/.kube/admin.key*.
* Create a administration configuration context from the configuration shell using the following commands.
  ::
      gcloud container clusters list
      kubectl config set-context demo-openebs03 --cluster=gke_strong-eon-153112_us-central1-a_demo-openebs03 --user=cluster-a

