#!/bin/bash

node_count=$(echo $NODE_COUNT) #--- number of nodes for the Azure kubernetes cluster
node_vm_size=$(echo $NODE_VM_SIZE) #--- VM size for the Azure Kubernetes  cluster
username=$(echo $USERNAME) #--- Username of the azure account 
password=$(echo $PASSWORD) #--- Password for the azure account

name=$(echo $(mktemp)| tr '[:upper:]' '[:lower:]' | cut -d '.' -f 2)

echo "Installing Prerequisites..."
sudo apt-get update

# Installing Azure CLI
function azure_cli_installed(){
  IS_AZ_INSTALLED=$(which az >> /dev/null 2>&1; echo $?)
  if [[ $IS_AZ_INSTALLED -eq 0 ]]; then
     echo "Azure CLI already Installed, Skipping"
     az=$(az --version | grep azure-cli | head -1 | cut -d ' ' -f2)
     echo "Installed Azure CLI Version:" ${az}
  else
     echo "Installing Python Packages"
     python=$(sudo apt-get install -y python-pip > oebs_aks.log)
     version=$(python --version)
     echo ${version}
     sleep 1
     echo "Installing Azure CLI" |& tee -a oebs_aks.log
     curl -L https://aka.ms/InstallAzureCli | bash >> oebs_aks.log
     az=$(az --version | grep azure-cli | head -1 | cut -d ' ' -f2)
     echo "Installed Azure CLI Version:" ${az}
  fi
}

# Login into Azure using Account Credentials
function azure_login(){
  IS_AZURE_LOGIN=$(az account show >> /dev/null 2>&1; echo $?)
  if [[ $IS_AZURE_LOGIN -eq 0 ]]; then
     echo "Already Logged in, Skipping"
     a=$(az account show | grep name | awk 'FNR == 2 {print $2}' | cut -d '"' -f2)
     echo "Logged in Account name :" ${a}
     sleep 1
  else
     echo "Logging into Azure Account"
     login=$(az login -u ${username} -p ${password})
     a=$(az account show | grep name | awk 'FNR == 2 {print $2}' | cut -d '"' -f2)
     echo "Logged in Account name :" ${a}
  fi
}

# Install kubernetes newest version >> aks-cluster.log
function kubectl_installed(){
  IS_KUBECTL_INSTALLED=$(which kubectl >> /dev/null 2>&1; echo $? )
  if [[ $IS_KUBECTL_INSTALLED -eq 0 ]]; then
     echo "Kubectl already Installed, Skipping"
     sleep 1
  else
     echo "Installing Kubectl newest version" |& tee -a oebs_aks.log
     az aks install-cli --install-location=./kubectl && sudo mv kubectl /usr/local/bin/kubectl >> oebs_aks.log
  fi
 }

#Creating Resource Group
function create_resource_group(){
  echo "Creating Resource Group" |& tee -a oebs_aks.log
  group=$(az group create -l eastus -n aks-openebs-${name}-rg >> oebs_aks.log)
  group_list=$(az group list | grep name | awk '{print $2}' | cut -d '"' -f2 | grep ${name})
  echo "Resource Group created in the name of :" ${group_list}
}

#Create AKS cluster
function create_cluster(){
  echo "Creating AKS Cluster....." |& tee -a oebs_aks.log
  cluster=$(az aks create -n aks-openebs-${name}-cluster  -g ${group_list} --node-count ${node_count} --node-vm-size ${node_vm_size} --generate-ssh-key >> oebs_aks.log)
  cluster_list=$( az aks list -g ${group_list} | grep name | awk '{print $2}' | cut -d '"' -f2 | grep ${name})
  echo "AKS cluster created in the name of:" ${cluster_list}
  #Connect to the AKS cluster
  echo "Getting credentials to connect aks cluster " |& tee -a oebs_aks.log
  az aks get-credentials -g ${group_list} -n ${cluster_list} >> oebs_aks.log
 }

#Create the Network Public IP Address
function create_public_ip(){
	 echo "Creating Public IP....." |& tee -a oebs_aks.log
	 MC_group_list=$(az group list | grep name | grep MC | awk '{print $2}' | cut -d '"' -f2 | grep ${name})
	 max=$(kubectl get nodes | grep -v 'NAME' | wc -l)
	 for (( i=0; i < $max; i++ ))
	 do
	   ip=$(az network public-ip create --resource-group ${MC_group_list} --name ip_${i}_${name} --allocation-method static >> oebs_aks.log)
	 done
}

#Associate the Public IP address to the Network Interface
function associate_ip(){
    echo "Associating Public IP to the Network Interface..." |& tee -a oebs_aks.log
    x=0
    nic_list=$(az network nic list -g ${MC_group_list} | grep name | grep nic | awk '{print $2}' | cut -d '"' -f2)
	for j in $nic_list
    do
       associate=$(az network nic ip-config update -g ${MC_group_list} --nic-name ${j} -n "ipconfig1" --public-ip-address ip_${x}_${name} >> oebs_aks.log)
       x=$((x+1))
    done
}

#SSH into nodes and install iscsi in kubelet container
function iscsi_install(){
 echo "Installing iSCSI packages" | & tee -a oebs_aks.log
    ip_address=$(az network public-ip list -g ${MC_group_list} | grep ipAddress | awk '{print $2}' | cut -d '"' -f2 )
    for k in $ip_address
    do
      container_id=$(ssh azureuser@"${k}" '( sudo docker ps  | grep "hyperkube kubele" )'| awk '{print $1}')
      ssh azureuser@"${k}" "( sudo docker exec $container_id /bin/bash -c \"rm -rf /var/lib/dpkg/statoverride && apt-get update && apt-get install -y open-iscsi\" )"
    done
	sleep 1
}

# Apply OpenEBS Operator to the kubernetes cluster
function openebs_operator(){
  echo "Deploying OpenEBS operator... " |& tee -a oebs_aks.log
  sleep 1
  kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml >> oebs_aks.log
  # Apply OpenBES Storage Classes
  echo "Deploying OpenEBS Storage classes" |& tee -a oebs_aks.log
  sleep 1
  kubectl create -f https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml >> oebs_aks.log
 }

# Checking status of OpenEBS Pods 
function pod_status(){
  echo "Checking Pod status... " |& tee -a oebs_aks.log
  sleep 20
  kubectl get pods --all-namespaces |& tee -a oebs_aks.log
}


azure_cli_installed
azure_login
create_resource_group
create_cluster
kubectl_installed
create_public_ip
associate_ip
iscsi_install
openebs_operator
pod_status

