## INTRODUCTION TO OPENEBS E2E

OpenEBS e2e is focused on workload simulation & application deployment on OpenEBS storage, predominantly in a 
kubernetes environment. It also includes compliance and resiliency tests. The scope of the said tests is expected to
evolve over time. The e2e is mostly written in ansible, i.e., as ansible playbooks with docker used for test images (these
include standard application images from dockerhub as well as custom-built images stored in openebs/test-storage). 
Since the tests are performed in a kubernetes environment, the test images are typically deployed as "pods" and "jobs".

## BUILDING BLOCKS OF OPENEBS CI

The OpenEBS e2e tests are executed upon commits to the core openebs github repositories such as openebs/openebs, 
openebs/mayaserver, openebs/jiva. This continuous integration is built around Jenkins, which creates a set of VMs using Vagrant,
and runs the ansible playbooks to setup the environment and execute e2e tests. The below schema illustrates this workflow

![OpenEBS CI Overview Diagram](https://github.com/ksatchit/openebs/blob/master/documentation/source/_static/OpenEBS_CI_Workflow.png)


