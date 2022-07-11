### Company: SurplusCI (https://surplusci.com/)

### Stateful Applications that you are running on OpenEBS
- Postgres
- KubeVirt (qemu)
- Grafana

### Type of OpenEBS Storage Engines behind the above application - cStor, Jiva or Local PV?
Jiva and ZFS LocalPV

### Are you evaluating or already using in development, CI/CD, production
- Evaluation (over the years I don't think there's an offering I haven't evaluated except for NFS provisioner)
- Production (ZFS LocalPV for all my machines)

### Are you using for home use or for your organization
Organization

### A brief description of the use case or details on how OpenEBS is helping your project
SurplusCI uses ZFS LocalPV (where it previously used Ceph) to speed up DinD workloads running on our runners.

The performance degradation of using Rook/Ceph (which is to be expected, it's there with Jiva/cStor and Mayastor to a lesser extent) and lack of a need for absolute high availability/durability on runner instances means that LocalPV gives superior performance, and the ability to even run things like Ceph on top of LocalPV.

The disks connected to my nodes are known to be a little flaky so RAID1 is recommended and normally preinstalled (Hetzner), so I was considering going with one of two setups:

- RAID1 (via mdadm) + openebs/rawfile-localpv (+/- Ceph/Jiva/cStor on top if needed)
    - Problem here is that I'm not protected from faulty drives (via checksumming) unless using Ceph w/ Bluestore
- RAID1 (via mdadm) on some disks + ZFS pool + openebs-zfs-localpv (+/- Mayastor/Ceph/Jiva/cStor/NFS on top if needed)
    - Here I have reliable data at the bottom (mirrored pool & checksumming), access to speedy local disks when I need it (ex. databases), and ability to still use high availability/durability solutions with a slight performance hit using ZVOL block volumes)

Obviously, in both situations OpenEBS is crucial to managing the underlying disks and providing dynamically provisioned PVs!