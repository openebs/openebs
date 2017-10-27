# Using OpenEBS with K8s

This folder contains the software components (plugins, scripts, drivers etc.,), usage instructions and application examples of using OpenEBS with K8s. 

OpenEBS can be deployed along-side Kubernetes master and minions (hyper-converged) or can be deployed in dedicated mode, connecting via the K8s FlexVolume plugins. 

If this is your first time to Kubernetes, please go through these introductory tutorials: 
- https://www.udacity.com/course/scalable-microservices-with-kubernetes--ud615
- https://kubernetes.io/docs/tutorials/kubernetes-basics/


The content here is organised as follows:

```
|---dedicated  ( install/setup instructions and usage examples )
|
|---hyperconverged ( install/setup instructions and usage examples )
|
|---demo ( scripts, providers for vagrant, terraform, ansible etc., used either in dedicated/hypercoverged mode )
|
|---flexvolume (K8s volume drivers used either in dedicated/hypercoverged mode)
|  |--- openebs-iscsi
|  |--- openebs-tcmu
|  |--- openebs-localdisks
|  
|---tests (e2e tests using the usage examples under dedicated and hypercoverged mode)
|
|  
```
