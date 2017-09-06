You can install OpenEBS instantly using the following procedure.

Prerequisite:
-------------
You must have Kubernetes installed.

1. Install Open-ISCSI using the following commands at the command prompt:

   **On Ubuntu -**

   * sudo apt-get update 
   * sudo apt-get install open-iscsi

   **On CoreOS - ??**

2. Run Kubernetes operator using the following commands at the command prompt:

   *  kubectl create/apply -f openebs-operator.yaml
   *  kubectl create/apply -f openebs-storageclasses.yaml

**See Also:**
    `Amazon Cloud`_
          .. _Amazon Cloud: http://openebs.readthedocs.io/en/latest/install/deploy_terraform_kops.html