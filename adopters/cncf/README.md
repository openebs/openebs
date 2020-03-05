# Company: CNCF, The Linux Foundation

# Stateful Applications that we are running on OpenEBS

CNCF:
- PostgresSQL (including automatic backups)
- NFS server (for allowing multiple r/w access)
- nginx (serving home pages, backups, CSV reports etc)
- Storage for git repositories clones
- All DevStats applications (homegrown)

The Linux Foundation:
- MariaDB database (Helm master + slave replication, automatic backups)
- ElasticSearch cluster (Helm chart master + 4 slave nodes)
- Postgres (including automatic backups)
- Redis
- Grimoire stack (CHAOSS)
- Storage for git repositories clones
- Homegrown tools (SDS - sync data sources, golang orchestrator to fetch Grimoire data)

# Type of OpenEBS Storage Engines behind the above applications

- Local PV - for everything, speed is the main reason. Postgres uses 4-node Patroni stateful deployment (1 master and 3 replication nodes). All runs on bare metal servers from packet.com, stateful DB storage is 4 local PV volumes each about 3.2T size.
- NFS server (with local PV underlying) for allowing multiple clients access.

# Are you evaluating or already using in development, CI/CD, production?

Used in `test` and `production` deployments (they're separated into different namespaces).
Everything runs on Kubernetes + Helm.

# Are you using for home use or for your organization?

Used for my organization (Both CNCF and The Linux Foundation)

# A brief description of the use case or details on how OpenEBS is helping your projects.

Installing Kubernetes, then configuring `/var/openebs` on all nodes, then installing OpenEBS, making `openebs-hostpath` default storage engine, installing NFS for shared access. Finally, everything installed in Kubernetes uses OpenEBS.

OpenEBS basically powers all storage for the following sites:
- https://devstats.cncf.io (and all subprojects) - prod site
- https://teststats.cncf.io (and all subprojects) - test site
- https://devstats.coreinfrastructure.org
- https://devstats.graphql.org
- https://devstats.cd.foundation
- https://devstats.cncf.io/backups (Backups)
- DevStats REST API: https://devstats.cncf.io/api/v1 (described [here](https://github.com/cncf/devstatscode#api))

See:
- https://github.com/cncf/devstats-helm#setup-per-node-local-storage.
- https://github.com/cncf/devstats-helm#architecture (Storage section).

