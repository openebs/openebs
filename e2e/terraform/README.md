# OpenEBS On The Cloud - Deployment Using Terraform and kops (Kubernetes Operations)

The purpose of this user guide is to provide the instructions to set up a Kubernetes cluster on AWS (Amazon Web Services) and have OpenEBS running in hyperconverged mode.

## Pre-requisites

Before starting off with the creation of the cluster and deployment of OpenEBS the following pre-requisites must be met.

- Create an account on AWS

Install the tools listed below on your local workstation:

- `awscli`
- `kops >= 1.6.2`
- `terraform >= 0.9.11`

**Amazon Web Services (AWS)** is a secure cloud services platform, offering compute power, database storage, content delivery and other functionality to help businesses scale and grow. Explore how millions of customers are currently leveraging AWS cloud products and solutions to build sophisticated applications with increased flexibility, scalability and reliability.

>Instructions for signing up for an **AWS (Amazon Web Services)** account can be found [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).

`awscli` **(AWS Command Line Interface)** is a unified tool to manage your AWS services. With just one tool to download and configure, you can control multiple AWS services from the command line and automate them through scripts.

>Instructions for downloading and installing `awscli` can be found [here](https://aws.amazon.com/cli/)

`kops` **(Kubernetes Operations)** is an open-source orchestration tool developed by Kubernetes that helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line.

>Instructions for downloading and installing `kops` can be found [here](https://github.com/kubernetes/kops#installing)

`terraform` is a product from *HashiCorp* that enables you to safely and predictably create, change, and improve production infrastructure. It is an open source tool that codifies APIs into declarative configuration files that can be shared amongst team members, treated as code, edited, reviewed, and versioned.

>Instructions for downloading and installing `terraform` can be found [here](https://www.terraform.io/).

## Prepare AWS

When you signup for AWS, Amazon provides the user with **Access Keys**. The Access Keys consists of:

- AccessKeyID. (for example, AKIAIOSFODNN7EXAMPLE)
- SecretAccessKey. (for example, wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY).

`awscli` requires  these AccessKeyID and a SecretAccessKey to access your AWS. Let us `export` these as environment variables in your local profile as shown below.

```
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret key>
```

We will be using `awscli` for creating a new **AWS IAM (Identity And Access Management)** user-group and an user.

*AWS Identity and Access Management (IAM)* is a web service that helps you securely control access to AWS resources for your users. You use IAM to control who can use your AWS resources (authentication) and what resources they can use and in what ways (authorization).

Verify the success of your `awscli` installation, by running the below command:
```
$ aws --version
aws-cli/1.11.83 Python/2.7.12 Linux/4.9.20-11.31.amzn1.x86_64 botocore/1.5.46
```

Using `awscli`, let us go ahead and create a group called *openebsusers* and assign the group with the required policies.

```
aws iam create-group --group-name openebsusers

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name openebsusers
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name openebsusers
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name openebsusers
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name openebsusers
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name openebsusers
```

The next step would be to create an user, and add him to the group created earlier. We will be creating an user called *openebsuser01*.

```
aws iam create-user --user-name openebsuser01

aws iam add-user-to-group --user-name openebsuser01 --group-name openebsusers
```

Generate **AccessKeys** for the user *openebsuser01*.

```
aws iam create-access-key --user-name openebsuser01
```

You should record the *SecretAccessKey* and *AccessKeyID* from the returned JSON output, and then use them below:

```
# configure the aws client to use your new IAM user
aws configure           # Use your new access and secret key here
aws iam list-users      # you should see a list of all your IAM users here

# Because "aws configure" doesn't export these vars for kops to use, we export them now
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret key>
```

## Generate terraform file(.tf) Using kops

- Verify the success of your `kops` installation, by running the below command.

```
$ kops version
Version 1.7.0 (git-e04c29d)
```

- We will use `kops` to generate a terraform file(.tf).
- `kops` has the ability to output a configuration file that `terraform` can utilize to bring up the infrastructure.
- Let us go ahead and create a terraform file(.tf) for:

  - One Master
  - Two Minions

- Run the below command in a terminal.

```
kops create cluster --cloud=aws \
--master-size=t2.micro \
--master-zones=us-east-1a \
--node-count=2 \
--node-size=t2.micro \
--zones=us-east-1a \
--ssh-public-key=/home/ubuntu/.ssh/id_rsa.pub \
--image=ami-9c3f6ce7 \
--target=terraform \
--out=. \
--name=openebs.k8s.local
```

>Note the --target=terraform and --out=.\ parameters, these parameters tell `kops` to output a terraform file (.tf) into the current directory.

- The generated terraform file(.tf), is named `kubernetes.tf` by default.
- `kops` also establishes a passwordless SSH connection between the local workstation and the remote EC2 instances.
- `kops` also outputs the SSH connection details that can be used to connect to the remote EC2 instances.

>Note: The SSH connection details that `kops` had output cannot be used for a cluster of type *.k8s.local*. Read below regarding Route53 Based DNS Gossip Based DNS for more info.

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

- Run the command `terraform plan` from the directory where the generated terraform file(.tf) is placed.
- `terraform` outputs a chuck of JSON data containing the changes that would be applied on AWS.
- `terraform plan` command also verifies your terraform files(.tf) and outputs any errors that it encountered.
- Fix these errors and re-verify with `terraform plan` before running the `terraform apply` command.
- Run the command `terraform apply` to initiate the creation of the infrastructure.

## Route 53-Based DNS Vs Gossip-Based DNS

Creating a Kubernetes cluster using kops requires a top-level domain or a sub domain and setting up Route 53 hosted zones. This domain allows the worker nodes to discover the master and the master to discover all the etcd servers. This is also needed for kubectl to be able to talk directly with the master.

But from a development point of view, the Route 53 hosted domains are charged and is not part of the Free-Tier that AWS offers.

With the release of kops 1.6.2, Kubernetes has introduced a gossip-based DNS-free protocol, which is based on Weave Mesh. This protocol allows the master and worker nodes to be discoverable without having a registered domain. But the protocol requires that while creating the cluster, the name that is provided to the cluster must end with *.k8s.local*

## Get Kubernetes Master EC2 Instance SSH Details (Specific To .k8s.local Cluster)

- Open your browser and login to *AWS Management Console*.
- Select *Services->EC2*.
- This should bring you to the **EC2 Dashboard**.
- Select *Instances* in the side-menu bar.
- Select the instance having *master* in its name and Click on *Connect* button.
- In the pop-up that is displayed copy the details from:
  - *Connect to your instance using its Public DNS:*
  - An example of the instance name could be - *ec2-34-230-5-248.compute-1.amazonaws.com*

## SSH To The Master Node

- From your workstation run the below command to connect to the EC2 instance running the Kubernetes Master.

```
ssh -i ~/.ssh/id_rsa admin@ec2-34-230-5-248.compute-1.amazonaws.com
```

>Note: id_rsa is your private key that `kops` used to establish the passwordless SSH with the EC2 instances.

- You should now be running inside the EC2 instance.

## Deploy OpenEBS On AWS

Deploying OpenEBS requires Kubernetes to be already available on the EC2 instances. Lets verify if a Kubernetes cluster has been created.

```
kubectl get nodes
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