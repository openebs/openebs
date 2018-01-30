#!/bin/bash

# Enable for logging
# set -x

master_dns_name=
s3_bucket_name=
amazon_machine_image=
ami_vm_os="ubuntu"
run_cluster_func=false
run_ssh_func=false
openebs_pod_status=
public_ip_addr=
terraform_url=

function show_help() {
    cat << EOF
Usage : $(basename "$0") --setup-local-env
        $(basename "$0") --create-cluster-config [--ami-vm-os=[ubuntu|coreos]]
        $(basename "$0") --list-aws-instances
        $(basename "$0") --ssh-aws-ec2[ ipaddress|=ipaddress]
        $(basename "$0") --delete-cluster 
        $(basename "$0") --help                    

Sets Up OpenEBS On AWS 
    
-h|--help                       Display this help and exit.
--setup-local-env               Sets up, AWSCLI, Terraform and KOPS.
--create-cluster-config         Generates a terraform file(.tf) and Passwordless SSH
--ami-vm-os                     The OS to be used for the Amazon Machine Image.
                                Defaults to Ubuntu.
--list-aws-instances            Outputs the list of AWS instances in the cluster.
--ssh-aws-ec2                   SSH to Amazon EC2 instance with Public IP Address.
--delete-cluster 		Deletes the Kubernetes cluster 
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

function add_network_rules() {

    cat <<'EOF' >>kubernetes.tf
resource "aws_security_group_rule" "allow_all_node_inbound" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.nodes-openebs-k8s-local.id}"
}

resource "aws_security_group_rule" "allow_all_node_outbound" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.nodes-openebs-k8s-local.id}"
}
EOF
}

function start_iscsi_services() {

    cat <<'EOF' >>data/aws_launch_configuration_nodes.openebs.k8s.local_user_data
sudo modprobe iscsi_tcp
sudo systemctl start iscsid-initiatorname
sudo systemctl start iscsid
EOF
}

function setup_local_env() {

    echo "Installing Prerequisites..."

    sudo apt-get update
    sudo apt-get install -y unzip curl wget jq

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
        terraform_url=$(curl https://releases.hashicorp.com/index.json | jq '{terraform}' | grep -E "linux.*amd64" | sort --version-sort -r | grep -E -v 'beta|rc' | head -1 | awk -F[\"] '{print $4}')
        curl -o terraform.zip $terraform_url
        unzip terraform.zip
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

    get_current_user=$(aws iam get-user | grep UserName | awk '{print $2}' | tr -d '", ')
    
    echo -ne "Creating Group on AWS for OpenEBS Admins..."
    
    aws iam create-group --group-name openebsadmins &
    show_progress_bar

    echo ""
    echo -ne "Attaching group policies to OpenEBS Admins..."

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name openebsadmins &
    show_progress_bar

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name openebsadmins &
    show_progress_bar

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name openebsadmins &
    show_progress_bar

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name openebsadmins &
    show_progress_bar

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name openebsadmins &
    show_progress_bar

    echo ""
    
    aws iam add-user-to-group --user-name $get_current_user --group-name openebsadmins &
    show_progress_bar
    
    create_terraform_file
    
}

function create_terraform_file() {

    echo -ne "Creating S3 bucket to store cluster state..."
    
    # Wait for AWS to refresh
    sleep 60 &
    show_progress_bar

    # Create unique S3 bucket name for each user
    # Amazon S3 bucket names are universal
    s3_bucket_name=$(echo $(mktemp)| tr '[:upper:]' '[:lower:]' | cut -d '.' -f 2)
    
    aws s3api create-bucket --bucket openebs-k8s-`echo $s3_bucket_name`-local-state-store &
    show_progress_bar

    if [ -e ~/.ssh/id_rsa.pub ];then
        echo "Using Public Key for Passwordless SSH."
    else
        echo "Generating Public Key for Passwordless SSH"
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    fi

    echo "Generating terraform file(.tf)"

    if [ "$ami_vm_os" = "ubuntu" ]; then
        # Ubuntu Image
        amazon_machine_image="ami-2757f631"
    else 
    
        if [ "$ami_vm_os" = "coreos" ]; then
            # CoreOS Image
            amazon_machine_image="ami-ee774a95"
        fi
    fi

    kops create cluster --cloud=aws \
    --master-size=t2.micro \
    --master-zones=us-east-1c \
    --node-count=2 \
    --node-size=t2.micro \
    --zones=us-east-1c \
    --image=$amazon_machine_image \
    --state=s3://openebs-k8s-`echo $s3_bucket_name`-local-state-store \
    --target=terraform \
    --out=. \
    --name=openebs.k8s.local

    add_network_rules

    if [ "$ami_vm_os" = "coreos" ]; then
        # CoreOS
        start_iscsi_services
    fi
    show_terraform_commands
}

function apply_openebs_operator(){
    
    if [ "$amazon_machine_image" = "ami-2757f631" ]; then        
        # Ubuntu Image
        ssh -i ~/.ssh/id_rsa ubuntu@$public_ip_addr 'source /etc/profile; kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml'
        ssh -i ~/.ssh/id_rsa ubuntu@$public_ip_addr 'source /etc/profile; kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml'
    else
        if [ "$amazon_machine_image" = "ami-ee774a95" ]; then
            echo "Apply OpenEBS Operator..." 
            # CoreOS Image
            ssh -i ~/.ssh/id_rsa core@$public_ip_addr 'source /etc/profile; kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml'
            ssh -i ~/.ssh/id_rsa core@$public_ip_addr 'source /etc/profile; kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml'
        fi
    fi 

}

function aws_instance_list(){

    mapfile -t groupname < <(aws ec2 describe-instances --region us-east-1 --query 'Reservations[*].Instances[*].[SecurityGroups[].GroupName]' --output text) 
    
    mapfile -t publicip < <(aws ec2 describe-instances --region us-east-1 --query 'Reservations[*].Instances[*].[NetworkInterfaces[].PrivateIpAddresses[].Association.PublicIp]' --output text)
    
    mapfile -t privateip < <(aws ec2 describe-instances --region us-east-1 --query 'Reservations[*].Instances[*].[NetworkInterfaces[].PrivateIpAddresses[].PrivateIpAddress]' --output text)    

    size=${#groupname[@]}
    
    printf "%-30s %-20s %-20s %s\n" "      Node" "Private IP Address" "Public IP Address" 
    for ((i = 0; i != size; i++)); do
        printf "%-32s %-20s %-20s %s\n" "${groupname[i]}" "${privateip[i]}" "${publicip[i]}" 
    done

    cat << EOF

SSH to nodes using the following command:

bash $(basename "$0") --ssh-aws-ec2[ public_ipaddress|=public_ipaddress]

EOF

}

function ssh_aws_ec2() {


    disp_conn_node="Connecting to Kubernetes Worker Node..."
    amazon_machine_image=$(aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].ImageId' | tail -n 2 | head -n 1 | tr -d '" ')
    
    is_node_master=$(aws ec2 describe-instances --region us-east-1 --filters "Name=ip-address, Values=$public_ip_addr" --query 'Reservations[].Instances[].[SecurityGroups[].GroupName]' | grep masters)

    if [ "$amazon_machine_image" = "ami-2757f631" ]; then
        # Ubuntu Image

        if [ ! -z "$is_node_master" ]; then

            disp_conn_node="Connecting to Kubernetes Master Node..."
 
            openebs_pod_status=$(ssh -i ~/.ssh/id_rsa ubuntu@$public_ip_addr 'source /etc/profile; kubectl get pods | grep -q maya-apiserver; if [ $? -ne 0 ]; then echo "true"; else echo "false"; fi')

            if [ "$openebs_pod_status" = "true" ]; then
                # Apply OpenEBS Operator to the kubernetes cluster
                apply_openebs_operator            
            fi
        fi
        echo $disp_conn_node
        ssh -i ~/.ssh/id_rsa ubuntu@$public_ip_addr
    else
        if [ "$amazon_machine_image" = "ami-ee774a95" ]; then
            # CoreOS Image

            if [ ! -z "$is_node_master" ]; then

                disp_conn_node="Connecting to Kubernetes Master Node..."
 
                openebs_pod_status=$(ssh -i ~/.ssh/id_rsa core@$public_ip_addr 'source /etc/profile; kubectl get pods | grep -q maya-apiserver; if [ $? -ne 0 ]; then echo "true"; else echo "false"; fi')

                if [ "$openebs_pod_status" = "true" ]; then
                    # Apply OpenEBS Operator to the kubernetes cluster
                    apply_openebs_operator
                fi
            fi
            echo $disp_conn_node
            ssh -i ~/.ssh/id_rsa core@$public_ip_addr
        fi
    fi    
    
}

function delete_cluster()
{
    while true; do
        read -p "Do you really wish to delete the cluster (y/n)?" yn
        case $yn in
            [Yy]* )
                  # Get state details from config data generated by cluster creation
                  clusterstate=`grep -r ConfigBase data | head -1 | awk '{print $2}' | sed 's|/openebs.k8s.local||g'`

                  # Perform kops delete cluster 
                  echo "Deleting the cluster.."
                  kops delete cluster --name=openebs.k8s.local --state=$clusterstate --yes  
   
                  # Remove the empty S3 bucket
                  aws s3api delete-bucket --bucket=`echo $clusterstate | sed 's|s3://||g'` 

                  # Perform cleanup on localhost by removing terraform files and cluster scripts 
                  rm -rf kubernetes.tf terraform.tfstate terraform.tfstate.backup data
                  
                  exit;;
            
            [Nn]* )
                  echo  "Cluster deletion is aborted" 
                  exit;;
       
            * ) 
               echo "Please answer yes(Y|y) or no(N|n)"
        esac
    done
}

function is_valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function show_progress_bar() {

    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"

}

if (($# == 0)); then
    show_help
    exit 2
fi

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|-\?|--help)  # Call a "show_help" function to display a synopsis, then exit.
                        show_help
                        exit
                        ;;

        --setup-local-env)  # Takes an option argument, ensuring it has been specified.
                        setup_local_env
                        exit
                        ;;
        --list-aws-instances) # Display the public dns names of aws instances
                        aws_instance_list
                        exit
                        ;;
        --ssh-aws-ec2)  # Takes an option argument, 
                        # ensuring it has been specified.
                        if [ -n "$2" ]; then
                           is_valid_ip $(echo $2)
                            if [ $? -eq 0 ]; then
                                public_ip_addr=$(echo $2)
                                is_aws_node=$(aws ec2 describe-instances --region us-east-1 --filters "Name=ip-address, Values=$public_ip_addr" --output text)
                                if [ -z "$is_aws_node" ]; then
                                    echo "Not a valid AWS Node"
                                    exit;
                                fi 
                                run_ssh_func=true
                            else 
                                 echo "Invalid IP Address"
                                 exit; 
                            fi                     
                        else
                            master_dns_name=$(aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].[SecurityGroups[].GroupName,PublicDnsName]' | grep -A 2 masters | grep ec2 | tr -d '" ')
                           
                            public_ip_addr=$(aws ec2 describe-instances --region us-east-1 --filters "Name=dns-name, Values=$master_dns_name" --query 'Reservations[*].Instances[*].[NetworkInterfaces[].PrivateIpAddresses[].Association.PublicIp]' --output text)
                            run_ssh_func=true
                        fi
                        ;;

        --ssh-aws-ec2=?*)  # Delete everything up to "=" 
                        # and assign the remainder.                        
                        is_valid_ip $(echo ${1#*=})
                        if [ $? -eq 0 ]; then
                            public_ip_addr=$(echo ${1#*=})
                            is_aws_node=$(aws ec2 describe-instances --region us-east-1 --filters "Name=ip-address, Values=$public_ip_addr" --output text)
                            if [ -z "$is_aws_node" ]; then
                                echo "Not a valid AWS Node"
                                exit;
                            fi
                            run_ssh_func=true
                        else
                             echo "Invalid IP Address"
                             exit;
                        fi
                        ;;

        --ssh-aws-ec2=)    # Handle the case of an empty --ami_vm_os=
                            master_dns_name=$(aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].[SecurityGroups[].GroupName,PublicDnsName]' | grep -A 2 masters | grep ec2 | tr -d '" ')

                            public_ip_addr=$(aws ec2 describe-instances --region us-east-1 --filters "Name=dns-name, Values=$master_dns_name" --query 'Reservations[*].Instances[*].[NetworkInterfaces[].PrivateIpAddresses[].Association.PublicIp]' --output text)
                            run_ssh_func=true
                        ;;


        --create-cluster-config)  # Takes an option argument, ensuring it has been specified.
                        run_cluster_func=true                        
                        ;;

        --ami-vm-os)  # Takes an option argument, 
                        # ensuring it has been specified.
                        if [ -n "$2" ]; then
                            ami_vm_os="$(echo $2 | tr '[:upper:]' '[:lower:]')"                            
                        else
                            ami_vm_os="ubuntu"                            
                        fi
                        ;;
        
        --ami-vm-os=?*)  # Delete everything up to "=" 
                        # and assign the remainder.
                        ami_vm_os="$(echo ${1#*=} | tr '[:upper:]' '[:lower:]')" 
                        ;;
        
        --ami-vm-os=)    # Handle the case of an empty --ami_vm_os=
                        ami_vm_os="ubuntu"
                        ;;
       
        --delete-cluster) # Delete the cluster on AWS
                        delete_cluster_func=true
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

if [ "$run_cluster_func" = true ] ; then
    create_cluster_config
fi

if [ "$run_ssh_func" = true ] ; then
    ssh_aws_ec2
fi

if [ "$delete_cluster_func" = true ] ; then
    delete_cluster
fi 
