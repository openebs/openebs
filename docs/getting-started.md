
#Get Started

OpenEBS Cluster comprises of OpenEBS Maya Masters (omm) for storing the metadata and orchestration of VSMs on the OpenEBS Storage Hosts (osh). The OpenEBS Storage Hosts typically would either have hard disks/SSDs or mounted file/block/s3 storage that will be used as persistent store.

You can get started with just 3 machines and configure 1 into omm and 2 into osh. OpenEBS Cluster capabilities (Capacity / IOPS ) can be increased by attaching new OpenEBS Storage Hosts into the same cluster. For configuration storage redundancy, you can also attach additional omms (3 would be sufficient to avoid SPOF and maintain qorum). 

It is very easy to install OpenEBS from binaries or source on your Ubuntu 16.04 VMs or Appliances and enable them to provide persistent distributed storage to your containers or VMs. All you require is access to Internet!
- [Install from Binaries](https://github.com/openebs/openebs/blob/master/docs/Installing-from-binaries.md)
- [Install from Sources](https://github.com/openebs/openebs/blob/master/docs/installing-from-source.md)
