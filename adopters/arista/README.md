### Company: Arista Networks (https://www.arista.com/en/)

### Stateful Applications that you are running on OpenEBS
- Gerrit (multiple flavors), NPM, Maven, Redis, NFS, Sonarqube
- Various internal tooling requiring stateful storage.

### Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV?
About ~90% cStor, 10% Jiva.

### Are you evaluating or already using in development, CI/CD, production
Used in dev, staging, and production clusters.

### Are you using for home use or for your organization
For Arista Networks.

### A brief description of the use case or details on how OpenEBS is helping your projects.
- Easy for developers to use: developers don't have to worry beyond choosing the right storageclass and size of storage. Decouples developers from storage integrity and unnecessary details that they shouldn't have to worry about.
- Withstand cluster disasters: OpenEBS' ability to spread volumes across multiple nodes in a kubernetes cluster as well as automatic recovery of degraded replicas without operator involvement was our highest requirement for a storage solution, and OpenEBS met this perfectly. Rolling upgrades with kubernetes is a breeze thanks OpenEBS, since we only need to maintain quorum and not require all replicas/nodes to be online.
- Separation of application from storage in terms of physical location: application is entirely decoupled from where the storage is thanks to iSCSI backbone. We can optimize storage nodes vs. nodes serving applications thanks to OpenEBS being built on networked storage.
- Configurability and ease of deployment: deployment of the entire stack is very easy. As an early adopter, upgrades are a pain point, but I'm pleased to see the team have fixed this in later versions with helm, which is the right thing to do. Configurable NDM and cStor pools that allowed us to have
 extensive custom configurations for our storage nodes vs. application nodes.
- Doesn't require 139746387243 nodes to operate (exaggeration): compared to Ceph, amount of starting nodes required to operate OpenEBS is incomparably lower/efficient. 
- Uses age old technologies proven to work, rather than unproven solutions: built on iSCSI, ZFS. Standard solutions. No unknown unicorn magic.
