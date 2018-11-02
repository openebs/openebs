# What is the Go Kit Project?
To understand in plain terms, let us take an example where we end up writing same Go packages, repeatedly, to do the same task at different levels in different Go projects under the same organization. We are all familiar with the custom logger package in the different Go projects.
What if, the custom logger package is same across the organization and can be reused by simply importing it, then this custom logger package is the perfect fit for kit project. The advantages of this approach go beyond avoiding duplicate code, improved readability of the projects in an organization, to savings in terms of time and cost as well :-)
If you go through the [Bill’s](https://twitter.com/goinggodotnet) [talk](https://youtu.be/spKM5CyBwJA?list=PLFjrjdmBd0CoclkJ_JdBET5fzz4u0SELZ), you will notice that kit project is characterized by usability, purpose and portability. In this blog, we will discuss how we have refractored the code to use the “Kit Project” pattern for [maya](https://github.com/openebs/maya).

## How to convert existing projects to have “kit”?
OpenEBS being a container native project is delivered via a set of containers. For instance, with OpenEBS 0.3 release we have the following active maya related projects:

* openebs/maya aka maya-cli : is the command line interface like kubectl for interacting with Maya services for performing storage operations.
* openebs/mayaserver : or m-apiserver abstracts a generic volume API that can be used to provision OpenEBS Disks using containers launched using the CO like K8s, nomad etc.,
* openebs/openebs-k8s-provisioner : is the K8s controller for dynamically creating OpenEBS PVs
With these projects, we are already seeing how code gets duplicated when each of these projects are independently developed. For example maya-cli and openebs-k8s-provisioner both need to interact with maya-apiserver, which resulted in maya-apiserver-client code being written in maya-cli and openebs-k8s-provisioner. Similarly, openebs-k8s-provisioner and maya-apiserver have duplicated code w.r.t to accessing the K8s services.

To avoid this duplicity of code using the kit project, we are transforming openebs/maya into a Kit project for the application projects like maya-apiserver, openebs-k8s-provisioner and many more coming up in the future. openebs/maya contains all the Kubernetes & nomad APIs, common utilities etc. needed for development of maya-apiserver and maya-storage-bot. In the near future, we are trying to push our custom libraries to maya, so that, it will become a promising Go kit project for OpenEBS community.

Let us now see, how maya (as a kit project) adheres to the package oriented design principles:

- Usability

    We moved common packages such as orchprovider, types, pkg to maya from maya-apiserver. These packages are very generic and can be used in most of the Go projects in the OpenEBS organization. Brief details about new packages in maya are as follows:
   *  orchprovider : orchprovider contains packages of different orchestrators such as Kubernetes and nomad.
   *  types: types provides all the generic types related to orchestrator.
   *  pkg: pkg contains packages like nethelper, util etc.
   *  volumes: volumes contain packages related to volume provisioner and profiles.

- Purpose

    While the packages in the kit project are categorized as per the functionality, the naming convention should ideally provide the reader with the information on what the package “provides”. So, the packages (in a kit project) must provide, not contain. In maya, we have packages like types, orchprovider, volumes etc. The name of these packages suggests the functionality provided by them.

- Portability

    Portability is an important factor for packages in a kit project. Hence, we are making maya in such a way that it will be easy to import and use in any Go project. Packages in maya are not a single point of dependency and all the packages are independent of each other. For example, types directory contains versioned Kubernetes and Nomad packages. These packages are simply importable to any project to use Kubernetes and Nomad API’s.

## Example usage of maya kit project
Maya-apiserver uses maya as a kit project. Maya-apiserver exposes OpenEBS operations in form of REST APIs. This allows multiple clients e.g. volume related plugins to consume OpenEBS storage operations exposed by maya-apiserver. Maya-apiserver will use volume provisioner as well as orchestration provider modules from maya. Maya-apiserver will always have HTTP endpoints to do OpenEBS operations.
Similarly, openebs-k8s-provisioner will use the maya-kit project Kubernetes API to query for details about the storage classes, etc.
Another usage is of the maya-kit project, maya-apiserver client that is accessed by maya-cli as well as the openebs-k8s-provisioner to talk to maya-apiserver.

## Conclusion
Go kit project should contain packages which are usable, purposeful and portable. Go Kit projects will improve the efficiency of the organization at both human and code level.
