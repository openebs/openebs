# AZURE

## Setting up OpenEBS with Kubernetes on AKS

This section provides detailed instructions on how to setup and use OpenEBS in Azure Container Service (AKS). This section uses a two node Kubernetes cluster.

#### Prerequisites

An Azure account

## Preparing your Kubernetes Cluster

To create a new cluster, perform the following procedure.

Go to the Azure Cloud URL at https://portal.azure.com and login with your azure credentials.

Click the **Cloud Shell** button on the menu in the upper right of the  Azure portal.

#### Create a resource group

Create a resource group with the `az group create` command. An Azure resource group is a logical group in which Azure resources are deployed and managed. When creating a resource group you are asked to specify a location, this is where your resources will live in Azure.

The following example creates a resource group named *aks-openebs-cluster-rg* in the *eastus* location.

```
devops@Azure:~$ az group create -l eastus -n aks-openebs-cluster-rg

{
  "id": "/subscriptions/c73e5d9b-160d-45e7-b84e-f243928ed8ed/resourceGroups/aks-openebs-cluster-rg",
  "location": "eastus",
  "managedBy": null,
  "name": "aks-openebs-cluster-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null
}
```
**Note:** The example commands below were run on a Kubernetes cluster aks-openebs-cluster  in zone eastus with resource group aks-openebs-cluster-rg. When you copy paste the command, ensure that you use the details from your project.

#### Create  cluster

Use the _az aks create_ command to create an AKS cluster. The following example creates a cluster named *aks-openebs-cluster* with two nodes and the vm size is Standard_A2_V2. For more details, click [node vm size](https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs) 

```
devops@Azure:~$ az aks create -n aks-openebs-cluster -g aks-openebs-cluster-rg --node-count 2 --kubernetes-version 1.8.7 --node-vm-size Standard_A2_v2 --generate-ssh-key
```
After few minutes, the cluster with the above configuration will be created successfully.

#### Connect to the cluster

To manage a Kubernetes cluster, use _kubectl_, the Kubernetes command-line client. If you're using Azure Cloud Shell, kubectl is already installed. 

To configure kubectl to connect to your Kubernetes cluster, use the _az aks get-credentials_ command. This step downloads credentials and configures the Kubernetes CLI to use them.

```
devops@Azure:~$ az aks get-credentials -g aks-openebs-cluster-rg -n aks-openebs-cluster

Merged "aks-openebs-cluster" as current context in /home/cloudbyte/.kube/config
```

To verify the connection to your cluster, use the _kubectl get_ command to return a list of the cluster nodes. Note that this can take a few minutes to appear.

```
devops@Azure:~$ kubectl get nodes
NAME                       STATUS    ROLES     AGE       VERSION
aks-nodepool1-46849391-0   Ready     agent     20h       v1.8.7
aks-nodepool1-46849391-1   Ready     agent     20h       v1.8.7
```

## iSCSI Configuration

Create Public IP addresses and associate them to all the nodes' network interfaces to configure iSCSI initiator. You can create and associate the Public IP address to the nodes by using Azure portal or Azure CLI

**Create Public IP address using Azure Portal**
- Go to the Azure Portal select **All Services**  search **Public IP addresses** and click it. 
- Click **Create Public IP adresses** and provide the required details such as **Name** , select _Static_ in the **IP address Assignment **, **Resource Group** and the **location** where the selected resource group resides. Click **Create**. You can either select the existing resource group or create a new resource group. Select the resource group that MC_aks-openebs-cluster-rg_aks-openebs-cluster_eastus.
- You need to create as many public IP address as the number of nodes in your Kubernetes cluster. Click **Add** to create more Public IP.
- Click **Refresh** at the top to list the Public IP addresses that you have created. Right click one of the Public IP addresses in the table and select **Associate** to get associated with a node.
- Select  _Network Interface_ in the **resource type**  dropdown and select the node to associate the IP address.

**Note:** Each AKS deployment spans two resource groups. The first is created by you and contains only the AKS resource. The AKS resource provider automatically creates the second one during deployment with a name like MC_aks-openebs-cluster-rg_aks-openebs-cluster_eastus. The second resource group contains all of the infrastructure resources associated with the cluster, such as VMs, networking, and storage. It is created to simplify resource cleanup.

**Create Public IP address using Azure CLI**

- To create Public IP address using Azure CLI  run the following command. You need to create as many public IP address as the number of nodes in your Kubernetes cluster
```
devops@Azure:~$ az group list | grep name | grep MC | awk {'print $2'} | cut -d '"' -f2

MC_aks-openebs-cluster-rg_aks-openebs-cluster_eastus
```
```
devops@Azure:~$ az network public-ip create --resource-group MC_aks-openebs-cluster-rg_aks-openebs-cluster_eastus --name ip1 --allocation-method static
```
- To associate public IP address to the node run the following commands.

**Note:** The example commands below were run on a resource group _MC_aks-openebs-cluster-rg_aks-openebs-cluster_eastus_ and network nic list as _aks-nodepool1-46849391-nic-0_ and the Public IP address name as _ip1_. When you copy paste the command, ensure that you use the details from your project.
```
devops@Azure:~$ az network nic list -g MC_aks-openebs-cluster-rg_aks-openebs-cluster_eastus | grep name

        "name": "ipconfig1",
          "name": null,
    "name": "aks-nodepool1-46849391-nic-0",
        "name": "ipconfig1",
          "name": null,
    "name": "aks-nodepool1-46849391-nic-1",

```

```
devops@Azure:~$ az network nic ip-config update -g "MC_aks-openebs-cluster-rg_aks-openebs-cluster_eastus" --nic-name "aks-nodepool1-46849391-nic-0" -n "ipconfig1" --public-ip-address "ip1"
```

**Install and configure iSCSI**

You can connect to the nodes through SSH using their public IP addresses by running the following command. 


```
devops@Azure:~$ ssh azureuser@40.71.213.221

azureuser@aks-nodepool1-46849391-1:~$
```

**Note:** Where azureuser is a default username.

Obtain the Container ID of the hyperkube kubelet on each node by running the below command.

```
azureuser@aks-nodepool1-46849391-1:~$ sudo docker ps | grep "hyperkube kubele"

3aab0f9a48e2    k8s-gcrio.azureedge.net/hyperkube-amd64:v1.8.7   "/hyperkube kubele..."   48 minutes ago      Up 48 minutes                           eager_einstein
```

Run the following commands to install and configure iSCSI in each node.

```
azureuser@aks-nodepool1-46849391-1:~$ sudo docker exec -it 3aab0f9a48e2 bash
# apt-get update
# apt install -y open-iscsi
# exit
```
Check the status of iSCSI service by running the following command,
```
azureuser@aks-nodepool1-46849391-1:~$ service open-iscsi status
● open-iscsi.service - Login to default iSCSI targets
   Loaded: loaded (/lib/systemd/system/open-iscsi.service; enabled; vendor preset: enabled)
   Active: active (exited) since Mon 2018-03-19 11:27:01 UTC; 21h ago
     Docs: man:iscsiadm(8)
           man:iscsid(8)
 Main PID: 1497 (code=exited, status=0/SUCCESS)
    Tasks: 0
   Memory: 0B
      CPU: 0
   CGroup: /system.slice/open-iscsi.service

Mar 19 11:27:03 aks-nodepool1-46849391-1 iscsiadm[1474]: iscsiadm: No records found
Mar 19 11:27:01 aks-nodepool1-46849391-1 systemd[1]: Starting Login to default iSCSI targets...
Mar 19 11:27:01 aks-nodepool1-46849391-1 systemd[1]: Started Login to default iSCSI targets.

azureuser@aks-nodepool1-46849391-1:~$ exit
devops@Azure:~$
```

**Note** : Install and configure iSCSI in all the nodes of your Kubernetes cluster by following the above procedure.

## Setting up OpenEBS

Download the latest OpenEBS repository using the following commands.

```
devops@Azure:~$ git clone https://github.com/openebs/openebs.git
Cloning into 'openebs'...
remote: Counting objects: 8081, done.
remote: Compressing objects: 100% (90/90), done.
remote: Total 8081 (delta 54), reused 42 (delta 16), pack-reused 7975
Receiving objects: 100% (8081/8081), 8.67 MiB | 64.00 KiB/s, done.
Resolving deltas: 100% (4587/4587), done.
Checking connectivity... done.

```

To install OpenEBS components in Kubernetes cluster, run the following commands.

```
devops@Azure:~$ cd openebs/k8s

devops@Azure:~/openebs/k8s$ kubectl apply -f openebs-operator.yaml
serviceaccount "openebs-maya-operator" created
clusterrole "openebs-maya-operator" created
clusterrolebinding "openebs-maya-operator" created
deployment "maya-apiserver" created
service "maya-apiserver-service" created
deployment "openebs-provisioner" created
customresourcedefinition "storagepoolclaims.openebs.io" created
customresourcedefinition "storagepools.openebs.io" created
storageclass "openebs-standard" created
customresourcedefinition "volumepolicies.openebs.io" created
```
OpenEBS provides a set of yaml files that illustrate the usage of its storage classes. This can be modified according to your requirements by editing openebs-storageclasses.yaml file. You can set replica count and the storage capacity of volumes for the respective storage classes according to your requirement in openebs-storageclasses.yaml as follows:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: openebs-standalone
provisioner: openebs.io/provisioner-iscsi
parameters:
  openebs.io/storage-pool: "default"
  openebs.io/jiva-replica-count: "1"
  openebs.io/volume-monitor: "true"
  openebs.io/capacity: 5G
```
In the above snippet, the storage class openebs-standalone is shown. Similarly, you can modify the other storage classes. After modification, run the following command to deploy storage classes.

```
devops@Azure:~/openebs/k8s$ kubectl apply -f openebs-storageclasses.yaml
storageclass "openebs-standalone" created
storageclass "openebs-percona" created
storageclass "openebs-jupyter" created
storageclass "openebs-mongodb" created
storageclass "openebs-cassandra" created
storageclass "openebs-redis" created
storageclass "openebs-kafka" created
storageclass "openebs-zk" created
storageclass "openebs-es-data-sc" created
```
To check if the OpenEBS components are integrated successfully, check the active pods by running following command.

```
devops@Azure:~/openebs/k8s$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                            READY     STATUS    RESTARTS   AGE
default       maya-apiserver-69f9db69-gfh4x                                   1/1       Running   0          17h
default       openebs-provisioner-77cb47986c-4nghb                            1/1       Running   0          17h
kube-system   heapster-669488959c-wj76s                                       2/2       Running   0          18h
kube-system   kube-dns-v20-5bf84586f4-72vmh                                   3/3       Running   0          18h
kube-system   kube-dns-v20-5bf84586f4-tp9rj                                   3/3       Running   0          18h
kube-system   kube-proxy-l28s4                                                1/1       Running   0          18h
kube-system   kube-proxy-s2mhj                                                1/1       Running   0          18h
kube-system   kube-svc-redirect-4nfjk                                         1/1       Running   0          18h
kube-system   kube-svc-redirect-mvs5g                                         1/1       Running   0          18h
kube-system   kubernetes-dashboard-69bb965b88-t8x5v                           1/1       Running   0          18h
kube-system   tunnelfront-8d78b6c97-kvwsn                                     1/1       Running   0          18h

```
Verify the storage classes by running the following command.

```
devops@Azure:~/openebs/k8s$ kubectl get sc
NAME                 PROVISIONER
default (default)    kubernetes.io/azure-disk
managed-premium      kubernetes.io/azure-disk
openebs-cassandra    openebs.io/provisioner-iscsi
openebs-es-data-sc   openebs.io/provisioner-iscsi
openebs-jupyter      openebs.io/provisioner-iscsi
openebs-kafka        openebs.io/provisioner-iscsi
openebs-mongodb      openebs.io/provisioner-iscsi
openebs-percona      openebs.io/provisioner-iscsi
openebs-redis        openebs.io/provisioner-iscsi
openebs-standalone   openebs.io/provisioner-iscsi
openebs-standard     openebs.io/provisioner-iscsi
openebs-zk           openebs.io/provisioner-iscsi
```

