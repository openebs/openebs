# Support for OpenEBS Volume Snapshots and Clones

This is a design proposal for implementing the workflow (orchestration) of creating snapshots and clones for a given OpenEBS Volume. 

## Prerequisites:
- Refer [Kubernetes Usecases for Snapshots](https://github.com/kubernetes-incubator/external-storage/blob/master/snapshot/doc/user-guide.md)
- Refer [Kubernetes Cron Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
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
  * Create a Clone of the volume from the snapshot and Run the database on the cloned volume.
  * Apply the schema changes on the new database and validate the changes.
  * Commit the validated schema changes and the upgrade sql (data migration) scripts on to the original database
  * Delete the cloned volume and the snapshot that was used to run the tests.

## Usecases (Non-Goals)
- User wishes to setup a process to protect the data stored on openebs volumes against system (kubernetes nodes or openebs storage) failures.
  Possible solution:
  * Snapshot the OpenEBS Volumes at regular intervals like daily or weekly. Transfer the data from the snapshot to a remote location - external from the current system (kubernetes nodes and storage). The remote locations could be an S3 store or another OpenEBS Volume in a different location.
  * In the event of an system failure, restore the data from the backup location - s3 or remote openebs volume.

Note:
- User could setup scheduled snasphots for a given volume as follows:
  * The functionality of create/delete snapshot could be provided in a container (say snap-manager).
  * The snap-manager can take as parameters - PV/PVC, Snapshot Name pattern, Retention copies, etc.
  * The snap-manager will use kubernetes api for creating the snapshot and deleting the older snapshot
  * A Kubernetes CronJob with desired schedule can be setup with the above container(snap-manager). 

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

When installing openebs, OpenEBS Snapshot Provisioner will be launched. The OpenEBS Snapshot Provisioner is an extension/plugin of https://github.com/kubernetes-incubator/external-storage/tree/master/snapshot

### Create Snapshot
* Admin uses the kubectl volume snapshot yaml to create a snapshot on a given PV/PVC. 
* Kubernetes will forward the snapshot create request to the OpenEBS Snapshot provisioner, which will do the following:
  - Identify the cStorService or the JivaService associated with the PV
  - If Jiva, call the REST API of Jiva Controller to create a new snapshot
  - If cStor: 
    * cstor-volume-mgmt side-car will be provisioned for cStorController. This will listen for cStorVolumeSnapshot CR events
    * cStorVolumeSnasphot will contain details like:
      - Volume Identifier
      - Snapshot Name
      - Status Fields for Controller and Replicas will be initialized with "init". Only the Replicas that are online will be included.
      (TODO: Vitta/Jeffry - If one of the Replica was offline during the snapshot creation, will it be created during rebuild process?)
    * cstor-volume-mgmt Add Event handler will pause the IOs and update the contoller state to pause. The controller will wait for a max of 2 seconds(?) for the snapshot to be taken on all the replicas. After every 1000ms, this side-car will check to resume IOs, if all the replica status are updated. 
    * cstor-pool-mgmt side-car will wait for the controller to set its status to pause and they will create Snapshot on the corresponding volume. After taking the snapshot, the status field will be updated. 
    * OpenEBS Snapshot Provisioner will check on the status of the cStorVolumeSnapshot CR and marks the success/failure.
* OpenEBS Snapshot provisioner will return the status back to Kubernetes
* Kubernetes will store the snapshot against the PV. The list of created snapshots can be obtained using kubectl get snapshots.

### Delete Snapshot
* Admin uses the kubectl volume snapshot yaml to create a snapshot on a given PV/PVC. 
* Kubernetes will delete snapshot from its configuration. Also pass the request to the OpenEBS Snapshot provisioner for cleanup. 
* If the volume type is cStor:
  * OpenEBS Snapshot provisioner will update the status on cStorVolumeSnapshot CR to Delete
  * cstor-pool-mgmt side-car will delete the snapshot on the volume. The cStorVolumeSansphot will be purged only after all the replica's have updated their state to Delete. 


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
    * create a new cStorSerivce and cStorController and corresponding cStorVolume CR
    * create new cStorReplica CRs on the cStorPools where the original volume resides. cStorReplica will specify that zVol should be created from a snapshot of original zvol.
    * create a PV using the new cStorService created above. Set the read-write or read-only based on the snapshot yaml passed by admin

### Delete Clone Volume
* Admin specifies the PV (snapshot) that needs to be deleted. 
* Kubernetes will forward the request to the OpenEBS Snapshot Provisioner
* OpenEBS Snapshot Provisioner will check the volume type:
  - If Jiva - delete the jivaService, jivaController and jivaReplica
  - If cStor:
    * delete cStorService and cStoreController and associated cStorVolume CR. 
    * delete the cStorReplica CR
    * cstor-pool-mgmt side car will delete the cloned zvol. 

### Revert the state of OpenEBS Volume to a previous snapshot
This option is a distruptive operation.
* Admin will have stopped the workload (if possible) that is using the volume.
* Admin will use mayactl to list the snapshot on the given volume
* Admin will select the snapshot to revert to. 
* mayactl will do the following:
  - issue commands to delete the snapshot via kubectl, that were taken after the selected snapshot (updating the k8s db)
  - update the cStorVolumeSnapshot CR to "revert". 
    * cstor-volume-mgmt will stop the target and update the status to "stopped"
    * cstor-pool-mgmt will rollback the zvol to the snapshot for the corresponding volumes. 
    * cstor-volume-mgmt will start the target (TODO - Confirm with Jeffry/Vitta)
* Admin will start (or restart) the workload.

