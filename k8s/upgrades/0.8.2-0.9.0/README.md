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

### Download the upgrade yamls

The easiest way to get all the upgrade yamls is via git clone.

```
mkdir upgrade-openebs
cd upgrade-openebs
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/upgrades/0.8.2-0.9.0/
```

## Step 1: Checking the OpenEBS current version.

#### Please make sure that current OpenEBS version is 0.8.2 before proceeding to step 2.

## Step 2: Upgrade the OpenEBS Operator

### Upgrading OpenEBS Operator CRDs and Deployments

The upgrade steps vary depending on the way OpenEBS was installed. Select one of the following based on your installation:

#### Install/Upgrade using kubectl (using openebs-operator.yaml )

**The sample steps below will work if you have installed openebs without modifying the default values in openebs-operator.yaml. If you have customized it for your cluster, you have to download the 0.9.0 openebs-operator.yaml and customize it again**

```
#Upgrade to 0.9.0 OpenEBS Operator
kubectl apply -f https://openebs.github.io/charts/openebs-operator-0.9.0.yaml
```

#### Install/Upgrade using helm chart (using stable/openebs, openebs-charts repo, etc.,)

**The sample steps below will work if you have installed openebs with default values provided by stable/openebs helm chart.**

Before upgrading using helm, please review the default values available with latest stable/openebs chart. (https://raw.githubusercontent.com/helm/charts/master/stable/openebs/values.yaml).

- If the default values seem appropriate, you can use the below commands to update OpenEBS. [More](https://hub.helm.sh/charts/stable/openebs) details about the specific chart version.
   ```sh
  $ helm upgrade --reset-values <release name> stable/openebs --version 0.9.2
  ```
- If not, customize the values into your copy (say custom-values.yaml), by copying the content from above default yamls and edit the values to suite your environment. You can upgrade using your custom values using:
  ```sh
  $ helm upgrade <release name> stable/openebs --version 0.9.2 -f custom-values.yaml`
  ```

#### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 0.9.0 release tags and changes made in the values/templates.

You can use the following as references to know about the changes in 0.9.0:
- openebs-charts [PR####](https://github.com/openebs/openebs/pull/2566) as reference.

After updating the YAML or helm chart or helm chart values, you can use the above procedures to upgrade the OpenEBS Operator

## Step 3: Upgrade the OpenEBS Pools and Volumes

Even after the OpenEBS Operator has been upgraded to 0.9.0, the cStor Storage Pools and volumes (both jiva and cStor)  will continue to work with older versions. Use the following steps in the same order to upgrade cStor Pools and volumes.

*Note: Upgrade functionality is still under active development. It is highly recommended to schedule a downtime for the application using the OpenEBS PV while performing this upgrade. Also, make sure you have taken a backup of the data before starting the below upgrade procedure.*

Limitations:
- this is a preliminary jobs (done via CASTemplate) only intended for using on volumes where data has been backed-up.
- please have the following link handy in case the volume gets into read-only during upgrade
  https://docs.openebs.io/docs/next/troubleshooting.html#recovery-readonly-when-kubelet-is-container
- automatic rollback option is not provided. To rollback, you need to update the controller, exporter and replica pod images to the previous version
- in the process of running the below steps, if you run into issues, you can always reach us on slack


# OpenEBS upgrade via CASTemplates from 0.8.2 to 0.9.0
**NOTE: Upgrade via these CAS Templates is only supported for OpenEBS in version 0.8.2. Trying to upgrade a OpenEBS version other than 0.8.2 to 0.9.0 using these CAS templates can result in undesired behaviours. If you are having any OpenEBS version lower than 0.8.2, first upgrade it to 0.8.2 and then these CAS templates can be used safely for 0.9.0 upgrade.**

## Upgrade Jiva based volumes

Make sure your current directory is openebs/k8s/upgrades/0.8.2-0.9.0/

### Steps before upgrade:
  - Make sure that all pods related to volume are in running state.
  - Apply rbac.yaml to manage permission rules `kubectl apply -f rbac.yaml`
  - cd jiva
  - Apply cr.yaml which installs a custom resource definition for UpgradeResult custom reource. This custom resource is used to capture upgrade related information for success or failure case.

### Steps For Jiva volume upgrade:

  - Apply jiva_upgrade_runtask.yaml using `kubectl apply`
  - Edit volume-upgrade-job.yaml and add the PV names which need to be upgraded.
  - After editing volume-upgrade-job.yaml, save it and apply.
  - Logs can be seen from the pod which is launched by upgrade job. Do a `kubectl get pod` to find the upgrade job pod and `kubectl logs` command to see the logs.
  - `kubectl get upgraderesult -o yaml` can be done to check the status of upgrade of each item.

## Upgrade cStor based volumes

Make sure your current directory is openebs/k8s/upgrades/0.8.2-0.9.0/

### Steps before upgrade:
  - Make sure that all pods related to pool and volume are in running state.
  - If cstor volumes are resized manually then make sure that PV is patched with latest size.
  - Apply rbac.yaml to manage permission rules `kubectl apply -f rbac.yaml`
  - cd cstor
  - Apply cr.yaml which installs a custom resource definition for UpgradeResult custom reource. This custom resource is used to capture upgrade related information for success or failure case.

### Steps For cStor pool upgrade:

  - Apply cstor-pool-update-082-090.yaml
  - Edit pool-upgrade-job.yaml and add the cstorpool resource names which need to be upgraded.
  - After editing pool-upgrade-job.yaml, save it and apply.
  - Logs can be seen from the pod which is launched by upgrade job. Do a `kubectl get pod` to find the upgrade job pod and `kubectl logs` command to see the logs.
  - `kubectl get upgraderesult -o yaml` can be done to check the status of upgrade of each item.

### Steps For cStor volume upgrade:

  - Apply cstor-volume-update-082-090.yaml
  - Edit volume-upgrade-job.yaml and add the cstorvolume resource names which need to be upgraded.
  - After editing volume-upgrade-job.yaml, save it and apply.
  - Logs can be seen from the pod which is launched by upgrade job. Do a `kubectl get pod` to find the upgrade job pod and `kubectl logs` command to see the logs.
  - `kubectl get upgraderesult -o yaml` can be done to check the status of upgrade of each item.

## Post upgrade steps:

  - Delete ServiceAccount, ClusterRole and ClusterRoleBindings that are created for upgrade using
`kubectl delete -f rbac.yaml` from openebs/k8s/upgrades/0.8.2-0.9.0/ directory.
