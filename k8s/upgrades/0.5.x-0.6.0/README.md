# UPGRADE FROM OPENEBS 0.5.3+ TO 0.6.0

## Overview

This document describes the steps for upgrading OpenEBS from 0.5.3 or 0.5.4 to 0.6.0. The upgrade of OpenEBS is a two step process. 
- *Step 1* - Upgrade the OpenEBS Operator 
- *Step 2* - Upgrade the OpenEBS Volumes that were created with older OpenEBS Operator (0.5.3 or 0.5.4)

## Terminology
- *OpenEBS Operator : Refers to maya-apiserver & openebs-provisioner along w/ respective services, service a/c, roles, rolebindings*
- *OpenEBS Volume: The Jiva controller & replica pods*
- *All steps described in this document need to be performed on the Kubernetes master or from a machine that has access to Kubernetes master*

## Step 1: Upgrade the OpenEBS Operator

Upgrade steps for OpenEBS Operator depend on the way OpenEBS was installed. Depending on the way OpenEBS was installed, select one of the following:

### Using openebs-operator.yaml 
With OpenEBS 0.6, all the components are installed in namespace `openebs` as opposed to `default` namespace in earlier releases. So before upgrading to 0.6, delete the older version and then apply the newer versions. Assuming there were no modifications done to the default operator, use the following steps:
```
#Delete older operator and storage classes.
kubectl delete -f https://raw.githubusercontent.com/openebs/openebs/v0.5/k8s/openebs-operator.yaml
kubectl delete -f https://raw.githubusercontent.com/openebs/openebs/v0.5/k8s/openebs-storageclasses.yaml
#Wait for objects to be delete, you can check using `kubectl get deploy`

#Install the 0.6 operator and storage classes.
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/v0.6/k8s/openebs-operator.yaml
kubectl apply -f https://raw.githubusercontent.com/openebs/openebs/v0.6/k8s/openebs-storageclasses.yaml
```

### Using stable/openebs helm chart
- Run `helm ls` to get the release name of openebs. 
- Upgrade using `helm upgrade -f https://openebs.github.io/charts/helm-values-0.6.0.yaml <release-name> stable/openebs`

### Using customized operator YAML or helm chart.
As a first step, you must update your custom helm chart or YAML with 0.6 release tags and changes made in the values/templates. You can use the following as references to know about the changes in 0.6: 
- stable/openebs [PR#6768](https://github.com/helm/charts/pull/6768) or 
- openebs-charts [PR#1646](https://github.com/openebs/openebs/pull/1646) as reference.

## Step 2: Upgrade the OpenEBS Volumes

TODO
