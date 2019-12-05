<h1><center>CSPC-Operator Design Document</h1>

## Authors:

### Ashutosh Kumar ( ashutosh.kumar@mayadata.io )
### Vishnu Itta ( vitta@mayadata.io )
### Kiran Mova ( kiran.mova@mayadata.io )

## Abstract

CStor data engine was made available in OpenEBS from the 0.7.0 version. StoragePoolClaim (SPC) was used to provision cStor Pools. A user was allowed only to change SPC to add new pools on new nodes. Handling the day 2 operations like pool expansion and replacing block devices and so forth were not intuitive via the current SPC schema. This document proposes the introduction of a new schema for cStor pool provisioning and also refactors the code to make cStor a completely pluggable engine into OpenEBS. The new schema also makes it easy to perform day 2 operations on cStor pools.

## Introduction

Users that have deployed cStor have the following feedback:
* The name StoragePoolClaim (SPC) is not intuitive.

* Single SPC CR is handling multiple provisioning modes for cStor pool i.e auto and manual provisioning.

* The topology information on the CR is not apparent.

* CStor-Operator that reconciles on SPC CR to provision, de-provision and carry the operations on cStor pools is also embedded in maya-apiserver which is against the microservice model.

* Additionally, SPC and other CRs used in cStor pool provisioning are at cluster namespace which stops or comes with challenges for multiple teams to use OpenEBS on the same cluster.

Please refer to the Appendix section (end of the doc) to gain more background on SPC and its limitations.

## Objectives

At a high level, the objective of this document is to introduce:
* Two new CRs i.e. CStorPoolcluster(CSPC) and CStorPoolInstance(CSPI) to facilitate pool provisioning which addresses the above-mentioned concerns related to naming, topology, multiple behaviors. This is analogous to StoragePoolClaim and CStorPool CRs respectively but with schema changes. CSPC and CSPI will be at namespace scope.

* New cStor pool provisioner known as ‘cspc-operator’ which will run as deployment and manages the CSPC. Also, introduces “cspi-mgmt” deployment that watches for CSPI and is analogous to “cstor-pool-mgmt” in SPC case.

**NOTES:**
* This design has also taken into account the backward compatibility so users running cStor with SPC will not be impacted. CSPC can be experimented with and the migration process to convert SPC to CSPC will be provided.

* The new schema also takes into account the ease with which cStor pool day 2 operations can be performed.

* Volume provisioning on CSPC provisioned pools will be supported only via CSI.

## Design Details

### CSPC Schema
Following is the proposed CSPC schema in go struct:
``` go
// CStorPoolCluster describes a CStorPoolCluster custom resource.
type CStorPoolCluster struct {
  metav1.TypeMeta   `json:",inline"`
  metav1.ObjectMeta `json:"metadata,omitempty"`
  Spec              CStorPoolClusterSpec   `json:"spec"`
  Status            CStorPoolClusterStatus `json:"status"`
}

// CStorPoolClusterSpec is the spec for a CStorPoolClusterSpec resource
type CStorPoolClusterSpec struct {
  // Pools is the spec for pools for various nodes
  // where it should be created.
  Pools []PoolSpec `json:"pools"`
}

//PoolSpec is the spec for a pool on a node where it should be created.
type PoolSpec struct {
  // NodeSelector is the labels that will be used to select
  // a node for pool provisioning.
  // Required field
  NodeSelector map[string]string `json:"nodeSelector"`
  // RaidConfig is the raid group configuration for the given pool.
  RaidGroups []RaidGroup `json:"raidGroups"`
  // PoolConfig is the default pool config that applies to the
  // pool on node.
  PoolConfig PoolConfig `json:"poolConfig"`
}

// PoolConfig is the default pool config that applies to the
// pool on node.
type PoolConfig struct {
  // Cachefile is used for faster pool imports
  // optional -- if not specified or left empty cache file is not
  // used.
  CacheFile string `json:"cacheFile"`
  // DefaultRaidGroupType is the default raid type which applies
  // to all the pools if raid type is not specified there
  // Compulsory field if any raidGroup is not given Type
  DefaultRaidGroupType string `json:"defaultRaidGroupType"`

  // OverProvisioning to enable over provisioning
  // Optional -- defaults to false
  OverProvisioning bool `json:"overProvisioning"`
  // Compression to enable compression
  // Optional -- defaults to off
  // Possible values : lz, off
  Compression string `json:"compression"`
}

// RaidGroup contains the details of a raid group for the pool
type RaidGroup struct {
  // Type is the raid group type
  // Supported values are: stripe, mirror, raidz and raidz2

  // stripe -- stripe is a raid group which divides data into blocks and
  // spreads the data blocks across multiple block devices.

  // mirror -- mirror is a raid group which does redundancy
  // across multiple block devices.

  // raidz -- RAID-Z is a data/parity distribution scheme like RAID-5, but uses dynamic stripe width.
  // radiz2 -- TODO
  // Optional -- defaults to `defaultRaidGroupType` present in `PoolConfig`
  Type string `json:"type"`
  // IsWriteCache is to enable this group as a write cache.
  IsWriteCache bool `json:"isWriteCache"`
  // IsSpare is to declare this group as spare which will be
  // part of the pool that can be used if some block devices
  // fail.
  IsSpare bool `json:"isSpare"`
  // IsReadCache is to enable this group as read cache.
  IsReadCache bool `json:"isReadCache"`
  // BlockDevices contains a list of block devices that
  // constitute this raid group.
  BlockDevices []CStorPoolClusterBlockDevice `json:"blockDevices"`
}

// CStorPoolClusterBlockDevice contains the details of block devices that
// constitutes a raid group.
type CStorPoolClusterBlockDevice struct {
  // BlockDeviceName is the name of the block device.
  BlockDeviceName string `json:"blockDeviceName"`
  // Capacity is the capacity of the block device.
  // It is system generated
  Capacity string `json:"capacity"`
  // DevLink is the dev link for block devices
  DevLink string `json:"devLink"`
}


// CStorPoolClusterStatus is for handling status of pool.
type CStorPoolClusterStatus struct {
  Phase    string                `json:"phase"`
  Capacity CStorPoolCapacityAttr `json:"capacity"`
}


// CStorPoolClusterList is a list of CStorPoolCluster resources
type CStorPoolClusterList struct {
  metav1.TypeMeta `json:",inline"`
  metav1.ListMeta `json:"metadata"`

  Items []CStorPoolCluster `json:"items"`
}

```

### CSPI Schema
Following is the proposed CSPI schema in go struct:

``` go
// CStorPoolInstance describes a cstor pool instance resource created as a custom resource.
type CStorPoolInstance struct {
  metav1.TypeMeta   `json:",inline"`
  metav1.ObjectMeta `json:"metadata,omitempty"`

  Spec   CStorPoolInstanceSpec `json:"spec"`
  Status CStorPoolStatus       `json:"status"`
}

// CStorPoolInstanceSpec is the spec listing fields for a CStorPoolInstance resource.
type CStorPoolInstanceSpec struct {
  // HostName is the name of Kubernetes node where the pool
  // should be created.
  HostName string `json:"hostName"`
  // NodeSelector is the labels that will be used to select
  // a node for pool provisioning.
  // Required field
  NodeSelector map[string]string `json:"nodeSelector"`
  // PoolConfig is the default pool config that applies to the
  // pool on node.
  PoolConfig PoolConfig `json:"poolConfig"`
  // RaidGroups is the group containing block devices
  RaidGroups []RaidGroup `json:"raidGroup"`
}




// CStorPoolInstanceList is a list of CStorPoolInstance resources
type CStorPoolInstanceList struct {
  metav1.TypeMeta `json:",inline"`
  metav1.ListMeta `json:"metadata"`

  Items []CStorPoolInstance `json:"items"`
}
```

## Pool Provisioning: Workflow

A user puts the cStor pool intent in a CSPC YAML and applies it to provision cStor pools.

* When a CSPC is created, ‘k’ number of CStorPoolInstance(CSPI) CR and CStorPool deployment(known as ‘cspi-mgmt’) is created. CStorPool deployment watches (is controller) for CSPI CR and there is one to one mapping between the CSPI CR and the ‘cspi-mgmt’ deployment. This number ‘k’ depends on the length of the “spec.pools” field on CSPC specification.


* For a given CSPC the number ‘k’ described above is known as the desired pool count. Also, the number of existing ‘CSPI’ CRs is known as the current pool count. The system will always try to converge the current pool count to the desired pool count by creating a required number of CSPI CRs.


* For every CSPI CR, a corresponding ‘cspi-mgmt’ deployment will always exist. If due to some reason, a ‘cspi-mgmt’ of a corresponding CSPI CR is deleted, a new ‘cspi-mgmt’ for the same CR will come up again.


* Similarly, if a CSPI of a given CSPC is deleted, its corresponding ‘cspi-mgmt’ will be deleted too but again a new CSPI and its corresponding ‘cspi-mgmt’ will come up again. The parent to child(left to right) structure of the resources are shown as :
```ascii
          |---> CSPI ---> cspi-mgmt
CSPC--->  |---> …   ---> …
          |---> CSPI ---> cspi-mgmt
```
The following are a few samples of CStorPoolCluster YAMLs to go through.

1. (Pool on one node with `stripe` type)

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-stripe
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostName: gke-cstor-it-default-pool-1
    raidGroups:
    - type: stripe
      isWriteCache:false
      isSpare: false
      isReadCache: false
      blockDevices:
      - blockDeviceName: sparse-3c1fc7491f9e4cf50053730740647318
    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: off
```

2. (Pool on one node with `stripe` type)

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-stripe
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostName: gke-cstor-it-default-pool-1
    raidGroups:
    - type: stripe
      isWriteCache:false
      isSpare: false
      isReadCache: false
      blockDevices:
      - blockDeviceName: sparse-3c1fc7491f9e4cf50053730740647318

      - blockDeviceName: sparse-9x6fc7491f9e4cf5005454373074fsds

      - blockDeviceName: sparse-8c1fc7491f9sdpefgsdjk46845nssdf5

      - blockDeviceName: sparse-54cedzcs1f9e4cf50053730740647318
    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: off
```

3. (Pool on one node with `stripe` and `mirror` type)

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-stripe
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostName: gke-cstor-it-default-pool-1
    raidGroups:
    - type: stripe
      isWriteCache:false
      isSpare: false
      isReadCache: false
      blockDevices:
      - blockDeviceName: sparse-3c1fc7491f9e4cf50053730740647318

      - blockDeviceName: sparse-9x6fc7491f9e4cf5005454373074fsds

      - blockDeviceName: sparse-8c1fc7491f9sdpefgsdjk46845nssdf5

      - blockDeviceName: sparse-54cedzcs1f9e4cf50053730740647318

    - type: mirror
      isWriteCache:false
      isSpare: false
      isReadCache: false
      blockDevices:
      - blockDeviceName: sparse-3c1fc7491f9e4cf50053730740647318

      - blockDeviceName: sparse-5x6fc7491sdffsfs75005454373074fs

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: off
```

4. (Pool on two nodes with `mirror` type)

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostname: gke-cstor-it-default-pool-1
    raidGroups:
    - type: mirror
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: pool-1-bd-1

      - blockDeviceName: pool-1-bd-2

    - type: mirror
      name: group-2
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: pool-1-bd-3

      - blockDeviceName: pool-1-bd-4

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: lz

  - nodeSelector:
      kubernetes.io/hostname: gke-cstor-it-default-pool-2
    raidGroups:

    - type: mirror
      blockDevices:
      - blockDeviceName: pool-2-bd-1

      - blockDeviceName: pool-2-bd-2

    - type: mirror
      name: group-2
      blockDevices:
      - blockDeviceName: pool-2-bd-3

      - blockDeviceName: pool-2-bd-4

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: off
```

## Pool Day 2 Operations: Workflow
Following operations should be supported on CSPC manifest to carry out pool day 2 operations

* A block device can be added on `striped` type raid group.`[Pool Expansion]`

* A new raid group of any type can be added inside the pool
  spec (Path on CSPC: spec.pools.raidGroups).`[Pool Expansion]`

* A new pool spec can be added on the CSPC.
  ( Path on CSPC: spec.pools) `[Horizontal Pool Scaling]`

* Node selector can be changed on CSPC to do pool migration on
  different node. But before doing that, all the associated block
  Devices should be attached to the newer nodes. [‘Pool Migration’]
  // TODO: More POC on `Pool Migration` regarding block devices
  // management.

* A block device can be replaced in raid-groups of type other than
  ‘striped’. `[Block Device Replacement]`

* A pool can be deleted by removing the entire pool spec. `[Pool Deletion]`

* Any other operations except those described above is invalid
  and will be handled gracefully via error returns. This validation
  is done by CSPC admission module in the openebs-admission server.

Following are some invalid operations (wrt to day2 ops) on CSPC but the list may not be exhaustive:

1. Block device Removal.
2. Raid group removal.


Pool Expansion

* “As an OpenEBS user, I should be able to add block devices to CSPC to increase the pool capacity.”

Steps To Be Performed By User:

1. `kubectl edit cspc your_cspc_name`

2. Put the block devices in the CSPC spec against the correct Kubernetes nodes.


**Consider following example for stripe pool expansion**

Current CSPC is following:


This CSPC corresponds to a stripe pool on node `gke-cstor-it-default-pool-1`

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-stripe
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostName: gke-cstor-it-default-pool-1
    raidGroups:
    - type: stripe
      isWriteCache:false
      isSpare: false
      isReadCache: false
      blockDevices:
      - blockDeviceName: sparse-3c1fc7491f9e4cf50053730740647318
    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: false

```

Expanding stripe pools -- the spec will look
following:


```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-stripe
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostName: gke-cstor-it-default-pool-1
    raidGroups:
    - type: stripe
      isWriteCache:false
      isSpare: false
      isReadCache: false
      blockDevices:
      - blockDeviceName: sparse-3c1fc7491f9e4cf50053730740647318
      // New block device added
      - blockDeviceName: sparse-4cf345h41f9e4cf50053730740647318

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: stripe
      overProvisioning: false
      compression: false
```

**Consider following example for mirror pool expansion**


Current CSPC is following:
This CSPC corresponds to a mirror pool on node `gke-cstor-it-default-pool-1` and on node `gke-cstor-it-default-pool-2`

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostname: gke-cstor-it-default-pool-1
    raidGroups:
    - type: mirror
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: pool-1-bd-1

      - blockDeviceName: pool-1-bd-2

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: false
```

Expanding mirror pools -- the spec will look
following:

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostname: gke-cstor-it-default-pool-1
    raidGroups:
    - type: mirror
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: pool-1-bd-1

      - blockDeviceName: pool-1-bd-2

    // New group added
    - type: mirror
      blockDevices:

      - blockDeviceName: pool-1-bd-3

      - blockDeviceName: pool-1-bd-4

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: false
```

### Disk Replacement

* “As an OpenEBS user, I should be able to replace existing block devices on CSPC to perform disk replacement operations.”

Steps To Be Performed By User:

1. `kubectl edit cspc your_cspc_name`

2. Update the existing block devices with new block devices in the CSPC spec against the correct Kubernetes nodes.


**Consider following example for mirror pool disk replacement**


Current CSPC is following:
This CSPC corresponds to a mirror pool on node `kubernetes-node1`.

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostname: kubernetes-node1
    raidGroups:
    - type: mirror
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: node1-bd-1

      - blockDeviceName: node1-bd-2

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: false
```

Replacing block devices in mirror pool -- the spec will look
following:

```yaml
apiVersion: openebs.io/v1alpha1
kind: CStorPoolCluster
metadata:
  name: cstor-pool-mirror
spec:
  pools:
  - nodeSelector:
      kubernetes.io/hostname: kubernetes-node1
    raidGroups:
    - type: mirror
      isWriteCache: false
      isSpare: false
      isReadCache: false
      blockDevices:

      - blockDeviceName: node1-bd-3

      - blockDeviceName: node1-bd-2

    poolConfig:
      cacheFile: /tmp/pool1.cache
      defaultRaidGroupType: mirror
      overProvisioning: false
      compression: false
```
In the above CSPC spec node1-bd-1 is replaced with node1-bd-3

Disk Replacement Validations:

Once user modifies the CSPC spec to trigger disk replacement process below are
the validations done by the admission-server to restrict invalid changes made to
CSPC

Below are validations on CSPC by admission server

1. Not more than one block device should be replaced simultaneously in the same
   raid group.

2. Replacing block devices should not be already in use by the same cStor pools.

3. Replacing another block device in the raid group is not allowed when any
   of the block device in the same raid group is undergoing replacement[How
   admission server can detect it? It can be verified by checking for
   `openebs.io/bd-predecessor` annotation in the block device claims of block
   devices present in the same raid group will not be empty].

4. Steps to validate whether someone(other CSPC or local PV) already claimed
   replacing block device

   4.1 Verify is there any claim create for replacing block device. If there are
       no claims for replacing block device jump to step 5.

   4.2 If replacing block device was already claimed and if that claim doesn't
       have CSPC label (or) different CSPC label(i.e block device belongs to
       some other CSPC) then reject replacement request.

   4.3 If existing block devices in this CSPC has block device claim with
       annotation openebs.io/bd-predecessor as replacing block device name then
       reject the request else jump to step 5.

5. Create a claim for replacing block device with annotation
   `openebs.io/bd-predecessor: old_block_device_name` only if claim doesn't
   exists.

6. If claim already exists for replacing block device then update annotation
   with proper block device name(If some operator or admin has already created
   claim for block device and triggered replace).

`NOTE:`
1. Pool expansion and disk replacement can go in parallel.

2. Across the pool parallel block device replacements are allowed only when the
   block devices belong to the different raid groups.

3. Block Device replacement is supported only in RAID groups(i.e Mirror, Raidz
   and Raidz2).

Block Device Replacement Workflow: CSPC-Operator

Work done by CStor-Operator after the user has updated the existing block device
name with new block device name

1. The CSPC-Operator will detect under which CSPC pool spec block device has been
   replaced[How it can detect? By comparing new CSPC spec changes with corresponding
   node CSPI spec] after identifying the changes CSPC-Operator will update the
   corresponding raid group of CSPI with new block device name(replace old block
   device with new block device name).

   Note:There can't be more than one block device change between CSPI and CSPC in
   a particular raid group.

Work done by CSPI-Mgmt after CSPC-Operator replaces block device name in CSPI spec

1. The CSPI-Mgmt will reconcile for the changes made on CSPI. CSPI-Mgmt will
   process changes in the following manner

   1.1 CSPI-Mgmt will detect are this changes for replacement[How? CSPI-Mgmt will
       trigger `zpool dump <pool_name>` command and it will get pool dump output
       from cstor-pool container. CSPI-Mgmt will verify whether any of block device
       links are in use by pool via pool dump output if links are not in use by pool
       then it might be pool expansion (or) replacement operation. If claim of
       current block device has annotation `openebs.io/bd-predecessor: old_bdName`
       then changes are identified as replacement]. If changes are for replacement
       CSPI-Mgmt will execute `zpool replace <pool_name> <old_device> <new_device>`
       this command which will trigger disk replacement operation in cstor.

   1.2 For each reconciliation CSPI-Mgmt will process each block device and
       checks if claim of current block device has `openebs.io/bd-predecessor`
       annotation then CSPI-Mgmt will trigger `zpool dump` command and verifies
       the status of resilvering for particular vdev(How it will detect vdev?
       CSPI-Mgmt will get vdev based on the device link of block device).

   1.3 On completion of resilvering process CSPI-Mgmt will unclaim the old block
       device if block device was replaced and removes the `openebs.io/bd-predecessor`
       annotation from new block device.

Note: Representing resilvering status on CSPI CR(Not targeted).

## Operations Workflow: CSPC-Operator
( Includes `Pool Expansion`, `Pool Deletion`, `Block Device Replacement`, and `Pool Migration`)

Work done by CStor-operator after the user has edited the CSPC:

1. The CSPC spec change as a result of the user modifying
   CSPC and the CStor-Operator should propagate the changes to
   corresponding CSPI(s).

2. Hostname changed in the CSPC can cause following:( `Pool Migration`)
Cstor-Operator will patch the corresponding CSPI and deployment with the hostname in the CSPI spec. ( // TODO: Is there anything that cspi-mgmt is expected to do ? )
   // TODO: More POC on pool migration wrt -- reconnecting volumes etc.

3. When the entire pool spec is deleted, CStor-Operator should figure out the orphaned CSP and delete it which will cause the pool to be deleted.

4. Block device addition can cause the following:
   1. Add block device in stripe pool on a node(`Pool Expansion`):
      If a block device is added in a stripe pool in CSPC, corresponding CSP will be patched by Cstor-Operator to reflect the new block device. Now cspi-mgmt should handle this change by adding the device to the pool

   2. Add a raid group to pool spec (`Pool Expansion`):
      A raid group can be added (`e.g. mirror raid group, raidz raid group etc`) and this change will propagate operation Workflow to corresponding CSP to be finally handled by cspi-mgmt.

5. If a pool spec is deleted the entire pool will get deleted. (`Pool Deletion`)

6. If a pool spec is added a new pool will be formed. (`Horizontal Pool Scale`)

7. Block device replacement can cause the following:
   1. Replacing a block device under spec of CSPC will trigger disk replacement.
   Note: Disk Replacement is supported only in mirror and raidz raid group.

**NOTE:**
Cstor-Operator will handle the spec change in the following order. Also, the pool operations will be carried out only when there is no pending pool creation/deletion on nodes.

1. Host Name Change<br/>
    1.1 Pool Migration

2. Block Device Addition<br/>
   2.1 Pool Expansion

3. Block Device Replacement<br/>
   3.1 Block Device Replacement

The order of handling is  1.1 > 2.1 > 3.1

## Appendix - SPC Limitations
Till OpenEBS 1.1 cStor pool can be provisioned using StoragePoolClaim and cStor volumes can be provisioned on the pools provisioned via SPC.
SPC provisioning is facilitated by CStor-Operator that runs as a routine in maya-apiserver. Please visit the following link to know more about the CStor-Operator which is also known as SPC-Watcher synonymously.


https://docs.google.com/document/d/1dcm7wvdpUHfSOMoFTPJBUeesMej46eAIN_06-1h_lvw/edit#heading=h.big02sfdb5gh

**Limitations with SPC:**


StoragePoolClaim parents a collection of cStor pools on different kubernetes nodes, meaning the creation of SPC can create 'k' number of cStor pools on nodes, where this 'k' can be controlled by the user. But looks like claim type of resources ( e.g PersistentVolumeClaim) maps to only one object ( e.g. PVC maps to a single PV) and this can create confusion at the very beginning.


Once you have created an SPC -- you do not get enough information from the SPC e.g. which block device is on what node, what are the collection of block devices that form a cStor pool!


`StoragePoolClaim` is at cluster scope which can cause a problem for multiple instances of OpenEBS running in the same cluster in different namespaces. Idea is to enable teams to use OpenEBS in their provided namespace in the cluster


Pool topology information is not visible on the SPC spec and it hides information about block devices/disks that constitute a cStor pool on a node. Additionally, this lack of information poses challenges in incorporating pool day 2 operations features such as pool expansion, block device replacement, etc.
