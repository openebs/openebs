.. _quick-start:

Quick Start
===========

This section allows you to setup OpenEBS instantly.

Prerequisites
--------------
You must have the following:

* Kubernetes installed.
* iSCSI initiator enabled on your minion nodes. The procedure to setup iSCSI initiator will differ based on your host Operating System (OS). 

The following example allows you set up Open-iSCSI on **Ubuntu**. Use the following commands at the command prompt:

  * sudo apt-get update 
  * sudo apt-get install open-iscsi
 
 
**NOTE**: If running inside Rancher, the above commands have to be executed inside the kubelet container. Although open-iscsi will run in a container, the data in /var/openebs will be stored on the hosts.

Run the following commands at the command prompt to run OpenEBS operator.

   1.  kubectl apply -f openebs-operator.yaml
   2.  kubectl apply -f openebs-storageclasses.yaml

**See Also:**

    `Amazon Cloud`_
          .. _Amazon Cloud: http://openebs.readthedocs.io/en/latest/install/cloud_solutions.html#amazon-cloud

    `Google Cloud`_
          .. _Google Cloud: http://openebs.readthedocs.io/en/latest/install/cloud_solutions.html#google-cloud      
