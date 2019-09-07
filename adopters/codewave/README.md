### Company: [CodeWave](https://codewave.eu)

### Storage Engine:
Jiva. We are planning tests on cStor and might switch to it.

### Number of Applications: 
varies between 20 and 50 

### Names of the Stateful Applications: 
The tools we are using or were using with OpenEBS: Bitwarden, Bookstack, Allegros Ralph, LimeSurvey, Grafana, Hackmd/Codimd, MinIO, Nextcloud, Percona XtraDB Cluster Operator, Nextcloud, SonarQube, Sentry, JupyterHub.

### Our products
Contente - CMS (more like Anything Management System, since it manages much more than just typical web content).
Synapticall - Callcenter management software with automatic routing, call recording, call transcription, etc.
 
### CI/CD powered review applications 
All of the projects we are writing for our customers (e.g. based on our CMS, or on Symfony, or simple static pages, WordPress) have a preview version for each of the feature branches and production-like staging, the last one being always persistent. For those, we are using OpenEBS to keep our data persisted and to move it around the cluster. 

### Cluster Type: 
Baremetal with some nodes on KVM virtual machines

### For whom 
CodeWave and all of our current clients we are hosting code/stagings for.

### Any short notes on use cases of why you selected OpenEBS. 

The above applications use OpenEBS mostly for DB persistence (Mysql/Maria/Percona, Postgres, Mongo etc), for live file storage (typical uploads, media etc) and/or for backups. Our internal tools are installed manually and mostly are under manual control, while CI/CD powered deployments (of our products and projects for our clients) are fully automated, with auto PVC provisioning and management. 

We started using OpenEBS over one year ago, mostly because we found it easier to use and a bit more stable on our cluster than it's competition. It's not the only way of supporting persistent apps, but currently, it's most often used in our case and OpenEBS StorageClass serves as our default SC. 
