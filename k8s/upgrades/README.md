# Upgrade OpenEBS

## Important Notice

### Migration of cStor Pools/Volumes to latest CSPC Pools/CSI based Volumes

OpenEBS 2.0.0 moves the cStor engine towards `v1` schema and CSI based provisioning. To migrate from old SPC based pools and cStor external-provisioned volume to CSPC based pools and cStor CSI volumes follow the steps mentioned in the [Migration doc](https://github.com/openebs/upgrade/blob/master/docs/migration.md). 

This migration can be performed after upgrading the old OpenEBS resources to `2.0.0` or above. 

### Upgrading CSPC pools and cStor CSI volumes

If already using CSPC pools and cStor CSI volumes they can be upgraded from `1.10.0` or later to the latest release via steps mentioned in the [Upgrade doc](https://github.com/openebs/upgrade/blob/master/docs/upgrade.md)

## Overview

This document describes the steps for the following OpenEBS Upgrade paths:

- Upgrade from 1.0.0 or later to a newer release up to 2.2.0

For other upgrade paths of earlier releases, please refer to the respective directories.
Example: 
- the steps to upgrade from 0.9.0 to 1.0.0 will be under [0.9.0-1.0.0](./0.9.0-1.0.0/).
- the steps to upgrade from 1.0.0 or later to a newer release up to 1.12.x will be under [1.x.0-1.12.x](./1.x.0-1.12.x/README.md).

The upgrade of OpenEBS is a three step process:
- *Step 1* - Prerequisites
- *Step 2* - Upgrade the OpenEBS Control Plane Components
- *Step 3* - Upgrade the OpenEBS Data Plane Components

### Terminology

- *OpenEBS Control Plane: Refers to maya-apiserver, openebs-provisioner, node-disk-manager etc along w/ respective RBAC components*
- *OpenEBS Data Plane: Refers to Storage Engine pods like cStor, Jiva controller(aka target) & replica pods*


## Step 1: Prerequisites

**Note: It is mandatory to make sure to that all OpenEBS control plane
and data plane components are running with the expected version before the upgrade.**
- **For upgrading to the latest release (2.2.0), the previous version should be minimum 1.0.0 **

**Note: All steps described in this document need to be performed from a
machine that has access to Kubernetes master**

- Note down the `namespace` where openebs components are installed.
  The following document assumes that namespace to be `openebs`.

- Note down the `openebs service account`.
  The following command will help you to determine the service account name.
  ```sh
  $ kubectl get deploy -n openebs -l name=maya-apiserver -o jsonpath="{.items[*].spec.template.spec.serviceAccount}"
  ```
  The examples in this document assume the service account name is `openebs-maya-operator`.

- Verify that OpenEBS Control plane is indeed in expected version. Say 1.12.0
  ```sh
  $ kubectl get pods -n openebs -l openebs.io/version=1.12.0
  ```

  The output will list the control plane services mentioned below, as well as some
  of the data plane components.
  ```sh
  NAME                                           READY   STATUS    RESTARTS   AGE
  maya-apiserver-7b65b8b74f-r7xvv                1/1     Running   0          2m8s
  openebs-admission-server-588b754887-l5krp      1/1     Running   0          2m7s
  openebs-localpv-provisioner-77b965466c-wpfgs   1/1     Running   0          85s
  openebs-ndm-5mzg9                              1/1     Running   0          103s
  openebs-ndm-bmjxx                              1/1     Running   0          107s
  openebs-ndm-operator-5ffdf76bfd-ldxvk          1/1     Running   0          115s
  openebs-ndm-v7vd8                              1/1     Running   0          114s
  openebs-provisioner-678c549559-gh6gm           1/1     Running   0          2m8s
  openebs-snapshot-operator-75dc998946-xdskl     2/2     Running   0          2m6s
  ```

  Verify that `apiserver` is listed. If you have installed with helm charts,
  the apiserver name may be openebs-apiserver.

## Step 2: Upgrade the OpenEBS Control Plane

Upgrade steps vary depending on the way OpenEBS was installed by you.
Below are steps to upgrade using some common ways to install OpenEBS:

### Prerequisite for control plane upgrade
1. Make sure all the blockdevices that are in use by cstor or localPV are connected to the node.
2. Make sure that all manually created and claimed blockdevices are excluded in the NDM configmap path
filter.

**NOTE: Upgrade of LocalPV rawblock volumes are not supported. Please exclude it in configmap**

eg: If partitions or dm devices are used, make sure it is added to the config map.
To edit the config map, run the following command
```bash
kubectl edit cm openebs-ndm-config -n openebs
```

Add the partitions or manually created disks into path filter if not already present

```yaml
- key: path-filter
        name: path filter
        state: true
        include: ""
        exclude: "loop,/dev/fd0,/dev/sr0,/dev/ram,/dev/dm-,/dev/md,/dev/rbd, /dev/sda1, /dev/nvme0n1p1"
``` 

Here, `/dev/sda1` and `/dev/nvm0n1p1` are partitions that are in use and blockdevices were manually created. It needs
to be included in the path filter of configmap

**Note: If you have any queries or see something unexpected, please reach out to the OpenEBS maintainers via [Github Issue](https://github.com/openebs/openebs/issues) or via #openebs channel on [Kubernetes Slack](https://slack.k8s.io).**

### Upgrade using kubectl (using openebs-operator.yaml):

**Use this mode of upgrade only if OpenEBS was installed using openebs-operator.yaml.**

**The sample steps below will work if you have installed OpenEBS without
modifying the default values in openebs-operator.yaml. If you have customized
the openebs-operator.yaml for your cluster, you will have to download the
desired openebs-operator.yaml and customize it again**

```
#Upgrade to OpenEBS control plane components to desired version. Say 2.2.0
$ kubectl apply -f https://openebs.github.io/charts/2.2.0/openebs-operator.yaml
```

### Upgrade using helm chart (using openebs/openebs, openebs-charts repo, etc.,):

**The sample steps below will work if you have installed openebs with
default values provided by openebs/openebs helm chart.**

Before upgrading via helm, please review the default values available with
latest openebs/openebs chart.
(https://github.com/openebs/charts/blob/master/charts/openebs/values.yaml).

- If the default values seem appropriate, you can use the below commands to
  update OpenEBS. [More](https://hub.helm.sh/charts/openebs/openebs) details about the specific chart version.
  ```sh
  $ helm upgrade --reset-values <release name> openebs/openebs --version 2.2.0
  ```
- If not, customize the values into your copy (say custom-values.yaml),
  by copying the content from above default yamls and edit the values to
  suite your environment. You can upgrade using your custom values using:
  ```sh
  $ helm upgrade <release name> openebs/openebs --version 2.2.0 -f custom-values.yaml`
  ```

### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with desired
release tags and changes made in the values/templates. After updating the YAML
or helm chart or helm chart values, you can use the above procedures to upgrade
the OpenEBS Control Plane components.

### After Upgrade
From 2.0.0 onwards, OpenEBS uses a new algorithm to generate the UUIDs for blockdevices to identify any type of disk across the 
nodes in the cluster. Therefore, blockdevices that were not used (Unclaimed state) in earlier versions will be made
Inactive and new resources will be created for them. Existing devices that are in use will continue to work normally.

**Note: After upgrading to 2.0.0 or above. If the devices that were in use before the upgrade are no longer required and becomes unclaimed at any point of time. Please restart NDM daemon pod on that node to sync those devices with the latest changes.**

## Step 3: Upgrade the OpenEBS Pools and Volumes

**Note:**
- It is highly recommended to schedule a downtime for the application using the
OpenEBS PV while performing this upgrade. Also, make sure you have taken a
backup of the data before starting the below upgrade procedure.
- please have the following link handy in case the volume gets into read-only during upgrade
  https://docs.openebs.io/docs/next/t-volume-provisioning.html#recovery-readonly-when-kubelet-is-container
- Automatic rollback option is not provided. To rollback, you need to update
  the controller, exporter and replica pod images to the previous version
- Before proceeding with the upgrade of the OpenEBS Data Plane components like cStor or Jiva,  verify that OpenEBS Control plane is indeed in desired version
  You can use the following command to verify components are in 2.2.0:
  ```sh
  $ kubectl get pods -n openebs -l openebs.io/version=2.2.0
  ```
  The above command should show that the control plane components are upgrade.
  The output should look like below:
  ```sh
  NAME                                           READY   STATUS    RESTARTS   AGE
  maya-apiserver-7b65b8b74f-r7xvv                1/1     Running   0          2m8s
  openebs-admission-server-588b754887-l5krp      1/1     Running   0          2m7s
  openebs-localpv-provisioner-77b965466c-wpfgs   1/1     Running   0          85s
  openebs-ndm-5mzg9                              1/1     Running   0          103s
  openebs-ndm-bmjxx                              1/1     Running   0          107s
  openebs-ndm-operator-5ffdf76bfd-ldxvk          1/1     Running   0          115s
  openebs-ndm-v7vd8                              1/1     Running   0          114s
  openebs-provisioner-678c549559-gh6gm           1/1     Running   0          2m8s
  openebs-snapshot-operator-75dc998946-xdskl     2/2     Running   0          2m6s
  ```

**Note: If you have any queries or see something unexpected, please reach out to the OpenEBS maintainers via [Github Issue](https://github.com/openebs/openebs/issues) or via #openebs channel on [Kubernetes Slack](https://slack.k8s.io).**

As you might have seen by now, control plane components and data plane components
work independently. Even after the OpenEBS Control Plane components have been
upgraded to 1.12.0, the Storage Pools and Volumes (both jiva and cStor)
will continue to work with older versions.

You can use the below steps for upgrading cstor and jiva components.

Starting with 1.1.0, the upgrade steps have been changed to eliminate the
need for downloading scripts. You can use `kubectl` to trigger an upgrade job
using Kubernetes Job spec.

The following instructions provide details on how to create your Upgrade Job specs.
Please ensure the `from` and `to` versions are as per your upgrade path. The below
examples show upgrading from 1.0.0 to 1.12.0.

### Upgrade the OpenEBS Jiva PV

**Note:Scaling down the application will speed up the upgrade process and prevent any read only issues. It is highly recommended to scale down the application upgrading from 1.8.0 or earlier versions of the volume.**

Extract the PV name using `kubectl get pv`

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS           REASON   AGE
pvc-713e3bb6-afd2-11e9-8e79-42010a800065   5G         RWO            Delete           Bound    default/bb-jd-claim   openebs-jiva-default            46m
pvc-80c120e8-bd09-4c5e-aaeb-3c37464240c5   4G         RWO            Delete           Bound    default/jiva-vol3     jiva-1r                         13m
pvc-82a2d097-c666-4f29-820d-6b7e41541c11   4G         RWO            Delete           Bound    default/jiva-vol2     jiva-1r                         43m

```

Create a Kubernetes Job spec for upgrading the jiva volume. An example spec is as follows:
```yaml
#This is an example YAML for upgrading jiva volume.
#Some of the values below needs to be changed to
#match your openebs installation. The fields are
#indicated with VERIFY
---
apiVersion: batch/v1
kind: Job
metadata:
  #VERIFY that you have provided a unique name for this upgrade job.
  #The name can be any valid K8s string for name. This example uses
  #the following convention: jiva-vol-<flattened-from-to-versions>
  name: jiva-vol-1120210

  #VERIFY the value of namespace is same as the namespace where openebs components
  # are installed. You can verify using the command:
  # `kubectl get pods -n <openebs-namespace> -l openebs.io/component-name=maya-apiserver`
  # The above command should return status of the openebs-apiserver.
  namespace: openebs

spec:
  backoffLimit: 4
  template:
    spec:
      # VERIFY the value of serviceAccountName is pointing to service account
      # created within openebs namespace. Use the non-default account.
      # by running `kubectl get sa -n <openebs-namespace>`
      serviceAccountName: openebs-maya-operator
      containers:
      - name:  upgrade
        args:
        - "jiva-volume"

        # --from-version is the current version of the volume
        - "--from-version=1.12.0"

        # --to-version is the version desired upgrade version
        - "--to-version=2.2.0"

        # Bulk upgrade is supported
        # To make use of it, please provide the list of PVs
        # as mentioned below
        - "pvc-1bc3b45a-3023-4a8e-a94b-b457cf9529b4"
        - "pvc-82a2d097-c666-4f29-820d-6b7e41541c11"
        
        #Following are optional parameters
        #Log Level
        - "--v=4"
        #DO NOT CHANGE BELOW PARAMETERS
        env:
        - name: OPENEBS_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        tty: true

        # the image version should be same as the --to-version mentioned above
        # in the args of the job
        image: openebs/m-upgrade:<same-as-to-version>
        imagePullPolicy: Always
      restartPolicy: OnFailure
---
```

Execute the Upgrade Job Spec
```sh
$ kubectl apply -f jiva-vol-1001120.yaml
```

You can check the status of the Job using commands like:
```sh
$ kubectl get job -n openebs
$ kubectl get pods -n openebs #to check on the name for the job pod
$ kubectl logs -n openebs jiva-upg-1120210-bgrhx
```

### Upgrade cStor Pools

Extract the SPC name using `kubectl get spc`

```sh
NAME                AGE
cstor-disk-pool     26m
cstor-sparse-pool   24m
```

The Job spec for upgrade cstor pools is:

```yaml
#This is an example YAML for upgrading cstor SPC.
#Some of the values below needs to be changed to
#match your openebs installation. The fields are
#indicated with VERIFY
---
apiVersion: batch/v1
kind: Job
metadata:
  #VERIFY that you have provided a unique name for this upgrade job.
  #The name can be any valid K8s string for name. This example uses
  #the following convention: cstor-spc-<flattened-from-to-versions>
  name: cstor-spc-1120210

  #VERIFY the value of namespace is same as the namespace where openebs components
  # are installed. You can verify using the command:
  # `kubectl get pods -n <openebs-namespace> -l openebs.io/component-name=maya-apiserver`
  # The above command should return status of the openebs-apiserver.
  namespace: openebs
spec:
  backoffLimit: 4
  template:
    spec:
      #VERIFY the value of serviceAccountName is pointing to service account
      # created within openebs namespace. Use the non-default account.
      # by running `kubectl get sa -n <openebs-namespace>`
      serviceAccountName: openebs-maya-operator
      containers:
      - name:  upgrade
        args:
        - "cstor-spc"

        # --from-version is the current version of the pool
        - "--from-version=1.12.0"

        # --to-version is the version desired upgrade version
        - "--to-version=2.2.0"

        # Bulk upgrade is supported
        # To make use of it, please provide the list of SPCs
        # as mentioned below
        - "cstor-sparse-pool"
        - "cstor-disk-pool"
    
        #Following are optional parameters
        #Log Level
        - "--v=4"
        #DO NOT CHANGE BELOW PARAMETERS
        env:
        - name: OPENEBS_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        tty: true

        # the image version should be same as the --to-version mentioned above
        # in the args of the job
        image: openebs/m-upgrade:<same-as-to-version>
        imagePullPolicy: Always
      restartPolicy: OnFailure
---
```


### Upgrade cStor Volumes

Extract the PV name using `kubectl get pv`

```sh
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                  STORAGECLASS           REASON    AGE
pvc-1085415d-f84c-11e8-aadf-42010a8000bb   5G         RWO            Delete           Bound     default/demo-cstor-sparse-vol1-claim   openebs-cstor-sparse             22m
pvc-a4aba0e9-8ad3-4d18-9b34-5e6e7cea2eb3   4G         RWO            Delete           Bound    default/cstor-disk-vol   openebs-cstor-disk            53s
```

Create a Kubernetes Job spec for upgrading the cstor volume. An example spec is as follows:
```yaml
#This is an example YAML for upgrading cstor volume.
#Some of the values below needs to be changed to
#match your openebs installation. The fields are
#indicated with VERIFY
---
apiVersion: batch/v1
kind: Job
metadata:
  #VERIFY that you have provided a unique name for this upgrade job.
  #The name can be any valid K8s string for name. This example uses
  #the following convention: cstor-vol-<flattened-from-to-versions>
  name: cstor-vol-1120210

  #VERIFY the value of namespace is same as the namespace where openebs components
  # are installed. You can verify using the command:
  # `kubectl get pods -n <openebs-namespace> -l openebs.io/component-name=maya-apiserver`
  # The above command should return status of the openebs-apiserver.
  namespace: openebs

spec:
  backoffLimit: 4
  template:
    spec:
      #VERIFY the value of serviceAccountName is pointing to service account
      # created within openebs namespace. Use the non-default account.
      # by running `kubectl get sa -n <openebs-namespace>`
      serviceAccountName: openebs-maya-operator
      containers:
      - name:  upgrade
        args:
        - "cstor-volume"

        # --from-version is the current version of the volume
        - "--from-version=1.12.0"

        # --to-version is the version desired upgrade version
        - "--to-version=2.2.0"

        # Bulk upgrade is supported from 1.9
        # To make use of it, please provide the list of PVs
        # as mentioned below
        - "pvc-c630f6d5-afd2-11e9-8e79-42010a800065"
        - "pvc-a4aba0e9-8ad3-4d18-9b34-5e6e7cea2eb3"
        
        #Following are optional parameters
        #Log Level
        - "--v=4"
        #DO NOT CHANGE BELOW PARAMETERS
        env:
        - name: OPENEBS_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        tty: true

        # the image version should be same as the --to-version mentioned above
        # in the args of the job
        image: openebs/m-upgrade:<same-as-to-version>
        imagePullPolicy: Always
      restartPolicy: OnFailure
---
```
