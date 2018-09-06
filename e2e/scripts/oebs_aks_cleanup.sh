#!/bin/bash

node_count=$(echo $NODE_COUNT) #--- number of nodes for the Azure kubernetes cluster
node_vm_size=$(echo $NODE_VM_SIZE) #--- VM size for the Azure Kubernetes  cluster
username=$(echo $USERNAME) #--- Username of the azure account 
password=$(echo $PASSWORD) #--- Password for the azure account
name=$(cat oebs_aks_name) #--- Getting resource name affix

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

# Deleting Resource Group
function delete_resource_group(){
  echo "Deleting Resource Group" |& tee -a oebs_aks.log
  group=$(az group delete -n aks-openebs-${name}-rg -y >> oebs_aks_cleanup.log)
  rm oebs_aks_name
  echo "Resource Group deleted in the name of : aks-openebs-"${name}"-rg"
}

azure_login
delete_resource_group