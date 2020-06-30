_RPI Dramble CLuster for Home Use_

**Stateful Applications that you are running on OpenEBS**
- NGINX
- MariaDB
- Homegrown programs

**Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV**
- OpenEBS Dynamic LocalPV, Jiva (local iSCSI Server)

**Are you evaluating or already using in development, CI/CD, production**
- In development, but soon to be in home-based production

**Are you using for home use or for your organization**
- Using in the home web project and using it as a lab example of OpenEBS to potential clients.

**A brief description of the use case or details on how OpenEBS is helping your projects**
- Raspberry PI Kubernetes-based Dramble project using NGINX web server and MariaDB. Various programs to auto build content on NGINX with content stored in MariaDB. OpenEBS is to be used initially as a way to abstract storage in a cluster and pools it as a resource but, now, will be used to enable the automated mapping of a node to the data and properly normalizing content based on content type and not necessarily include nodename. It just makes things easier!
