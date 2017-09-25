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

Setting up OpenEBS 
==================
Perform this procedure to run OpenEBS operator. Use the following commands at the command prompt:

   1.  kubectl create/apply -f openebs-operator.yaml
   2.  kubectl create/apply -f openebs-storageclasses.yaml

**See Also:**

    `Amazon Cloud`_
          .. _Amazon Cloud: http://openebs.readthedocs.io/en/latest/install/deploy_terraform_kops.html
