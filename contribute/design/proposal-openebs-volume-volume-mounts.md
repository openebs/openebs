# Managing Volume Mounts of OpenEBS Volume Containers

## Background

OpenEBS Volumes (storage controller) functionality is delivered through containers (say OVCs). Each OpenEBS Volume can comprise of a single or multiple OVCs depending on the redudancy requirements etc.,. Each of these OVCs will persit data to the attached volume-mounts. The volume-mounts attached to OVCs can range from local directory, a single disk, mirrored (lvm) disk to cloud disks. The volume-mounts also can vary in terms of their performance characteristics like - SAS, SSD or Cache

OVCs are designed to run (in hyper-converged) mode on any Container Orchestrators. Maya - will provide the functionality to abstract the different types of storage (also called hence forth as "Raw Storage") and convert them into a "Storage Backend" that can be associated to the OVCs as Volumes. In case of Kubernetes, the Maya will convert the Storage Backends into Persitent Volumes and associate them with OVC (Pod).
