## Procedure to run OpenEBS on Multi-Node Cotainerized OpenShift Cluster

This tutorial provides detailed instructions on how to setup a multi-node BYO (Bring-Your-Own-Host) OpenShift Containerized cluster on 
RHEL 7.5 and run applications on it with OpenEBS storage.

### Prerequisites

-At least 2 or more RHEL 7.5 hosts (virtual-machines/baremetal/cloud instances) with 3 vCPUs, 16GB RAM and 60GB hard disk.
-A valid Red Hat subscription

### Attach OpenShift Container Platform Subscription

1. As root on the target machines (both master and node), use subscription-manager to register the systems with Red Hat.

```
$ subscription-manager register
```

2. Pull the latest subscription data from RHSM:

```
$ subscription-manager refresh
```

3. List the available subscriptions.

```
$ subscription-manager list --available
```

4. Find the pool ID that provides OpenShift Container Platform subscription and attach it.

```
$ subscription-manager attach --pool=<pool_id>
```

5. Replace the string <pool_id> with the pool ID of the pool that provides OpenShift Container Platform. The pool ID is a long alphanumeric string.

These RHEL systems are now authorized to install OpenShift Container Platform. Now you need to tell the systems from where to get 
OpenShift Container Platform.

### Set Up Repositories
On both master and node, use subscription-manager to enable the repositories that are necessary in order to install OpenShift Container 
Platform. You may have already enabled the first two repositories in this example.

```
$ subscription-manager repos --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.9-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rhel-7-server-ansible-2.4-rpms"
```

This command tells your RHEL system that the tools required to install OpenShift Container Platform will be available from these 
repositories. Now we need the OpenShift Container Platform installer that is based on Ansible.


### Install the OpenShift Container Platform Package
The installer for OpenShift Container Platform is provided by the atomic-openshift-utils package. Install it using yum on both the 
master and the node, after running yum update.

```
$ yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
$ yum -y update
$ yum -y install atomic-openshift-utils
$ yum -y install docker
```

-Functional DNS server, with all hosts configured by appropriate domain names (Ensure nslookup of the hostnames is successful in 
 resolving the machine's IP addresses).The detailed steps can be found by going to the following link..
 (https://medium.com/@fromprasath/adding-centos-to-windows-domain-298977008f6c)
 
 ```
 [root@OSNode1 ~]# nslookup OSNode2
Server:         20.10.21.21
Address:        20.10.21.21#53

Name:   OSNode2.cbqa.in
Address: 20.10.31.7

[root@OSNode2 ~]# nslookup OSNode1
Server:         20.10.21.21
Address:        20.10.21.21#53

Name:   OSNode1.cbqa.in
Address: 20.10.31.6
```
 
 -Setup passwordless SSH between the Master and other Nodes.
 
 ### Run the Installer
 
 ```
 $ atomic-openshift-installer install
 ```
 
 This is an interactive installation process that guides you through the various steps. In most cases, you may want the default options. When it 
 starts, select the option for OpenShift Container Platform. You are installing one master and one node.
 
 
  **Note**:The Openshift deploy cluster playbook performs a health-check prior to executing the install roles to verify system
readiness. Typically, the following pitfalls may be observed: 

- Memory_availability and storage_availability 

  - Issue: Checks fail if we do not adhere to production standards. 
  - Workaround: Disable check by adding into openshift_disable_check inventory variable.
  
- Docker image availability 

  - Issue: Checks fail if there are DNS issues/flaky networks due to which the docker.io registry cannot
    be accessed. Sometimes, this fails even when a manual inspection shows that they are available and accessible to the machine.
  - Workaround: If manual Skopeo inspect is successful, disable check by adding into openshift_disable_check inventory variable.
  
    Skopeo inspect example : ```skopeo inspect --tls-verify=false docker://docker.io/cockpit/kubernetes:latest```
  
- Docker storage availability 

  - Issue: Can fail if the Docker service is not running. The daemon does not automatically run post yum install.
  - Workaround: Restart the Docker.
 
- Docker_image_availability

If the above pitfall is observerd during containerzied OpenShift installation, you must copy the hosts from 
/root/.config/openshift/hosts and paste the same in /etc/ansible/hosts and add the Openshift_disable_check in the hosts file.

```
[root@osnode1 ansible]# cat hosts

[OSEv3:children]
nodes
nfs
masters
etcd

[OSEv3:vars]
openshift_master_cluster_public_hostname=None
ansible_ssh_user=root
openshift_master_cluster_hostname=None
openshift_hostname_check=false
deployment_type=openshift-enterprise
openshift_disable_check=disk_availability,memory_availability,docker_storage,docker_image_availability

[nodes]
20.10.45.111  openshift_public_ip=20.10.45.111 openshift_ip=20.10.45.111 openshift_public_hostname=osnode1.mdataqa.in openshift_hostname=osnode1.mdataqa.in containerized=True connect_to=20.10.45.111 openshift_node_labels="{'region': 'infra'}" openshift_schedulable=True ansible_connection=local
20.10.45.112  openshift_public_ip=20.10.45.112 openshift_ip=20.10.45.112 openshift_public_hostname=osnode2.mdataqa.in openshift_hostname=osnode2.mdataqa.in containerized=True connect_to=20.10.45.112 openshift_node_labels="{'region': 'infra'}" openshift_schedulable=True

[nfs]
20.10.45.111  openshift_public_ip=20.10.45.111 openshift_ip=20.10.45.111 openshift_public_hostname=osnode1.mdataqa.in openshift_hostname=osnode1.mdataqa.in containerized=True connect_to=20.10.45.111 ansible_connection=local

[masters]
20.10.45.111  openshift_public_ip=20.10.45.111 openshift_ip=20.10.45.111 openshift_public_hostname=osnode1.mdataqa.in openshift_hostname=osnode1.mdataqa.in containerized=True connect_to=20.10.45.111 ansible_connection=local

[etcd]
20.10.45.111  openshift_public_ip=20.10.45.111 openshift_ip=20.10.45.111 openshift_public_hostname=osnode1.mdataqa.in openshift_hostname=osnode1.mdataqa.in containerized=True connect_to=20.10.45.111 ansible_connection=local
```

-While installing, if you get following error, use docker pull command to download the package on both master and nodes.

```

  1. Hosts:    20.10.45.111
     Play:     OpenShift Health Checks
     Task:     Run health checks (install) - EL
     Message:  One or more checks failed
     Details:  check "docker_image_availability":
               One or more required container images are not available:
                   openshift3/node:v3.9.33,
                   openshift3/openvswitch:v3.9.33,
                   openshift3/ose-deployer:v3.9.33,
                   openshift3/ose-docker-registry:v3.9.33,
                   openshift3/ose-haproxy-router:v3.9.33,
                   openshift3/ose-pod:v3.9.33,
                   openshift3/ose:v3.9.33,
                   openshift3/registry-console:v3.9,
                   registry.access.redhat.com/rhel7/etcd
               Checked with: skopeo inspect [--tls-verify=false] [--creds=<user>:<pass>] docker://<registry>/<image>
               Default registries searched: registry.access.redhat.com
               Failed connecting to: registry.access.redhat.com


  2. Hosts:    20.10.45.112
     Play:     OpenShift Health Checks
     Task:     Run health checks (install) - EL
     Message:  One or more checks failed
     Details:  check "docker_image_availability":
               One or more required container images are not available:
                   openshift3/node:v3.9.33,
                   openshift3/openvswitch:v3.9.33,
                   openshift3/ose-deployer:v3.9.33,
                   openshift3/ose-docker-registry:v3.9.33,
                   openshift3/ose-haproxy-router:v3.9.33,
                   openshift3/ose-pod:v3.9.33,
                   openshift3/registry-console:v3.9
               Checked with: skopeo inspect [--tls-verify=false] [--creds=<user>:<pass>] docker://<registry>/<image>
               Default registries searched: registry.access.redhat.com
               Failed connecting to: registry.access.redhat.com
```

The following command can be used to download the required package (master and node).

```
docker pull openshift3/node:v3.9.33
```

-While installing, if you get the error "Currently, NetworkManager must be installed and enabled prior to installation", you must follow the steps mentioned below to make it active (master and node).

```
[root@ocp-node-3 ~]# systemctl show NetworkManager | grep ActiveState
ActiveState=inactive
$systemctl enable NetworkManager; systemctl start NetworkManager
```

After installing, you will see the following output.

```
  PLAY RECAP *********************************************************************
  20.10.45.111               : ok=383  changed=142  unreachable=0    failed=0
  20.10.45.112               : ok=61   changed=13   unreachable=0    failed=0
  localhost                  : ok=14   changed=0    unreachable=0    failed=0
  INSTALLER STATUS *****************************************************************************************************************************************************
  Initialization             : Complete (0:00:58)
  Health Check               : Complete (0:05:35)
  etcd Install               : Complete (-1 day, 22:57:25)
  NFS Install                : Complete (0:00:48)
  Master Install             : Complete (0:06:25)
 Master Additional Install  : Complete (0:01:01)
 Node Install               : complete (0:03:20)
```

-Installation takes approximately 10-15 minutes.

### Start OpenShift Container Platform
After successful installation, use the following command to start OpenShift Container Platform.

```
systemctl restart atomic-openshift-master-api atomic-openshift-master-controllers
```

-Before you do anything more, log in at least one time with the default system:admin user and on the master run the following command.

```
$ oc login -u system:admin
```

-Run the following command to verify that OpenShift Container Platform was installed and started successfully.
```
$ oc get nodes
```

### Change Log In Identity Provider
The default behavior of a freshly installed OpenShift Container Platform instance is to deny any user from logging in. To change the 
authentication method to HTPasswd:

1. Open the /etc/origin/master/master-config.yaml file in edit mode.
2. Find the identityProviders section.
3. Change DenyAllPasswordIdentityProvider to HTPasswdPasswordIdentityProvider.
4. Change the value of the name label to htpasswd_auth and add a new line file: /etc/origin/openshift-passwd in the provider section.

An example identityProviders section with HTPasswdPasswordIdentityProvider will look like the following.

```
oauthConfig:
  ...
  identityProviders:
  - challenge: true
    login: true
    name: htpasswd_auth provider
    provider:
      apiVersion: v1
      kind: HTPasswdPasswordIdentityProvider
      file: /etc/origin/openshift-passwd
```

5. Save the file.

### Create User Accounts
1. You can use the httpd-tools package to obtain the htpasswd binary that can generate these accounts.

```
# yum -y install httpd-tools
```

2. Create a user account.

```
# touch /etc/origin/openshift-passwd
# htpasswd -b /etc/origin/openshift-passwd admin redhat
```
You have created a user with admin role and password as redhat.

3. Restart OpenShift before going forward.

```
# systemctl restart atomic-openshift-master-api atomic-openshift-master-controllers
```

4. Give this user account cluster-admin privileges, which allows it to do everything.

```
oc adm policy add-cluster-role-to-user cluster-admin admin --as=system:admin
```

5. You can use this username/password combination to log in via the web console or the command line. To test this, run the following command.

```
$ oc login -u admin
```

6. Provide access to the host-volumes (which are needed by the OpenEBS volume replicas) by updating the default security context (scc).

```
oc edit scc restricted
```

-Add ```allowHostDirVolumePlugin: true```, ```runAsUser: type: RunAsAny``` and save changes.

7. Allow the containers in the project to run as root.

```
oc adm policy add-scc-to-user anyuid -z default --as=system:admin 
```
**Note**: While the above procedures may be sufficient to enable host access to the containers, you may also need to disable selinux (via setenforce 0) to ensure the same.


### Setup OpenEBS Control Plane
-Download the latest OpenEBS operator files and sample application specifications on OpenShift-Master machine.

```
git clone https://github.com/openebs/openebs.git
cd openebs/k8s
```
-Apply the openebs-operator on the openshift cluster.

```
oc apply -f openebs-operator
oc apply -f openebs-storageclasses.yaml
```

-After applying the operator yaml, if you see pod status is in pending state and on describing the maya-apiserver pod the the following error message is found.

```
[root@osnode1 ~]# oc get pods -n openebs
NAME                                        READY     STATUS    RESTARTS   AGE
maya-apiserver-6f48fc5449-7kxfz             0/1       Pending   0          3h
openebs-provisioner-7bf6fd7c8f-ph84w        0/1       Pending   0          3h
openebs-snapshot-operator-8bd769dc7-8c47x   0/2       Pending   0          3h



Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  1m (x772 over 3h)  default-scheduler  0/2 nodes are available: 2 MatchNodeSelector.
```

- You need to have Node-Selectors label set for the nodes that you want to use for compute. i.e. oc edit node osnode1.mdataqa.in and  
  insert this label node-role.kubernetes.io/compute: "true". That will schedule your pods.

```
 labels:
    beta.kubernetes.io/arch: amd64
    beta.kubernetes.io/os: linux
    kubernetes.io/hostname: osnode1.mdataqa.in
    node-role.kubernetes.io/compute: "true"
    node-role.kubernetes.io/master: "true"
```

-Reapply the Openebs-operator and openebs-storageclass yaml.

```
[root@osnode1 prabhat]# oc get deployments -n openebs
NAME                        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
maya-apiserver              1         1         1            1           3d
openebs-provisioner         1         1         1            1           3d
openebs-snapshot-operator   1         1         1            1           3d
```

```
[root@osnode1 prabhat]# oc get pods -n openebs
NAME                                       READY     STATUS    RESTARTS   AGE
maya-apiserver-dc8f6bf4d-75bd4             1/1       Running   0          3d
openebs-provisioner-7b975bcd56-whjxq       1/1       Running   0          3d
openebs-snapshot-operator-7f96fc56-8xcw8   2/2       Running   0          3d
```

```
[root@osnode1 prabhat]# oc get svc
NAME                                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                 AGE
kubernetes                                          ClusterIP   172.30.0.1      <none>        443/TCP,53/UDP,53/TCP   4d
pvc-1f85ecd4-90e4-11e8-bbab-000c29d8ed2b-ctrl-svc   ClusterIP   172.30.236.57   <none>        3260/TCP,9501/TCP       3d
[root@osnode1 prabhat]# oc get svc -n openebs
NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
maya-apiserver-service   ClusterIP   172.30.242.47   <none>        5656/TCP   3d
```

```
[root@osnode1 prabhat]# oc get sa -n openebs
NAME                    SECRETS   AGE
builder                 2         3d
default                 2         3d
deployer                2         3d
openebs-maya-operator   2         3d
```

```
[root@osnode1 prabhat]# oc get clusterrole openebs-maya-operator
NAME
openebs-maya-operator
```

```
[root@osnode1 prabhat]# oc get clusterrolebindings openebs-maya-operator
NAME                    ROLE                     USERS     GROUPS    SERVICE ACCOUNTS                                 SUBJECTS
openebs-maya-operator   /openebs-maya-operator                       openebs/openebs-maya-operator, default/default
```

```
[root@osnode1 prabhat]# oc get sc
NAME                        PROVISIONER                                                AGE
openebs-cassandra           openebs.io/provisioner-iscsi                               3d
openebs-es-data-sc          openebs.io/provisioner-iscsi                               3d
openebs-jupyter             openebs.io/provisioner-iscsi                               3d
openebs-kafka               openebs.io/provisioner-iscsi                               3d
openebs-mongodb             openebs.io/provisioner-iscsi                               3d
openebs-percona             openebs.io/provisioner-iscsi                               3d
openebs-redis               openebs.io/provisioner-iscsi                               3d
openebs-snapshot-promoter   volumesnapshot.external-storage.k8s.io/snapshot-promoter   3d
openebs-standalone          openebs.io/provisioner-iscsi                               3d
openebs-standard            openebs.io/provisioner-iscsi                               3d
openebs-zk                  openebs.io/provisioner-iscsi                               3d
```

#### Deploy a sample application with OpenEBS storage

- Use OpenEBS as persistent storage for a Percona deployment by selecting the openebs-Percona storageclass in the persistent 
volume claim. 

Apply this Percona deployment yaml.

```
cd demo/percona
oc apply -f demo-percona-mysql-pvc.yaml
```

```
[root@osnode1 prabhat]# oc get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
percona                                                          1/1       Running   0          3d
pvc-1f85ecd4-90e4-11e8-bbab-000c29d8ed2b-ctrl-7bc6dbf48b-hvf5r   2/2       Running   0          3d
pvc-1f85ecd4-90e4-11e8-bbab-000c29d8ed2b-rep-85bf9bb55b-jc7np    1/1       Running   0          3d
pvc-1f85ecd4-90e4-11e8-bbab-000c29d8ed2b-rep-85bf9bb55b-t4jrt    1/1       Running   0          3d
```

The link of the documentation [openshift](https://access.redhat.com/documentation/en-us/openshift_container_platform/3.9/html-single/getting_started/#developers-console-before-you-begin)


















