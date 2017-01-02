#Introduction to OpenEBS

OpenEBS is a storage platform, written in GoLang, to deliver persistent block storage for container eco system. The storage itself is containerized through a storage POD concept called VSM or "Virtual Storage Machine". VSMs are scheduled and managed using an orchestrator engine called "Maya". VSMs are fully isolated user space storage engines that present the block storage at the front end through iSCSI, NBD or TCMU protocol and consume raw storage from a local OpenEBS host or remote storage.  

#Components of OpenEBS platform
OpenEBS platform contains three major components
* Storage PODs or VSMs
* An orchestration engine or VSM Scheduler called Maya
* The OpenEBS hosts that provide the data store from either local disks or remote disks

![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/OpenEBS-intro-v1.jpg)



#Architectural overview
![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/MayaArchitectureOverview.png)

Maya is the orchestration engine that schedules the VSMs among OpenEBS hosts as needed. Maya driver (Docker Volume Driver for Maya) plays an important role in achieving the smooth flow of provisioning of VSMs and attaining the application consistent snapshots. The data is kept in more than one copy among the OpenEBS hosts through a backend network replication, thus achieving the necessary redundancy. VSMs expose the iSCSI interface currently. 

The backend data store for Jiva containers come either through locally managed disks or through remotely managed network disks. The intelligent caching along with the lazy read indexing capability makes it possible to treat remote S3 storage also as the backing data store (Refer to the Roadmap: TBD)

#Built with the best tools 
OpenEBS uses the best available infrastructure libraries underneath. Jiva (means "life" in Sanskrit) is the core software that runs inside the storage container. The core functionalities of Jiva include 
- Block storage protocol (iSCSI/TCMU/NBD)
- Replication
- Snapshotting
- Caching to NVMe
- Encryption 
- Backup/Restore
- QoS 
Jiva inherits majority of its capabilities from Rancher Longhorn (https://github.com/rancher/longhorn). QoS, Caching, Backup/Restore capabilities are being added to Jiva.

Use | Library |  Logo     | Usage
------- | ---------------- | ---------- | ---------
Containerization  | Docker |  ![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/docker.png) | Dockerized images are pushed onto docker hub
Jiva  | Rancher Longhorn        | ![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/rancher.png)       | Longhorn is one of the software components of Jiva. Multiple Jiva containers make a VSM
Maya Scheduler   | Nomad | ![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/nomad.jpg)      | Nomad library forms the core of Maya scheduler
Networking   | Flannel | ![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/flannel.png)      | Flannel library is used without its config db
Automation   | Terraform | ![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/terraform.jpg)      | Terraform compatible
Automation   | Ansible | ![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/ansible.png)      | Ansible compatible
Orchestration integration   | Kubernetes | ![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/kubernetes.png)      | VSMs are scheduled from k8s



#Programmable storage
Maya is designed to have developer friendly interfaces to configure, deploy and manage the storage platform. Maya provides the configuration through YAML files and automation is made possible through ansible and/or terraform

![alt tag](https://raw.githubusercontent.com/openebs/openebs/master/docs/images/programmable-storage.jpg)







#Jiva overview



#Maya overview





