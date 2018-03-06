# Support for OpenEBS Volume Snapshots and Clones

This is a design proposal for implementing the workflow (orchestration) of creating snapshots and clones from a given OpenEBS Volume. 

## Prerequisites:
- Refer Kubernetes Usecases for Snapshots. 
  https://github.com/kubernetes-incubator/external-storage/blob/master/snapshot/doc/user-guide.md
- Related Issues : #440, #631, #1046, 

## Usecases (Goals)
- User wants to protect the data stored on openebs volumes against application errors. 
  Possible solution:
  * Snapshot the OpenEBS Volumes at specified or regular intervals, by co-ordinating with the application access pattern. 
  * In the event of an error/partial-data-loss, mount the snapshot as a read-only volume and recover the required data.
  * In the event of an error/complete-data-loss, mount the snapshot as a read-only volume, verify the snapshot contains the required data and mount the volume as read-write - this new volume created from snapshot replaces the earlier volume. 

- User wants to share(read-only) the data stored on openebs volume with multiple clients. 
  Possible solution:
  * Once the data that needs to be shared is available on the OpenEBS volume, create a snapshot. 
  * Create a Clone of the volume from the snapshot. And provide ReadOnlyMany access to the cloned volume. 

- User is running a Database on the OpenEBS Volume. User wants to try out some schema upgrades to the Database which will determine if the new changes need to be applied or the database needs to be restored back to its original state. 
  Possible solution:
  * Create a snapshot of the OpenEBS Volume associated with the database
  * Create a Clone of the volume from the snapshot and Run the database onthe cloned volume.
  * Apply the schema changes on the new database and validate the changes.
  * Commit the validated schema changes and the upgrade sql (data migration) scripts on the original database
  * Deleted the cloned volume and the snapshot that was used to run the tests.

## Usecases (Non-Goals)
- Uses wishes to setup a process to protect the data stored on openebs volumes against system (kubernetes nodes or openebs storage) failures.
  Possible solution:
  * Snapshot the OpenEBS Volumes at regular intervals like daily or weekly. Transfer the data from the snapshot to a remote location - external from the current system (kubernetes nodes and storage). The remote locations could be an S3 store or another OpenEBS Volume in a different location.
  * In the event of an system failure, restore the data from the backup location - s3 or remote openebs volume.


## Desgin

The usecases related to protecting data against application failures and recovering data from local snapshots can be achieved if the following primitives(API) are supported by the OpenEBS Volumes:
- Create Snapshot
- Delete Snapshot
- List Snapshot
- Mount Snapshot - same as Clone Volume with ReadOnly Option
- Unmount Snapshot - same as Delete Clone Volume.
- Clone Volume
- Delete Clone Volume
- Revert Volume State to a previous Snapshot

Along wih the OpenEBS Volume Dynamic Provisioner, OpenEBS Snapshot Provisioner will be launched during the openebs install. The Snapshot Provisioner is an extension/plugin of https://github.com/kubernetes-incubator/external-storage/tree/master/snapshot

### Create Snapshot
* Admin uses the kubectl volume snapshot yaml to create a snapshot on a given PV/PVC. 
* Kubernets will forward the snapshot create request to the OpenEBS Snapshot provisioner, while will do the following:
  - Identify the cStorService or the JivaService associated with the PV
  - If Jiva, call the REST API of Jiva Controller to create a new snapshot
  - If cStor, call the REST API of cStorVolumeMgmt(side-car?) to create a new snapshot
* OpenEBS Snapshot provisioner will return the status back to Kubernetes
* Kubernetes will store the snapshot against the PV. The list of created snapshots can be obtained using kubectl get snapshots.

### Delete Snapshot
* Admin uses the kubectl volume snapshot yaml to create a snapshot on a given PV/PVC. 
* Kubernetes will delete snapshot from its configuration. Also pass the request to the OpenEBS Snapshot provisioner for cleanup. 
* OpenEBS Snapshot provisioner will check if the volume associated is of type cStor and will forward the delete snapshot request to cStorVolumeMgmt(side-car?)


### List Snapshot
* No code changes required, the kubectl takes care of listing the created snapshots from its configuration.

### Mount Snapshot as Read-only or Read-Write
* Admin specifies the snapshot that needs to be mounted as read-only or read-write.
* Kubernetes will forward the request to the OpenEBS Snapshot Provisioner
* OpenEBS Snapshot Provisioner will check the volume type:
  - If Jiva
    * create a new jivaService, jivaController and jivaReplica. For the controller, pass the original volume and snapshot details
    * create a PV using the new jivaService created above. Set the read-write or read-only based on the snapshot yaml passed by admin
  - If cStor
    * create a new cStorSerivce and cStorController
    * create new cStorReplicasi(CRD) on the cStorPools where the original volume resides. cStorReplica will specify that zVol should be created from a snapshot of original zvol.
    * create a PV using the new cStorService created above. Set the read-write or read-only based on the snapshot yaml passed by admin

### Delete Clone Volume
* Admin specifies the PV (snapshot) that needs to be deleted. 
* Kubernetes will forward the request to the OpenEBS Snapshot Provisioner
* OpenEBS Snapshot Provisioner will check the volume type:
  - If Jiva - delete the jivaService, jivaController and jivaReplica
  - If cStor:
    * delete cStorService and cStoreController and associated configmap. 
    * delete the cStorReplica (CRD)
    * cstor-pool-mgmt side care will delete the cloned zvol. 

### Revert the state of OpenEBS Volume to a previous snapshot
* Admin will use mayactl to list the snapshot on the given volume
* Admin will select the snapshot to revert to. 
* mayactl will do the following:
  - issue commands to delete the snapshot via kubectl, that were taken after the selected snapshot (updating the k8s db)
  - issues REST API to either jivaController or cStorController(volume-mgmt sidecar?) to revert the state to selected snapshot

