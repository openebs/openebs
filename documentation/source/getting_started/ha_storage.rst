How does Storage High Availability Work?
=========================================

High Availability storage (HA storage) is a storage system that is continuously operational. Redundancy is a key feature of HA storage, as it allows data to be kept in more than one place.

OpenEBS Jiva Volume is a controller with one or more replicas. The controller is an iSCSI target whereas the replica plays the role of disk. The controller exposes the iSCSI target while the actual data is written. The controller and each individual replica run inside a dedicated container.

OpenEBS Jiva Volume controller exists as a single instance but there can be multiple instances of OpenEBS Jiva volume replicas. Peristent data is synced between replicas. 

OpenEBS Jiva Volume HA is based on various scenarios as explained in the following sections.

Deployment 1 - OpenEBS Jiva Volume with single replica and single controller
----------------------------------------------------------------------------
**Scenario 1** - When an OpenEBS volume controller POD crashes, the following occurs.

* The controller gets re-scheduled as a new Kubernetes POD.
* Policies are in place that ensures faster rescheduling.

**Scenario 2** - When K8s node that hosts OpenEBS volume controller goes offline, the following occurs.

* The controller gets re-scheduled as a new Kubernetes POD.
* Policies are in place that ensures faster rescheduling.
* If Kubernetes node is unavailable, the controller gets scheduled on one of the available nodes.

**Scenario - 3** - When OpenEBS volume replica POD crashes due to reasons other than node not-ready and node un-reachable, the following occurs.

* The replica gets re-scheduled as a new Kubernetes POD. 
* The replica may or may not be re-scheduled on the same K8s node.
* There is data loss and hence storage downtime if replica gets re-scheduled on a different K8s node.

**Scenario 4** - When K8s node that hosts OpenEBS volume replica goes offline, the following occurs.

* Results in a storage downtime.
* Policies are in place that does not allow re-scheduling of replica (as replica is tied to a node's resources) to any other node.

Deployment Type 2: OpenEBS Jiva Volume with 2 or more replicas and single controller
--------------------------------------------------------------------------------------

**NOTE:** In this deployment, each of the replicas get scheduled in a unique K8s node that is, a K8s node will never have two replicas of an OpenEBS volume.

**Scenario 1** - OpenEBS volume controller POD crashes.

* The controller gets re-scheduled as a new Kubernetes POD.
* Policies are in place that ensures faster rescheduling.

**Scenario 2** - K8s node that hosts OpenEBS volume controller goes offline.

* The controller gets re-scheduled as a new Kubernetes POD.
* Policies are in place that ensures faster rescheduling.
* If Kubernetes node is unavailable, the controller gets scheduled on one of the available nodes.

**Scenario 3** - OpenEBS volume replica POD crashes for reasons other than node not-ready and node un-reachable.

* The replica is re-scheduled as a new Kubernetes POD. 
* The replica may or may not be re-scheduled on the same K8s node.
* There is data loss with this newly scheduled replica if it gets re-scheduled on a different K8s node.
 
**Scenario 4** - K8s node that hosts OpenEBS volume replica goes offline:

* There is no storage downtime as the other available replica displays inputs/outputs.
* Policies are in place that does not allow re-scheduling of crashed replica (as replica is tied to a node's resources) to any other node.