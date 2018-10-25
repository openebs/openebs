# UPGRADE FROM OPENEBS 0.6.0 TO 0.7.0

## Overview

This document describes the steps for upgrading OpenEBS from 0.6.0 to 0.7.0. The upgrade of OpenEBS is a two step process. 
- *Step 1* - Upgrade the OpenEBS Operator 
- *Step 2* - Upgrade the OpenEBS Volumes that were created with older OpenEBS Operator (0.6.0) 

### Terminology
- *OpenEBS Operator : Refers to maya-apiserver & openebs-provisioner along w/ respective services, service a/c, roles, rolebindings*
- *OpenEBS Volume: The Jiva controller & replica pods*
- *All steps described in this document need to be performed on the Kubernetes master or from a machine that has access to Kubernetes master*

## Step 1: Upgrade the OpenEBS Operator

OpenEBS 0.7.0 has made the following significant changes to the OpenEBS Operator (aka OpenEBS control plane components):
- A new provisioning and policy enforcement engine. This introduces breaking changes as it expects the volume policies to be present as annotations in storage class as opposed to `parameters` or `environment variables`.
- OpenEBS will install default jiva storage pool (named `default`) and storage class (named `openebs-jiva-default`). If these names conflict with your existing storage pool or storage classes, rename and re-apply your storage classes.
- Integrated with OpenEBS NDM project. A new Daemonset will be launched to discover the block devices attached to the nodes.

### Download the upgrade scripts

Either `git clone` or download the following files to your work directory. 
https://github.com/openebs/openebs/tree/master/k8s/upgrades/0.6.0-0.7.0
- `patch-strategy-recreate.json`
- `replica.patch.tpl.yml`
- `controller.patch.tpl.yml`
- `oebs_update.sh`
- `pre_upgrade.sh`

### Pre-requisites
Before upgrading the OpenEBS Operator, check if you are using a storage pool named `default` which will conflict with default jiva pool installed with OpenEBS 0.7.0:
```
./pre_upgrade.sh <openebs-namespace>
```

### Upgrade volume policies in existing storage classes

Use the following command to upgrade the storage classes volume policies. Move from parameters to annotations. This script will only update the following volume policies:
- `openebs.io/replica-count`
- `openebs.io/storage-pool`
- `openebs.io/volume-monitor`

The remaining policies will fallback to their default values. 

```
./upgrade_sc.sh
```

Alternatively, you can skip this step and re-apply your StorageClasses as per the 0.7.0 volume policy specification. 

**Note: StorageClasses have to updated prior to provisioning any new volumes with 0.7.0.**

### Upgrading OpenEBS Operator CRDs and Deployments

The upgrade steps vary depending on the way OpenEBS was installed, select one of the following:

#### Install/Upgrade using kubectl (using openebs-operator.yaml )

**The sample steps below will work if you have installed openebs without modifying the default values in openebs-operator.yaml. If you have customized it for your cluster, you will have to download the 0.7.0 openebs-operator.yaml and cutomize it again**

```
#If Upgrading from 0.5.x, delete older operator. 
# Starting with OpenEBS 0.6, all the components are installed in namespace `openebs`
# as opposed to `default` namespace in earlier releases. 
kubectl delete -f https://raw.githubusercontent.com/openebs/openebs/v0.5/k8s/openebs-operator.yaml
#Wait for objects to be delete, you can check using `kubectl get deploy`

#Upgrade to 0.7 OpenEBS Operator
kubectl apply -f https://openebs.github.io/charts/openebs-operator-0.7.0.yaml
```

#### Install/Upgrade using helm chart (using stable/openebs, openebs-charts repo, etc.,) 

**The sample steps below will work if you have installed openebs with default values provided by stable/openebs helm chart.**

- Run `helm ls` to get the release name of openebs. 
- Upgrade using `helm upgrade -f https://openebs.github.io/charts/helm-values-0.7.0.yaml <release-name> stable/openebs`

#### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 0.7 release tags and changes made in the values/templates. 

You can use the following as references to know about the changes in 0.7: 
- openebs-charts [PR#1878](https://github.com/openebs/openebs/pull/1878) as reference.

After updating the YAML or helm chart or helm chart values, you can use the above procedures to upgrade the OpenEBS Operator

## Step 2: Upgrade the OpenEBS Volumes

Even after the OpenEBS Operator has been upgraded to 0.7, the volumes will continue to work with older versions. Each of the volumes should be upgraded (one at a time) to 0.7, using the steps provided below. 

*Note: Upgrade functionality is still under active development. It is hightly recommended to schedule a downtime for the application using the OpenEBS PV while performing this upgrade. Also, make sure you have taken a backup of the data before starting the below upgrade procedure.*

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
./oebs_update.sh pvc-48fb36a2-947f-11e8-b1f3-42010a800004 openebs-storage
```

