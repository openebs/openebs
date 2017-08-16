#!/bin/bash

set -e

master_dns_name=

function show_help() {
    cat << EOF
    Usage : $(basename "$0") --setup-local-env
            $(basename "$0") --create-cluster-config
            $(basename "$0") --ssh-aws-ec2
            $(basename "$0") --help                    

    Sets Up OpenEBS On AWS 
    
    -h|--help                       Display this help and exit.
    --setup-local-env               Sets up, AWSCLI, Terraform and KOPS.
    --create-cluster-config         Generates a terraform file(.tf) and Passwordless SSH
    --ssh-aws-ec2                   SSH to Kubernetes Master on EC2 instance.                             
EOF
}

function show_terraform_commands() {
    cat << EOF
    Run the terraform commands in the following order:
    $ terraform init
    $ terraform plan
    $ terraform apply
EOF
}

function --setup-local-env() {

    echo "Installing Pre-requisites..."

    sudo apt-get update
    sudo apt-get install -y unzip curl wget

    IS_AWS_CLI_INSTALLED=$(which aws >> /dev/null 2>&1; echo $?)
    if [ $IS_AWS_CLI_INSTALLED -eq 0 ]; then
        echo "aws is installed; Skipping"
        sleep 2
    else
        echo "Missing aws; Installing..."
        sudo apt-get update
        sudo apt-get install -y python-pip
        sudo -H pip install awscli
    fi

    IS_TERRAFORM_INSTALLED=$(which terraform >> /dev/null 2>&1; echo $?)
    if [ $IS_TERRAFORM_INSTALLED -eq 0 ]; then
        echo "terraform is installed; Skipping"
        sleep 2
    else 
        echo "Missing terraform; Downloading and installing..."
        wget "https://releases.hashicorp.com/terraform/0.10.0/terraform_0.10.0_linux_amd64.zip"
        unzip terraform_0.10.0_linux_amd64.zip
        chmod +x terraform
        sudo mv terraform /usr/local/bin/terraform
    fi

    IS_KOPS_INSTALLED=$(which kops >> /dev/null 2>&1; echo $?)
    if [ $IS_KOPS_INSTALLED -eq 0 ]; then
        echo "kops is installed; Skipping"
        sleep 2
    else
        echo "Missing kops; Downloading and installing..."
        wget "https://github.com/kubernetes/kops/releases/download/1.7.0/kops-linux-amd64"
        chmod +x kops-linux-amd64
        sudo mv kops-linux-amd64 /usr/local/bin/kops
    fi
}

function create_cluster_config() {

    echo "Creating Group on AWS for OpenEBS Users..."
    aws iam create-group --group-name openebsusers

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name openebsusers

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name openebsusers

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name openebsusers

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name openebsusers

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name openebsusers

    aws iam add-user-to-group --user-name openebsuser01 --group-name openebsusers
    
    create_terraform_file
    
}

function create_terraform_file() {

    echo "Creating S3 bucket to store cluster state..."
    aws s3api create-bucket --bucket openebs-k8s-local-state-store

    if [ -e ~/.ssh/id_rsa.pub ];then
        echo "Using Public Key for Passwordless SSH."
    else
        echo "Generating Public Key for Passwordless SSH"
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    fi

    echo "Generating terraform file(.tf)"

    kops create cluster --cloud=aws \
    --master-size=t2.micro \
    --master-zones=us-east-1a \
    --node-count=2 \
    --node-size=t2.micro \
    --zones=us-east-1a \
    --image=ami-2757f631 \
    --state=s3://openebs-k8s-local-state-store \
    --target=terraform \
    --out=. \
    --name=openebs.k8s.local

    show_terraform_commands
}

function ssh_aws_ec2() {

    master_dns_name=`aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].[SecurityGroups[].GroupName,PublicDnsName]' | grep -A 2 masters | grep ec2 | tr -d '"'`
    if [ -z "$master_dns_name" ]; then
        echo " The EC2 instance is not available yet."
        exit 1
    fi    
    ssh -i ~/.ssh/id_rsa ubuntu@$master_dns_name
}

if (($# == 0)); then
    show_help
    exit 2
fi

while :; do
    case $1 in
        -h|-\?|--help)  # Call a "show_help" function to display a synopsis, then exit.
                        show_help
                        exit
                        ;;

        --setup-local-env)  # Takes an option argument, ensuring it has been specified.
                        setup_local_env
                        exit
                        ;;
        
        --ssh-aws-ec2)  # Takes an option argument, ensuring it has been specified.
                        ssh_aws_ec2
                        exit
                        ;;

        --create-cluster-config)  # Takes an option argument, ensuring it has been specified.
                        create_cluster_config
                        exit
                        ;;
        
        --)             # End of all options.
                        shift
                        break
                        ;;
        
        -?*)
                        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
                        ;;

        *)              # Default case: If no more options then break out of the loop.
                        break
    esac
shift
done