## OpenEBS on AZURE - Deployment using Shell script

The purpose of this user guide is to provide the instructions to set up a Kubernetes cluster on AWS (Amazon Web Services) and have OpenEBS running in hyperconverged mode.

### Prerequisites

- An Azure account

Download the script file called oebs_aks.sh.
```
    $ mkdir -p openebs
    $ cd openebs
    $ wget https://raw.githubusercontent.com/openebs/openebs/master/e2e/scripts/oebs_aks.sh
    $ chmod +x oebs_aks.sh
```
#### Updating .profile file:

This script require the AZURE credentials to access AKS services.

- Add path /usr/local/bin to the PATH environment variable.
```
    $ vim ~/.profile
    
    # Add the AKS credentials as environment variables in .profile
    export USERNAME="<username>"
    export PASSWORD="<password>"
    export NODE_COUNT="<node count>"
    export NODE_VM_SIZE="<node vm size>"
    
    # Add /usr/local/bin to PATH
    PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
    
    $ source ~/.profile
```
**NOTE:** Node count will be the number of nodes, and Node vm size is the size of the virtual machine. For details of node vm size goto the following URL  https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs

Create a cluster on AKS

Run the  oebs_aks.sh to create AKS cluster and deploy OpenEBS. The above script will installs the Azure CLI, Kubectl,  iSCSI packages on Kubelet container and it deploy OpenEBS operator and OpenEBS storage class files. And It creates the Log file in the name of oebs_aks.log.

To verify the resource group run the below command.
```
    devops@Azure:~$ az group list
```
To verify the Created cluster run the following command.
```
    devops@Azure:~$ az aks list -g <resource group name>
```
To verify the successful deployment of OpenEBS run the following command.
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

