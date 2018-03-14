# Support for OpenEBS Volume Snapshots and Clones

This is a design proposal for implementing the workflow (orchestration) of creating snapshots and clones for a given OpenEBS Volume. 

## Prerequisites:
- Refer [Kubernetes Use-cases for Snapshots](https://github.com/kubernetes-incubator/external-storage/blob/master/snapshot/doc/user-guide.md)
- Refer [Kubernetes Cron Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- Related Issues : #440, #631, #1046, 

## Use-cases (Goals)
- User wants to protect the data stored on openebs volumes against application errors. 
  Possible solution:
  * Snapshot the OpenEBS Volumes at specified or regular intervals, by coordinating with the application access pattern. 
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

## Use-cases (Non-Goals)
- User wishes to setup a process to protect the data stored on openebs volumes against system (Kubernetes nodes or openebs storage) failures.
  Possible solution:
  * Snapshot the OpenEBS Volumes at regular intervals like daily or weekly. Transfer the data from the snapshot to a remote location - external from the current system (Kubernetes nodes and storage). The remote locations could be an S3 store or another OpenEBS Volume in a different location.
  * In the event of an system failure, restore the data from the backup location - s3 or remote openebs volume.

Note:
- User could setup scheduled snapshots for a given volume as follows:
  * The functionality of create/delete snapshot could be provided in a container (say snap-manager).
  * The snap-manager can take as parameters - PV/PVC, Snapshot Name pattern, Retention copies, etc.
  * The snap-manager will use Kubernetes api for creating the snapshot and deleting the older snapshot
  * A Kubernetes CronJob with desired schedule can be setup with the above container(snap-manager). 

## High Level Design

The use-cases related to protecting data against application failures and recovering data from local snapshots can be achieved if the following primitives(API) are supported by the OpenEBS Volumes:
- Create Snapshot
- Delete Snapshot
- List Snapshot
- Mount Snapshot - same as Clone Volume with ReadOnly Option
- Unmount Snapshot - same as Delete Clone Volume.
- Clone Volume
- Delete Clone Volume
- Revert Volume State to a previous Snapshot

When installing openebs, OpenEBS Snapshot Provisioner will be launched. The OpenEBS Snapshot Provisioner is an extension/plugin of https://github.com/kubernetes-incubator/external-storage/tree/master/snapshot

cstor-volume-mgmt side-car running along side cStorController will expose API for snapshots and clones that will be used by the OpenEBS Snapshot Provisioner. 

### Workflow for Create Snapshot
* Admin uses the kubectl volume snapshot yaml to create a snapshot on a given PV/PVC. 
  ```
  apiVersion: volumesnapshot.external-storage.k8s.io/v1
  kind: VolumeSnapshot
  metadata:
    name: snap1
  spec:
    persistentVolumeClaimName: demo-vol1-claim
  ```

* Kubernetes will generate an unique id to this snapshot request and attach to the above VolumeSnapshot object, along with a few other house keeping parameters.
  ```
  apiVersion: volumesnapshot.external-storage.k8s.io/v1
  kind: VolumeSnapshot
  metadata:
    name: snap1
  spec:
    persistentVolumeClaimName: demo-vol1-claim
    snapshotDataName: k8s-volume-snapshot-680b2b68-e279-44c6-8dee-df7201a6e0f9
  ```

* Kubernetes will forward the snapshot create request to the OpenEBS Snapshot provisioner. (TODO - Prateek, fill in the specific details here)

* OpenEBS Snapshot provisioner will pass the unique id and the snapshot name to the openebs volume controller (jiva or cstor), depending on the type of the volume. For cstor, the API endpoint is served by the gRPC running in the cstor-volume-mgmt sidecar of the cStorController, while Jiva runs an HTTP endpoint. Let us call this as `CreateSnapshot` API.
  The CreateSnapshot API is provided with
  - snapshot name (snap1)
  - snapshot unique id (680b2b68-e279-44c6-8dee-df7201a6e0f9) 
  - volume id (ee171da3-07d5-11e8-a5be-42010a8001be) 

  How to use the above Ids are used is up to the API implementation. For instance, the snapshot could be created either with name or unique id. The volume id can be used to identify the volume, if multiple volumes are served by the same controller.

  Also, the implementation details of how the Create Snapshots is implemented within the controller, by quiescing the IOs is not in the scope of this workflow. However the following flow has been suggested:
  - The controller will pause the IO, issue the snapshot request to all its replicas and wait for a max of 2 seconds(?) for the snapshot to be taken on all the replicas. After every 1000ms, it will check to resume IOs, if all the replica responded for the snapshot request. 
  - Each of the replica will flush its data and take a snapshot and respond status to the controller. 
  - The controller will respond back with failure(timeout/error) or success

  Depending on the status from API server, the VolumeSnapshot details are updated.

  In case of success, the details are:
  ```
  apiVersion: volumesnapshot.external-storage.k8s.io/v1
  kind: VolumeSnapshot
  metadata:
    creationTimestamp: 2018-03-14T01:02:03Z
    labels:
      #Fill the PV name associated with the above demo-vol1-claim
      SnapshotMetadata-PVName: pvc-ee171da3-07d5-11e8-a5be-42010a8001be
      #Timestamp returned from the Snapshot API when the snapshot was actually taken. 
      SnapshotMetadata-Timestamp: "1520989324069268076"
    name: snap1
  spec:
    persistentVolumeClaimName: demo-vol1-claim
    snapshotDataName: k8s-volume-snapshot-680b2b68-e279-44c6-8dee-df7201a6e0f9
  status:
    conditions:
    - lastTransitionTime: 2018-03-14T01:02:04Z
      message: Snapshot created successfully
      reason: ""
      status: "True"
      type: Ready
  ``` 

* OpenEBS Snapshot provisioner will return the status back to Kubernetes

* Kubernetes will store the snapshot against the PV. The list of created snapshots can be obtained using `kubectl get volumesnapshots`.

### Workflow for Delete Snapshot
* Admin uses the kubectl to delete a previously created snapshot.
  `kubectl delete volumesnapshot/snap1`

* Kubernetes passes the request to the OpenEBS Snapshot Provisioner.

* OpenEBS Snapshot provisioner will pass the unique id and the snapshot name to the DeleteSnapshot API on openebs volume controller (jiva or cstor), depending on the type of the volume. The API implementation in the controller will take care of clearing the snapshot information by enforcing checks like - there are no cloned volumes created out of the snapshot etc., Depending on the response from the API server, the status of failure/success will be returned to Kubernetes. 

* On success, Kubernetes will delete snapshot from its configuration.


### List Snapshot
* No code changes required, the `kubectl get volumesnapshots` can be used to query for available snapshots. To get snapshots on a specific volume, use `kubectl get volumesnapshots -l SnapshotMetadata-PVName=pvc-ee171da3-07d5-11e8-a5be-42010a8001be `

### Workflow for Mount Snapshot as Read-only or Read-Write

To mount a snapshot, a new volume is created from the snapshot, as per the design outlined in [Kubernetes Snapshot Design Proposal](://github.com/kubernetes-incubator/external-storage/blob/master/snapshot/doc/volume-snapshotting-proposal.md). In order to support creation of the volumes, jiva controller and replica API are being enhanced to:

* Admin creates a new StorageClass for creating Volumes using a Snapshot or what is called promoting a snapshot into a PV. 
  ```
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: snapshot-promoter
  provisioner: volumesnapshot.external-storage.k8s.io/snapshot-promoter
  ```

* Admin creates a PVC that specifies the snapshot from which the new Volume needs to be created. The PVC also contains the access mode. 
  ```
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: snapshot-vol-claim
    annotations:
      snapshot.alpha.kubernetes.io/snapshot: snap1
  spec:
    accessModes:
      - ReadWriteOnce
    storageClassName: snapshot-promoter
  ```

* Kubernetes will forward the request to the OpenEBS Snapshot Provisioner

* OpenEBS Snapshot Provisioner will pull in the source volume details and will invoke the maya-apiserver clone volume API with following details: 
  - source volume name (pvc-ee171da3-07d5-11e8-a5be-42010a8001be)
  - source snapshot (snap1)
  - clone volume name (pvc-54ad20e4-0082-46da-8bc7-ead47c9019e7)

  The maya-apiserver clone volume will initiate a new volume creation (which involves creating Kubernetes YAMLs and CRs) by using the same volume policies that were used to create the source volume. Only minor modifications will be done to the Kubernetes YAMLs and CRs depending on the volume type.
  - If volume type is Jiva, the only change will be in the Jiva Controller Deployment YAML, to include the following additional command-line arguments:
    ```
      --sourceIP
      <source-controller-cluster-ip-address>
      --sourceSnap
      <source-snap-name>
    ```
    It is outside the scope of this document to describe how the Jiva Controller will clone the data from the source volume replicas to its replicas, but it suffices to say that using the cloned volume, the maya-apiserver can query for the status.

  - If volume type is cStor, the change is in the way the CStorVolumeReplica CRs are created. The maya-apiserver will have to fetch the pools on which the source volume replicas are present, and create the CStorVolumeReplica on the same pools. In addition, the CStorVolumeReplica will contain the name of the source volume and the source snap. The YAML will look as follows:
   ```
   apiVersion: openebs.io/v1alpha1
   kind: CStorVolumeReplica
   metadata:
     name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-rep-9440ab
     poolguid: 7b99e406-1260-11e8-aa43-00505684eb2e
   spec:
     source-vol-name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be
     source-snap-name: snap1
     capacity: 5G
     cstor-controller-ip: <ip-address>
     vol-name: pvc-54ad20e4-0082-46da-8bc7-ead47c9019e7
     capacity: 5G
   ```
   cstor-pool-mgmt side-car while processing the CStorVolumeReplica, will check of the source-vol-name and instead of creating a new zvol, it will create a clone of the source-volume@source-snap. Once the clone (zvol) is created, it will proceed with registering them with controller. 

* OpenEBS Provisioner will query for the status of the clone volume and when it goes to running state, it will create a PV for the cloned OpenEBS Volume (pvc-54ad20e4-0082-46da-8bc7-ead47c9019e7). The access mode will be set as read-write or read-only based on the snapshot yaml passed by admin

* Kubernetes will then bind this cloned volume with the snapshot-pv claim.


### Workflow for Delete Clone Volume
The flow for deleting a cloned volume is similar to deleting a regular volume. 

* Admin specifies the cloned PV/PVC that needs to be deleted. 

* Kubernetes will forward the request to the OpenEBS Snapshot Provisioner

* OpenEBS Snapshot Provisioner will invoke the Delete Volume API on the maya-apiserver. maya-apiserver will check for the type of the volumes and will clean up the respective objects.

### Revert the state of OpenEBS Volume to a previous snapshot
This option is a disruptive operation.
* Admin will have stopped the workload (if possible) that is using the volume.
* Admin will use mayactl to list the snapshot on the given volume
* Admin will select the snapshot to revert to. 
* mayactl will do the following:
  - issue commands to delete the snapshot via kubectl, that were taken after the selected snapshot (updating the k8s db)
  - invoke the cstor-volume-mgmt SnapshotRollback API by passing the snapshot name to which Admin wants to revert.
* Admin will start (or restart) the workload.



## Feature Implementation Plan

### Phase 1
- Setup/Install of openebs snapshot provisioner 
- Embed a gRPC based API server into the cstor-volume-mgmt sidecar. 
- Implement the gRPC client in maya-apiserver to interact with cstor-volume-mgmt
- Support for CreateSnapshot API in cstor-volume-mgmt gRPC
- Support for DeleteSnapshot API in cstor-volume-mgmt gRPC
- Support for ListSnapshot API in cstor-volume-mgmt gRPC
- Support for CreateSnapshot API in maya-apiserver
- Support for DeleteSnapshot API in maya-apiserver
- Support for snapshot commands (create/delete/list) through mayactl for cstor volumes

### Phase 2
- Support for creating a clone from a snapshot by cstor-pool-mgmt, triggered by CStorVolumeReplica CR
- Support for Clone API in maya-apiserver
- Test Delete Clone Volume using Volume Delete API
- Support for clone commands through mayactl for cstor volumes

### Phase 2
- Support for SnapshotRollBack API in cstor-volume-mgmt gRPC
- Support for snapshot rollback via mayactl

### Future

