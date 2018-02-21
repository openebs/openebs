# STEPS TO CREATE GKE CLUSTER USING TERRAFORM

## Step-1 : Obtain the Google Credentials from Google Developers Console 

- Log into the Google Developers Console and select a project.
- The API Manager view should be selected, click on "Credentials" on the left, then "Create credentials," and finally "Service account key."
- Select "Compute Engine default service account" in the "Service account" dropdown, and select "JSON" as the key type.
- Clicking "Create" will download your credentials.
- Rename this file to account.json and place in the directory where the terraform templates are present/will-be-placed

## Step-2 : Obtain the Google project ID

- Log into the Google Developers Console to be sent to the Google API library page screen
- Click the Select a project drop-down in the upper left
- Copy the Project ID for the desired project from the window that shows 

## Step-3 : Provide appropriate input parameters 

- Replace the values present in the variables.tf with appropriate values.
- The list of supported keys and values can be obtained from : https://www.terraform.io/docs/providers/google/r/container_cluster.html

## Step-4 : Execute terraform commands

- Execute the terraform commands in this order : terraform init, terraform plan & terraform apply

## Step-5 : Confirm successful cluster creation

- Log into the Google Developers Console and verify that the cluster has been created w/ specified attributes

## Notes: 
--------

- It is recommended to to use latest versions of terraform (v0.11.3) on the deployment/test-harness machine where the above steps are performed.
  On older versions, some of the keys such as machine_type & image_type are unsupported. 

- Use the command terraform destroy to delete the cluster. 



