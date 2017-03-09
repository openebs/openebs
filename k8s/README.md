# Using OpenEBS with K8s

This folder contains the software components, usage instructions and examples of using OpenEBS with K8s. 

OpenEBS can be deployed along-side Kubernetes master and minions (hyper-converged) or can be deployed in dedicated mode, connecting via the K8s FlexVolume plugins. 

If this is your first time to Kubernetes, please go through these introductory tutorials: 
- https://www.udacity.com/course/scalable-microservices-with-kubernetes--ud615
- https://kubernetes.io/docs/tutorials/kubernetes-basics/


The content here is organised as follows:

```
|---dedicated  (scripts, install/setup instructions and usage examples )
|  
|---flexvolume (K8s volume drivers used either in dedicated or hypercoverged model)
|  |--- openebs-iscsi
|  |--- openebs-tcmu
|  |--- openebs-localdisks
|
|--hyperconverged (scripts, install/setup instructions and usage examples )
|  
   
   
```
