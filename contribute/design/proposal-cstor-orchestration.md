# Managing cStor based OpenEBS Volumes. 

This document provides the design details on how the OpenEBS Orchestration Components will create OpenEBS StoragePools and Volumes using OpenEBS cStor storage-engine. 

## Prerequisites
- Container Attached Storage - or using containers to server the storage that is in turn used by the stateful workloads. 
- Knowledge about Kubernetes CRDs 
- Knowledge about Kubernetes concepts like Custom Controllers, initializers and reconcilation loop that wait on objects to move from actual to desired state.
- Familiar with Kubernetes and OpenEBS Storage Concepts:
  * PersistentVolume(PV) and PersistentVolumeClaim(PVC) are standard kubernetes terms used to associate volumes to a given workload. A PVC will be watched by a dynamic provisioner, which will inturn spin-up OpenEBS Volume Containers and create a PV (iSCSI) to be used by the workload.
  * PersistentDisks(PDs) and PersistentDiskClaims(PDCs) are used to represent and identify the storage (a disk) attached to a Kubernetes Node. PersistentDiskClaims are created by the User and maya-nodebot will use that information to discover disks matching the criteria mentioned in PDC to create the PDs. It is also possible that the User will directly create PD representing a storage attached to a node. Each PD will be represented by a cluster wide unique identifier like -- rs://host:nodea/device:/dev/disk-by-id/avcd-121312-hfjgdf. (TODO - Provide the link to the design documented here)
  * StoragePool(SP) and StoragePoolClaim(SPC) are used to respresent and identify a pool of storage that is created using one more PDs. Each StoragPool can be used to then serve one or more OpenEBS Volume Replicas. The StoragePools can be of different types depending on how the underlying disks/storage are aggregated and how the pool is exposed. Till 0.6, OpenEBS supported storage pools of type (filesystem), which where basically either a hostDirectory or ext4 mount of a single block disk. From 0.7, OpenEBS will support creation of storage pools that expose blocks. These block type pools are implemented using cStor containers. 


## Design

The design is split into two aspects - creation of storage pools using cStor Engine and creating OpenEBS Volumes using the cStor engine. This implementation makes use of CRDs to storage the disk, pool and volume related information. As part of the openebs installation, the followind CRDs are loaded:
- PeristentDisk and PersistentDiskClaim
- StoragePool and StoragePoolClaim
- cStorPool
- cStorReplica
(TODO: @ganesh) Fill in the YAMLs for the above CRDs. 

### Creating cStor StoragePools:

   * Admin will create StoragePoolClaim(SPC) with type=block and the SPC will contains information like:
     ```
     apiVersion: openebs.io/v1alpha1
     kind: StoragePoolClaim
     metadata:
       name: pool1
       type: block
     spec:
       scope: Cluster
       disks:
         #Disks here refer to the PDs or PDCs. With PDC/PDs, the disks could refer to local disks or 
         # disks from external storage providers like EBS, GPD or SAN.
         pdc-list: ["pdc-name1", "pdc-name2",...]
         #pd-list: ["pd-name1", "pd-name2",...]
       #Admin can specify the maximum number of cStor pools to be created with this name. 
       #max-pools: 3 (default no-limit)
       #Admin can specify the exact nodes or a list of nodes where the pool has to be created. 
       #nodeSelector: [ "host-label1", "host-label2",..]
       #poolspec: 
         #Define the type of pool to be created. Default is stripe. The other supported type is "mirror"
         #type: "stripe"
         #Use the following to enforce the limits on CPU and RAM to be allocated/used by the cStor Pool containers.
         #resources:
           #cpu: 
           #memory: 
         #Pools can be configured with different features. An example feature could be to enable/disable thin provisioning.
         #thinprovisioning: true
     ```

   * maya-cstor-operator (could be embedded into maya-apiserver), will be watching for SPCs (type=block).
   
   * When maya-cstor-operator detects a new SPC object, it will identify the list of nodes that satisfy the SPC constraints in terms of:
     - availability of disks
     - resources (CPU and RAM) 
     - nodes selector. 
     This step can result in more than one node satisfying the constraints. Only the number of nodes required (as specified using max-pools) will be picked up. 
     
   * For each of the potentional node where the cStor pool can be created, maya-cstor-operator will:
     * create a cStorPool (CRD), which will include the following information:
       - unique id
       - name
       - actual disks paths to be used. 
       - raid type
       
       ```
       apiVersion: openebs.io/v1alpha1
       kind: cStorPool
       metadata:
         name: pool1
         guid: 7b99e406-1260-11e8-aa43-00505684eb2e
         node: node-host-label
       spec:
         disks:
           #Disks that are actually used for creating the cstor pool are listed here. 
           #pd-list: ["pd-name1", "pd-name2",...]
       poolspec: 
         #Defines the type of pool as passed from the SPC. stripe or mirror. 
         type: "stripe"
         #Pool features as passed from the SPC.
         #thinprovisioning: true       
       ```
       
     * create a Deployment YAML file that contains the cStor container and its associated sidecars. The cStor-Sidecar is passed the “unique id” of the cStorPool (CRD)
       ```
       apiVersion: extensions/v1beta1
       kind: Deployment
       metadata:
         name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-cstor
         node: node-host-label
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
             spc: spc-7b99e406-1260-11e8-aa43-00505684eb2e
         spec:
           containers:
           - name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-container
             image: openebs/cstor:0.7.0
             resources: {}
           - name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-mgmt
             image: openebs/m-cstor-mgmt:0.7.0
             resources: {}
             args:
             - --cstor-id
             - 7b99e406-1260-11e8-aa43-00505684eb2e
             command:
             - launch
           - name: spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-exporter
             image: openebs/m-exporter:0.7.0               
             ports:
             - containerPort: 9500
               protocol: TCP
             resources: {}      
       ```
       The resources{} will be filled based on the resource (cpu, mem) limits given in the cStorPool spec. If nothing has been provided, these will be left as default. 
       
     * create SP object
       ```
       apiVersion: openebs.io/v1alpha1
       kind: StoragePool
       metadata:
         name: spc-7b99e406-1260-11e8-aa43-00505684eb2e
         type: block
         node: node-host-label
       spec:
         scope: Cluster
         disks:
           #PDCs as mentioned in the SPC. 
           pdc-list: ["pdc-name1", "pdc-name2",...]
           #PDs that are associated with this Pool.
           pd-list: ["pd-name1", "pd-name2",...]
           #This can contain the list of PDs that can be used as hot-spares if any of the
           # used disk are errored.
           #pd-list-spares: ["pd-namex", "pd-namey",...]
         poolspec: 
           #Defines the type of pool as passed from the SPC. stripe or mirror. 
           type: "stripe"
           #Save the resources as sent from SPC. If these values are updated, 
           # the corresponding values on the cStorPool Deployment YAML will have to be updated.
           #resources:
             #cpu: 
             #memory: 
           #Pool features as passed from the SPC.
           #thinprovisioning: true       
       ```
   * Admin associates the SPC with a StorageClass
     ```
     apiVersion: storage.k8s.io/v1
     kind: StorageClass
     metadata:
       name: openebs-pool1
     provisioner: openebs.io/provisioner-iscsi
     parameters:
       openebs.io/storage-pool-claim: pool1
     ```

2. Creating Volume using the (cStor) Storage Pools:

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

   * maya-apiserver will create the OV cStorService (to get the portal ip address) and the OV cStorController. The OV cStorController will be passed a ConfigMap - cStorControllerConfig (that will be mounted into the OV cStorController). 
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
       
     - The cStorControllerConfigMap will contain the following details:
       - portal ip - obtained from the cStorService ClusterIP
       - volume id - will be pv id (like ee171da3-07d5-11e8-a5be-42010a8001be), used from the pvc name. 
       - volume name - will also be the pv id. _(TODO Or should this be pvc name like demo-vol. Verify this with @gila)_
       - config-map name - pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-config-map
       - _(TODO Fill in the exact configmap. @payes)_
       
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
             volumeMounts:
             - name: cstor-ctrl-istgt-config-map
               mountPath: /etc/istgt/istgt.conf
             resources: {}
           - name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-exporter
             image: openebs/m-exporter:0.7.0               
             ports:
             - containerPort: 9500
               protocol: TCP
             resources: {}             
           volumes:
           - name: cstor-ctrl-istgt-config-map
             configMap:
               defaultMode: 420
               name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-config-map  
       ```
       The resources{} will be filled based on the volume policy rules that determine the resource (cpu, mem) limits to be associated with a given volume.

   * maya-apiserver will create the OV cStorReplicas as follows: 
     * Query for the storage pools matching the given pool name in the PVC and pick up a subset of pools (based on the replica-count of the PVC). 
     * For each replica, maya-apiserver will create - cStorReplica CRD. This cStorReplica CRD will contain:
       - cStorPool (unique id like _7b99e406-1260-11e8-aa43-00505684eb2e_)
       - Unique Name ( an hash will be suffixed to the PVC name like - _pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-rep-9440ab_
       - Required capacity (obtained from PVC or StorageClass or default value)
       - OV cStorService IP (obtained from cStorService _(pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-ctrl-service)_ CluserIP )
       
       The YAML for the cStorReplica is as follows:
       ```
       apiVersion: openebs.io/v1alpha1
       kind: cStorReplica
       metadata:
         name: pvc-ee171da3-07d5-11e8-a5be-42010a8001be-cstor-rep-9440ab
         poolguid: 7b99e406-1260-11e8-aa43-00505684eb2e
       spec:
         cstor-controller-ip: <ip-address>
         capacity: 5G
       ```
       
    * The cstor-sidecar (spc-7b99e406-1260-11e8-aa43-00505684eb2e-pool-mgmt) running in the cStorPool(7b99e406-1260-11e8-aa43-00505684eb2e), will watch on the cStorReplica CRD for creating the zVol and associating itself with the OV cStorController. The cstor-sidecar will only be allowed to update the cStorReplica CRD, it SHOULD NOT create/delete cStorReplica CRD.


### Design Considerations
The previous two sections have laid out the workflow for a successful pool and volume creation. As part of the workflow, several cases need to be considered like:
- Node hosting the cStorPool is down or not reachable. 
- Node hosting the cStorContainer is running out of resources and cStorContainer is evicted
- Node hosting the cStorPool is restarted
- OpenEBS Volume with replica count = 1 and cStorPool is restarted. 
- OpenEBS Volume with replica count = 3 and case where 1 of the 3 replica nodes, 2 of 3 replica nodes and 3 or 3 replica nodes are down
- All nodes are down and are restarted one by one
- OpenEBS Volume (PVC) is accidentally deleted and user wants to get the data stored in the volume back. 
- OpenEBS Volume data needs to be backed up or restored from a backup. 
- cStorPool has a capacity of 100G and volumes are created adding up to more than 100G
- One of the disks of the cStorPool is showing high latency
- 







 
