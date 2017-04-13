.. _getting_started:


*********************************
Installations and configurations
*********************************

.. _installing-docdir:

Installing from binaries
=============================

Install Maya
-------------


maya is a single binary that will be installed on both OpenEBS Maya Master (OMM) and OpenEBS Storage Host (OSH) machines. Maya can then be used to configure the machine either as omm or osh. Maya will pull in the dependencies from github or dockerhub. OpenEBS binary (maya) releases are maintained in github at https://github.com/openebs/maya/releases

Before proceeding to install maya, verify that wget and unzip packages are installed.::

  RELEASE_TAG=0.0.4
  wget https://github.com/openebs/maya/releases/download/${RELEASE_TAG}/maya-linux_amd64.zip
  unzip maya-linux_amd64.zip
  sudo mv maya /usr/bin
  rm -rf maya-linux_amd64.zip
  maya version


.. _fetching-the-data:

Setup OpenEBS Maya Master (OMM)
--------------------------------

Verify that maya is installed and obtain the Listen IP address for Maya Master. The maya cli will connect to this IP address for scheduling and managing the VSMs.::

  ubuntu@master-01:~$ maya version
  Maya v'0.0.4'-dev ('6fe624e3bc71c0b053795939511eff00a18c10f3')
  ubuntu@master-01:~$ ip addr show | grep global
     inet 10.0.2.15/24 brd 10.0.2.255 scope global enp0s3
     inet 172.28.128.8/24 brd 172.28.128.255 scope global enp0s8
  ubuntu@master-01:~$ maya version

Let us use the 172.28.128.8 as the listen IP address. Configure the machine as OMM with the following instruction.::
  
  ubuntu@master-01:~$ maya setup-omm -self-ip=172.28.128.8
  ubuntu@master-01:~$ source ~/.profile	

Verify that Maya Master is configured by running the following command::
  
  ubuntu@master-01:~$ maya omm-status
  Name              Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
  master-01.global  172.28.128.8  4648  alive   true    2         0.5.0  dc1         global
  ubuntu@master-01:~$ 


Setup OpenEBS Storage Host (OSH)
---------------------------------

Verify that maya is installed and obtain the Listen IP address for Maya Master. The maya cli will connect to this IP address for scheduling and managing the VSMs.::
  
  ubuntu@host-01:~$ maya version
  Maya v'0.0.4'-dev ('6fe624e3bc71c0b053795939511eff00a18c10f3')
  ubuntu@host-01:~$ ip addr show | grep global
     inet 10.0.2.15/24 brd 10.0.2.255 scope global enp0s3
     inet 172.28.128.9/24 brd 172.28.128.255 scope global enp0s8
  ubuntu@host-01:~$ 

Let us use the 172.28.128.9 as the listen IP address and connect to the previously installed Maya Master at 172.28.128.8 Configure the machine as OSH with the following instruction.::
  
  ubuntu@host-01:~$ maya setup-osh -self-ip=172.28.128.9 -omm-ips=172.28.128.8
  ubuntu@host-01:~$ source ~/.profile

Verify that Storage Host is configured by running the following command::
  
  ubuntu@host-01:~$ maya osh-status
  ID        DC   Name     Class   Drain  Status
  dc7fd9b9  dc1  host-01  <none>  false  ready
  ubuntu@host-01:~$

Repeat the same steps on the host-02 as well.



Verify configuration
---------------------

On successful completion, the omm-status should show one entry and osh-status should have two entries. The output should look like below::
  
  ubuntu@master-01:~$ maya omm-status
  Name              Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
  master-01.global  172.28.128.8  4648  alive   true    2         0.5.0  dc1         global
  ubuntu@master-01:~$ maya osh-status
  ID        DC   Name     Class   Drain  Status
  cbceb3d2  dc1  host-02  <none>  false  ready
  dc7fd9b9  dc1  host-01  <none>  false  ready
  ubuntu@master-01:~$ 
  Next  Previous

Installing from source
========================

An OpenEBS Cluster comprises of OpenEBS Maya Masters (omm) for storing the metadata and orchestrating the VSMs on the OpenEBS Storage Hosts (osh). The OpenEBS Storage Hosts typically would either have hard disks/SSDs or mounted file/block/s3 storage that will be used as persistent store.

maya is the only binary that needs to be installed on the machine to turn the machine in to either omm or osh. Maya will pull in the dependencies from githup or dockerhub as required. You need to have the machine connected to internet while running the setup commands.

Software Requirements
-----------------------

On your machine, ensure the following: - golang is installed. Verify $GOPATH environment variable is set and $GOPATH/bin is included in your $PATH - git is installed for downloading the source - zip and unzip packages are required for creating and distributing the depedencies

Download Source, Compile and Install maya 
-------------------------------------------

  mkdir -p $GOPATH/src/github.com/openebs && cd $GOPATH/src/github.com/openebs
  git clone https://github.com/openebs/maya.git
  cd maya && make dev

Verify maya is running 
-----------------------

  maya

Setup OpenEBS Maya Master (omm) 
--------------------------------

  ubuntu@master-01:~$ maya setup-omm -self-ip=172.28.128.3


Setup OpenEBS Host (osh)
-------------------------

  ubuntu@host-01:~$ maya setup-osh -self-ip=172.28.128.6 -omm-ips=172.28.128.3


Configuration
================

Storage Configuration
-----------------------

Download the Sample Configuration:

 ubuntu@master-01:~$ mkdir vsms
 ubuntu@master-01:~$ cd vsms/
 ubuntu@master-01:~/vsms$ wget https://raw.githubusercontent.com/openebs/maya/master/demo/jobs/demo-vsm1.hcl


Modify the IP address on which the iSCSI volumes needs to be accessed by the frontend container. Provide the size and an unique name.::
  
  meta {
      JIVA_VOLNAME = "demo-vsm1-vol1"
      JIVA_VOLSIZE = "10g"
      JIVA_FRONTEND_VERSION = "openebs/jiva:latest"
      JIVA_FRONTEND_NETWORK = "host_static"
      JIVA_FRONTENDIP = "172.28.128.101"
      JIVA_FRONTENDSUBNET = "24"
      JIVA_FRONTENDINTERFACE = "enp0s8"
      }  



Similarly, customise the backend container pamameters::

  env {
     JIVA_REP_NAME = "${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}"
     JIVA_CTL_IP = "${NOMAD_META_JIVA_FRONTENDIP}"
     JIVA_REP_VOLNAME = "${NOMAD_META_JIVA_VOLNAME}"
     JIVA_REP_VOLSIZE = "${NOMAD_META_JIVA_VOLSIZE}"
     JIVA_REP_VOLSTORE = "/tmp/jiva/vsm1/rep1"
     JIVA_REP_VERSION = "openebs/jiva:latest"
     JIVA_REP_NETWORK = "host_static"
     JIVA_REP_IFACE = "enp0s8"
     JIVA_REP_IP = "172.28.128.102"
     JIVA_REP_SUBNET = "24"
     }



Schedule the VSM Creation::

  ubuntu@master-01:~/vsms$ maya vsm-create demo-vsm1.hcl 
  ==>Monitoring evaluation "f8917fad"
     Evaluation triggered by job "demo-vsm1"
     Allocation "59ecd70d" created: node "1baf7f69", group "demo-vsm1-backend-container1"
     Allocation "d10ff4fc" created: node "b779de4d", group "demo-vsm1-fe"
     Allocation "d196cfb3" created: node "1baf7f69", group "demo-vsm1-backend-container2"
     Evaluation status changed: "pending" -> "complete"
     ==>  Evaluation "f8917fad" finished with status "complete"



Check the status::

  ubuntu@master-01:~/vsms$ maya vsm-list demo-vsm1
  ID          = demo-vsm1
  Name        = demo-vsm1
  Type        = service
  Priority    = 50
  Datacenters = dc1
  Status      = running
  Periodic    = false

  Summary
  Task Group                    Queued  Starting  Running  Failed  Complete  Lost
  demo-vsm1-backend-container1  0       0         1        0       0         0
  demo-vsm1-backend-container2  0       0         1        0       0         0
  demo-vsm1-fe                  0       0         1        0       0         0

  Allocations::
  ID        Eval ID   Node ID   Task Group                    Desired  Status   Created At
  59ecd70d  f8917fad  1baf7f69  demo-vsm1-backend-container1  run      running  01/04/17 07:39:33 UTC
  d10ff4fc  f8917fad  b779de4d  demo-vsm1-fe                  run      running  01/04/17 07:39:33 UTC
  d196cfb3  f8917fad  1baf7f69  demo-vsm1-backend-container2  run      running  01/04/17 07:39:33 UTC
  ubuntu@master-01:~/vsms$ 


Check the osh where the VSMs are running.::

  ubuntu@master-01:~/vsms$ maya osh-status
  ID        DC   Name     Class   Drain  Status
  1baf7f69  dc1  host-02  <none>  false  ready
  b779de4d  dc1  host-01  <none>  false  ready
  ubuntu@master-01:~/vsms$ 

Docker status::

  ubuntu@host-02:~$ docker images
  REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
  openebs/jiva        latest              d3e3835763f3        11 days ago         308 MB
  ubuntu@host-02:~$ docker ps
  CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS              PORTS               NAMES
  2427c7a510bb        openebs/jiva:latest   "launch controller --"   57 seconds ago      Up 51 seconds                           demo-vsm1-ctl
  c01ce8d57dd8        openebs/jiva:latest   "launch replica --fro"   57 seconds ago      Up 51 seconds                           demo-vsm1-rep-store1
  ubuntu@host-02:~$ 
  Next  Previous

Configuring Docker with OpenEBS Storage
========================================

  ubuntu@client-01:~$ sudo iscsiadm -m discovery -t st -p 172.28.128.101:3260
  172.28.128.101:3260,1 iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1
  ubuntu@client-01:~$ sudo iscsiadm -m node -l
  Logging in to [iface: default, target: iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1, portal: 172.28.128.101,3260] (multiple)
  Login to [iface: default, target: iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1, portal: 172.28.128.101,3260] successful.


Check the block device::

  ubuntu@client-01:~$ sudo iscsiadm -m session -P 3
  iSCSI Transport Class version 2.0-870
  version 2.0-873
  Target: iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1 (non-flash)
     Attached SCSI devices:
     Host Number: 3  State: running
     scsi3 Channel 00 Id 0 Lun: 1
     Attached scsi disk sdc      State: running
     ubuntu@client-01:~$ 


Check the size

  ubuntu@client-01:~$ sudo blockdev --report /dev/sdc
  RO    RA   SSZ   BSZ   StartSec            Size   Device
  rw   256   512  4096          0     10737418240   /dev/sdc
  ubuntu@client-01:~$ 





