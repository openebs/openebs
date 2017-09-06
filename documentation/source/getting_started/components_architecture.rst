Components and Architecture
===========================
This section includes OpenEBS components and architecture.

Components
----------

OpenEBS platform contains three major components:

  * Storage PODs or VSMs
  * An orchestration engine or VSM Scheduler called Maya
  * The OpenEBS hosts that provide the data store from either local disks or remote disks

.. image:: /_static/basic.png

Architecture
-------------

Maya is the orchestration engine that schedules the VSMs among OpenEBS hosts as needed. Maya driver (Docker Volume Driver for Maya) plays an important role in achieving the smooth flow of provisioning of VSMs and attaining the application consistent snapshots. The data is kept in more than one copy among the OpenEBS hosts through a backend network replication, thus achieving the necessary redundancy. VSMs expose the iSCSI interface currently.

The backend data store for Jiva containers come either through locally managed disks or through remotely managed network disks. The intelligent caching along with the lazy read indexing capability makes it possible to treat remote S3 storage also as the backing data store (Refer to the Roadmap: TBD)

.. image:: /_static/architecture.png
