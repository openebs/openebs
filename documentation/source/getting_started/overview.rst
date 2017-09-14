
Introducing OpenEBS
===================
OpenEBS is a storage platform, written in GoLang, to deliver persistent block storage for container eco system. The storage itself is containerized through a storage POD concept called VSM or "Virtual Storage Machine". VSMs are scheduled and managed using an orchestrator engine called "Maya". VSMs are fully isolated user space storage engines that present the block storage at the front end through iSCSI, NBD or TCMU protocol and consume raw storage from a local OpenEBS host or remote storage.

**See Also:**

Changelog_
          .. _Changelog: https://github.com/openebs/openebs/releases


.. <<TBD>> Include why OpenEBS/Benefits <<TBD>>

..
   Virtual Tour of OpenEBS
   =======================
  <<TBD>> Include video about OpenEBS <<TBD>>



.. 
  OpenEBS Usecases/Examples
   =========================
   <<TBD>>Can add examples about OpenEBS here and relevant examples with regards to various installations under specific sections.<<TBD>>

.. 
  Tools and Storage <<TBD>> To delete?? <<TBD>>
  ==================

  Built with the best tools
  --------------------------

  OpenEBS uses the best available infrastructure libraries underneath. Jiva (means "life" in Sanskrit) is the core software that runs inside the storage container. The core functionalities of Jiva include - Block storage protocol (iSCSI/TCMU/NBD) - Replication - Snapshotting - Caching to NVMe - Encryption - Backup/Restore - QoS Jiva inherits majority of its capabilities from Rancher Longhorn (https://github.com/rancher/longhorn). QoS, Caching, Backup/Restore capabilities are being added to Jiva.


  Programmable storage
  ----------------------

  Maya is designed to have developer friendly interfaces to configure, deploy and manage the storage platform. Maya provides the configuration through YAML files and automation is made possible through ansible and/or terraform

  .. image:: _static/storage.png
