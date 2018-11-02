# Proposal for OpenEBS Volume (jiva) Snapshots using extended kubernetes Snapshot APIs

## Background

Kubernetes is being enhanced to support Snapshots using native API. This is being done in
phases:
* Phase 1: The API is supported via Snapshot Operators using CRDs as addon
functionality. For more details refer to the design and examples at:
kubernetes-incubator/external-storage/snapshots​.
* Phase 2: The API will be added directly into the Kubernetes API - by 1.11/1.
* Phase 3: CSI will include the Snapshot API
This document describes the support of Snapshot API for OpenEBS volumes using the Phase 1
implementation using the Snapshot Operators.

## Kubernetes Snapshot Workflow

At a very high level the feature works as follows:
* Cluster Administrator will have to launch the Snapshot Operators

     i. snapshot-controller: responsible for managing snapshots.

     ii. snapshot-pv-provisioner: responsible for dynamically creating a clone from snapshots.

* Both users and admins might create/delete snapshots, using Snapshot CRs that refer to
the PVC.

    i. Create:
   * The user creates a ​VolumeSnapshot​ referencing a persistent volume
     claim bound to a persistent volume
   * The snapshot-controller fulfils the ​VolumeSnapshot​ by creating a
     snapshot using the volume plugins.
   * A new object ​VolumeSnapshotData​ is created to represent the actual
    snapshot binding the ​VolumeSnapshot​ with the on-disk snapshot.

    ii. List:

   * The user is able to list all the ​VolumeSnapshot​ objects in the
     namespace

   iii. Delete:
   * The user deletes the ​VolumeSnapshot
   * The controller removes the on-disk snapshot. Note: snapshots have no
     notion of "reclaim policy" - there is no way to recover the deleted snapshot.
   * The controller removes the ​VolumeSnapshotData​ object.
  
* After snapshots are taken, users might use them to create new volumes using the snapshot, that was previously taken.

    i. Promote snapshot to PV (or Clone PV using a snapshot):

   * The user creates a persistent volume claim referencing the snapshot
object in the annotation. The PVC must belong to a ​StorageClass​ using
the external volume snapshot provisioner. Note: the special annotation
might get replaced by a dedicated attribute of the
PersistentVolumeClaim​ in the future.
   * The snapshot-pv-provisioner will use the ​VolumeSnapshotData​ object
to create a persistent volume using the corresponding volume snapshot
plugin.

   * The PVC is bound to the newly created PV containing the data from the
  snapshot.

* The snapshot operation is a no-op for volume plugins that do not support snapshots via
an API call (i.e. non-cloud storage).

* The snapshot objects are namespaced:

    i. Users should only get access to the snapshots belonging to their namespaces.
For this aspect, snapshot objects should be in user namespace. Admins might
want to choose to expose the snapshots they created to some users who have
access to those volumes.

    ii. There are use cases that data from snapshots taken from one namespace need
to be accessible by users in another namespace.
    
    iii. For security purpose, if a snapshot object is created by a user, kubernetes should
prevent other users duplicating this object in a different namespace if they
happen to use the same snapshot name.
    
    iv. There might be some existing snapshots taken by admins/users and they want to
use those snapshots through kubernetes API interface.


#### Snapshot Operators Internals

The volume snapshot controller maintains two data structures (ActualStateOfWorld and
DesiredStateOfWorld) and periodically reconciles the two. The data structures are being update
by the API server event handlers.

 * If a new ​VolumeSnapshot is added, the ​ add ​ handler adds it to the DesiredStateOfWorld (DSW)
 * If a ​VolumeSnapshot is deleted, the ​ delete ​ handler removes it from the DSW.

* Reconciliation loop in the controller
  * For every ​VolumeSnapshot​ in the ActualStateOfWorld (ASW) find the
corresponding ​VolumeSnapshot​ in the DSW. If such a snapshot does not exist,
start a snapshot deletion operation:
   * Determine the correct volume snapshot plugin to use from the
VolumeSnapshotData​ referenced by the ​VolumeSnapshot
   * Create a delete operation: only one such operation is allowed to exist for
the given ​VolumeSnapshot​ and​VolumeSnapshotData​ pair
   * The operation is an asynchronous function using the volume plugin to
delete the actual snapshot in the back-end.
   * When the plugin finishes deleting the snapshot, delete the
VolumeSnapshotData​ referencing it and remove the​VolumeSnapshot
reference from the ASW
* For every ​VolumeSnapshot​ in the DSW find the corresponding
VolumeSnapshot​ in the ASW. If such a snapshot does not exist, start a
snapshot creation operation:
  * Determine the correct volume snapshot plugin to use from the
VolumeSnapshotData​ referenced by the​VolumeSnapshot
  * Create a volume snapshot creation operation: only one such operation is
allowed to exist for the given ​VolumeSnapshot​ and
VolumeSnapshotData​ pair.
  * The operation is an asynchronous function using the volume plugin to
create the actual snapshot in the back-end.
  * When the plugin finishes creating the snapshot a new
VolumeSnapshotData​ is created holding a reference to the actual
volume snapshot.
* For every snapshot present in the ASW and DSW find its
VolumeSnapshotData​ and verify the bi-directional binding is correct: if not,
update the ​VolumeSnapshotData​ reference.

The following diagram describes the different components involved in supporting Snapshots. We
can see how a VolumeSnapshot ​ binds to a ​ VolumeSnapshotData resource. This is
analogous to PersistentVolumeClaims ​ and​ PersistentVolumes. We can also see that
VolumeSnapshotData references the actual snapshot taken by the volume provider, in the
same way to how a ​ PersistentVolume references the physical volume backing it.









### Use Case

The Kubernetes design proposal for Snapshot provides a valid use case on how Snapshots and
Clone (Promoting a Snapshot to PV) can be used for ​restoring data for a MySQL database​ (Ref:
https://github.com/openebs/litmus/issues/53).

In addition, we would also like to use this feature for CI/CD pipeline as follows:

## Reduce the turnaround time for testing apps with production like data

(Ref: https://github.com/openebs/litmus/issues/51)

Felix is a DevOps admin who is responsible for maintaining Staging Databases for a large
enterprise corporation with 400+ developers working on 200+ applications. The Staging database
contains a pruned (for user information) and is constantly updated with production data. When
developers make some data schema changes, they would like to test them out on the Staging
setup with real data before pushing the changes for Review.

* The staging database PV, PVC and the associated application are created in a separate
namespace called “staging”. Only Felix has access to this namespace. He creates
snapshots of the production database volume. Along with creating the snapshots, he
appends some information into the snapshots that will be helpful for developers like the:
like the version of the applications that are running in the staging database when this
snapshot was taken.
* Each developer has their own namespace. For example Simon, runs his development
application in “dev-simon-app” namespace.
* The cluster admin authorize Simon to access (read/get) the snapshots from the staging
setup.
* Simon gets the list of snapshots that are available. Picks up the snapshot or snapshots
that are best suited for testing his application.
* Simon creates a PVC / PV with the select snapshot and launches his applications with
modified changes on it.
* Simon then runs the integration tests on his application which is now accessing
production like data - which helps him to identify issues with different types of data and
running at scale.
* After completing the tests, Simon deletes the application and the associated cloned
volumes.

#### Make it easy to debug the build (CI) failures with stateful apps

(Ref: https://github.com/openebs/litmus/issues/52)

Tim is a DevOps engineer at a large Retail store who is responsible for running a complex build
pipeline that involves several mico-services. The microservices that implement a order and supply
management functionalities - store the states in a set of common datastores. The Jenkins CI
pipeline simulates real world interactions with the system that begin with simulating customers
placing the orders to the backend systems optimizing the supply and delivery of these orders to the
customers. Tim has setup the Job execution pipeline in such a way that, if there are failures, the
developers can back trace the state of the database and the logs associated with each stage.

* The build (or job) logs are saved onto OpenEBS PV, say Logs PV
* The datastores are created on OpenEBS Volumes, say Datastore PVs.
* At the end of each job, either on success of failure, snapshots are taken of the Logs PV
and the Datastore PVs.
* When there is a build failure, the volume snapshot information is sent to all the
developers whose service were running when the job was getting executed.
* Each developer can bring up their own debug session in their namespace by creating a
environment with cloned volumes. Either they re-run the tests manually by going back to
the previous state with higher debug level or analyze the currently available data that is
causing the issue.

#### Big Data - Share the downloaded dataset among multiple people/projects.

(Ref : https://github.com/openebs/openebs/issues/440)

In Data Science Projects, it is common to have a Data Retriever pod that downloads data from
externals sources. Once the data is made available, snapshot will be created on this data volume.
Other projects/people can clone from this snapshot and access the data either in read-only or
read-write.


### Goals

* User should be able to perform all snapshot operations on the OpenEBS volumes using
the API exposed from Kubernetes
* User should be able to perform snapshot operations on all types of OpenEBS volumes
that support snapshots like Jiva, cstor.

### Non-goals

* Consistency Group: This will be supported by higher level operators or meta-controllers
that will send snapshot request for multiple volumes at the same time.
* Scheduled Snapshots. This will be supported by higher level operators or
meta-controllers that will make use the native API supported in this design
* Offline Backup/Restore. This design doesn’t include pushing the snapshot to backup -
outside of the volume for later restore.
* Syncing the snapshots with the actual state on the Storage. For example, the K8s can
have a snapshot data, which was removed from the storage system either manually
using a different CLI or due to an irrecoverable disk failure. Some kind of a scheduled job
can be run to make sure that the snapshot states are still valid w.r.t to the state on the
storage backend.

### Assumptions/Limitations

* Only OpenEBS volumes are used in the Kubernetes Cluster. This is a limitation of the
snapshot provisioner that only accepts a generic provisioner key:
volumesnapshot.external-storage.k8s.io/snapshot-promoter​. This is being
addressed in the upcoming CSI based snapshot interface.
* Snapshots taken at the storage side don’t guarantee consistency from the
application side. For generating application consistent snapshots, it is
recommended to pause the application before taking the snapshots.
* For jiva based OpenEBS Volumes:
  * creating a clone from snapshot can take longer depending on the data size. The
kubectl describe pvc can show a lot of failed attempts to connect to the cloned
volume. The recommended approach in this case will be to create a PVC first
and then latter associated once it is ready to a Pod/Deployment.
  * Delete snapshot will not delete the actual snapshot on the jiva backend. This
could lead to issues if the user is trying to create-delete-create snapshot with the
same name. ​ To avoid this issue - the snapname provided by user will be suffixed
by a unique GUID before creating the snap on the backend.
  * Since snapshot are not deleted, large number of volumes can run into out of
space issue.
  * In case initial sync failures due to either the clone volume (replica) restarts - the
sync will be resumed from the beginning. Say 2TB volume 1.8TB was synced before the clone 
volume restarted. After restart, the clone volume will reset its
sync status.

* CSI Spec has been recently updated to include the snapshot related operations. ​PR

#224​. The code from the snapshot controller / provisioner will have to be shifted into the
the OpenEBS CSI drivers.
* The cloned volumes share the same properties of the source volume, unless the PVC
overrides them.
* This feature will work only after the maya-apiserver is upgraded to 0.6 version that
includes the API changes. While creating snapshots will work for volumes with older
version (0.5.x jiva), the clone operation will only work for volumes in 0.6 version or
higher.
* The snapshot directly taken on the volumes using mayactl (without kubectl) will not be
available for taking cloning operations.
(https://github.com/openebs/openebs/issues/1416)

### High Level Overview

#### Components

The following diagram depicts the different components involved in snapshot management. The
interactions to the snapshots is via the ​ kubectl. The user pushes the intent for creating or deleting
or promoting a snapshot to PV with YAMLs. These intent YAMLs are loaded into the Kubernetes
etcd, by kube-apiserver. The openebs-snap-controller watches for these YAMLs are proceeds with
performing the snapshot or clone operations.

![Snapshot Design][Snapshot Design]


The new and modified components are as follows:

* [New] openebs-snap-controller , extends the Kubernetes Snapshot provisioner and
controller:

  * snapshot-controller :​ is responsible for creating and watching for the CRDs-
VolumeSnapshot and VolumeSnapshotData. It watches for the creation of the
VolumeSnapshot CR and invokes the maya-apiserver API to manage snapshot.

  * snapshot-provisioner: ​is responsible for watching for a PVC request for creating a
PV from a snapshot and invokes the maya-apiserver API to create new persistent volume via dynamic provisioning or delete a PV created from snapshot.

* [Modified] maya-apiserver API is extended to support:
  * Snapshot - Create, List, Delete API
  * Volume Create is extended to take additional parameters like “Source Volume”
and “Source Snapshot” to allow for creating a cloned volume from a snapshot.

* [Modified] jiva-controller and replica API is enhanced to create a volume from
“Source Volume” and “Source Snapshot”. The jiva volume will create a replica that will
sync the data from the source volume and revert to the specified snapshot.


#### Installation and Setup

* Administrator will install the openebs-snapshot-controller using the helm charts or via the
openebs-operator.yaml.

  Below is deployment spec for creating above mentioned ​ openebs-snapshot-controller.

```yaml
---
kind: Deployment
apiVersion: apps/v1beta
metadata:
name: openebs-snapshot-controller
namespace: ​default
spec:
replicas: 1
strategy:
type: Recreate
template:
metadata:
labels:
app: openebs-snapshot-controller
spec:
serviceAccountName: ​snapshot-controller-runner
containers:
- name: snapshot-controller
image: openebs/snapshot-controller:0.
imagePullPolicy: Always
- name: snapshot-provisioner
image: openebs/snapshot-provisioner:0.
imagePullPolicy: Always
```

* The namespace and serviceAccountName will be as per the helm chart installation or
depending on the openebs-operator.yaml. When running the
openebs-snapshot-controller independently, the following ServiceAccount can be
created to grant the required permissions for creating and watching the CRDs.

```yaml
---
apiVersion: v
kind: ServiceAccount
metadata:
name: snapshot-controller-runner
namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1beta
kind: ClusterRole
metadata:
name: snapshot-controller-role
namespace: default
rules:
- apiGroups: [""]
resources: ["pods"]
verbs: ["get", "list", "delete"]
- apiGroups: [""]
resources: ["persistentvolumes"]
verbs: ["get", "list", "watch", "create", "delete"]
- apiGroups: [""]
resources: ["persistentvolumeclaims"]
verbs: ["get", "list", "watch", "update"]
- apiGroups: ["storage.k8s.io"]
resources: ["storageclasses"]
verbs: ["get", "list", "watch"]
- apiGroups: [""]
resources: ["events"]
verbs: ["list", "watch", "create", "update", "patch"]
- apiGroups: ["apiextensions.k8s.io"]
resources: ["customresourcedefinitions"]
verbs: ["create", "list", "watch", "delete"]
- apiGroups: ["volumesnapshot.external-storage.k8s.io"]
resources: ["volumesnapshots", "volumesnapshotdatas"]
verbs: ["get", "list", "watch", "create", "update", "patch","delete"]
- apiGroups: [""]
resources: ["services"]
verbs: ["get"]_**
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta
metadata:
name: snapshot-controller
namespace: default
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: snapshot-controller-role
subjects:
- kind: ServiceAccount
name: snapshot-controller-runner
namespace: default
---
```

The resources highlighted in blue(bold) above, are the ones required by the Snapshot
Provisioners and Controller to interact with Kubernetes on Snapshot Management and
Dynamic Volume Provisioning. The access to the Services (highlighted in light orange -
bold italics) is required for accessing the maya-apiservice.

* Additional StorageClass is created to support the Promotion of Snapshot to PV, as
required by the Snapshot Operators design. The promoter StorageClass can be defined
as below, here provisioner field in the spec define which provisioner should be used and
what parameters should be passed to that provisioner when dynamic provisioning is
invoked.

```yaml
---
kind: StorageClass
apiVersion: storage.k8s.io/v
metadata:
name: openebs-snapshot-promoter
provisioner: volumesnapshot.external-storage.k8s.io/snapshot-promoter
---
```

#### Create Snapshot

User will trigger the creation of the snapshot by applying a VolumeSnapshot object. The
openebs-snapshot-controller receives the request and will invoke the maya-apiserver api to create
the snapshot.

![Snapshot API][Snapshot API]

Here are additional details as the request traverses through different components:

* User will load the following VolumeSnapshot object to create a snapshot:

```yaml
---
apiVersion: volumesnapshot.external-storage.k8s.io/v
kind: VolumeSnapshot
metadata:
name: snapshot-demo
namespace: default
spec:
persistentVolumeClaimName: demo-vol1-claim
---
```

* Snapshot Controller will process the VolumeSnapshot request and will start the following
process:

  * Does the housekeeping of creating the VolumeSnapshotData object and fetching
the associated PV for this PVC. Based on the PV type, in this case (iscsi),
invokes the openebs driver specific logic to create a snapshot of the persistent
volume referenced by the PVC.
  * Generate a unique snapname to be sent to the storage. The name will be
generated as <pv-name>_<snap_name>_current_nano_timestamp. Including the
pv_name and snapname will allow for tools like mayctl to co-relate the snapshots
taken at storage with the corresponding Kubernetes PV and Snapshot objects.
  * The driver plugin (in this case the openebs) will call maya-apiserver create
snapshot API - which in turn will propagate the snapshot request to Jiva Replicas
via the associated Jiva Controller. The snapshot API on maya-apiserver is
invoked with:

    * Unique Snapshot name (which is pv name + snapshot name + timestamp)
    * Volume Name

  * In case of any errors, the are perculated up the stack from replica up to the
snapshot-controller, which will set the VolumeSnapshot Condition to errored
state.
  * Once a snapshot is created successfully, Snapshot Controller will update the
snapshot ID/timestamp to the ​VolumeSnapshotData​ API object and also
update its VolumeSnapshot and VolumeSnaphotData status fields. The snapshot
ID is the unique snapname generated above. This way the K8s can link the user
provided name with the actual name used to create a snap.

* The user is expected to get the current status of the snapshot by querying for the
VolumeSnapshot objects that was loaded.

#### List Snapshot

User can query for the available snapshots using - `​kubectl get volumesnapshot`​.

The volumesnapshot are fetched directly from the K8s configuration store. Since there are no calls
made to maya-apiserver, it is possible that the information returned from the k8s configuration store
can be stale, if the snapshots were deleted from maya-apiserver or jiva directly.

#### Delete Snapshot

User can query for the available snapshots using - `​kubectl delete volumesnapshot​ <snapshot-name>`.

The volumesnapshot are deleted from the K8s configuration store. Since there are no calls made to
maya-apiserver, the snapshots continue to exist at the storage side.


#### Describe Snapshot

User can query for the available snapshots using -​ `kubectl describe volumesnapshot​ <snapshot-name>`.

The volumesnapshot details stored in the volumesnapshot and volumesnapshotdata objects are
shown to the user. This call displays the status of the volumesnapshot operation. Since there are
no calls made to maya-apiserver, the usage details of snapshots like how much space is occupied
or if snapshots are used by clones (references) are not shown.

#### Snapshot to PV promotion (aka Clone)

User can create a cloned volume from a previously taken snapshot by creating a new PVC. The
PVC should reference the snapshot and StorageClass should be pointing to snapshot-promoter:

```yaml
---
apiVersion: v
kind: PersistentVolumeClaim
metadata:
name: demo-snap-vol-claim
namespace: default
annotations:
  snapshot.alpha.kubernetes.io/snapshot: snapshot-demo
spec:
  storageClassName: snapshot-promoter
accessModes: [ "ReadWriteOnce" ]
resources:
requests:
storage: 5Gi
---
```

Snapshot-promoter is like any other external-storage provisioner that processes a PVC request by
dynamically creating a PV and Binding the PV to PVC. The workflow for creating the volume from a
snapshot is as described below:

![Snapshot Promote][Snapshot Promote]

snapshot-provisioner:
* Snapshot provisioner - OpenEBS Plugin will call create volume API request to
maya-apiserver for creating a new volume using the given snapshot. The Plugin will
pass the following details to maya-apiserver

  * Clone Volume Name

  * Clone Volume Namespace

  * Clone Volume Capacity (this should be equal to the source volume)

  * Source Volume Name

  * Source Volume Namespace

  * Source Volume Snapshot Unique Name

* OpenEBS Plugin will return errors if the Clone Operation couldn’t be initiated or if the
details of the cloned volume could not be obtained due to errors interacting with maya-apsierver 
or source controller.

  * The snapshot provisioner will mark the PVC as unbound and keep retrying till the
user deletes the PVC.

* On successfully creating the Cloned Volume, the OpenEBS Plugin will return PV object
that will be bound to the PVC. Note that this is just initiation of the Cloned Volume and
the sync can take longer. During the sync, the kubelet can keep trying to connect to the
PV object that keeps failing.

maya-apiserver:

* maya-apiserver will validate the request by checking “ReplicaType==clone” (type will set
while making the clone request from snapshot provisioner with some other reference
details), if true then invokes extended clone volume API’s of maya-apiserver.
* This extended volume API having some more details which are specific to invoke the jiva
clone API’s:
  * Source jiva controller IP
  * Snapshot name (to be cloned)
  * New PV name ( to be provisioned)
  * Type of replica ( i.e. “clone”)

* maya-apiserver will fetch the details like source volume controller IP and source volume
storage class.

* maya-apiserver will create the cloned volume by setting the same properties as the
source volume (source storage class) when they are not overridden by the configuration
in the clone PVC.

  * Service and Controller Deployments are untouched

  * Replica Deployment will be provided with two additional parameters - clone ip
and source snapshot.

Jiva:
* New jiva controller is started as per the Deployment spec. As part of the startup,
controller will wait for its replica to register. Once the replica is registered, the controller
will wait until the replica's clone status is updated to "completed" or "na"​ - before making
the volume available for accepting IO.
* New jiva replica’s are created as per the Deployment Spec, that includes type=clone,
source controller ip and source snapshot. If the type is set as clone, this replica will
contact the source controller and identify a replica that can be used for copying over the
data from source replica to this replica.

### Detailed Design

#### Build Changes

* The code is split under external-storage/openebs/pkg, which contains the common code
that is used by both openebs provisioner and the snapshot controller and provisioner.
* The code specific to snapshot controller and provisioner are embedded into the
external-storage/snapshot
* So both folders - external-storage/openebs/pkg and external-storage/snapshot are built
and 3 containers are created and pushed to dockerhub.
  * openebs/openebs-k8s-provisioner
  * openebs/snapshot-controller
  * openebs/snapshot-provisioner

* Update the CI scripts to include helm based installation that includes
openebs-snapshot-controller with ci-tag.

* Update the openebs-operator.yaml, kubernetes helm charts and the openebs helm
charts with the openebs-snapshot-controller deployment specs.

#### openebs-snapshot-controller

##### snapshot-controller

* Snapshot Controller will be able to contact K8s Cluster using inClusterConfig or
outOfCluster, secure or insecure ports.
* Snapshot Controller will be able to contact the maya-apiserver when running in default or
non-default namespace.
* OpenEBS Snapshot Controller Plugin will be registered with the Snapshot Controller to
be invoked for iSCSI volumes and will implement the required interfaces. Since iSCSI is
a generic volume type - within the implementation, there will be checks to ensure that
only OpenEBS volumes are operated by the plugin.

* Create Snapshot is called with PV object and a set of values that includes snapshot
name. On receiving the request, do the following:
  * Extract the PV Name and Snapname from the input parameters and generate a
unique snapshot name: <pvname>_<snapname>_<timestamp>
  * Validate that the PV belongs to OpenEBS
  * Validate that the name generated can be within 255 characters.
  * Call the maya-apiserver with pv-name and snapshot name.
  * Return either success or failure based on the response from maya-apsierver.
User should be able to view the details failure/success messages by performing
a kubectl describe <snapshot>
  * The failure responses:
i. Unsupported PV. Only PVs provisioned by OpenEBS are handled
ii. Snapshot unique name is longer than 255 characters. Only up to 255
characters are supported.
iii. Unable to contact K8s server
iv. Unable to contact maya-apiserver
v. <Failure messages from maya-apiserver will be relayed back>
○ Timeout response ( max time = 1 min. no-retries)
i. Failed to take snapshot. Took longer than a minute to take snapshot.

* Delete Snapshot with the snapshot data and the PV object. On receiving this request do
the following:
  * Returns success. <Delete is currently unsupported>

* Describe Snapshot with the snapshot data. On receiving this request do the following:

  * Fetch the last status - error/success and return them. <Partially implemented>

* Find Snapshot with the tags that include snapname. On receiving this request do the
following:

  * Returns nil. "Find is currently unsupported"

##### snapshot-provisioner

* Snapshot Provisioner will be able to contact K8s Cluster using inClusterConfig or
outOfCluster, secure or insecure ports.
* Snapshot Provisioner will be able to contact the maya-apiserver when running in default
or non-default namespace.
* OpenEBS Snapshot Provisioner Plugin will be registered with the Snapshot Controller to
be invoked for iSCSI volumes and will implement the required interfaces. Since iSCSI is
a generic volume type - within the implementation, there will be checks to ensure that
only OpenEBS volumes are operated by the plugin.

* Snapshot Restore (or Clone Volume) API is invoked by passing the following arguments:

  * SnapshotData Object
  * PVC Object
  * PV Name
  * Parameters

On receiving the request perform the following:
  * Validate that the SnapshotData objects belongs to OpenEBS Volumes
  * Extract the StorageClass associated with the Source PV
  * Call the maya-apiserver create volume by passing the following details:

      i. Clone Volume Name

     ii. Clone Volume Namespace

     iii. Clone Volume Capacity (this should be equal to the source volume)

     iv. Source Volume Name

     v. Source Volume Namespace

     vi. Source Volume Snapshot Unique Name

 * On failure conditions a nil object is returned along with the error.
 
 * On success a iSCSI PV object is created with the details returned from the
maya-apiserver.
 * The failure responses:
  
     i. Unable to contact the K8s API server
  
    ii. Unable to contact maya-apiserver
  
   iii. Unable to access the Source Volume details
  
    iv. Errors returned from the maya-apiserver

* No retries or timeout implemented within this API. The caller of this API,
snapshot-provisioner will keep retrying the creation of PV till the PVC object is
deleted by the user or a PVC is successfully created.

#### maya-apiserver

* Create Snapshot API: mayactl and openebs-snapshot-controller should be able to
contact maya-apiserver for creating a snapshot. maya-apiserver will have to identify the
storage engine associated with Volume and delegate the create snapshot request to the
storage engine. This API takes two parameters:

  * Volume Name
  * Snapshot Name

Validation and Error responses:
  * 500: Snapshot Name - is within 255 characters long
  * 500: Unable to Contact the K8s server
  * 404: Volume Name - doesn’t reference a valid Volume.
  * 500: Unable to contact the Storage Engine
  * 500: Volume Status - is offline and snapshot can’t be taken on the Volume.
  * 500: Snapshot Name - is unique on the volume. This validation is delegated to
  the Storage Engine to verify
  * 500: Error response from the Storage Engine
  * 500: Timed out waiting for snapshot operation to complete

Success Response:
  * Only if the storage engine returns a success

* Clone Volume API: maya-apiserver ​ Create Volume API is extended to include source
volume and source snapshot details. The following modifications will be done to the
Create Volume API, when it detects the presence of source volume and source
snapshot:

  * Fetch the Storage Class and Controller IP associated with the Source Volume.
  * Replace the incoming Storage Class with the Storage Class of the Source
Volume
  * Process the Create Volume Request as earlier, by fetching the required details
and applying the parameter override logic - PVC > Storage Class > ENV >
Defaults.
  * During the Replica Creation, include the following additional parameters:
    i. Controller IP
    ii. Source Snapshot
  * The source volume and source snapshot details will be saved as annotations
onto the Volume Objects.
Validations and Error Responses:
  * 500: Unable to contact K8s server to fetch Source Volume Details
  * 404: Source Volume doesn’t exist
  * 500: Unable to retrieve the Storage class associated with the Volume
  * 500: Unable to retrieve the Storage Volume - Controller IP
  * 500: Insufficient space on the storage pool to create the clone.
  * 500: <Error messages> that come up during the processing of the Volume
  Request.

  * 500: Unable to deploy the cloned Volume in the target namespace
Success:
  * Cloned Volume has been successfully deployed.
* maya-apiserver should only allow Snapshot and Clone operations on PVs that have the
snapshot capabilities enabled (via Policies) and if the associated backend storage
engine supports it.
* The maya-apiserver will retrieve the StorageClass associated with the Source PV
and check if Clones can be supported. The operations will be supported for jiva
volumes with version 0.6 or higher.
* In future this code change changed to read a configuration on the storage class,
or the PV that indicates whether snapshots are supported:
config.openebs.io/clones: enabled|disabled.

#### jiva

##### jiva-controller

* Create Snapshot API
  
  * An error message will be returned by the controller if the volume is in offline state
w.r.t to the replicas.
  * IO will be quiesced and Snapshot will be taken on all the available replicas.
  * If some of the replica’s are offline, when they come back online, they will sync
data and snapshots from the available replica(s)

* List Replica
  * The replica status should included details like - initial sync status along with other
details that is currently provides.
  * The clone replica should not be visible in the source volume - list replica
response.

* At Startup, the controller will check for the clone status of the replicas:
  * If the clone is status is either “NA” or “completed” the Replica will be registered
and IO will be served to the replica.

##### jiva-replica

* Create Snapshot API
* At startup the replica​ will:
  * Register itself with its controller.
  * If replicaType is not passed as clone, the clone status is set as “na” in the volume
metadata file.
  * If replicaType is passed as clone, clone status is fetched from the volume
metadata file. If clone status is not set as completed, it is set to inProgress and
the clone process is triggered and managed by the replica:
    * Get the replica list from the source controller.
    * Find a replica in RW mode(let's call it the source replica)
    * Get the list of snapshots(snapshot chain) present at the source replica.
    * If the snapshot to be cloned is not present error out.
    * Set the rebuilding flag at the target replica.
    * Sync all the snapshots taken till the required snapshot.
    * Clear the rebuilding flag at the target replica.
    * On completing the sync process, the clone status is updated to
    “completed”.
* The replica should indicate that sync is in progress. At the beginning of the sync, the
    amount of time required to perform the sync operation should be estimated and the
    current progress should be made available in the replica status.
* The sync process will be restarted in the following cases:
  * Unable to fetch the source replica
  * Restart of the clone replica
  * Connection failures during the sync
* The sync process will return failures when:
  * Snapshot is not available at the source replica
* The failure error messages should be accessible via the replica status API

#### mayactl

* mayactl volume info : should display if the volume is a cloned volume and the status of
the cloned volume. In addition to the values displayed for the regular volumes, it should
also display clone specific details like:
  * Source Volume
  * Source Snapshot Name
  * Initial Sync Status - in progress or Online or failed

* mayactl clone : should allow the user to create a new volume. The details for this
command will be:

  * clone volume name
  * clone volume size
  * Source volume name
  * Source volume size

#### Unit testing:

Unit test needs to be added to cover the negative test cases.[WIP]

#### Integration testing:

Integration tests will be carried out on travis or any other K8s cluster. The prerequisites are to
have admin privileges to the cluster and access to helm.

#### openebs/jiva

##### Setup:

* Bring up jiva controller and replica using docker containers.

#### Test Cases:

##### Basic Success Scenarios

* Verify that a clone can be created from a snapshot when source volume exists.
* Verify that once the initial sync is completed, and cloned volume is online. A restart of
the cloned replica will not trigger (restart) of sync again.
* Verify that source volume - List Replica doesn’t show any clone replica’s while the sync
is in progress
 Verify that the clone volume - List Replica provides the status of the replica, which
includes the clone status.

##### Basic Failure Scenarios

* Verify that controller returns an valid error response when the replicas are not available
to process the snapshot.
* Verify that if the snapshot to be cloned is not present at the source, an error message is
generated and the volume creation is aborted.
* Verify that a proper error message is displayed when the replica is unable to contact the
source controller or if the source replicas are unavailable.
* Verify that a proper error message is displayed when there is not enough space to
perform the sync.

##### Resiliency Scenarios

* Verify that snapshots are synced with the offline replica after it becomes online.
* Verify that clone can be created from a snapshot on a degraded source volume.
* Verify that if the clone replica restarts during initial sync, after the clone replica restarted
- the initial sync is triggered again.
* Verify that if the source replica from where the data is being received is restarted, the
sync is restarted by the clone replica with another available replica or when the replica
becomes online.
* Verify that source volume (replica) doesn’t have multiple sync ongoing sync requests to
the same clone (replica)

#### openebs/maya

##### Setup:

* Verify k8s cluster is running and helm is installed
* Running openebs maya-apiserver and provisioner using helm charts
* The test operations will be triggered via mayactl


##### Test Cases:

* Verify that snapshot can be taken on a volume and a clone is created from the volume.
* Verify the boundary condition for the name - the snapshot should be created with a
name up to 255 chars.
* Verify that snapshot with the same name is not created.
* Verify that the cloned volume is getting deleted even if the initial sync is in progress. For
example if the volume is of high data size. And if the user is associated a PVC that is still
in sync with a Pod, then kubelet can run out of retry attempts and the user will try to go
and delete it.

#### openebs/external-storage

##### Setup:

* Verify k8s cluster is running and helm is installed
* Running openebs maya-apiserver and provisioner using helm charts
* Running deployment for snapshot-controller which runs snapshot-controller and
snapshot-provisioner as containers in single POD.
* Create snapshot-promoter storage class.

##### Test Cases:

* Verify that a new PV can be created using a snapshot of existing PV.
  * Provision PVC “demo-vol” and mount in a busybox application.
  * Busybox app will write/create some files in a mountpath dir.
  * Create a snapshot of PVC “demo-vol”.
  * Provision new PVC “snap-demo-vol” using the above created snapshot
  * Mount PVC “snap-demo-vol” volume to a new application pod
  * Perform validation/Md5sum check on data files to verify data integrity.

* Verify that user is provided with proper messages if a Volume can’t be created using a
snapshot due to unavailability of the snapshot or other services.

* Verify that snapshot create request is not retried when the elapsed time is greater than
60 sec.

* Verify that user is provided with proper error/status messages on success and failure of
the snapshot creation. The failure cases are:
  * K8s is not reachable or unable to get the SC associated with the PVC
  * maya-apiserver is not reachable. A max timeout of 60 sec.
  * maya-apiserver is unable to contact the volume controller for taking snapshots.
  * PVC or PV on which the snapshot was requested no longer exists

* Verify that snapshot promote - or clone volume operation is resilient against the following
failures. There has to be a reconciliation loop that keeps retrying till the clone volume is
created:
  * maya-apiserver is not reachable
  * K8s is not reachable or unable to get the SC associated with the PVC
  * maya-apiserver is unable to contact the volume controller for taking snapshots.
  * Source PV object is in degraded or offline state or enters a degraded or offline
  state while the clone volume operation is in progress.
  * Clone PV object (replica) gets restarted or rescheduled to another node during
  initial sync.
  * Clone PV object (controller) gets restarted or rescheduled to another node during
  initial sync.

* Verify that clone volume operation returns a valid error/status message that can be seen
from kubectl. Some of the irrecoverable failures are:
  * PV on which the snapshot was taken doesn’t support clone - like jiva with version
less than 0.6
  * PV on which the snapshot was requested no longer exists
  * PV on which the snapshot was taken and clone was in progress got deleted.
  * There is not enough space to create a clone.

* Verify that a failed operation is not being indefinitely re-tried.

* Verify that user provided snapshots are converted into unique name when sent to the
maya-apiserver. Ideally this should be handled by K8s validations, but there could be a
scenario where the backend already has a snapshot with that name.

* Verify that snapshot operations are performed only on PV with StorageClasses that have
snapshot policy enabled.

* Verify that Snapshot Provisioner and snapshot controller will be able to contact K8s

* Cluster using inClusterConfig or outOfClusterConfig, secure or insecure ports.


### E2E Testing

1. Verify that the OpenEBS snapshots are interoperable in a environment that has other
    volume types like glusterfs, that also supports snapshots. Make sure that the snapshot
    requests are routed correctly to the respective snapshot provisioners.

2. Verify the operations at scale - creating snapshots on multiple PVs at the same time.
    Typically required for issuing snapshots on a group of volumes belonging to the same
    application.

3. Verify periodic backup and restore on any given volume, i.e., creation of multiple
    snapshots on the same PV, with clones created on each snapshot

4. Verify that creating multiple clones using a snapshot works without any errors. Measure
    the impact on the IO on the source volume, while the clone is in progress. Perform
    relative performance/benchmark tests to note the difference.

5. Verify that snapshots are taken within the tolerable limits of the application under
    non-stress and stress conditions. The snapshot operation should not result in the volume
    becoming offline/unavailable since the application will be quieced during snapshot
    creation.

6. Verify the usage reporting of actual used and total capacity is not affected due to high
    number of snapshots being retained.

7. Verify that RBAC rules are applied and sure that a user can issue snapshots on only the
    PVCs that belong in his/her authorized namespace. Similarly PVs can be created only
    on the authorized snapshots.
8. Verify that user can create a snapshot in his namespace - which is different than that of
  the namespace where ​ openebs-snapshot-controller is running.

9. Verify that the cloned volume comes up with the same number of replicas as the source
    volume. In this case, the PVC doesn’t override any properties.

10. Verify that the cloned volume comes up with properties overridden from the PVC. For
    example, the cloned volume can be set to have one replica as opposed to 3 replicas on
    the source volume. Along with replica, other configurable properties should be validated.

11. Verify that openebs-snapshot-controller can be deployed in highly available mode by
    modifying the values (replica, affinity, etc.,) associated with the
    openebs-snapshot-controller in the helm or openebs-operator.yaml.

12. Verify that only one snapshot request is processed when there are multiple
    openebs-snapshot-controller running for HA.

13. Snapshot & clone creation across Kubernetes versions (n -> (n-2) : say, 1.10.x to 1.8.x)

14. Snapshot & clone creation on OpenShift platform (CentOS)

15. Snapshots with filesystems (ext4, xfs) supported by provisioner


16. Snapshot creation with inflight/ongoing I/O (verify data sync at the time of snap creation)

17. Stricter data-integrity tests using :
    a. FIO where patterns are read with “data_verification” flags enabled from the clone
(​https://fio.readthedocs.io/en/latest/fio_doc.html#verification​)
    b. Different application DI tests (each application has its own latency/sync timeouts
etc.,) The tests will involve using an app-specific DI checker utility against the
clone.

18. Subject following components to chaos tests (failures / restarts / network delays). The
expectation being in each case that : (a) The snapshot object, clone pvc reflects
appropriate status (b) User data is maintained.

   * maya-apiserver, provisioner, snapshot operator pod, source volume controller,
source volume replicas, clone volume replicas (syncing), clone volume controller
   * Kubernetes master failure/recovery
   * Kubernetes nodes failure/recovery
   * Source replica disk failures
   * Clone replica disk failures

**Note** ​: The integration tests also cover the unreachable cases. Here chaos tools will be
employed to randomly cause these failures followed by recovery.

### Implementation Plan

#### Pre-Alpha

* (Coding) Enhance the jiva controller and replica to allow for cloning volumes from
snapshot

* (Coding) Enhance the maya-apiserver volume create API to process the clone
parameters - source volume and source snapshot

* (Coding) Implement the openebs-snapshot-controller - snapshot controller and snapshot
provisioner extensions.

* (Coding) Update the helm charts in openebs repo and kubernetes/stable with
openebs-snapshot-controller

* (Coding) Update the openebs-operator with the ​ openebs-snapshot-controller
deployment.

* (E2E) Verify successful infrastructure setup and the basic backup(snap)-recovery(clone)
workflow for a MySQL application with test database content across commonly used
kubernetes versions (1.8, 1.9. 1.10) and operating systems (CentOS, Ubuntu), with the
snapshot operator and application running on their respective namespaces. (8, 12)

##### Alpha

* (Coding) ​ mayactl info should show the status of the clone volume.

* (Coding)​ mayactl clone should be available.

* (Coding) Failure conditions are handled in the snapshot and clone operations in Jiva,
maya-apiserver and the openebs-snapshot-controller with user-friendly error messages

* (E2E) Run backup and recovery workflows with data integrity checks on multiple
applications on the cluster with active data traffic. (Refer Alice’s job to sync to remote
backup server) (2, 4, 15, 16) (candidate for staging workload)

* (E2E) Run periodic backup recovery jobs on a given PostgreSQL DB with prometheus
monitoring setup to get volume metrics. Ensure snapshots are discarded once
backed-up. (3, 5, 6)

* (E2E) Run application backup and recovery workflows on Openshift (14)

* (E2E) Perform tool-based data-integrity validation on cloned data (17)

* (E2E/IT) Verify creation of snapshots on authorized PVCs & clones on authorized
snapshots (same namespace) (7, 8)

* (E2E) Verify snapshot and clone workflows with highly available snapshot operator (11)

* (Litmus) Litmus test jobs are available to demonstrate the use cases with MySQL
restore.

#### Beta

* (Coding) A PV which has snapshots should not be deleted unless all the associated
cloned volumes are deleted. This may require changes to the openebs-provisioner.

* (Coding) Make the jiva resilient against component failures

* (Coding) Make the maya-apiserver and openebs-snapshot-controller resilient against
components failures.

* (Coding) The snapshot and clone operations should only be allowed, if the StorageClass
associated with the PVC has enabled them.

* (Coding) maya-apiserver should check for the available space of the storage pool before
creating a replica on a node.

* (Coding) Snapshot info/get should provide usage details like the space used and the
volumes (clones) referring to this snapshot.

* (E2E) Obtain relative benchmark of I/O performance on volumes upon clone creation
with variables as : Cloud VM instance type (resources), Data size, Clone count,
Workload type (4)

* (E2E/IT) Verify cloned volumes can : a) Inherit source volume properties by default b)
Override source volume properties

* (E2E) Verify snapshot interoperability on clusters running other storage engines. (1)

* (E2E) Verify snapshot interoperability with multiple volume filesystems (15)

* (E2E) Resiliency tests for component failures (17)

#### Future

* Snapshot scheduling using meta-controller.
* Provide snapshot operations through CSI Plugin
* Snapshot state validation using meta-controller. Make sure there are no stale snapshots.
Similarly, there may be a need to create snapshot objects for the snapshots that exist on
the storage side.
* Jiva - Snapshot delete should delete from the storage (Jiva replica).
* Error and Log messages are done via L10n and i18n norms. Depends on the
maya-apsierver and other components already providing a framework for L10n and i18n.
* mayactl should be able to confirm if the user has setup the snapshot provisioners
correctly. For example, it should throw a warning, if the storage class required to create
clones is missing, or if the required custom resource objects are missing.

### Related Pull Requests:

1. Maya : ​https://github.com/openebs/maya/pull/283
2. External storage: ​https://github.com/openebs/external-storage/pull/37
3. Jiva: ​https://github.com/openebs/jiva/pull/48
4. OpenEBS: ​https://github.com/openebs/openebs/pull/1405

[Snapshot API]: images/api.png
[Snapshot Design]: images/design.png
[Snapshot Promote]: images/promote.png