*************
Google Cloud
*************

Setting up OpenEBS with Kubernetes on Google Container Engine
=============================================================

This section provides instructions to set up a Kubernetes cluster on Amazon Web Services (AWS) and to have OpenEBS running in hyperconverged mode.

Prerequisites:
-------------
Perform the following procedure to setup the prerequisites for AWS:

1. Signup for AWS `here`_.
            .. _here: https://portal.aws.amazon.com/gp/aws/developer/registration/index.html
If you already have an AWS account, skip the above step.

2.  Start your browser.
3.  Open **AWS Management Console**.
4.  Select **IAM** under **Security, Identity & Compliance**.
5.  In the **Dashboard**, click **Users**.
6.  Click **Add User**. 
7.  In the **User name** textbox, enter openebsuser01 as the username.
8.  Select **Access Type** as **Programmatic** access.
9.  Click **Next Permissions**.
10. Select **Attach existing policies directly**.
11. In the **Search Box** enter IAMFullAccess and select the listed permissions.
12. Click **Next Review**.
13. Click **Create User**.

A user, named *openebsuser01* will be created and an Access key ID and a Secret access key will be assigned as in the following example:
::
     User              Access key ID             Secret access key
     openebsuser01     AKIAI3MRLHNGU6CNKJQE      udxZi33tvSptXCky31kEt4KLRS6LSMMsmmdLx501

**Note:**

 Note down the *Access key ID* and the *Secret access key* as AWS will not display it again.

kops, terraform and awscli
--------------------------
 
We have created a script that does most of the work for you. Download the script file *oebs-cloud.sh*:
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

Running the following command allows you to install the required tools on your workstation:
::
     $ ./oebs-cloud.sh --setup-local-env

The following tools are installed:

* awscli
* kops >= 1.6.2
* terraform >= 0.9.11

Updating the .profile file:
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

* You must generate a terraform file (.tf) that will later spawn:

     * One Master
     * Two Minions

* Run the following command in a terminal:
::
     
     $ ./oebs-cloud.sh --create-cluster-config

* A terraform file *kubernetes.tf* is generated in the same directory.

* Passwordless SSH connection between the local workstation and the remote EC2 instances is established.

Creating a Cluster on AWS using Terraform
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Run the following command to verify successful installation of terraform:
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
* Run the command *terraform plan* from the directory where the generated terraform file (.tf) is placed.
     * terraform outputs a chunk of JSON data containing changes that would be applied on AWS.
     * *terraform plan* command verifies your terraform files (.tf) and displays errors that it encountered.
     * Fix these errors and verify again with the *terraform plan* command before running the terraform *apply* command.
* Run the command terraform apply to initiate creation of the infrastructure.

SSH to the Master Node
^^^^^^^^^^^^^^^^^^^^^^
* From your workstation, run the following command to connect to the EC2 instance running the Kubernetes Master.
  ::
     $ ./oebs-cloud.sh --ssh-aws-ec2

* You should now be running inside the EC2 instance.

Deploying OpenEBS on AWS
^^^^^^^^^^^^^^^^^^^^^^^^^^
Deploying OpenEBS must have Kubernetes running on the EC2 instances. 

* Verify if a Kubernetes cluster is created.
  ::
     ubuntu@ip-172-20-53-140:~$ kubectl get nodes 
     NAME                            STATUS    AGE       VERSION 
     ip-172-20-36-126.ec2.internal   Ready     1m        v1.7.0 
     ip-172-20-37-115.ec2.internal   Ready     1m        v1.7.0 
     ip-172-20-53-140.ec2.internal   Ready     3m        v1.7.0

* This will output any cluster information if the cluster was already created.
* Download the *openebs-operator* and *openebs-storage-classes* YAMLs from the locations listed below:

  * wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml
  * wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml

* Use the following commands to apply *openebs-operator* and *openebs-storage-classes* to the Kubernetes cluster.

  * kubectl create -f openebs-operator.yaml
  * kubectl create -f openebs-storageclasses.yaml

You should now have a working OpenEBS deployment on AWS.