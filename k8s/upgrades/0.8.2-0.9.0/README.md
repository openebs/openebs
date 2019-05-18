# UPGRADE FROM OPENEBS 0.8.2 TO 0.9.0

## Overview

This document describes the steps for upgrading OpenEBS from 0.8.2 to 0.9.0

The upgrade of OpenEBS is a two step process:
- *Step 1* - Upgrade the OpenEBS Operator
- *Step 2* - Upgrade the OpenEBS Volumes from previous versions (0.8.2)

#### Note: It is mandatory to make sure to that all volumes are running at version 0.8.2 before the upgrade.

### Terminology
- *OpenEBS Operator : Refers to maya-apiserver, admission-server & openebs-provisioner along w/ respective services, service a/c, roles, rolebindings*
- *OpenEBS Volume: Storage Engine pods like cStor or Jiva controller(aka target) & replica pods*

## Prerequisites

*All steps described in this document need to be performed on the Kubernetes master or from a machine that has access to Kubernetes master*

### Download the upgrade scripts

The easiest way to get all the upgrade yamls is via git clone.

```
mkdir upgrade-openebs
cd upgrade-openebs
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/upgrades/0.8.2-0.9.0/
```

## Step 1: Checking the OpenEBS current version.

#### Please make sure that current OpenEBS version is 0.8.2 before proceeding to
step 2.

## Step 2: Upgrade the OpenEBS Operator

### Upgrading OpenEBS Operator CRDs and Deployments

The upgrade steps vary depending on the way OpenEBS was installed, select one of the following:

#### Install/Upgrade using kubectl (using openebs-operator.yaml )

**The sample steps below will work if you have installed openebs without modifying the default values in openebs-operator.yaml. If you have customized it for your cluster, you will have to download the 0.8.2 openebs-operator.yaml and customize it again**

```
#Upgrade to 0.9.0 OpenEBS Operator
kubectl apply -f https://openebs.github.io/charts/openebs-operator-0.9.0.yaml
```

#### Install/Upgrade using helm chart (using stable/openebs, openebs-charts repo, etc.,)

**The sample steps below will work if you have installed openebs with default values provided by stable/openebs helm chart.**

Before upgrading using helm, please review the default values available with latest stable/openebs chart. (https://raw.githubusercontent.com/helm/charts/master/stable/openebs/values.yaml).

- If the default values seem appropriate, you can use the `helm upgrade --reset-values <release name> stable/openebs`.
- If not, customize the values into your copy (say custom-values.yaml), by copying the content from above default yamls and edit the values to suite your environment. You can upgrade using your custom values using:
`helm upgrade <release name> stable/openebs -f custom-values.yaml`

#### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 0.9.0 release tags and changes made in the values/templates.

You can use the following as references to know about the changes in 0.9.0:
- openebs-charts [PR####](https://github.com/openebs/openebs/pull/2566) as reference.

After updating the YAML or helm chart or helm chart values, you can use the above procedures to upgrade the OpenEBS Operator

## Step 3: Upgrade the OpenEBS Pools and Volumes

Even after the OpenEBS Operator has been upgraded to 0.9.0, the cStor Storage Pools and volumes (both jiva and cStor)  will continue to work with older versions. Use the following steps in the same order to upgrade cStor Pools and volumes.

*Note: Upgrade functionality is still under active development. It is highly recommended to schedule a downtime for the application using the OpenEBS PV while performing this upgrade. Also, make sure you have taken a backup of the data before starting the below upgrade procedure.*

Limitations:
- this is a preliminary jobs(will be done via CASTemplate) only intended for using on volumes where data has been backed-up.
- please have the following link handy in case the volume gets into read-only during upgrade
  https://docs.openebs.io/docs/next/readonlyvolumes.html
- automatic rollback option is not provided. To rollback, you need to update the controller, exporter and replica pod images to the previous version
- in the process of running the below steps, if you run into issues, you can always reach us on slack


### Upgrade the Jiva based OpenEBS PV

Extract the PV name using `kubectl get pv`

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                          STORAGECLASS      REASON    AGE
pvc-48fb36a2-947f-11e8-b1f3-42010a800004   5G         RWO            Delete           Bound     percona-test/demo-vol1-claim   openebs-percona             8m
```
If your `pwd` is openebs/k8s/upgrades/0.8.2-0.9.0/

```
1. cd jiva
2. Update the `volume-upgrade-job.yaml` with corresponding jiva pv name and volume namespace
3. kubectl apply -f rbac.yaml
4. kubectl apply -f upgrade-job.yaml
5. kubectl apply -f jiva_upgrade_runtask.yaml
6. kubectl apply -f volume-upgrade-job.yaml
```
After applying volume-upgrade-job.yaml job will be triggered upon successfull
job status will be updated to completed else job status will be error.
If error occured then check the logs of pod(volume-upgrade job) and desribe of
upgraderesult
To get logs of job `kubectl logs -f volume-upgrade-22331`
To get describe upgrade result output `kubectl describe upgraderesults`

### Upgrade cStor Pools

##TODO: Update the file with steps to upgrade cstro-pools from 0.8.2 to 0.9.0

Make sure that this step completes successfully before proceeding to next step.


### Upgrade cStor Volumes

Extract the PV name using `kubectl get pv`

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                  STORAGECLASS           REASON    AGE
pvc-1085415d-f84c-11e8-aadf-42010a8000bb   5G         RWO            Delete           Bound     default/demo-cstor-sparse-vol1-claim   openebs-cstor-sparse             22m
```

##TODO: Update the file with steps to upgrade cstro-volumes from 0.8.2 to 0.9.0
