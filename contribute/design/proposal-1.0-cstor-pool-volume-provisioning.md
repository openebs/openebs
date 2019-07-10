# Provisioning cStor Pools and Volumes

This document provides the design details on how the OpenEBS 
Control Plane will create OpenEBS StoragePools and Volumes using 
OpenEBS cStor storage-engine. 

## Prerequisites
- Container Attached Storage or storage for containers in containers. 
  [Introduction to OpenEBS](https://docs.google.com/presentation/d/1XPZZx7DYv2ah0Yy_A_CwTVVhZj3Sc0XkSsdQc7BG72I/edit#slide=id.p)
- Knowledge about Kubernetes [CRDs](https://kubernetes.io/docs/concepts/api-extension/custom-resources/)
- Knowledge about Kubernetes [Resource limits and requests for CPU and Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container)
- Knowledge about Kubernetes concepts like Custom Controllers, 
  initializers and reconciliation loop that wait on objects to 
  move from actual to desired state.
- Familiar with Kubernetes and OpenEBS Storage Concepts:
  * PersistentVolume(PV) and PersistentVolumeClaim(PVC) are 
    standard Kubernetes terms used to associate volumes to a 
    given workload. A PVC will be watched by a dynamic provisioner, 
    and helps with provisioning a new PV and binding to PVC. In 
    case of OpenEBS, provisoining a PV involves launching OpenEBS 
    Volume Containers (aka iSCSI Target Service) and creating a 
    in-tree iSCSI PV.
  * BlockDevices(BDs) and BlockDeviceClaims(BDCs) are Kubernetes 
    custom resources, used to represent and identify the storage 
    (a disk) attached to a Kubernetes Node. BlockDiskClaims are 
    used by the cStor Pool Operator to claim a BlockDevice before
    using it to create a Pool. Each BlockDevice will be represented 
    by a cluster wide unique identifier. BlockDevice and 
    BlockDeviceClaims are managed by [OpenEBS Node Disk Manager](https://github.com/openebs/node-disk-manager/blob/master/docs/design.md)
  * StoragePoolClaim(SPC) is a custom resource, that can be used to 
    claim creation of cStor Pools. Unlike, PVC/PV - SPC can result in 
    more than one cStor Pool. Think of SPC as more of a Deployment
    Kind or Statefulset Kind with replica count. 
- Familiar with cStor Data Engine. cStor Data Engine comprises of 
  two components - cStor Target (aka iSCSI frontend) and cStor Pool. 
  cStor Target recieves the IO from the application and it interacts
  with one or more cStor Pools to serve the IO. A single cStor Volume
  comprises of a cStor target and the logical replicas that are 
  provisioned on a set of cStor Pools. The replicas are called as 
  cStor Volume Replicas. The cStor Pool and Replica functionality 
  is containerized and is available in `openebs/cstor-pool`. 
  The target functionality is available under `openebs/cstor-istgt`.
  Each of these expose a CLI that can be accessed via UXD.

## Design Constraints / Considerations
- The dynamic provisioner will be implemented using the 
  kubernetes-incubator/external-provisioner, which is already 
  used for Jiva volumes. At the time of this writing CSI was 
  still under heavy development. In future, the external-provisioner
  can be replaced with CSI. 
- Creation of cStor Pools and cStor Volume Replicas will follow
  the Kubernetes reconciliation pattern - where a custom resource 
  is defined and the operator will eventually provision the objects. 
  This approach was picked over - an API based approach - because:
  * The cStor Pool and Target pods only support CLI that can 
    be accessed via UXD. Write a higher level operator requires 
    API to be exposed.  
  * The reconciliation has the advantage of removing the dependency
    on control plane once provisioned - for cases like node/pool 
    not being ready to receive the requests. Recover from chaos 
    generated within the cluster - without having to depend on a 
    higher level operator.


## High Level Design and Proposed Workflow

To make use of the cStor Volumes, users will have to select a 
StorageClass - that indicates the volumes should be created using 
a certain set of cStor Pools. As part of setting up the cluster, 
the administrator will have to create cStor Pools and a corresponding
StorageClass. 

At a high level, the provisioning can be divided into two steps:
- Administrator - creating cStor Storage Pool and StorageClass (and)
- Users - request for cStor Volume via PVC and cStor StorageClass. 

As part of implementing the cStor, the following new CRDs are loaded:
- StoragePoolClaim
- CStorPool
- CStorVolume
- CStorVolumeReplica

The following new operators/controllers are created to watch for the
new CRs:
- cstor-pool-operator ( embedded in the maya-apiserver), will watch
  for SPC and helps with creating and deleting the cStor Pools. 
- cstor-pool-mgmt ( deployed as a side-car to the cStor Pool Pod
  will help with watching the cStorPool - to create uZFS Pool using
  the provided block devices. Will also watch for the cStorVolumeReplica
  to create uZFS Volumes (aks zvol) to be assicated with cStor Volume.
- cstor-volume-mgmt ( deployed as a side-car to the cStor Target Pod
  will help with reading the target parameters and setting them on
  cStor Target.)

Also, this workflow assumes that BlockDevice and BlockDevice claims
are available. 

### Workflow for creating cStor Pools:

   * Admin will create StoragePoolClaim(SPC) with type=cstor and 
     the SPC will contains information like:
     ```
     apiVersion: openebs.io/v1alpha1
     kind: StoragePoolClaim
     metadata:
       name: pool1
       annotations:
         openebs.io/cas-type: cstor
         #(Optional) Use the following to enforce the limits on CPU and RAM to be allocated/used 
         # by the cStor Pool containers. AuxResourceLimits can be used to specify 
         # CPU and RAM limits for the cStor Pool Management side cars
         #If not specified, the default requests and limits will be assigned.
         cas.openebs.io/config: |
           - name: PoolResourceRequests
             value: |-
                 memory: 1Gi
                 cpu: 100m
           - name: PoolResourceLimits
             value: |-
                 memory: 2Gi
           - name: AuxResourceLimits
             value: |-
                 memory: 0.5Gi 
                 cpu: 50m
     spec:
       name: pool1
       #Specify whether cstor pool should be created with disk or sparse files. 
       type: disk
       #Admin can specify the maximum number of cStor pools to be created with this name. 
       #maxPools: 3 (default no-limit)
       poolSpec:
         #Define the type of pool to be created. Default is striped. The other supported type is "mirror"
         poolType: striped
         #Pools can be configured with different features. 
         #An example feature could be to enable/disable over provisioning.
         overProvisioning: false
         #(Optional - Phase2) Define the required capacity and the max limit
         #capacity: 
         # requests:
         #   storage: 100Gi
         # increment:
         #   storage: 100Gi
         # limits:
         #   storage: 1PBi
       #(Optional) Specify the exact disks or type of disks on which pools 
       # should be created. Disks here refer to the Disk CRs added 
       # by the node-disk-manager. The disks could refer to local disks 
       # or disks from external storage providers like EBS, GPD or SAN.
       disks:
         # Specify exact disks. 
         # If 3 striped pools of single disk, then provide 3 disks from different nodes.
         # If 3 striped pools of two disk, then provide 6 disks with 2 from 3 different nodes.
         diskList:
           - disk-0c84c169ab2f398b92914f56dad41f81
           - disk-66a74896b61c60dcdaf7c7a76fde0ebb
           - disk-b34b3f97840872da9aa0bac1edc9578a
         #(Optiona - Phase2) Specify the type of disks to select from different nodes
         # disks will be selected to specify the requested capacity
         diskTypes:
           - type: block
             capacity:
               minStorage: 10Gi
               maxStorage: 10Ti
       #(Optional - Phase2) Specify the nodes or a list of nodes where the pool has to be created. 
       # by providing a list of node labels
       #nodeSelector: 
         nodetype: storage
     ```

   * maya-cstor-operator (embedded into maya-apiserver), will be watching for SPCs (type=cstor).
   
   * When maya-cstor-operator detects a new SPC object, it will identify the list of nodes that satisfy the SPC constraints in terms of:
     - availability of disks
     - resources (CPU and RAM) 
     - node selector. 
     This step can result in more than one node satisfying the constraints. Only the number of nodes required (as specified using maxPools) will be picked up. 
     
   * For each of the potential node where the cStor pool can be created, maya-cstor-operator will:
     * create a CStorPool (CR), which will include the following information:
       - unique id
       - name
       - actual disks paths to be used. 
       - redundancy type (stripe or mirror)
       
       ```
       apiVersion: openebs.io/v1alpha1
       kind: CStorPool
       metadata:
         #Name is auto generated using the prefix of StoragePoolClaim name and 
         # nodename hash
         name: pool1-84eb2e
         #Following uid will be auto generated when the CR is created.
         uid: 7b99e406-1260-11e8-aa43-00505684eb2e
         labels:
           "kubernetes.io/hostname": "node-host-label"
           openebs.io/storage-pool-claim: pool1
       spec:
         disks:
           #Disks that are actually used for creating the cstor pool are listed here. 
           diskList: 
             - disk-0c84c169ab2f398b92914f56dad41f81
         poolSpec: 
           #Pool features as passed from the SPC.
           #Defines the type of pool as passed from the SPC. stripe or mirror. 
           poolType: "striped"
           #overProvisioning: false       
       # status is updated by the cstor-pool-mgmt to reflect the current status of the pool. 
       # The valid values are : init, online, offline
       status:
         phase: init
       ```
       
     * create a Deployment YAML file that contains the cStor container and its associated sidecars. The cStor sidecar is passed the “unique id” of the CStorPool (CR). The Deployment YAML will have the node selectors set to pin the containers to the node where the disks are attached.
       ```
       apiVersion: extensions/v1beta1
       kind: Deployment
       metadata:
         name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-cstor
         labels:
           "kubernetes.io/hostname": "node-host-label"
       spec:
         replicas: 1
         selector:
           matchLabels:
             monitoring: volume_exporter_prometheus
             openebs/pool: cstor-pool
             spc: pool1
             sp: spc-7b99e406-1260-11e8-aa43-00505684eb2e
       template:
         metadata:
           labels:
             monitoring: volume_exporter_prometheus
             openebs/pool: cstor-pool
             spc: pool1
             sp: spc-7b99e406-1260-11e8-aa43-00505684eb2e
         spec:
           containers:
           - name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-container
             securityContext:
               privileged: true
             image: openebs/cstor:0.7.0
             volumeMounts:
             - name: device
               mountPath: /dev     
             - name: shared-tmp
               mountPath: /tmp/shared
               mountPropagation: Bidirectional
             resources: {}
           - name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-mgmt
             securityContext:
               privileged: true
             image: openebs/m-cstor-mgmt:0.7.0
             args:
             - --cstor-id
             - 7b99e406-1260-11e8-aa43-00505684eb2e
             command:
             - launch
             ports:
             - containerPort: 9500
               protocol: TCP
             volumeMounts:
             - name: device
               mountPath: /dev     
             - name: shared-tmp
               mountPath: /tmp/shared
               mountPropagation: Bidirectional
             resources: {}
           - name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-exporter
             image: openebs/m-exporter:0.7.0               
             ports:
             - containerPort: 9500
               protocol: TCP
             resources: {}      
           volumes:
           - name: device
             hostPath:
             # directory location on host
             path: /dev
             # this field is optional
             type: Directory
           - name: shared-tmp
             hostPath:
             path: /tmp/spc-7b99e406-1260-11e8-aa43-00505684eb2e
             type: Directory

       ```
       The resources{} will be filled based on the resource (cpu, mem) requests and limits given in the CStorPool spec. If nothing has been provided, Kubernetes will assign default values depending on the node resources. Please refer to the [Kubernetes Resource Limits and Request](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container).
       
     * create SP object
       ```
       apiVersion: openebs.io/v1alpha1
       kind: StoragePool
       metadata:
         name: spc-7b99e406-1260-11e8-aa43-00505684eb2e
         labels:
           "kubernetes.io/hostname": "node-host-label"
       spec:
         type: openebs-cstor
         disks:
           #Disks that are associated with this Pool.
           diskList: ["disk-name1", "disk-name2",...]
           #This can contain the list of Disks that can be used as hot-spares if any of the
           # used disk are errored.
           #diskListSpares: ["disk-namex", "disk-namey",...]
           poolspec: 
             #Defines the type of pool as passed from the SPC. stripe or mirror. 
             poolType: "stripe"
             #Save the resources as sent from SPC. If these values are updated, 
             # the corresponding values on the CStorPool Deployment YAML will have to be updated.
             #resources:
               #cpu: 
               #memory: 
             #Pool features as passed from the SPC.
             #overProvisioning: false       
       ```
   * Admin associates the SPC with a StorageClass
     ```
     apiVersion: storage.k8s.io/v1
     kind: StorageClass
     metadata:
       name: openebs-pool1
     provisioner: openebs.io/provisioner-iscsi
     parameters:
       openebs.io/volume-parameter-group: openebs-cstor-volume-v0.1
     ```
     The VolumeParameterGroup (*openebs-cstor-volume-v0.1*) will define the capacity, storage pool, number of replica's etc. Example:
     ```
     apiVersion: openebs.io/v1alpha1
     kind: VolumeParameterGroup
     metadata:
       name: openebs-cstor-volume-v0.1
     spec:
      policies:
      - name: ReplicaCount
        value: "3"
      - name: StoragePoolClaim
        value: "pool1"
     ...
     ``` 

### Creating Volume using the (cStor) Storage Pools:

   * Admin will create a PVC that is associated to StoragePool (linked by the pool name). 
     ```
     apiVersion: v1
     kind: PersistentVolumeClaim
     metadata:
       name: demo-vol
     spec:
       accessModes:
         - ReadWriteOnce
       resources:
         requests:
           storage: 5G
       storageClassName: openebs-pool1
     ```

   * maya-apiserver will create the OV cStorService (to get the portal ip address) and the OV cStorController Deployment that will contain cstor-ctrl (iscsi target) container and a cstor-ctrl-mgmt side-car. The configuration options for running the cstor-ctrl(iscsi target) will be passed via CStorVolume CR. 
     - The cStorService YAML will have the following details:
       ```
       apiVersion: v1
       kind: Service
       metadata:
         name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-service
         labels:
           pv: pvc-ee171da3-07d5-11e8-a5be-42010a8001be
       spec:
         type: ClusterIP
         ports:
         - name: iscsi
           port: 3260
           protocol: TCP
           targetPort: 3260
         selector:
           openebs/controller: cstor-controller
           pv: pvc-ee171da3-07d5-11e8-a5be-42010a8001be
       ```
       
     - The CStorVolume CR will contain the following details:
       ```
       apiVersion: openebs.io/v1alpha1
       kind: CStorVolume
       metadata:
         name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-volume
       spec:
         # The following details are obtained from cStorService
         cstorControllerIP: <ip-address>
         # The following details are obtained from PVC
         volumeName: demo-vol 
         volumeID: ee171da3-07d5-11e8-a5be-42010a8001be
         capacity: 5G
         # There could be additional details like Unmap etc.
         #  can be obtained via Volume Policies attached to PVC/StorageClass
         # status is updated by the cstor-ctrl-mgmt to reflect the current status of the cStor Volume Controller. 
         # The valid values are : init, online, offline
         status: init
       ```
       The cstor-ctrl-mgmt will get the details from this CR and create the required istgt.conf
       
     - The cStorController YAML will have the following details:
       ```
       apiVersion: extensions/v1beta1
       kind: Deployment
       metadata:
         name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl
         labels:
           pv: pvc-ee171da3-07d5-11e8-a5be-42010a8001be
           openebs/controller: cstor-controller
       spec:
         replicas: 1
         selector:
           matchLabels:
             monitoring: volume_exporter_prometheus
             openebs/controller: cstor-controller
             pv: pvc-ee171da3-07d5-11e8-a5be-42010a8001be
       template:
         metadata:
           labels:
             monitoring: volume_exporter_prometheus
             openebs/controller: cstor-controller
             pv: pvc-ee171da3-07d5-11e8-a5be-42010a8001be
         spec:
           containers:
           - name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl
             image: openebs/cstor:0.7.0               
             ports:
             - containerPort: 3260
               protocol: TCP
             resources: {}
           - name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-mgmt
             image: openebs/m-cstor-mgmt:0.7.0
             args:
             - --volume-cr
             - pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-volume
             command:
             - launch
             ports:
             - containerPort: 9500
               protocol: TCP
             resources: {}
           - name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-exporter
             image: openebs/m-exporter:0.7.0               
             ports:
             - containerPort: 9500
               protocol: TCP
             resources: {}             
       ```
       The resources{} will be filled based on the resource (cpu, mem) requests and limits given in the Volume Policies associated with PVC. If nothing has been provided, Kubernetes will assign default values depending on the node resources. Please refer to the [Kubernetes Resource Limits and Request](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container).

   * maya-apiserver will create the OV CStorVolumeReplicas as follows: 
     * Query for the storage pools matching the given pool name in the PVC and pick up a subset of pools (based on the replica-count of the PVC). 
     * For each replica, maya-apiserver will create - CStorVolumeReplica CR. This CStorVolumeReplica CR will contain:
       - CStorPool (unique id like _7b99e406-1260-11e8-aa43-00505684eb2e_)
       - Unique Name ( an hash will be suffixed to the PVC name like - _pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-rep-9440ab_
       - Required capacity (obtained from PVC or StorageClass or default value)
       - OV cStorService IP (obtained from cStorService _(pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-service)_ CluserIP )
       - status that can have values like pending, read-write, write-only, read-only depending on current state of replica. cstor-pool-mgmt will update the status with the correct value. 
       
       The YAML for the CStorVolumeReplica is as follows:
       ```
       apiVersion: openebs.io/v1alpha1
       kind: CStorVolumeReplica
       metadata:
         name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-rep-9440ab
         uid: ee171da3-07d5-11e8-a5be-42010a8001be
         labels:
           "pool.openebs.io/uid" : 7b99e406-1260-11e8-aa43-00505684eb2e
           "pool.openebs.io/name" : pool1-84eb2e
       spec:
         cstorControllerIP: <ip-address>
         volumeName: demo-vol
         capacity: 5G
       status:
         phase: init
       ```
       
    * The cstor-sidecar (spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-mgmt) running in the CStorPool(7b99e406-1260-11e8-aa43-00505684eb2e), will watch on the CStorVolumeReplica CR for creating the zVol and associating itself with the OV cStorController. The cstor-sidecar will only be allowed to update the CStorVolumeReplica CR, it SHOULD NOT create/delete CStorVolumeReplica CR.


### Design Considerations
The previous two sections have laid out the workflow for a successful pool and volume creation. As part of the workflow, several cases need to be considered like:
- Node hosting the CStorPool is down or not reachable. 
- Node hosting the cStorContainer is running out of resources and cStorContainer is evicted
- Node hosting the CStorPool is restarted
- OpenEBS Volume with replica count = 1 and CStorPool is restarted. 
- OpenEBS Volume with replica count = 3 and case where 1 of the 3 replica nodes, 2 of 3 replica nodes and 3 or 3 replica nodes are down
- All nodes are down and are restarted one by one
- OpenEBS Volume (PVC) is accidentally deleted and user wants to get the data stored in the volume back. 
- OpenEBS Volume data needs to be backed up or restored from a backup. 
- CStorPool has a capacity of 100G and volumes are created adding up to more than 100G
- One of the disks of the CStorPool is showing high latency
- cStorPool has exclusive access to the disks. Can there be some kidn of lock mechnisms implemented?



## Implementation Plan

### Phase 1
- Install/Setup the CRDs used in this design
- Container images for - cstor-pool, cstor-pool-mgmt
- cstor-pool-mgmt sidecar interfaces between observing the CStorPool CR objects and issues - pool create and delete

### Phase 2
- Container images for - cstor-ctrl, cstor-ctrl-mgmt
- cstor-pool-mgmt sidecar interfaces between observing the CStorVolumeReplica CR objects and issues - volume create and delete
- cstor-ctrl-mgmt sidecar interfaces between observing the CStorVolume CR objects and generates the configuration required for cstor-ctrl
- Enhance the maya-exporter to interface with cstor-pool to gather pool level metrics 
- Enhance the maya-exporter to interface with cstor-ctrl to gather volume level metrics 

### Phase 3
- Enhance the maya-apiserver to observe StoragePoolClaim and create CStorPool, StoragePool and associated Kubernetes Deployments and Services
- Enhance the maya-apiserver to create cstor based volumes - which will involve creating CStorVolumeReplica, CStorVolume and associated Kubernetes Deployments and Services.
- Enhance the maya-apiserver to delete cstor based volumes - which will involve deleting CStorVolumeReplica, CStorVolume and associated Kubernetes Deployments and Services.
- Enhance the maya-apiserver to observe StoragePoolClaim and delete CStorPool, StoragePool and associated Kubernetes Deployments and Services
- Grafana Dashboard for showing the cStor Pool status and statistics
- Grafana Dashboard for showing the cStor Volume status and statistics
- Enhance mayactl for fetching pool status and volume status. (volume info and pool info commands)


### Future
- Upgrade (image version) of cstor related containers
- Editing either the Pool or Volume related parameters
- Replacing failed disks using a spare disk from the pool
- Expanding the pool to add more capacity
- Working with disks that have pools created directly on the host - that will conflict with pools from within cStorPool
- Marking a Pool as unavailable or failed due to slow disk or to bring it down for maintenance of the underlying disks
- Reassign the pool from one node to another by shifting the attached disks to a new node
- User should be able to specify required values for the features available on the CStorPool and CStorVolumeReplica like compression, block size, deduplication, etc. This has to be aligned with the VolumePolicies and VolumeUpdatePolicies being implemented in OpenEBS 0.6 and 0.7 respectively.
- Scale up/down the number of replicas associated with a cStor Volume. One of the approach to implement scale-up would be:
  * User will specify the desired number of replicas by passing a VolumeUpdate (a CR associated with a PV/PVC along with parameters that need to modified)
  * maya-apiserver will process with VolumeUpdate request and if the request is to scaled up the replica, a new CStorVolumeReplica CR will be created. The cstor-pool-mgmt will then create the required replica on the pool and will invoke a API on CStorVolume (cstro-ctrl), to register itself as a new replica - passing the self IP address and ID.
  * cstor-ctrl will set the state as new replica, kick-start a resync/rebuild with already existing replicas. CStorVolume will use the IP address passed in the registration to call the API on the CStorVolumeReplica for state transitions and checking status.
  * As part of this implementation, failure cases involving either the source replica or new replica (under sync) should be considered. 
- QoS Policies can be implemented in two phases:
  * Translate the QoS Policies in terms of IOPS/Throughput into resource allocation on the K8s Deployment YAMLs
  * Allow for passing the QoS control parameters to the containers (pool or controller) via the CRs.
  
