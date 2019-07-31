# UPGRADE FROM OPENEBS 1.0.0 TO 1.1.0

## Overview

This document describes the steps for upgrading OpenEBS from 1.0.0 to 1.1.0

The upgrade of OpenEBS is a three step process:
- *Step 1* - Prerequisites
- *Step 2* - Upgrade the OpenEBS Control Plane Components
- *Step 3* - Upgrade the OpenEBS Data Plane Components from previous version (1.0.0)

### Terminology

- *OpenEBS Control Plane: Refers to maya-apiserver, openebs-provisioner, etc along w/ respective RBAC components* 
- *OpenEBS Data Plane: Refers to Storage Engine pods like cStor, Jiva controller(aka target) & replica pods*


## Step 1: Prerequisites

**Note: It is mandatory to make sure to that all OpenEBS control plane 
and data plane components are running with version 1.0.0 before the upgrade.**

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

- Verify that OpenEBS Control plane is indeed in 1.0.0 version
  ```sh
  $ kubectl get pods -n openebs -l openebs.io/version=1.0.0
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

### Upgrade using kubectl (using openebs-operator.yaml):

**Use this mode of upgrade only if OpenEBS was installed using openebs-operator.yaml.**

**The sample steps below will work if you have installed OpenEBS without 
modifying the default values in openebs-operator.yaml. If you have customized 
the openebs-operator.yaml for your cluster, you will have to download the 
1.1.0 openebs-operator.yaml and customize it again**

```
#Upgrade to OpenEBS control plane components to version 1.1.0 
$ kubectl apply -f https://openebs.github.io/charts/openebs-operator-1.1.0.yaml
```

### Upgrade using helm chart (using stable/openebs, openebs-charts repo, etc.,):

**The sample steps below will work if you have installed openebs with 
default values provided by stable/openebs helm chart.**

Before upgrading via helm, please review the default values available with 
latest stable/openebs chart. 
(https://raw.githubusercontent.com/helm/charts/master/stable/openebs/values.yaml).

- If the default values seem appropriate, you can use the below commands to
  update OpenEBS. [More](https://hub.helm.sh/charts/stable/openebs) details about the specific chart version.
  ```sh
  $ helm upgrade --reset-values <release name> stable/openebs --version 1.1.0
  ```
- If not, customize the values into your copy (say custom-values.yaml), 
  by copying the content from above default yamls and edit the values to 
  suite your environment. You can upgrade using your custom values using:
  ```sh
  $ helm upgrade <release name> stable/openebs --version 1.1.0 -f custom-values.yaml`
  ```

### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 1.1.0 
release tags and changes made in the values/templates. After updating the YAML 
or helm chart or helm chart values, you can use the above procedures to upgrade 
the OpenEBS Control Plane components.

## Step 3: Upgrade the OpenEBS Pools and Volumes


**Note: Upgrade functionality is still under active development. 
It is highly recommended to schedule a downtime for the application using the 
OpenEBS PV while performing this upgrade. Also, make sure you have taken a 
backup of the data before starting the below upgrade procedure.**

- please have the following link handy in case the volume gets into read-only during upgrade
  https://docs.openebs.io/docs/next/troubleshooting.html#recovery-readonly-when-kubelet-is-container

- automatic rollback option is not provided. To rollback, you need to update 
  the controller, exporter and replica pod images to the previous version

**Note: Before proceeding with the upgrade of the OpenEBS Data Plane components 
like cStor or Jiva, verify that OpenEBS Control plane is indeed in 1.1.0 version**

  You can use the following command to verify:
  ```sh
  $ kubectl get pods -n openebs -l openebs.io/version=1.1.0
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

**Note: If you have any queries or see something unexpected, please reach out to the 
OpenEBS maintainers via [Github Issue](https://github.com/openebs/openebs/issues) or via [OpenEBS Slack](https://slack.openebs.io).**

As you might have seen by now, control plane components and data plane components
work independently. Even after the OpenEBS Control Plane components have been 
upgraded to 1.1.0, the Storage Pools and Volumes (both jiva and cStor)
will continue to work with older versions. 

You can use the below steps for upgrading cstor and jiva components. 

Starting with 1.1.0, the upgrade steps have been changed to eliminate the
need for downloading scripts. You can use `kubectl` to trigger an upgrade job 
using Kubernetes Job spec. The following instructions provide details on how
to create your Upgrade Job specs. 

### Upgrade the OpenEBS Jiva PV

Extract the PV name using `kubectl get pv`

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS           REASON   AGE
pvc-713e3bb6-afd2-11e9-8e79-42010a800065   5G         RWO            Delete           Bound    default/bb-jd-claim   openebs-jiva-default            46m
```

Create a Kubernetes Job spec for upgrading the jiva volume. An example spec is as follows:
```
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
  #the following convention: jiva-vol-<flattened-from-to-versions>-<pv-name>
  name: jiva-vol-100110-pvc-713e3bb6-afd2-11e9-8e79-42010a800065
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
        - "jiva-volume"
        - "--from-version=1.0.0"
        - "--to-version=1.1.0"
        #VERIFY that you have provided the correct cStor PV Name
        - "--pv-name=pvc-713e3bb6-afd2-11e9-8e79-42010a800065"
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
        image: quay.io/openebs/m-upgrade:1.1.0
      restartPolicy: OnFailure
---
```

Execute the Upgrade Job Spec
```
$ kubectl apply -f jiva-vol-100110-pvc713.yaml
```

You can check the status of the Job using commands like:
```
$ kubectl get job -n openebs
$ kubectl get pods -n openebs #to check on the name for the job pod
$ kubectl logs -n openebs jiva-upg-100111-pvc-713e3bb6-afd2-11e9-8e79-42010a800065-bgrhx
```

### Upgrade cStor Pools

Extract the SPC name using `kubectl get spc`

```sh
NAME                AGE
cstor-sparse-pool   24m
```

The Job spec for upgrade cstor pools is:

```sh
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
  #the following convention: cstor-spc-<flattened-from-to-versions>-<spc-name>
  name: cstor-spc-100110-cstor-sparse-pool
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
        - "--from-version=1.0.0"
        - "--to-version=1.1.0"
        #VERIFY that you have provided the correct SPC Name
        - "--spc-name=cstor-sparse-pool"
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
        image: quay.io/openebs/m-upgrade:1.1.0
      restartPolicy: OnFailure
---
```


### Upgrade cStor Volumes

Extract the PV name using `kubectl get pv`

```sh
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                  STORAGECLASS           REASON    AGE
pvc-1085415d-f84c-11e8-aadf-42010a8000bb   5G         RWO            Delete           Bound     default/demo-cstor-sparse-vol1-claim   openebs-cstor-sparse             22m
```

Create a Kubernetes Job spec for upgrading the cstor volume. An example spec is as follows:
```
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
  #the following convention: cstor-vol-<flattened-from-to-versions>-<pv-name>
  name: cstor-vol-100110-pvc-c630f6d5-afd2-11e9-8e79-42010a800065
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
        - "--from-version=1.0.0"
        - "--to-version=1.1.0"
        #VERIFY that you have provided the correct cStor PV Name
        - "--pv-name=pvc-c630f6d5-afd2-11e9-8e79-42010a800065"
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
        image: quay.io/openebs/m-upgrade:1.1.0
      restartPolicy: OnFailure
---
```
