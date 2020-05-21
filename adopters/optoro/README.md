### Company: Optoro  (https://www.optoro.com/)

### Stateful Applications that you are running on OpenEBS
- Postgres
- MySQL
- Kafka
- Redis
- ElasticSearch
- Prometheus 
- Thanos


### Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV?
100% zfs-localpv

### Are you evaluating or already using in development, CI/CD, production
OpenEBS is the default in all of our baremetal kubernetes environments.

### Are you using for home use or for your organization
We use OpenEBS to power Optoro's Optiturn Platform. 

### A brief description of the use case or details on how OpenEBS is helping your projects.
The vast majority of applications are able to better handle failover and replication than a block level device.  Instead of introducing another distributed system into an already complex environment, OpenEBS's localPVs allow us to leverage fast local storage.  Additionly, by leveraging ZFS we are able to have encryption at rest for all of our workloads, compression, and the piece of mind of  a COW based filesystem.  OpenEBS has allowed us to not introduce a complicated distributed system into our platform.  The adoption has been smooth and completely transparent to our end users.   
