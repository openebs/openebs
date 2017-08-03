# OpenEBS On The Cloud - Deployment Using Terraform and kops (Kubernetes Operations)

*Terraform* enables you to safely and predictably create, change, and improve production infrastructure. It is an open source tool that codifies APIs into declarative configuration files that can be shared amongst team members, treated as code, edited, reviewed, and versioned.

*kops (Kubernetes Operations)* helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line.

The purpose of this user guide is to provide the user with instructions to set up a Kubernetes cluster on AWS (Amazon Web Services) and have OpenEBS running in hyperconverged mode in the cluster.

**Pre-requisites:**

- Active AWS account.
- Hashicorp terraform >= 0.9.11
- kops >= 1.6.2

## Prepare AWS For kops And Terraform

- Signup for AWS (Amazon Web Services).
- Amazon provides a AccessKeyID and a SecretAccessKey for the user.
- Save the AccessKeyID and a SecretAccessKey as environment variables in your local machine.

```
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret key>
```

- In AWS create a IAM (Identity and Access Management) user group.
- Assign the following permissions to the group.

  - AmazonEC2FullAccess
  - AmazonRoute53FullAccess
  - AmazonS3FullAccess
  - IAMFullAccess
  - AmazonVPCFullAccess

- Now create a new user and add him to the group created earlier.

## Use kops To Create The Terraform File

- *kops* has the ability to output a configuration file that *terraform* can utilize to bring up the infrastructure.
- We will be using *kops create cluster* command to create a cluster of:

  - One Master
  - Two Minions

- Copy the below command in a terminal.

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

- Note the --target=terraform and --out=.\ parameters, these parameters tell kops to output a terraform file (.tf) in the current directory.
- The generated terraform file(.tf), is named kubernetes.tf by default.
- kops establishes a passwordless SSH connection between the local workstation and the remote EC2 instances.
- kops also dumps the SSH connection details that can be used to connect to the remote EC2 instances.

## Creating Cluster On AWS Using Terraform File

- terraform usually looks for terraform file(.tf) in the location where the terraform commands are run.
- Run the command *terraform plan* to see the preview of the changes to the AWS infrasructure.
- terraform outputs a chuck of JSON data containing the changes that would be applied on AWS.
- *terraform plan* command also acts as a verifier of terraform files. It outputs any errors that the terraform file might have, that could break the creation of the infrastructure when running the *terraform apply* command.
- Run the command *terraform apply* to initiate the creation of the infrastructure.

## Route 53-Based DNS Vs Gossip-Based DNS

Creating a Kubernetes cluster using kops requires a top-level domain or a sub domain and setting up Route 53 hosted zones. This domain allows the worker nodes to discover the master and the master to discover all the etcd servers. This is also needed for kubectl to be able to talk directly with the master.

But from a development point of view, the Route 53 hosted domains are charged and is not part of the Free-Tier that AWS offers.

With the release of kops 1.6.2, Kubernetes has introduced a gossip-based DNS-free protocol, which is based on Weave Mesh. This protocol allows the master and worker nodes to be discoverable without having a registered domain. But the protocol requires that while creating the cluster, the name that is provided to the cluster must end with *.k8s.local*

## Deploy OpenEBS On AWS

Deploying OpenEBS requires Kubernetes to be already available on the EC2 instances. Lets verify if a Kubernetes cluster has been created.

- SSH into the master node of the cluster and type the following command on the terminal.

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