# UPGRADE FROM OPENEBS 0.5.3+ TO 0.6.0

## Overview

This document describes the steps for upgrading OpenEBS from 0.5.3 or 0.5.4 to 0.6.0. The upgrade of OpenEBS is a two step process. 
- *Step 1* - Upgrade the OpenEBS Operator 
- *Step 2* - Upgrade the OpenEBS Volumes that were created with older OpenEBS Operator (0.5.3 or 0.5.4)

### Terminology
- *OpenEBS Operator : Refers to maya-apiserver & openebs-provisioner along w/ respective services, service a/c, roles, rolebindings*
- *OpenEBS Volume: The Jiva controller & replica pods*
- *All steps described in this document need to be performed on the Kubernetes master or from a machine that has access to Kubernetes master*

## Step 1: Upgrade the OpenEBS Operator

OpenEBS installation is very flexible and highly configurable. It can be installed using the default openebs-operator.yaml file with default settings or via customized openebs-operator.yaml. One of the key features or flexibility added in openebs 0.6 is to have the option of selecting the nodes on which replica's will be installed. To enable this feature, you will need to label the nodes using `kubectl label nodes ...` and then customize the default openebs-operator.yaml to include the label in the `REPLICA_NODE_SELECTOR_LABEL`.  Note that, this feature of node-selector will help if you have a K8s cluster of more than 3 nodes and you would like to restrict the volume replicas to a subset of 3 nodes. 

Upgrade steps for OpenEBS Operator depend on the way OpenEBS was installed. Depending on the way OpenEBS was installed, select one of the following:

### Install/Upgrade using kubectl (using openebs-operator.yaml )

**The sample steps below will work if you have installed openebs without modifying the default values**

```
#Delete older operator and storage classes. With OpenEBS 0.6, all the components are installed in namespace `openebs`
# as opposed to `default` namespace in earlier releases. Before upgrading to 0.6, delete the older version and 
# then apply the newer versions. 
kubectl delete -f https://raw.githubusercontent.com/openebs/openebs/v0.5/k8s/openebs-operator.yaml
kubectl delete -f https://raw.githubusercontent.com/openebs/openebs/v0.5/k8s/openebs-storageclasses.yaml
#Wait for objects to be delete, you can check using `kubectl get deploy`

#Install the 0.6 operator and storage classes.
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/v0.6/k8s/openebs-operator.yaml
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/v0.6/k8s/openebs-storageclasses.yaml
```

### Install/Upgrade using helm chart (using stable/openebs, openebs-charts repo, etc.,) 

**The sample steps below will work if you have installed openebs with default values provided by stable/openebs helm chart.**

- Run `helm ls` to get the release name of openebs. 
- Upgrade using `helm upgrade -f https://openebs.github.io/charts/helm-values-0.6.0.yaml <release-name> stable/openebs`

### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 0.6 release tags and changes made in the values/templates. 

You can use the following as references to know about the changes in 0.6: 
- stable/openebs [PR#6768](https://github.com/helm/charts/pull/6768) or 
- openebs-charts [PR#1646](https://github.com/openebs/openebs/pull/1646) as reference.

After updating the YAML or helm chart or helm chart values, you can use the above procedures to upgrade the OpenEBS Operator

## Step 2: Upgrade the OpenEBS Volumes

Even after the OpenEBS Operator has been upgraded to 0.6, the volumes will continue to work with 0.5.3 or 0.5.4. Each of the volumes should be upgraded (one at a time) to 0.6, using the steps provided below. 

*Note: There has been a change in the way OpenEBS Controller Pods communicate with the Replica Pods. So, it is recommended to schedule a downtime for the application using the OpenEBS PV while performing this upgrade. Also, make sure you have taken a backup of the data before starting the below upgrade procedure.*

In 0.5.x releases, when a replica is shutdown, it will get rescheduled to another available node in the cluster and start copying the data from the other replicas. This is not a desired behaviour during upgrades, which will create new replica's as part of the rolling-upgrade. To pin the replicas or force them to the nodes where the data is already present, starting with 0.6 - we use the concept of nodeSelector and Tolerations that will make sure replica's are not moved on node or pod delete operations.

So as part of upgrade, we recommend that you label the nodes where the replica pods are scheduled as follows:
```
kubectl label nodes gke-kmova-helm-default-pool-d8b227cc-6wqr "openebs-pv"="openebs-storage"
```
Note that the key `openebs-pv` is fixed, however you can use any value in place of `openebs-storage`. This value will be taken as a parameters in the upgrade script below. 

Repeat the above step of labellilng the node for all the nodes where replica's are scheduled. The assumption is that all the PV replica's are scheduled on the same set of 3 nodes. 

Limitations:
- need to handle cases where there are a mix of PVs with 1 and 3 replicas or 
- scenario like PV1 replicas are on nodes - n1, n2, n3, where as PV2 replicas are on nodes - n2, n3, n4
- this is a preliminary script only intended for using on volumes where data has been backed-up.
- please have the following link handy in case the volume gets into read-only during upgrade 
  https://docs.openebs.io/docs/next/readonlyvolumes.html
- automatic rollback option is not provided. To rollback, you need to update the controller, exporter and replica pod images to the previous version
- in the process of running the below steps, if you run into issues, you can always reach us on slack

### Download the upgrade scripts

Either `git clone` or download the following files to your work directory. 
https://github.com/openebs/openebs/tree/master/k8s/upgrades/0.5.x-0.6.0
- `patch-strategy-recreate.json`
- `replica.patch.tpl.yml`
- `controller.patch.tpl.yml`
- `oebs_update.sh`

### Select the PV that needs to be upgraded. 

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

