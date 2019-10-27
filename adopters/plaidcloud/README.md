### Company: [Plaid Cloud](https://github.com/PlaidCloud)

### Stateful Applications that we are running on OpenEBS

- Redis
- Prometheus
- Elasticsearch
- PostgreSQL
- Some home-grown stuff

### Type of OpenEBS Storage Engines behind the above applications

- **cStor** (for "monitoring" apps like Prometheus and Elasticsearch)
- **Local PV** (for "customer-facing" apps like Redis, PostgreSQL, and our own)

Initially we used cStor for all of our apps (separated into "fast" and "slow" storage pools), but recently moved our performance-sensitive workloads to use Local PVs.

### Are you evaluating or already using in development, CI/CD, production?

We are in the process of migrating our entire application stack to kubernetes, and so our environments are primarily evaluation. However, we are currently running customer workloads internally on our evaluation cluster, so OpenEBS is being used as close to production as it can be.

### Are you using for home use or for your organization?

We intend to use it in hosting https://plaidcloud.com for our organization once we complete our migration.

### A brief description of the use case or details on how OpenEBS is helping your projects.

Initially we used Portworx, but maintaining an external etcd cluster was troublesome for us and the cost of the setup was a bit excessive for an evaluation. So we evaluated OpenEBS as an alternative and it fit our needs well:
- Relatively simple to install and configure (especially with recent versions).
- Supports kubernetes-native operations.
- Fast (Local PVs have had a noticeable improvement on the performance of our applications).
- Very active project, good documentation, excellent support.

Definitely happy with OpenEBS so far.

