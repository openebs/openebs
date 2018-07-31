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

## Step 2: Upgrade the OpenEBS Volumes (WIP)

Even after the OpenEBS has been upgraded to 0.6, the volumes will continue to work with 0.5.3. However, with 0.6 - there are good fixes w.r.t volume stability in the event of node failures that are good to consume. The upgrades of the volumes have to be planned by scheduling an application downtime. 



```
kubectl get pv
```

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                          STORAGECLASS      REASON    AGE
pvc-48fb36a2-947f-11e8-b1f3-42010a800004   5G         RWO            Delete           Bound     percona-test/demo-vol1-claim   openebs-percona             8m
```

```
kubectl label nodes gke-kmova-helm-default-pool-d8b227cc-6wqr "openebs-pv"="pvc-48fb36a2-947f-11e8-b1f3-42010a800004"
```

```
./oebs_update.sh pvc-48fb36a2-947f-11e8-b1f3-42010a800004
```
