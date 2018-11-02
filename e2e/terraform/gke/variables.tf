/* THIS IS THE VARIABLE DEFINITION FILE IN WHICH THE CONFIG 
   PARAMETERS CAN BE SPECIFIED */ 


#-------PROVIDER VARS-------# 

# Default: Use key for compute-engine-default sa, or other w/ adequate permissions
variable "credentials" { default = "account.json" }

# Region & zone in which master and nodes will be created
variable "region" { default = "us-central1-a" }

# Google cloud platform project name
# Set env TF_VAR_project
variable "project" {}  

#-------RESOURCE VARS-------#

# Name of kubernetes cluster 
variable "clustername" { default = "oebs-staging" }

# Default: 3 (Accommodate min. 3 OpenEBS vol replicas as per recommendation)
variable "nodecount" { default = "3" } 

#-------MASTER_AUTH VARS-------#

# Set env TF_VAR_username
variable "username" {} 

# Ensure a min. 16-character pwd
# Set env TF_VAR_password
variable "password" {} 

#-------NODE_CONFIG VARS-------#

# Options: https://cloud.google.com/compute/docs/machine-types
# Default: n1-standard-2 (2 vCPUs, 7.5GB Memory)  
variable "machinetype" { default = "n1-standard-2" } 

# Options: Ubuntu, ContainerOptimized OS (cos) 
# Default: Ubuntu (Has pre-installed iSCSI initiator)
variable "imagetype" { default = "Ubuntu" } # To obtain pre-installed iSCSI initiator


