_backup solution for home laptop_

**Stateful Applications that you are running on OpenEBS**
- Minio

**Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV**
- Jiva

**A brief description of the use case or details on how OpenEBS is helping your projects.**
- Restic uploads my laptop to Minio running on my home k8s cluster (powered by openebs). A “mc mirror” pod then uploads it to the cloud. I get full speed backups on my laptop and still have a cloud copy

