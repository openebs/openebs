# Managing cStor based OpenEBS Volumes. 

## Background 


## Design

Provisioning of cStor based Volume involve two steps. 

1. Creating cStor StoragePools:

- Admin will create SPC that contains information like:
  - type=block
  - disks list (type of PDC or specific disks)
  - nodes list (optional)

- maya-cstor-operator (embedded into maya-apiserver), will be watching for SPCs (type=block). If nodes were not specified in the PVC, the maya-cstor-operator will query the kube-ectd for the availability of the disks and determine the nodes. 

- maya-cstor-operator will create a cStorPoolConfig object -  (with information required to initialize the zpool) 

- maya-cstor-operator will create a Deployment YAML file  that contains the cStor container, the associated sidecars.  The cStor-Sidecar is passed the “id” of the cStorPoolConfig object 

- once the cStor pool (container) is started, maya-cstor-operator will create the SP object. 


2. Creating Volume using the (cStor) Storage Pools:

- maya-apiserver will identify the storagepools to use based on the pool information specified in the PVC/StorageClass

- maya-apiserver will create the OV Controller and the service (to get the portal ip address)

- when the pool type is cStor, maya-apiserver will create - cStorVolume CRD. This cStorVolume CRD will be associated with the corresponding cStorPool, required capacity, etc., and also information required to connect to the OV Controller (target)

-  The cstor-sidecar running in the cStor Pool, will act on the cStorVolume CRD for creating the zVol.


