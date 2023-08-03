### **Company**: Reformational Study Centre ([refstudycentre.com](https://www.refstudycentre.com/))

### Stateful Applications that you are running on OpenEBS
- Drupal
- Grafana
- Moodle
- MariaDB
- Apache Solr
- Verdaccio (Private NPM registry)

Probably more that I'm forgetting now. All our stateful stuff is on ZFS datasets provisioned by OpenEBS :)

### Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV?
Local ZFS PVs

### Are you evaluating or already using in development, CI/CD, production
Production and development.

### Are you using for home use or for your organization
Organization: Reformational Study Centre -- ([www.refstudycentre.com](https://www.refstudycentre.com/))

### A brief description of the use case or details on how OpenEBS is helping your projects
- This is a super easy way of creating isolated file systems of any size.
- Instant snapshots are amazing for backups and development (i.e. cloning a large production site instantly and working on that). This requires some fancy custom scripting with kubectl, but it would have been slow or impossible without openebs/zfs-localpv.