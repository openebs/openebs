_backup solution for home laptop_

**Stateful Applications that you are running on OpenEBS**
- Minio

**Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV**
- cStor

**A brief description of the use case or details on how OpenEBS is helping your projects.**
- Restic uploads my laptop to Minio running on my home Kubernetes cluster. Minio runs on a 2 replica OpenEBS cStor PV . A `mc mirror` pod then watches the bucket and uploads it's content to the cloud. I get full speed backups on my laptop and still have a cloud copy
