# UPGRADE FROM OPENEBS 0.9.0 TO 1.0.0

## Overview

This document describes the steps for upgrading OpenEBS from 0.9.0 to 1.0.0

The upgrade of OpenEBS is a three step process:
- *Step 1* - Prerequisites
- *Step 2* - Upgrade the OpenEBS Operator
- *Step 3* - Upgrade the OpenEBS Pools and Volumes from previous versions (0.9.0)

#### Note: It is mandatory to make sure to that all OpenEBS control plane components and volumes are running with version 0.9.0 before the upgrade.

### Terminology
- *OpenEBS Operator : Refers to maya-apiserver & openebs-provisioner along w/ respective services, service a/c, roles, rolebindings*
- *OpenEBS Volume: Storage Engine pods like cStor or Jiva controller(aka target) & replica pods*

### Download the upgrade scripts

The easiest way to get all the upgrade scripts is via git clone.

```sh
$ mkdir upgrade-openebs
$ cd upgrade-openebs
$ git clone https://github.com/openebs/openebs.git
$ cd openebs/k8s/upgrades/0.9.0-1.0.0/
```

## Step 1: Prerequisites

*All steps described in this document need to be performed on the Kubernetes master or from a machine that has access to Kubernetes master*
- If OpenEBS has been deployed using openebs helm charts, it has to be in chart version `0.9.2` . Run `helm list` to verify the chart version.
   If not, we have to update openebs chart version using below commands.

    - Firstly we have to delete the `admission-server` secret, which will be deployed again once we upgrade charts to `0.9.2` version using below command:
      ```sh
      $ kubectl delete secret admission-server-certs -n openebs
      ```

    - Upgrade OpenEBS chart version to 0.9.2 using below command:
      ```sh
      $ helm repo update

      $ helm upgrade <release-name> stable/openebs --version 0.9.2
      ```

    - Run `helm list` to verify deployed OpenEBS chart version:
      ```sh
      $ helm list
      NAME    REVISION        UPDATED                         STATUS          CHART           APP VERSION     NAMESPACE
      openebs 3               Mon Jun 24 20:57:05 2019        DEPLOYED        openebs-0.9.2   0.9.0           openebs
      ```

 - Before proceeding with below steps please make sure the daemonset `DESIRED` count is equal to `CURRENT` count.
    ```sh
    $ kubectl get ds openebs-ndm -n <openebs-namespace>
    NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    openebs-ndm   3         3         3       3            3           <none>          7m6s
    ```
    Sometimes, the `DESIRED` count may not be equal to the `CURRENT` count. This may happen due to following cases:
   - If any NodeSelector has been used to deploy openebs related pods.
   - Master or any Node has been tainted in k8s cluster.

 - Run below command to update OpenEBS control plane components labels.
    ```sh
    $ ./pre-upgrade.sh <openebs_namespace> <mode>
    ```
    `<openebs_namespace>` is the namespace where OpenEBS control plane components are installed.
    `<mode>` provide mode as helm if OpenEBS is installed via helm (or) provide
     mode as operator if OpenEBS is installed via operator yaml

Note:
 - No new spc should be created after this step until the upgrade is complete. If created, execute `pre-upgrade.sh` again.
 - It is mandatory to make sure that all OpenEBS control plane components are running at version 0.9.0 before the upgrade


## Step 2: Upgrade the OpenEBS Operator

### Upgrading OpenEBS Operator CRDs and Deployments:

Upgrade steps vary depending on the way OpenEBS was installed. Below are the possible ways:

#### Upgrade using kubectl (using openebs-operator.yaml):

**Use this mode of upgrade only if OpenEBS was installed using openebs-operator.yaml.**

**The sample steps below will work if you have installed OpenEBS without modifying the default values in openebs-operator.yaml. If you have customized it for your cluster, you will have to download the 1.0.0 openebs-operator.yaml and customize it again**

```
#Upgrade to 1.0.0 OpenEBS Operator
$ kubectl apply -f https://openebs.github.io/charts/openebs-operator-1.0.0.yaml
```

#### Upgrade using helm chart (using stable/openebs, openebs-charts repo, etc.,):

**The sample steps below will work if you have installed openebs with default values provided by stable/    openebs helm chart.**

Before upgrading using helm, please review the default values available with latest stable/openebs chart. (https://raw.githubusercontent.com/helm/charts/master/stable/openebs/values.yaml).

- If the default values seem appropriate, you can use the below commands to update OpenEBS. [More](https://hub.helm.sh/charts/stable/openebs) details about the specific chart version.
  ```sh
  $ helm upgrade --reset-values <release name> stable/openebs --version 1.0.0
  ```
- If not, customize the values into your copy (say custom-values.yaml), by copying the content from above default yamls and edit the values to suite your environment. You can upgrade using your custom values using:
  ```sh
  $ helm upgrade <release name> stable/openebs --version 1.0.0 -f custom-values.yaml`
  ```

#### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 1.0.0 release tags and changes made in the values/templates.

You can use the following as references to know about the changes in 1.0.0:
- openebs-charts [PR####](https://github.com/openebs/openebs/pull/2352) as reference.

After updating the YAML or helm chart or helm chart values, you can use the above procedures to upgrade the OpenEBS Operator

## Step 3: Upgrade the OpenEBS Pools and Volumes

Even after the OpenEBS Operator has been upgraded to 1.0.0, the Storage Pools and Volumes (both jiva and cStor)  will continue to work with older versions. Use the following steps in the same order to upgrade Pools and Volumes.

*Note: Upgrade functionality is still under active development. It is highly recommended to schedule a downtime for the application using the OpenEBS PV while performing this upgrade. Also, make sure you have taken a backup of the data before starting the below upgrade procedure.*

Limitations:
- this is a preliminary script only intended for using on volumes where data has been backed-up.
- please have the following link handy in case the volume gets into read-only during upgrade
  https://docs.openebs.io/docs/next/troubleshooting.html#recovery-readonly-when-kubelet-is-container
- automatic rollback option is not provided. To rollback, you need to update the controller, exporter and replica pod images to the previous version
- in the process of running the below steps, if you run into issues, you can always reach us on slack


### Upgrade the Jiva based OpenEBS PV

Extract the PV name using `kubectl get pv`

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                          STORAGECLASS      REASON    AGE
pvc-48fb36a2-947f-11e8-b1f3-42010a800004   5G         RWO            Delete           Bound     percona-test/demo-vol1-claim   openebs-percona             8m
```

```
$ cd jiva
$ ./jiva_volume_upgrade.sh pvc-48fb36a2-947f-11e8-b1f3-42010a800004
```

### Upgrade cStor Pools

Extract the SPC name using `kubectl get spc`

```sh
NAME                AGE
cstor-sparse-pool   24m
```

```sh
$ cd cstor
$ ./cstor_pool_upgrade.sh cstor-sparse-pool <openebs_namespace>
```
`<openebs_namespace>` is the namespace where OpenEBS control plane components are installed.

Make sure that this step completes successfully before proceeding to next step.


### Upgrade cStor Volumes

Extract the PV name using `kubectl get pv`

```sh
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                  STORAGECLASS           REASON    AGE
pvc-1085415d-f84c-11e8-aadf-42010a8000bb   5G         RWO            Delete           Bound     default/demo-cstor-sparse-vol1-claim   openebs-cstor-sparse             22m
```

```sh
$ cd cstor
$ ./cstor_volume_upgrade.sh pvc-1085415d-f84c-11e8-aadf-42010a8000bb <openebs_namespace>
```
`<openebs_namespace>` is the namespace where OpenEBS control plane components are installed.
