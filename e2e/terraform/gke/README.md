# STEPS TO CREATE GKE CLUSTER USING TERRAFORM

## Step-1 : Obtain the Google Credentials from Google Developers Console 

- Log into the Google Developers Console and select a project.
- The API Manager view should be selected, click on "Credentials" on the left, then "Create credentials," and finally "Service account key."
- Select "Compute Engine default service account" in the "Service account" dropdown, and select "JSON" as the key type.
- Clicking "Create" will download your credentials.
- Rename this file to account.json and place in the directory where the terraform templates are present/will-be-placed. 

  ```
  ciuser@OpenEBSClient:~/oebs/gke$ ll
  total 36
  drwxrwxr-x  5 ciuser ciuser 4096 Feb 28 10:46 ./
  drwxrwxr-x  4 ciuser ciuser 4096 Feb 22 14:22 ../
  -rw-rw-r--  1 ciuser ciuser 2329 Feb 21 12:35 account.json
  -rw-rw-r--  1 ciuser ciuser 1084 Feb 28 10:32 oebs-staging.tf
  drwxrwxr-x  3 ciuser ciuser 4096 Feb 21 13:50 .terraform/
  -rw-rw-r--  1 ciuser ciuser 1253 Feb 28 10:33 variables.tf
  ```

Note: The user can use/create other service account credentials as long as it has adequate permissions to create cluster resources

## Step-2 : Obtain the Google project ID

- Log into the Google Developers Console to be sent to the Google API library page screen
- Click the Select a project drop-down in the upper left
- Copy the Project ID for the desired project from the window that shows 

## Step-3 : Create environment variables to store config secrets
 
- Add ENV variables (preferably, in ~/.profile) to store values of project_id, master_auth credentials (username, password)
- The terraform variables need to be defined in a specific format as shown below : 

  ```
  # Terraform variables

  export TF_VAR_project="<project_id>"
  export TF_VAR_username="<username>"
  export TF_VAR_password="<password>"
  ```
  
  The `TF_VAR_` string should be followed by the actual terraform variable name used in the variables.tf file

## Step-4 : Provide appropriate input parameters 

- Replace the values present in the variables.tf with appropriate values.
- The list of supported keys and values can be obtained from : https://www.terraform.io/docs/providers/google/r/container_cluster.html

## Step-5 : Execute terraform commands

- Execute the terraform commands in this order : terraform init, terraform plan & terraform apply

## Step-6 : Confirm successful cluster creation

- Log into the Google Developers Console and verify that the cluster has been created w/ specified attributes

## Notes: 
--------

- The user can use/create other service account credentials as long as it has adequate permissions to create cluster resources

- It is recommended to to use latest versions of terraform (v0.11.3) on the deployment/test-harness machine where the above steps are performed.
  On older versions, some of the keys such as machine_type & image_type are unsupported. 

- Use the command terraform destroy to delete the cluster. 



