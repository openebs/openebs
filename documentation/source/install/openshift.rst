:orphan:

Running OpenEBS on a Multi-Node CentOS 7 OpenShift Cluster
------------------------------------------------------------

This section provides detailed instructions on how to setup a multi-node Bring-Your-Own-Host (BYO) OpenShift cluster on CentOS 7 and run applications on it with OpenEBS storage.

Pre-requisites:
^^^^^^^^^^^^^^^^^^
* At least 2 or more CentOS 7 hosts (virtual-machines/baremetal/cloud instances) with 2 vCPUs, 4G RAM and 16GB hard disk.

* Ensure that the following package dependencies are installed on the hosts using yum install. 
  **Note:** yum update may be needed prior to this step.

  -   python, wget, git, net-tools, bind-utils, iptables-services, bridge-utils, bash-completion, kexec-tools, sos, psacct, docker-1.12.6

* Ensure that the following python packages are installed on hosts using pip install. 
  **Note:** Python-pip can be installed using easy_install pip if not present already.

  - Ansible (>= 2.3) on the local machine or any one of the hosts (typically installed on the host used as openshift-master).
  - pyYaml Python package on all the hosts.

* Functional DNS server, with all hosts configured by appropriate domain names (ensure nslookup of the hostnames is successful in resolving the machine's IP addresses).

* Setup passwordless SSH between the Ansible host and other hosts.

**Notes:**

* System recommendations for production cluster can be found here. This document focuses on bringing up a setup for evaluation purposes.

* Ensure that the Docker service is running.

Installing OpenShift
^^^^^^^^^^^^^^^^^^^^^^

1. Download the OpenShift Ansible Playbooks.

  Clone the OpenShift Ansible repository of any stable release branch to your Ansible machine and go to the directory. Use the same version of openshift-ansible and openshift-origin release for installation.

  In this example, you will install Openshift Origin release v3.7 using the following commands.
  ::  
    git clone https://github.com/openshift/openshift-ansible.git
    cd openshift-ansible

2. Prepare the OpenShift Inventory file.

  Create the ansible inventory file to install a simple OpenShift cluster with only master and nodes setup. You can use the following inventory template.
  ::
    cat openshift_inventory

    [OSEv3:children]
    masters
    nodes
    etcd

    [OSEv3:vars]
    # SSH user, this user should allow ssh based auth without requiring a password
    ansible_ssh_user=root
    ansible_ssh_port=22
    openshift_deployment_type=origin
    deployment_type=origin
    openshift_release=v3.7
    openshift_pkg_version=-3.7.0
    debug_level=2
    openshift_disable_check=disk_availability,memory_availability,docker_storage,docker_image_availability
    openshift_master_default_subdomain=apps.cbqa.in
    osm_default_node_selector='region=lab'

    openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/htpasswd'}]

    [masters]
    CentOS1.cbqa.in

    [etcd]
    CentOS1.cbqa.in

    [nodes]
    CentOS1.cbqa.in openshift_node_labels="{'region': 'infra', 'zone': 'baremetal'}" openshift_schedulable=true
    CentOS2.cbqa.in openshift_node_labels="{'region': 'lab', 'zone': 'baremetal'}" openshift_schedulable=true
    CentOS3.cbqa.in openshift_node_labels="{'region': 'lab', 'zone': 'baremetal'}" openshift_schedulable=true
    CentOS4.cbqa.in openshift_node_labels="{'region': 'lab', 'zone': 'baremetal'}" openshift_schedulable=true

**Note:**
The OpenShift deploy cluster playbook performs a health-check prior to execution of the install roles to verify system readiness. Typically, the following pitfalls can be observed:

* Memory_availability and storage_availability

  - Issue: Checks fail if you do not adhere to production standards.
  - Workaround: Disable check by adding into openshift_disable_check inventory variable.

* Docker image availability

  - Issue: Checks fail if there are DNS issues/flaky networks due to which the docker.io registry cannot be accessed. Sometimes, this fails even when a manual inspection shows they are available and accessible to the machine.
  - Workaround: If manual Skopeo inspect is successful, disable check by adding into openshift_disable_check inventory variable.

    Skopeo inspect example: skopeo inspect --tls-verify=false docker://docker.io/cockpit/kubernetes:latest

* Docker storage availability

  - Issue: Can fail if the Docker service is not running. The daemon does not automatically run post yum install.
  - Workaround: Restart Docker daemon.

* Package availability and Package version

  - Issue: OpenShift packages with desired versions (specified in the inventory) are not available for install with default repository setup.

  - Workaround: The OpenShift Origin packages are released separately for CentOS. The repositories on these need to be added into the hosts.

    The packages are available here and the GPG keys can be downloaded from here.

    Following additions can be made to the existing CentOS repositories (/etc/yum.repos.d/CentOS-Base.repo):
    ::
      #openshift
      [openshift]
      name=CentOS-OpenShift
      baseurl=http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin/
      gpgcheck=1
      enabled=1
      gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-PaaS

3. Run the Ansible Playbook job to setup OpenShift cluster.

  Once the inventory file is ready, run the deploy_cluster playbook to setup the OpenShift cluster. The setup can take around 15-20 minutes depending on network speed and resources available.

  **Note:**
  The deploy_cluster playbook also includes playbooks to setup Glusterfs, monitoring, logging and so on which are optional. In this example, only the etcd, master, node, and management setup playbooks were executed, with other playbook imports commented.
  ::
    ansible-playbook -i openshift-ansible/openshift_inventory openshift-ansible/playbooks/deploy_cluster.yml

  The playbook should complete without errors. The trailing output of the playbook run should look similar to the following:
  ::
    PLAY RECAP *************************************************************************************************************
    CentOS1.cbqa.in            : ok=404  changed=124  unreachable=0    failed=0
    CentOS2.cbqa.in            : ok=144  changed=46   unreachable=0    failed=0
    CentOS3.cbqa.in            : ok=144  changed=46   unreachable=0    failed=0
    CentOS4.cbqa.in            : ok=144  changed=46   unreachable=0    failed=0
    localhost                  : ok=12   changed=0    unreachable=0    failed=0

    INSTALLER STATUS *******************************************************************************************************
    Initialization             : Complete (0:00:43)
    Health Check               : Complete (0:00:11)
    etcd Install               : Complete (0:01:20)
    Master Install             : Complete (0:09:44)
    Master Additional Install  : Complete (0:00:48)
    Node Install               : Complete (0:06:28)

  Execute the following commands to verify successful installation.
  ::
    oc get nodes

    NAME              STATUS    AGE       VERSION
    centos1.cbqa.in   Ready     16h       v1.7.6+a08f5eeb62
    centos2.cbqa.in   Ready     16h       v1.7.6+a08f5eeb62
    centos3.cbqa.in   Ready     16h       v1.7.6+a08f5eeb62
    centos4.cbqa.in   Ready     16h       v1.7.6+a08f5eeb62

4. Initial setup

* Execute the following command to create a new administrator user with cluster-admin role/permissions which can be used to run the OpenEBS operator and deploy applications.
  ::
     oc adm policy add-cluster-role-to-user cluster-admin admin --as=system:admin

* Assign password to the administrator user using the following command.
  ::
      htpasswd /etc/origin/htpasswd admin

* Login as administrator user and use the "default" project (administrator is logged into this project by default).
  ::
      oc login -u admin

* Provide access to the host-volumes (which are needed by the OpenEBS volume replicas) by updating the default security context (scc) using the following command.
  ::
      oc edit scc restricted

Add **allowHostDirVolumePlugin: true** and save changes.

Alternatively, you can use the following command.
::
    oc adm policy add-scc-to-user hostaccess admin --as:system:admin

* Allow the containers in the project to run as root using the following command.
  ::
    oc adm policy add-scc-to-user anyuid -z default --as=system:admin 

**Note:**
While the above procedures may be sufficient to enable host access to the containers, it may also be needed to disable selinux (using setenforce 0) to ensure the same.

5. Setup OpenEBS Control Plane

* Download the latest OpenEBS operator files and sample application specifications on the OpenShift-Master machine using the following commands.
  ::
    git clone https://github.com/openebs/openebs.git
    cd openebs/k8s

* Apply the openebs-operator on the OpenShift cluster using the following commands.
  ::
    oc apply -f openebs-operator
    oc apply -f openebs-storageclasses.yaml

* Verify that the OpenEBS operator services are created successfully and deployments are running using the following commands. Also, check whether the storageclasses are created successfully.
  ::
    oc get deployments

    NAME                                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    maya-apiserver                                  1         1         1            1           13h
    openebs-provisioner                             1         1         1            1           13h
    oc get pods

    NAME                                                             READY     STATUS    RESTARTS   AGE
    maya-apiserver-3053842955-wdxdl                                  1/1       Running   0          13h
    openebs-provisioner-2499455298-n8lgc                             1/1       Running   0          13h
    oc get svc

    NAME                                                CLUSTER-IP      EXTERNAL-IP   PORT(S)                 AGE
    kubernetes                                          172.30.0.1      <none>        443/TCP,53/UDP,53/TCP   17h
    maya-apiserver-service                              172.30.168.61   <none>        5656/TCP                13h
    oc get sa

    NAME                    SECRETS   AGE
    builder                 2         17h
    default                 2         17h
    deployer                2         17h
    openebs-maya-operator   2         13h
    oc get clusterrole openebs-maya-operator

    NAME
    openebs-maya-operator
    oc get clusterrolebindings openebs-maya-operator

    NAME                    ROLE                     USERS     GROUPS    SERVICE ACCOUNTS                                 SUBJECTS
    openebs-maya-operator   /openebs-maya-operator                       default/openebs-maya-operator, default/default
    oc get sc

    NAME                 TYPE
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

6. Deploy a sample application with OpenEBS storage.

* Use OpenEBS as persistent storage for a percona deployment by selecting the openebs-percona storageclass in the persistent volume claim. A sample is available in the openebs git repo (which was cloned in the previous steps).

  Apply the following percona deployment yaml using the following commands.
  ::
    cd demo/percona
    oc apply -f demo-percona-mysql-pvc.yaml

* Verify that the deployment runs successfully using the following commands.
  ::
    oc get pods

    NAME                                                             READY     STATUS    RESTARTS   AGE
    maya-apiserver-3053842955-wdxdl                                  1/1       Running   0          13h
    openebs-provisioner-2499455298-n8lgc                             1/1       Running   0          13h
    percona-1378140207-5q2gb                                         1/1       Running   0          11h
    pvc-de965f7d-f301-11e7-a6ce-000c29a47920-ctrl-2226696718-sh8cc   2/2       Running   0          11h
    pvc-de965f7d-f301-11e7-a6ce-000c29a47920-rep-4109589824-5zf7t    1/1       Running   0          11h

7. Manage cluster from OpenShift management console

Login to the OpenShift management console at https://:8443 as "admin" user. Navigate on the left pane to view different consoles and manage the cluster resources.

  .. figure:: /_static/openshift.png
    :align: center


