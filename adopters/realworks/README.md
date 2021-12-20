### **Company**: Realworks BV ([realworks.nl](https://www.realworks.nl/))

### Stateful Applications that you are running on OpenEBS
Strimzi operator Kafka, Spilo operator Postgres ... and possibly more on the way.

### Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV?
Hostpath local PV

### Environment
Production & Development

### Usage
Moving all operations to Kubernetes

### Why OpenEBS?
- NFS semantics are not safe with Kafka or Postgres;
- NFS performance sucks for busy data stores
- CSI standard
- Ease of use
- Ability to install only the required features

OpenEBS just works, and it was easy to drop it in as a replacement for our NFS storage. Kudos!