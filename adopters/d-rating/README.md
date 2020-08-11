### Company
D-Rating

### Stateful Applications that we are running on OpenEBS
MongoDB
Elasticsearch
Postgresql

### Type of OpenEBS Storage Engines behind the above applications
cStor

### Are you evaluating or already using in development, CI/CD, production?
We are using a full CI/CD Rancher/Kubernetes stack.

### Are you using for home use or for your organization?
Organization

### A brief description of the use case or details on how OpenEBS is helping your projects.

We where using local volumes at first but we had to become HA and then we had to adopt a dedicated system. We tried longhorn and migrated to OpenEBS. We lost a node (bare metal) recently which was used as a cStor blockdevice, the replication seemed to work as we didn't loose any data ;)
