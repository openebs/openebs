# Using OpenEBS with Kubernetes on Google Container Engine

This tutorial, provides detailed instructions on how to setup and use OpenEBS in Google Container Enginer (GKE). This tutorial uses a 3 node container cluster. 

## Step 1 : Preparing your Container Cluster 

You can either use an existing container cluster or create a new one using, Login to your Google Cloud Platoform -> Container Engine -> Create Container Cluster. The minimum requirements for the cluster are as follows:

### Minimum Requirements
- Machine Type - (Minimum 2 vCPUs)
- Node Image - (container-vm)
- Size - (Minimum 3)
- Cluster Version - (1.6.4+)

*Note: The example commands below were run on a container cluser named (demo-openebs03) in zone (us-central1-a). The project unique id (strong-eon-153112). When copy/pasting the command, make sure to use the details from your project.*

### Add iSCSI Support

SSH into the nodes of the cluster to install open-iscsi package. OpenEBS 0.3 uses iscsi to connect to the block volumes. 

```
sudo apt-get update
sudo apt-get install open-iscsi
sudo service open-iscsi restart
```

#### Verify that iSCSI is configured

Check that initiator name is configured and iscsi service is running
```
sudo cat /etc/iscsi/initiatorname.iscsi
sudo service open-iscsi status
```

## Step 2 : Run OpenEBS Operator

Download the latest OpenEBS Operator Files
```
git clone https://github.com/openebs/openebs.git
cd openebs/k8s
```

Setup the kubectl to run in admin context. (See Appendix below for creating an admin context in GCP). The below command will prompt for username/password. Provide username as "admin" and password for the admin can be obtained from : Google Cloud Platform -> Container Engine -> (cluster) -> Show Credentials
```
kubectl config use-context demo-openebs03
kubectl apply -f openebs-operator.yaml
kubectl config use-context gke_strong-eon-153112_us-central1-a_demo-openebs03
```

Add OpenEBS related Storage Classes, that can then be used by developers/apps. 

```
kubectl apply -f openebs-storageclasses.yaml
```

Note: The persistent storage is carved out from the space available on the nodes (default host directory : /var/openebs). There are efforts underway to provide administrator with additional options of consuming the storage (as outlined in "openebs-config.yaml"). These are slated to work hand-in-hand with the local storage manager of the kubernetes that is due in Kubernetes 1.7/1.8. 

## Step 3 : Running Stateful workloads with OpenEBS Storage. 

All you need to do, to use OpenEBS as persistent storage for your Stateful workloads, is to set the Storage Class in the PVC to the OpenEBS Storage Class.

Get the list of storage classes using the below command. Choose the storage class that best suits your application. 

```
kubectl get sc
```

Some sample yaml files for stateful workoads using OpenEBS are provided in the [openebs/k8s/demo](https://github.com/openebs/openebs/tree/master/k8s/demo)

```
kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml
```
The above command will create the following, which can be verified using the corresponding kubectl commands:
- Launch a Jupyter Server, with the specified notebook file from github
  (kubectl get deployments)
- Create an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data)
  (kubectl get pvc)
  (kubectl get pv)
  (kubectl get pods)
- Expose the Jupyter Server to external world via the http://NodeIP:32424 (NodeIP is any of the minion nodes external IP)
  (kubectl get pods)

Note:To access the Jupyter Server over the internet, set the firewall rules to allow traffic on port 32424 in you GCP / Networking / Firewalls



## Appendix

### Setting kubernetes cluster admin context

To create/modify service accounts and grant previleges, kubectl needs to be run with admin previleges. The following commands help to setup and use the admin context for Google Container Engine via the Google Cloud Shell. 

#### Step 1: Initialize credentails to allow kubectl to execute commands on the container cluster. 
```
gcloud container clusters list
gcloud container clusters get-credentials demo-openebs03 --zone us-central1-a
```

#### Step 2 : Setup the admin context

- Access the credentails information from : Google Cloud Platform -> Container Engine -> (cluster) -> Show Credentials. 
- Save the "Cluster CA Certificate" to ~/.kube/admin.key
- Create a admin config context from the config shell
```
gcloud container clusters list
kubectl config set-context demo-openebs03 --cluster=gke_strong-eon-153112_us-central1-a_demo-openebs03 --user=cluster-admin
```







