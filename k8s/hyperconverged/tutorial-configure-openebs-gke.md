# Using OpenEBS with Kubernetes on Google Container Engine

This tutorial, provides detailed instructions on how to setup and use OpenEBS in Google Container Engine (GKE). This tutorial uses a 3 node container cluster.

## Step 1 : Preparing your Container Cluster

You can either use an existing container cluster or create a new one by Logging in to your Google Cloud Platform -> Container Engine -> Create Container Cluster. The minimum requirements for the cluster are as follows:

### Minimum Requirements

- Machine Type - (Minimum 2 vCPUs)
- Node Image - (Ubuntu)
- Size - (Minimum 3)
- Cluster Version - (1.6.4+)

*Note: The example commands below were run on a container cluser named (demo-openebs03) in zone (us-central1-a). The project unique id (strong-eon-153112). When copy/pasting the command, make sure to use the details from your project.*

### iSCSI Configuration

Go to **Google Cloud Platform** -> **Compute Engine** -> **VM instances**. The nodes that are displayed by default in this console are the Compute Engine VMs.The display is similar to the following screen.

![Compute VMs]

#### Verify that iSCSI is configured

 OpenEBS uses iSCSI to connect to the block volumes. Select one of the nodes in the cluster and click **SSH**, to open the node in a terminal.

1. Check if the initiator name is configured.

  ```bash

    ~$ sudo cat /etc/iscsi/initiatorname.iscsi
    ## DO NOT EDIT OR REMOVE THIS FILE!
    ## If you remove this file, the iSCSI daemon will not start.
    ## If you change the InitiatorName, existing access control lists
    ## may reject this initiator.  The InitiatorName must be unique
    ## for each iSCSI initiator.  Do NOT duplicate iSCSI InitiatorNames.
    InitiatorName=iqn.1993-08.org.debian:01:6277ea61267f

  ```

2. Check if the iSCSI service is running.

  ```bash

   ~$ sudo service open-iscsi status
   ● open-iscsi.service - Login to default iSCSI targets
     Loaded: loaded (/lib/systemd/system/open-iscsi.service; enabled; vendor preset: enabled)
     Active: active (exited) since Tue 2017-10-24 14:33:57 UTC; 3min 6s ago
       Docs: man:iscsiadm(8)
             man:iscsid(8)
    Main PID: 1644 (code=exited, status=0/SUCCESS)
       Tasks: 0
      Memory: 0B
         CPU: 0
      CGroup: /system.slice/open-iscsi.service
   Oct 24 14:33:57 gke-cluster-3-default-pool-8b0f2a27-5nr2 systemd[1]: Starting Login to default iSCSI targets...
   Oct 24 14:33:57 gke-cluster-3-default-pool-8b0f2a27-5nr2 iscsiadm[1640]: iscsiadm: No records found
   Oct 24 14:33:57 gke-cluster-3-default-pool-8b0f2a27-5nr2 systemd[1]: Started Login to default iSCSI targets.

  ```

3. Repeat steps 1 and 2 for the remaining nodes.

## Step 2 : Run OpenEBS Operator (via Google Cloud Shell)

Before applying the OpenEBS Operator, the admin context has be set for the cluster. Follow the steps below to setup the admin context.

### Setting kubernetes cluster admin context

To create/modify service accounts and grant previleges, kubectl needs to be run with admin previleges. The following commands help to setup and use the admin context for Google Container Engine via the Google Cloud Shell.

#### Step 1: Initialize credentials to allow kubectl to execute commands on the container cluster

```bash
gcloud container clusters list
root@ubuntu:~$ gcloud container clusters get-credentials mycluster_223 --zone us-central1-a --project strong-eon-153112
Fetching cluster endpoint and auth data.
kubeconfig entry generated for mycluster_223.
```

#### Step 2 : Setup the admin context

Create a admin config context from the config shell:

```bash
gcloud container clusters list
root@ubuntu:~$ kubectl config set-context test-admin --cluster=gke_strong-eon-153112_us-central1-a_mycluster_223 --user=cluster-admin
Context "test-admin" modified.
```

The below command will prompt for username/password. Provide username as "admin" and password for the admin can be obtained from : Google Cloud Platform -> Container Engine -> (cluster) -> Show Credentials:

```bash
root@ubuntu:~$ kubectl config use-context test-admin
Switched to context "test-admin".

root@ubuntu:~$ kubectl config use-context gke_strong-eon-153112_us-central1-a_mycluster_223
Switched to context "gke_strong-eon-153112_us-central1-a_mycluster_223".
```
**To get the admin priviledge to your cluster(cluster-role admin)**
 get current google identity
`$ gcloud info | grep Account`
Account: [myname@example.org]

 grant cluster-admin to your current identity
`$ root@ubuntu:~$ kubectl create clusterrolebinding mycluster_223-cluster-admin-binding --clusterrole=cluster-admin --user=ranjith.raveendran@cloudbyte.com
clusterrolebinding.rbac.authorization.k8s.io "mycluster_223-cluster-admin-binding" created
`
Download the latest OpenEBS Operator Files:

```bash
git clone https://github.com/openebs/openebs.git
cd openebs/k8s
```

Apply OpenEBS Operator and add related OpenEBS Storage Classes, that can then be used by developers/apps:

```bash
root@ubuntu:~/demo_k8/openebs/k8s$ kubectl apply -f openebs-operator.yaml
namespace "openebs" created
serviceaccount "openebs-maya-operator" created
clusterrole.rbac.authorization.k8s.io "openebs-maya-operator" created
clusterrolebinding.rbac.authorization.k8s.io "openebs-maya-operator" created
deployment.apps "maya-apiserver" created
service "maya-apiserver-service" created
deployment.apps "openebs-provisioner" created
deployment.apps "openebs-snapshot-controller" created
customresourcedefinition.apiextensions.k8s.io "storagepoolclaims.openebs.io" created
customresourcedefinition.apiextensions.k8s.io "storagepools.openebs.io" created
storageclass.storage.k8s.io "openebs-standard" created
storageclass.storage.k8s.io "snapshot-promoter" created
customresourcedefinition.apiextensions.k8s.io "volumepolicies.openebs.io" created

root@ubuntu:~/demo_k8/openebs/k8s$ kubectl get pods -n openebs
NAME                                           READY     STATUS    RESTARTS   AGE
maya-apiserver-84fd4f776d-w5g9j                1/1       Running   0          47s
openebs-provisioner-74cb999586-v7jjm           1/1       Running   0          45s
openebs-snapshot-controller-6449b4cdbb-t7m29   2/2       Running   0          44s
```
```
root@ubuntu:~/demo_k8/openebs/k8s$ kubectl apply -f openebs-storageclasses.yaml
storageclass.storage.k8s.io "openebs-standalone" created
storageclass.storage.k8s.io "openebs-percona" created
storageclass.storage.k8s.io "openebs-jupyter" created
storageclass.storage.k8s.io "openebs-mongodb" created
storageclass.storage.k8s.io "openebs-cassandra" created
storageclass.storage.k8s.io "openebs-redis" created
storageclass.storage.k8s.io "openebs-kafka" created
storageclass.storage.k8s.io "openebs-zk" created
storageclass.storage.k8s.io "openebs-es-data-sc" created
```
Note: The persistent storage is carved out from the space available on the nodes (default host directory : /var/openebs). There are efforts underway to provide administrator with additional options of consuming the storage (as outlined in "openebs-config.yaml"). These are slated to work hand-in-hand with the local storage manager of the kubernetes that is due in Kubernetes 1.7/1.8.

## Step 3 : Running Stateful workloads with OpenEBS Storage

All you need to do, to use OpenEBS as persistent storage for your Stateful workloads, is to set the Storage Class in the PVC to the OpenEBS Storage Class.

Get the list of storage classes using the below command. Choose the storage class that best suits your application.

```bash
root@ubuntu:~/demo_k8/openebs/k8s$ kubectl get sc
NAME                 PROVISIONER                                                AGE
openebs-cassandra    openebs.io/provisioner-iscsi                               1m
openebs-es-data-sc   openebs.io/provisioner-iscsi                               1m
openebs-jupyter      openebs.io/provisioner-iscsi                               1m
openebs-kafka        openebs.io/provisioner-iscsi                               1m
openebs-mongodb      openebs.io/provisioner-iscsi                               1m
openebs-percona      openebs.io/provisioner-iscsi                               1m
openebs-redis        openebs.io/provisioner-iscsi                               1m
openebs-standalone   openebs.io/provisioner-iscsi                               1m
openebs-standard     openebs.io/provisioner-iscsi                               5m
openebs-zk           openebs.io/provisioner-iscsi                               1m
snapshot-promoter    volumesnapshot.external-storage.k8s.io/snapshot-promoter   5m
standard (default)   kubernetes.io/gce-pd    
```

Some sample yaml files for stateful workoads using OpenEBS are provided in the [openebs/k8s/demo](https://github.com/openebs/openebs/tree/master/k8s/demo)

```bash
root@ubuntu:~/demo_k8/openebs/k8s$ kubectl apply -f demo/jupyter/demo-jupyter-openebs.yaml
deployment.apps "jupyter-server" created
persistentvolumeclaim "jupyter-data-vol-claim" created
service "jupyter-service" created
```

The above command will create the following, which can be verified using the corresponding kubectl commands:

- Launch a Jupyter Server, with the specified notebook file from github
  ```
  root@ubuntu:~/demo_k8/openebs/k8s$  kubectl get deployments
  NAME                                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
  jupyter-server                                  1         1         1            1           2m
  pvc-41964ed3-790a-11e8-a986-42010a80017b-ctrl   1         1         1            1           2m
  pvc-41964ed3-790a-11e8-a986-42010a80017b-rep    3         3         3            3           2m
  ```
- Create an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data)
  ```
  root@ubuntu:~/demo_k8/openebs/k8s$ kubectl get pvc
  NAME                     STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
  jupyter-data-vol-claim   Bound     pvc-1827892f-7909-11e8-a986-42010a80017b   5G         RWO            openebs-jupyter   43s
  ```
  ```
  root@ubuntu:~/demo_k8/openebs/k8s$ kubectl get pv
  NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                   STORAGECLASS      REASON    AGE
  pvc-1827892f-7909-11e8-a986-42010a80017b   5G         RWO            Delete           Bound     default/jupyter-data-vol-claim           openebs-jupyter     
  ```
  ```
  root@ubuntu:~/demo_k8/openebs/k8s$ kubectl get pods
  NAME                                                             READY     STATUS              RESTARTS   AGE
  jupyter-server-68d4ddc48-mml47                                   1/1       Running		       	   0          2m
  pvc-41964ed3-790a-11e8-a986-42010a80017b-ctrl-6877d997fb-msnxk   2/2       Running             0          2m
  pvc-41964ed3-790a-11e8-a986-42010a80017b-rep-8f94c7b48-gdxbb     1/1       Running             0          2m
  pvc-41964ed3-790a-11e8-a986-42010a80017b-rep-8f94c7b48-h5d9p     1/1       Running             0          2m
  pvc-41964ed3-790a-11e8-a986-42010a80017b-rep-8f94c7b48-skssw     1/1       Running             0          2m
  ```
- Expose the Jupyter Server to external world via the http://NodeIP:32424 (NodeIP is any of the worker nodes external IP where application Pod is running)
  ```
  root@ubuntu:~/demo_k8/openebs/k8s$ kubectl get nodes -o wide
  NAME                                        STATUS    ROLES     AGE       VERSION        EXTERNAL-IP      OS-IMAGE             KERNEL-   VERSION    CONTAINER-RUNTIME
  gke-ranjith223-default-pool-314af41d-fk18   Ready     <none>    24m        v1.9.7-gke.3   35.224.182.169   Ubuntu 16.04.4 LTS           4.13.0-1015-gcp   docker://17.3.2
  gke-ranjith223-default-pool-314af41d-hc03   Ready     <none>    24m        v1.9.7-gke.3   35.188.50.11     Ubuntu 16.04.4 LTS           4.13.0-1015-gcp   docker://17.3.2
  gke-ranjith223-default-pool-314af41d-lgzf   Ready     <none>    24m       v1.9.7-gke.3   35.192.216.68    Ubuntu 16.04.4 LTS   4.13.0-   1015-gcp   docker://17.3.2
  ```
Note:To access the Jupyter Server over the internet, set the firewall rules to allow traffic on port 32424 in you GCP / Networking / Firewalls

[Compute VMs]: ../../documentation/source/_static/compute_engine_vms.png
