### User: Rytis Ilciukas ([linkedin.com/in/rytis-ilciukas](https://linkedin.com/in/rytis-ilciukas))

I'm running True NAS Scale with OpenEBS (Local PV) + FluxCD

### **Stateful Applications that you are running on OpenEBS**

- ownCloud
- Jellyfin
- PhotoPrism
- filebrowser
- pyLoad

### **Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV?**
ZFS-LocalPV

### **Are you evaluating or already using in development, CI/CD, production**
Evaluating for Home NAS

### **A brief description of the use case or details on how OpenEBS is helping your projects.**
I'm using True NAS Scale with Flux CD to fully describe the desired state of my NAS. OpenEBS + Flux CD allows me to define my applications, their configs and storage needs (ZPool Datasets) in git without needing to interact with True NAS Scale UI. Since the entire state is version controlled disaster recovery should be a cake walk.
