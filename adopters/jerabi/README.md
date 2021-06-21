### **Company**: Jerabi Inc. 

### Stateful Applications that you are running on OpenEBS
Databases (influxdb, mariadb, elasticsearch, neo4j)
Monitoring stack (Prometheus, Grafana, AlertManager)
All our company stateful applications

### Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV?
cStor (with and without mirror).

### Are you evaluating or already using in development, CI/CD, production
We are currently using it in our development and go in production with it.

### Are you using for home use or for your organization
Our organization (and personal uses too).

### A brief description of the use case or details on how OpenEBS is helping your projects.
The goal was to be able to adapt the storage solution easily without too much knowledge about the solution. We don't want to hire a cloud administrator to handle the storage and configuration, instead we use a devops approach to simplify the process.

With OpenEBS it is easy to switch storage solution (cStor, localpv) when we need. We use OpenEBS on premise and the nodes won't have internet access once the solution is deployed so we couldn't used external cloud solution.

The configuration with Helm chart is well documented and easy to install. One thing that is missing, is a free UI to create cStor pools or partition disks or even update storage configuration.
