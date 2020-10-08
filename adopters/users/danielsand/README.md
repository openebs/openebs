### Home Baremetal MultiArch Cluster

NAS Intel i5 16 GB RAM ZFS 12 TB (amd64)
3x RPI4 8 GB (aarch64)

### Stateful Applications that you are running on OpenEBS

- Postgres
- Prometheus
- Mongodb
- Concourse
- Harbor
- openldap
- NextCloud

and more

### Type of OpenEBS Storage Engine(s)

cStor deployed on multiarch 

### Are you evaluating or already using in development, CI/CD, production

CI/CD - **check**  
Production Applications for myself - **check**  
Development - **check**  

### Are you using for home use or for your organization

home use

### A brief description of the use case or details on how OpenEBS is helping your projects.

Im running for 3+ Years a Baremetal Kubernetes Cluster at home - 4 Intel Nodes in total - the PVC was done before with rook / NFS / Native Ceph / GlusterFS
Most of the time i sticked to 3 Node Rook Ceph setup - which works good but has a lot of Memory usage especially on a long running enviroment.
Also i wanted to shift to aarch64 since the RPI4 8GB versions reached the marked out of power consumption reasons.

### A big **Thank you** to the OpenEBS slack channel support people

thanks ! 
