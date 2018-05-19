# What is the Go Kit Project?
To understand in plain terms, let us take an example where we end up writing same Go packages again and again to do the same task at different levels in the different Go projects under the same organization. We are all familiar with the custom logger package in the different Go projects.
What if, the custom logger package is same across the organization and can be reused by simply importing it, then this custom logger package is the perfect fit for Kit project. The advantages of this approach go beyond avoiding duplicate code, improved readability of the projects in an organization, to savings in terms of time and cost as well :-)
If you go through the [Bill’s](https://twitter.com/goinggodotnet) [talk](https://youtu.be/spKM5CyBwJA?list=PLFjrjdmBd0CoclkJ_JdBET5fzz4u0SELZ), you will notice that Kit project is characterized by Usability, Purpose and Portability. In this blog, I will discuss how I have applied the refactored the code to use the “Kit Project” pattern for [maya](https://github.com/openebs/maya).

## How to convert existing projects to have “kit”
OpenEBS being a container native project is delivered via set of containers. For instance, with OpenEBS 0.3 release we have the following active maya related projects:

* openebs/maya aka maya-cli : is the command line interface like kubectl for interacting with maya services for performing storage operations.
* openebs/mayaserver : or m-apiserver abstracts a generic volume api that can be used to provision OpenEBS Disks using containers launched using the CO like K8s, nomad etc.,
* openebs/openebs-k8s-provisioner : is the K8s controller for dynamically creating OpenEBS PVs
With these projects, we are already seeing how code gets duplicated when each of these projects are independently developed. For example maya-cli and openebs-k8s-provisioner both need to interact with maya-api-server, which resulted in maya-api-server-client code being written in maya-cli and openebs-k8s-provisioner. Similarly, openebs-k8s-provisioner and maya-api-server have duplicated code w.r.t to accessing the K8s services.

To avoid this duplicity of code using the kit project, we are transforming openebs/maya into a Kit project for the Application projects like maya-api-server, openebs-k8s-provisioner and many more coming up in the future. openebs/maya contains all the kubernetes & nomad API’s, common utilities etc. needed for development of maya-api-server and maya-storage-bot. In the near future, we are trying to push our custom libraries to maya. So that, it will become a promising Go kit project for OpenEBS community.

Lets now see, how maya (as kit project) adheres to the package oriented design principles:


- Usability    
    
    We moved common packages such as orchprovider, types, pkg to maya from maya-api-server. These packages are very generic and can be used in most of the Go projects in OpenEBS organization. Brief details about new packages in Maya. 
   *  Orchprovider : orchprovider contains packages of different orchestrators such as kubernetes and nomad.
   *  types: types provides all the generic types related to orchestrator.
   *  pkg: pkg contains packages like nethelper, util etc.
   *  volumes: volumes contain packages related to volume provisioner and profiles.

- Purpose
        
    While the Packages in the Kit project are categorised as per the functionality, the naming convention should ideally provide the reader with the information on what the package “provides”. So, the packages (in kit project) must provide, not contain. In maya, we have packages like types, orchprovider, volumes etc. name of these packages suggests the functionality provided by them.
- Portability
    
    Portability is important factor for packages in kit project. Hence, we are making maya in such a way that it will be easy to import and use in any Go project. Packages in the Maya are not single point of dependency and all the packages are independent of each other. For example, types directory contains versioned Kubernetes and Nomad packages. These packages are simply importable to any project to use kubernetes and Nomad API’s.

## Example usage of maya kit project
Maya-api-server uses maya as a Kit project. Maya-api-server exposes OpenEBS operations in form of REST APIs. This allows multiple clients e.g. volume related plugins to consume OpenEBS storage operations exposed by Maya API server. Maya-api-server will use volume provisioner as well as orchestration provider modules from Maya. Maya-api-server will always have HTTP endpoints to do OpenEBS operations.
Similarly, openebs-k8s-provisioner will use the maya-kit project kubernetes API to query for details about the Storage Classes, etc.,
Another usage is of the maya-kit project, maya-api-server client that is accessed by maya-cli as well as the openebs-k8s-provisioner to talk to maya-api-server.

## Conclusion
Go Kit project should contain packages which are usable, purposeful and portable. Go Kit projects will improve the efficiency of the organization at both human and code level.
