_ARM64 cluster in a home-lab setting_

**Stateful Applications that you are running on OpenEBS**
- Wordpress
- MariaDB

**Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV**
- Jiva

**Are you evaluating or already using in development, CI/CD, production**
- In "production"

**Are you using for home use or for your organization**
- For use in home lab, potential organizational use in the future based on technical needs

**A brief description of the use case or details on how OpenEBS is helping your projects.**
- I have a small Raspberry Pi-based Kubernetes cluster (using k3s.io), operating using the official Raspbian 64-bit kernel. My cluster is capable of running arm (32bit) or arm64 containers, and for OpenEBS I'm using the new arm64 images recently published. My home lab setup is small (3 nodes), but they have external storage attached and it's helpful to know that if one node goes down, the pods can safely migrate to another node and be recreated with the same storage.

