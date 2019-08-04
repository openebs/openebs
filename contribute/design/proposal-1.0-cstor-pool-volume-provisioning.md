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
    case of OpenEBS, provisioning a PV involves launching OpenEBS 
    Volume Containers (aka iSCSI Target Service) and creating a 
    in-tree iSCSI PV.
  * BlockDevices(BDs) and BlockDeviceClaims(BDCs) are Kubernetes 
    custom resources, used to represent and identify the storage 
    (a disk) attached to a Kubernetes Node. BlockDeviceClaims are 
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
  cStor Target receives the IO from the application and it interacts
  with one or more cStor Pools to serve the IO. A single cStor Volume
  comprises of a cStor target and the logical replicas that are 
  provisioned on a set of cStor Pools. The replicas are called as 
  cStor Volume Replicas. The cStor Pool and Replica functionality 
  is containerized and is available in `openebs/cstor-pool`. 
  The target functionality is available under `openebs/cstor-istgt`.
  Each of these expose a CLI that can be accessed via UXD.

## Design Constraints / Considerations
- The dynamic provisioner will be implemented using the 
  Kubernetes-incubator/external-provisioner, which is already 
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
  to create uZFS Volumes (aka zvol) to be associated with cStor Volume.
- cstor-volume-mgmt ( deployed as a side-car to the cStor Target Pod
  will help with reading the target parameters and setting them on
  cStor Target.)

Also, this workflow assumes that BlockDevice and BlockDevice claims
are available. 

### Workflow for creating cStor Pools:

   * Admin will create StoragePoolClaim(SPC) with `cas-type=cstor`.
     The SPC will contain information regarding the blockdevices
     to be used for creating cstor pools. A SPC is analogous to a 
     Deployment that results in creating one or more pods. 
     A sample SPC is as follows:
     ```
     #Use the following YAMLs to create a cStor Storage Pool.
     apiVersion: openebs.io/v1alpha1
     kind: StoragePoolClaim
     metadata:
       name: cstor-disk-pool
       annotations:
         cas.openebs.io/config: |
           # the resource request and limits on the 
           # pool deployments can be passed via this configuration
           # the format is similar to Kubernetes type: value. 
           - name: PoolResourceRequests
             value: |-
                 memory: 2Gi
           - name: PoolResourceLimits
             value: |-
                 memory: 4Gi
     spec:
       name: cstor-disk-pool
       type: disk
       poolSpec:
         # On each of the resulting cstor pool, the block devices
         # can be either configured to use striped or have some 
         # redundancy like mirror or raidz1 (those supported by ZFS)
         poolType: striped
       blockDevices:
         blockDeviceList:
         # List the devices from different nodes in the cluster. 
         # cstor pools will be created on nodes where the 
         # block devices reside. The list of block devices can 
         # be retrieved using `kubectl get bd -n openebs --show-labels`
         - blockdevice-936911c5c9b0218ed59e64009cc83c8f
         - blockdevice-77f834edba45b03318d9de5b79af0734
         - blockdevice-1c10eb1bb14c94f02a00373f2fa09b93
     ---
     ```
     Note: It is possible to let cstor-operator automatically select the 
     block devices by replacing the `blockDevices` section with
     `maxPool: 3` as shown [here](https://github.com/openebs/openebs/blob/master/k8s/sample-pv-yamls/spc-cstor-disk-type.yaml).
     The support for automatic selection is experimental and will 
     undergo changes in the upcoming releases. To keep clear separation
     between the auto and manual mode of provisioning, the auto mode
     might be represented by a totally different CRD. 
     
   * maya-cstor-operator (embedded into maya-apiserver), will be 
     watching for SPCs (type=cstor).
   
   * When maya-cstor-operator detects a new SPC object, it will 
     identify the list of nodes that satisfy the SPC constraints 
     in terms of availability of disks/block devices.
     
   * For each of the potential node where the cStor pool can be created, 
     maya-cstor-operator will:
     * create a CStorPool (CR), which will include the following information:
       - unique id
       - name
       - actual disks paths to be used. 
       - redundancy type (stripe or mirror)
       
       ```
       apiVersion: openebs.io/v1alpha1
       kind: CStorPool
       metadata:
         labels:
           kubernetes.io/hostname: gke-kmova-helm-default-pool-20ff78e2-w4q3
           openebs.io/storage-pool-claim: cstor-disk-pool
         #Name is auto generated using the prefix of StoragePoolClaim name and 
         # nodename hash
         name: cstor-disk-pool-2i3d
         ownerReferences:
         - apiVersion: openebs.io/v1alpha1
           blockOwnerDeletion: true
           controller: true
           kind: StoragePoolClaim
           name: cstor-disk-pool
           uid: 594b983b-b6c1-11e9-93aa-42010a800035
         uid: 598ad94c-b6c1-11e9-93aa-42010a800035
       spec:
         #Disks that are actually used for creating the cstor pool are listed here. 
         group:
         - blockDevice:
           - deviceID: /dev/disk/by-id/scsi-0Google_EphemeralDisk_local-ssd-1
             inUseByPool: true
             name: blockdevice-22f5154b7fe508f65a72fea09311d29e
         poolSpec:
           #Pool features as passed from the SPC or default values.
           cacheFile: /tmp/pool1.cache
           overProvisioning: false
           poolType: striped
       # status is updated by the cstor-pool-mgmt to reflect the 
       # current status of the pool. 
       # The valid values are : init, online, offline
       status:
         phase: init
       ```
       
     * create a Deployment YAML file that contains the cStor container 
       and its associated sidecars. The cStor sidecar is passed the 
       “unique id” of the CStorPool (CR). The Deployment YAML will 
       have the node selectors set to pin the containers to the node 
       where the disks are attached.
       ```
       apiVersion: extensions/v1beta1
       kind: Deployment
       metadata:
         labels:
           openebs.io/cstor-pool: cstor-disk-pool-2i3d
           openebs.io/storage-pool-claim: cstor-disk-pool
         name: cstor-disk-pool-2i3d
         namespace: openebs
       spec:
         replicas: 1
         selector:
           matchLabels:
             app: cstor-pool
         strategy:
           type: Recreate
         template:
           metadata:
             labels:
               app: cstor-pool
           spec:
             nodeSelector:
               kubernetes.io/hostname: gke-kmova-helm-default-pool-20ff78e2-w4q3
             containers:
             - name: cstor-pool
               image: quay.io/openebs/cstor-pool:1.1.0
               imagePullPolicy: IfNotPresent
               env:
               - name: OPENEBS_IO_CSTOR_ID
                 value: 598ad94c-b6c1-11e9-93aa-42010a800035
               ports:
               - containerPort: 12000
                 protocol: TCP
               - containerPort: 3233
                 protocol: TCP
               - containerPort: 3232
                 protocol: TCP
               resources:
                 limits:
                   memory: 4Gi
                 requests:
                   memory: 2Gi
               securityContext:
                 privileged: true
               volumeMounts:
               - mountPath: /dev
                 name: device
               - mountPath: /tmp
                 name: tmp
               - mountPath: /var/openebs/sparse
                 name: sparse
               - mountPath: /run/udev
                 name: udev
             - name: cstor-pool-mgmt
               image: quay.io/openebs/cstor-pool-mgmt:1.1.0
               imagePullPolicy: IfNotPresent
               env:
               - name: OPENEBS_IO_CSTOR_ID
                 value: 598ad94c-b6c1-11e9-93aa-42010a800035
               resources: {}
               securityContext:
                 privileged: true
                 procMount: Default
               volumeMounts:
               - mountPath: /dev
                 name: device
               - mountPath: /tmp
                 name: tmp
               - mountPath: /var/openebs/sparse
                 name: sparse
               - mountPath: /run/udev
                 name: udev
             - name: maya-exporter
               image: quay.io/openebs/m-exporter:1.1.0
               imagePullPolicy: IfNotPresent
               command:
               - maya-exporter
               args:
               - -e=pool
               ports:
               - containerPort: 9500
                 protocol: TCP
               resources: {}
               securityContext:
                 privileged: true
                 procMount: Default
               volumeMounts:
               - mountPath: /dev
                 name: device
               - mountPath: /tmp
                 name: tmp
               - mountPath: /var/openebs/sparse
                 name: sparse
               - mountPath: /run/udev
                 name: udev
             volumes:
             - hostPath:
                 path: /dev
                 type: Directory
               name: device
             - hostPath:
                 path: /var/openebs/sparse/shared-cstor-disk-pool
                 type: DirectoryOrCreate
               name: tmp
             - hostPath:
                 path: /var/openebs/sparse
                 type: DirectoryOrCreate
               name: sparse
             - hostPath:
                 path: /run/udev
                 type: Directory
               name: udev
       ```
       Above is a snipped version to indicate the main aspects of the 
       deployment. A key aspect is that resources{} will be filled 
       based on the resource (cpu, mem) requests and limits given in 
       the SPC spec. 

       If nothing has been provided, Kubernetes will assign default
       values depending on the node resources. Please refer to the
       [Kubernetes Resource Limits and Request](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container).
       
   * Admin associates the SPC with a StorageClass
     ```
     apiVersion: storage.k8s.io/v1
     kind: StorageClass
     metadata:
       name: openebs-cstor-disk
       annotations:
         openebs.io/cas-type: cstor
         cas.openebs.io/config: |
           - name: StoragePoolClaim
             value: "cstor-disk-pool"
           - name: ReplicaCount
             value: "3"
     provisioner: openebs.io/provisioner-iscsi
     ``` 

### Creating Volume using the (cStor) Storage Pools:

   * Admin will create a PVC that is associated to above CStor Pools
    (linked by the pool name). 
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
       storageClassName: openebs-cstor-disk
     ```

   * openebs-provisioner receives the request for volume provisioning
     and passes on the request to maya-apsierver. 

   * maya-apiserver will create target service corresponding to the 
     new PVC (to get the portal ip address) and a cStor Target Deployment 
     that will contain cstor-target (iscsi target) container. This 
     target deployment will be attached with cstor-volume-mgmt 
     and metrics exporter side-cars. The configuration options for 
     running the cstor-ctrl(iscsi target) will be passed via 
     CStorVolume CR. 

     - The Kubernetes Service YAML for Target Service will have the 
       following details:
       ```
       apiVersion: v1
       kind: Service
       metadata:
         name: pvc-42c47193-b6c8-11e9-93aa-42010a800035
       spec:
         ports:
         - name: cstor-iscsi
           port: 3260
           protocol: TCP
           targetPort: 3260
         << other ports for management and metrics >>
         selector:
           openebs.io/persistent-volume: pvc-42c47193-b6c8-11e9-93aa-42010a800035
           openebs.io/target: cstor-target
         type: ClusterIP
       ```
       
     - The CStorVolume CR will contain the following details:
       ```
       apiVersion: openebs.io/v1alpha1
       kind: CStorVolume
       metadata:
         labels:
           openebs.io/persistent-volume: pvc-42c47193-b6c8-11e9-93aa-42010a800035
         # Persistent volume name.
         name: pvc-42c47193-b6c8-11e9-93aa-42010a800035
       spec:
         capacity: 5G
         # derived from the replica count specified in StorageClass
         replicationFactor: 3
         # This is either 1 for single replica volumes or 2 for replica > 1
         consistencyFactor: 2
         # The following details are obtained from cStorService
         targetIP: 10.47.243.9
         targetPort: "3260"
       ```

       The cstor-volume-mgmt will get the details from this CR and creates
       the required iSCSI Target configuration
       
     - The cStorTarget Deployment YAML will have the following details:
       ```
       apiVersion: extensions/v1beta1
       kind: Deployment
       metadata:
         name: pvc-42c47193-b6c8-11e9-93aa-42010a800035-target
       spec:
         replicas: 1
         selector:
           matchLabels:
             app: cstor-volume-manager
             openebs.io/persistent-volume: pvc-42c47193-b6c8-11e9-93aa-42010a800035
             openebs.io/target: cstor-target
         strategy:
           type: Recreate
         template:
           metadata:
             labels:
               app: cstor-volume-manager
               openebs.io/persistent-volume: pvc-42c47193-b6c8-11e9-93aa-42010a800035
               openebs.io/target: cstor-target
           spec:
             containers:
             - name: cstor-istgt
               image: quay.io/openebs/cstor-istgt:1.1.0
               imagePullPolicy: IfNotPresent
               ports:
               - containerPort: 3260
                 protocol: TCP
               resources: {}
               securityContext:
                 privileged: true
                 procMount: Default
               volumeMounts:
               - mountPath: /var/run
                 name: sockfile
               - mountPath: /usr/local/etc/istgt
                 name: conf
               - mountPath: /tmp
                 mountPropagation: Bidirectional
                 name: tmp
             - name: maya-volume-exporter
               image: quay.io/openebs/m-exporter:1.1.0
               imagePullPolicy: IfNotPresent
               args:
               - -e=cstor
               command:
               - maya-exporter
               ports:
               - containerPort: 9500
                 protocol: TCP
               resources: {}
               volumeMounts:
               - mountPath: /var/run
                 name: sockfile
               - mountPath: /usr/local/etc/istgt
                 name: conf
             - name: cstor-volume-mgmt
               image: quay.io/openebs/cstor-volume-mgmt:1.1.0
               imagePullPolicy: IfNotPresent
               env:
               - name: OPENEBS_IO_CSTOR_VOLUME_ID
                 value: 42e222c8-b6c8-11e9-93aa-42010a800035
               ports:
               - containerPort: 80
                 protocol: TCP
               resources: {}
               securityContext:
                 privileged: true
                 procMount: Default
              volumeMounts:
              - mountPath: /var/run
                name: sockfile
              - mountPath: /usr/local/etc/istgt
                name: conf
              - mountPath: /tmp
                mountPropagation: Bidirectional
                name: tmp
            volumes:
            - emptyDir: {}
              name: sockfile
            - emptyDir: {}
              name: conf
            - hostPath:
                path: /var/openebs/sparse/shared-pvc-42c47193-b6c8-11e9-93aa-42010a800035-target
                type: DirectoryOrCreate
              name: tmp
       ```
       The resources{} will be filled based on the resource (cpu, mem) 
       requests and limits given in the Storage Policies associated 
       with PVC. If nothing has been provided, Kubernetes will assign 
       default values depending on the node resources. Please refer to 
       the [Kubernetes Resource Limits and Request](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container).

   * maya-apiserver will then create the CStorVolumeReplicas as follows: 
     * Query for the cStor Storage Pools patching the SPC provided 
       in the StorageClass. Pickup a subset of pools based on the 
       replica-count of the PVC. 
     * For each replica, maya-apiserver will create - CStorVolumeReplica CR. 
       This CStorVolumeReplica CR will contain:
       - CStorPool  on which the Replica needs to be provisioned
       - Unique Name (same in all replicas for a given PVC)
       - Required capacity (obtained from PVC or StorageClass or default value)
       - cStor Target Service IP 
       
       The YAML for the CStorVolumeReplica is as follows:
       ```
       apiVersion: openebs.io/v1alpha1
       kind: CStorVolumeReplica
       metadata:
         labels:
           cstorpool.openebs.io/name: cstor-disk-pool-2i3d
           cstorpool.openebs.io/uid: 598ad94c-b6c1-11e9-93aa-42010a800035
           cstorvolume.openebs.io/name: pvc-42c47193-b6c8-11e9-93aa-42010a800035
           openebs.io/persistent-volume: pvc-42c47193-b6c8-11e9-93aa-42010a800035
         name: pvc-42c47193-b6c8-11e9-93aa-42010a800035-cstor-manual-pool-2i3d
       spec:
         capacity: 5G
         targetIP: 10.47.243.9
       status:
         phase: Init
       ```
       
    * The cstor-sidecar (cstor-pool-mgmt) running in the CStorPool(cstor-disk-pool-2i3d), 
      will watch on the CStorVolumeReplica CR for creating the replica and 
      associating itself with the cStor Target. The cstor-sidecar will 
      only be allowed to update the CStorVolumeReplica CR, it 
      SHOULD NOT create/delete CStorVolumeReplica CR.


### Design Considerations
The previous two sections have laid out the workflow for a successful 
pool and volume creation. As part of the workflow, several cases 
need to be considered like:
- Node hosting the CStorPool is down or not reachable. 
- Node hosting the cStorContainer is running out of resources and cStorContainer is evicted
- Node hosting the CStorPool is restarted
- OpenEBS Volume with replica count = 1 and CStorPool is restarted. 
- OpenEBS Volume with replica count = 3 and cases 
  where 1 of the 3 replica nodes, 2 of 3 replica nodes and 3 or 3 replica nodes are down
- All nodes are down and are restarted one by one
- OpenEBS Volume (PVC) is accidentally deleted and user wants to 
  get the data stored in the volume back. 
- OpenEBS Volume data needs to be backed up or restored from a backup. 
- CStorPool has a capacity of 100G and volumes are created adding up 
  to more than 100G
- One of the disks of the CStorPool is showing high latency
- cStorPool has exclusive access to the disks. 
  Can there be some kind of lock mechanisms implemented?


## Implementation Plan

### Phase 1 ( Part of OpenEBS 1.0) 
- Install/Setup the CRDs used in this design
- Container images for - cstor-pool, cstor-istgt, cstor-pool-mgmt, cstor-volume-mgmt
- cstor-pool-mgmt sidecar interfaces between observing the CStorPool CR 
  objects and issues - pool create and delete
- cstor-volume-mgmt sidecar interfaces between observing the CStorVolume 
  CR objects and generates the configuration required for cstor-ctrl
- Usage of NDM to manage access to the underlying block devices. Issue
  claims on devices before using them. 
- Enhance the maya-exporter to export cstor volume and pool metrics
- Enhance openebs-provisioner and maya-apiserver to implement the 
  workflow specified above for creation of pools and volumes. 
- Enhance mayactl to display the details of cstor pools and volumes.
- Support for upgrading cstor pools and volumes with newer versions.

### Phase 2 ( Part of OpenEBS 1.0) 
- Support for Snapshot and Clones
- Support for Backup and Restore

### Future (Implemented post 1.0)
- Expanding the pool to add more capacity
- Replacing failed disks using a spare disk from the pool
- Editing either the Pool or Volume related parameters
- Marking a Pool as unavailable or failed due to slow disk or to bring 
  it down for maintenance of the underlying disks
- Reassign the pool from one node to another by shifting the 
  attached disks to a new node
- User should be able to specify required values for the features 
  available on the CStorPool and CStorVolumeReplica like compression, 
  block size, de-duplication, etc. 
- Scale up/down the number of replicas associated with a cStor Volume. 
- Performance Testing and Tunables
