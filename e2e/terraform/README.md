# OpenEBS On The Cloud - Deployment Using Terraform and kops (Kubernetes Operations)

The purpose of this user guide is to provide the instructions to set up a Kubernetes cluster on AWS (Amazon Web Services) and have OpenEBS running in hyperconverged mode.

## Pre-requisites

Follow the steps below to setup-up the pre-requisites:

**Amazon Web Services (AWS):**

- Signup for AWS [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).

People who already have an AWS account can skip the above step.

- Start your browser.
- Open *AWS Management Console*.
- Select *IAM* under *Security, Identity & Compliance*.
- In the *Dashboard*, click on *Users*.
- Click on *Add User* button.
- For the *User name* textbox, give *openebsuser01* as the username.
- Select *Access Type* as *Programmatic access*.
- Click on *Next Permissions* button.
- Select *Attach existing policies directly*.
- In the *Search Box* type *IAMFullAccess* and select the listed permission.
- Click on *Next Review* button.
- Click on *Create User* button.

A user, named *openebsuser01* would have been created and an *Access key ID* and a *Secret access key*
would have been assigned to him.

```
For Example:
User              Access key ID             Secret access key
openebsuser01     AKIAI3MRLHNGU6CNKJQE      udxZi33tvSptXCky31kEt4KLRS6LSMMsmmdLx501
```

>Record the *Access key ID* and the *Secret access key* as AWS will not show it to you again.

**kops, terraform and awscli:**

The following tools have to be installed on your local workstation:

- `awscli`
- `kops >= 1.6.2`
- `terraform >= 0.9.11`

We have created a script that does most of the work for you. Download the script file called `oebs-cloud.sh`.

```
$ mkdir -p openebs
$ cd openebs
$ wget https://raw.githubusercontent.com/openebs/openebs/master/e2e/terraform/oebs-cloud.sh
$ chmod +x oebs-cloud.sh
```

List the operations performed by the script:
```
$ ./oebs-cloud.sh
Usage : oebs-cloud.sh --setup-local-env
        oebs-cloud.sh --create-cluster-config
        oebs-cloud.sh --ssh-aws-ec2

Sets Up OpenEBS On AWS

-h|--help                       Display this help and exit.
--setup-local-env               Sets up, AWSCLI, Terraform and KOPS.
--create-cluster-config         Generates a terraform file(.tf) and Passwordless SSH
--ssh-aws-ec2                   SSH to Kubernetes Master on EC2 instance.

```

Lets go ahead and install the tools, run the following command:

```
$ ./oebs-cloud.sh --setup-local-env
```

The command will install `awscli`, `terraform` and `kops` on the workstation.

**Updating .profile file:**

The tools `awscli` and `kops` require the AWS credentials to access AWS services.

- Let us use the credentials that were generated earlier for the user *openebsuser01*.
- Add the path */usr/local/bin* to PATH environment variable.

```
$ vim ~/.profile

# Add the AWS credentials as environment variables in .profile
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret key>

# Add /usr/local/bin to PATH
PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

$ source ~/.profile
```

## Creating The Config For Cluster

- We will be generating a terraform file(.tf) that will later spawn:
  - One Master
  - Two Minions
- Run the following command in a terminal.

```
$ ./oebs-cloud.sh --create-cluster-config
```

- A terraform file(.tf), named `kubernetes.tf` is generated in the same directory.
- Passwordless SSH connection between the local workstation and the remote EC2 instances is also established.

## Create Cluster On AWS Using terraform

- Verify the success of your `terraform` installation, by running the below command.

```
$ terraform
Usage: terraform [--version] [--help] <command> [args]

The available commands for execution are listed below.
The most common, useful commands are shown first, followed by
less common or more advanced commands. If you're just getting
started with Terraform, stick with the common commands. For the
other commands, please read the help and docs before usage.

Common commands:
    apply              Builds or changes infrastructure
    console            Interactive console for Terraform interpolations
# ...
```

- Run the command `terraform init` to initialize `terraform`.
- Run the command `terraform plan` from the directory where the generated terraform file(.tf) is placed.
- `terraform` outputs a chuck of JSON data containing the changes that would be applied on AWS.
- `terraform plan` command also verifies your terraform files(.tf) and outputs any errors that it encountered.
- Fix these errors and re-verify with `terraform plan` before running the `terraform apply` command.
- Run the command `terraform apply` to initiate the creation of the infrastructure.

## SSH To The Master Node

- From your workstation run the below command to connect to the EC2 instance running the Kubernetes Master.

```
$ ./oebs-cloud.sh --ssh-aws-ec2
```

- You should now be running inside the EC2 instance.

## Deploy OpenEBS On AWS

Deploying OpenEBS requires Kubernetes to be already running on the EC2 instances. Lets verify if a Kubernetes cluster has been created.

```
ubuntu@ip-172-20-53-140:~$ kubectl get nodes 
NAME                            STATUS    AGE       VERSION 
ip-172-20-36-126.ec2.internal   Ready     1m        v1.7.0 
ip-172-20-37-115.ec2.internal   Ready     1m        v1.7.0 
ip-172-20-53-140.ec2.internal   Ready     3m        v1.7.0
```

- This will output any cluster information if the cluster was created.
- Download the *openebs-operator* and *openebs-storage-classes* yamls from the below location.

```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml
```

- Apply the *openebs-operator* and *openebs-storage-classes* to the Kubernetes cluster.

```
kubectl create -f openebs-operator.yaml
kubectl create -f openebs-storageclasses.yaml
```

We should now have a working OpenEBS deployment on AWS (Amazon Web Services.)