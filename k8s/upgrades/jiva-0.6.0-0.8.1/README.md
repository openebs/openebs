# UPGRADE FROM OPENEBS 0.6.0 TO 0.8.1

## Overview

This document describes the steps for upgrading OpenEBS from 0.6.0 to 0.8.1 

The upgrade of OpenEBS is a two step process: 
- *Step 1* - Upgrade the OpenEBS Operator 
- *Step 2* - Upgrade the OpenEBS Volumes from previous versions 0.6.0 

### Terminology
- *OpenEBS Operator : Refers to maya-apiserver & openebs-provisioner along w/ respective services, service a/c, roles, rolebindings*
- *OpenEBS Volume: The Jiva controller(aka target) & replica pods*

## Prerequisites

*All steps described in this document need to be performed on the Kubernetes master or from a machine that has access to Kubernetes master*

### Download the upgrade scripts

You can either `git clone` or download the upgrade scripts.

```
mkdir upgrade-openebs
cd upgrade-openebs
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/upgrade/jiva-0.6.0-0.8.1/
```

### Breaking Changes in 0.7.x

#### Default Jiva Storage Pool
OpenEBS 0.7.0 auto installs a default Jiva Storage Pool and a default Storage Class named `default` and `openebs-jiva-default` respectively. If you have a storage pool named `default` created in earlier version, you will have to re-apply your Storage Pool after the upgrade is completed.

Before upgrading the OpenEBS Operator, check if you are using a storage pool named `default` which will conflict with default jiva pool installed with OpenEBS 0.8.1:
```
./pre_upgrade.sh <openebs-namespace>
```

#### Storage Classes
OpenEBS supports specified Storage Policies in Storage Classes. The way storage policies are specified has changed in 0.7.x. The policies will have to be specified under metadata instead of parameters. 

For example, if your storage class looks like this in 0.6.0:
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: openebs-mongodb
provisioner: openebs.io/provisioner-iscsi
parameters:
  openebs.io/storage-pool: "default"
  openebs.io/jiva-replica-count: "3"
  openebs.io/volume-monitor: "true"
  openebs.io/capacity: 5G
  openebs.io/fstype: "xfs"
```

There is no need to mention the volume-monitor and capacity with 0.7.0. The remaining policies like storage pool, replica count and the fstype should be specified as follows:
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: openebs-mongodb
   annotations:
    cas.openebs.io/config: |
      - name: ReplicaCount
        value: "3"
      - name: StoragePool
        value: default
      - name: FSType
        value: "xfs"
provisioner: openebs.io/provisioner-iscsi
```

Make edits to your Storage Class YAMLs - delete them and add them back. A delete and re-apply is required since updates to Storage Class parameters are not possible. 

If you are using `ext4` for FSType, you could use the following script to upgrade your StorageClasses. 
```
./upgrade_sc.sh
```

Alternatively, you can skip this step and re-apply your StorageClasses as per the 0.7.0 volume policy specification. 

**Important Note: StorageClasses have to updated prior to provisioning any new volumes with 0.7.0.**

## Step 1: Upgrade the OpenEBS Operator

### Upgrading OpenEBS Operator CRDs and Deployments

The upgrade steps vary depending on the way OpenEBS was installed, select one of the following:

#### Install/Upgrade using kubectl (using openebs-operator.yaml )

**The sample steps below will work if you have installed openebs without modifying the default values in openebs-operator.yaml. If you have customized it for your cluster, you will have to download the 0.7.0 openebs-operator.yaml and customize it again**

```
#Upgrade to 0.8.1 OpenEBS Operator
kubectl apply -f https://openebs.github.io/charts/openebs-operator-0.8.1.yaml
```

#### Install/Upgrade using helm chart (using stable/openebs, openebs-charts repo, etc.,) 

**The sample steps below will work if you have installed openebs with default values provided by stable/openebs helm chart.**

Before upgrading using helm, please review the default values available with latest stable/openebs chart. (https://raw.githubusercontent.com/helm/charts/master/stable/openebs/values.yaml).

- If the default values seem appropriate, you can use the `helm upgrade --reset-values <release name> stable/openebs`.
- If not, customize the values into your copy (say custom-values.yaml), by copying the content from above default yamls and edit the values to suite your          environment. You can upgrade using your custom values using:
`helm upgrade <release name> stable/openebs -f custom-values.yaml`

#### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 0.8.1 release tags and changes made in the values/templates. 

You can use the following as references to know about the changes in 0.8.1: 
- openebs-charts [PR#2352](https://github.com/openebs/openebs/pull/2352) as reference.

After updating the YAML or helm chart or helm chart values, you can use the above procedures to upgrade the OpenEBS Operator

## Step 2: Upgrade the OpenEBS Volumes

Even after the OpenEBS Operator has been upgraded to 0.8.1, the volumes will continue to work with older versions. Each of the volumes should be upgraded (one at a time) to 0.8.1, using the steps provided below. 

*Note: Upgrade functionality is still under active development. It is highly recommended to schedule a downtime for the application using the OpenEBS PV while performing this upgrade. Also, make sure you have taken a backup of the data before starting the below upgrade procedure.*

Limitations:
- this is a preliminary script only intended for using on volumes where data has been backed-up.
- please have the following link handy in case the volume gets into read-only during upgrade 
  https://docs.openebs.io/docs/next/readonlyvolumes.html
- automatic rollback option is not provided. To rollback, you need to update the controller, exporter and replica pod images to the previous version
- in the process of running the below steps, if you run into issues, you can always reach us on slack


```
kubectl get pv
```

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                          STORAGECLASS      REASON    AGE
pvc-48fb36a2-947f-11e8-b1f3-42010a800004   5G         RWO            Delete           Bound     percona-test/demo-vol1-claim   openebs-percona             8m
```

### Upgrade the PV that needs to be upgraded. 

```
./jiva_volume_upgrade.sh pvc-48fb36a2-947f-11e8-b1f3-42010a800004
```

