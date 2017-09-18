# OpenEBS on the Cloud - Deployment using Terraform and kops (Kubernetes Operations)

The purpose of this user guide is to provide the instructions to set up a Kubernetes cluster on AWS (Amazon Web Services) and have OpenEBS running in hyperconverged mode.

## Pre-requisites

Perform the following procedure to setup-up the pre-requisites:

**Amazon Web Services (AWS):**

- Signup for AWS [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).

People who already have an AWS account can skip the above step.

- Start your browser.
- Open *AWS Management Console*.
- Select *IAM* under *Security, Identity & Compliance*.
- In the *Dashboard*, click *Users*.
- Click *Add User* button.
- In the *User name* textbox, enter the name of the user you want to create. For example, *openebuser*.
- Select *Access Type* as *Programmatic access*.
- Click *Next Permissions*.
- Select *Attach existing policies directly*.
- In the *Search Box* enter *IAMFullAccess* and select the listed permission.
- Click *Next Review*.
- Click *Create User*.

A user, named *openebsuser* will be created and an *Access key ID* and a *Secret access key*
will be assigned.

```
Example:
User              Access key ID             Secret access key
openebsuser     AKIAI3MRLHNGUExample      udxZi33tvSptXCky31kEt4KLRS6LSMMsmExample
```

>Note the *Access key ID* and the *Secret access key* as AWS will not display it again.

**kops, terraform and awscli:**

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
        oebs-cloud.sh --create-cluster-config [--ami-vm-os=[ubuntu|coreos]]
        oebs-cloud.sh --list-aws-instances
        oebs-cloud.sh --ssh-aws-ec2 [ ipaddress|=ipaddress]
        oebs-cloud.sh --help

Sets Up OpenEBS On AWS

-h|--help                       Display this help and exit.
--setup-local-env               Sets up, AWSCLI, Terraform and KOPS.
--create-cluster-config         Generates a terraform file(.tf) and Passwordless SSH
--ami-vm-os                     The OS to be used for the Amazon Machine Image.
                                Defaults to Ubuntu.
--list-aws-instances            Outputs the list of AWS instances in the cluster.
--ssh-aws-ec2                   SSH to Amazon EC2 instance with Public IP Address.

```

Run the following command to install the required tools:

```
$ ./oebs-cloud.sh --setup-local-env
```

The command will install the below tools on the workstation:

- `awscli`
- `kops >= 1.6.2`
- `terraform >= 0.9.11`

**Updating .profile file:**

The tools `awscli` and `kops` require the AWS credentials to access AWS services.

- Use the credentials that were generated earlier for the user *openebsuser*.
- Add path */usr/local/bin* to the PATH environment variable.

```
$ vim ~/.profile

# Add the AWS credentials as environment variables in .profile
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret key>

# Add /usr/local/bin to PATH
PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

$ source ~/.profile
```

## Creating the Config For Cluster
- We will be generating a terraform file(.tf) that will later spawn:
  - One Master
  - Two Nodes
- Run the following command in a terminal.

```
$ ./oebs-cloud.sh --create-cluster-config
```

- A terraform file `kubernetes.tf` is generated in the same directory.
- Passwordless SSH connection between the local workstation and the remote EC2 instances is established.

```
Note:
- The script uses *t2.micro* instance for the worker nodes, which should be well within the **Amazon Free Tier** limits.
- But for process intensive containers you may have to modify the script to use *m3.large* instances, which could be charged.
```

## Create Cluster on AWS using Terraform

- Run the following command to verify successful installation of `terraform`.

```
$ terraform
Usage: terraform [--version] [--help] <comman> [args]

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
- Run the command `terraform plan` from the directory where the generated terraform file (.tf) is placed.
  - `terraform` outputs a chunk of JSON data containing changes that would be applied on AWS.
  - `terraform plan` command verifies your terraform files (.tf) and outputs any errors that it encountered.
  - Fix these errors and re-verify with `terraform plan` before running the `terraform apply` command.
- Run the command `terraform apply` to initiate creation of the infrastructure.

## SSH to the Master Node

- From your workstation, run the following command to connect to the EC2 instance running the Kubernetes Master.

```
$ ./oebs-cloud.sh --ssh-aws-ec2
```

- You should now be running inside the EC2 instance.

## Deploy OpenEBS on AWS

Deploying OpenEBS requires Kubernetes to be already running on the EC2 instances. Verify if a Kubernetes cluster has been created.

```
ubuntu@ip-172-20-53-140:~$ kubectl get nodes 
NAME                            STATUS    AGE       VERSION 
ip-172-20-36-126.ec2.internal   Ready     1m        v1.7.0 
ip-172-20-37-115.ec2.internal   Ready     1m        v1.7.0 
ip-172-20-53-140.ec2.internal   Ready     3m        v1.7.0
```

OpenEBS is already deployment by the time you are logged into AWS (Amazon Web Services).

```
ubuntu@ip-172-20-53-140:~$ kubectl get pods
NAME                     READY     STATUS    RESTARTS   AGE
maya-apiserver-h714w      1/1       Running   0          12m
openebs-provisioner-5e6ij 1/1       Running   0          9m

```
