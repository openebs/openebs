## INTRODUCTION TO OPENEBS E2E

OpenEBS e2e is focused on workload simulation and application deployment on OpenEBS storage, predominantly in a 
kubernetes environment.In its current state, it includes application workflow tests, basic compliance and resiliency tests. 
The scope of the said tests is expected to evolve over time to include performance and security tests as well. 
e2e is mostly written in ansible, that is, as ansible playbooks with docker used for test images(these include standard 
application images from dockerhub as well as custom-built images stored in openebs/test-storage).Since the tests are performed 
in a Kubernetes environment, the test images are typically deployed as "pods" and "jobs".Therefore they are accompanied by the 
respective YAML specification files.

## BUILDING BLOCKS OF OPENEBS CI

OpenEBS Continuous Integration (CI) has two distinct parts:

- Travis is used to run unit tests, build code and push images to dockerhub (in case of repositories where image is the build artifact)
- Jenkins pulls these images, creates the Kubernetes-based test environment and executes e2e. It is also used to run tests on commits that change application specifications or OpenEBS Kubernetes deployment specifications

While you can run OpenEBS e2e as a standalone suite, the priority is to run them on commits done on the core OpenEBS github
repositories such as openebs/openebs, openebs/mayaserver, openebs/jiva. This part of the continuous integration is built around a dedicated Jenkins server.On detecting commits via a polling mechanism, Jenkins launches VMs using Vagrant and runs the ansible playbooks to setup the environment and execute e2e tests.The openebs/e2e project focuses on this part of the CI.

The following schema illustrates the workflow

![OpenEBS CI Overview Diagram](https://github.com/ksatchit/openebs/blob/master/documentation/source/_static/OpenEBS_CI_Workflow.png)

## CONTRIBUTING TO E2E and OPENEBS CI 

Contributions are welcome !!  Before starting, a reading of the project documentation at [ReadTheDocs](http://openebs.readthedocs.io/en/latest/ ) is highly recommended. Please raise a github issue for any questions you may have on the project in general or e2e or CI in particular.
You can post questions on the OpenEBS [slack channel](http://slack.openebs.io/) too.

You could contribute to any of the following areas: 

- Submit proposals to add new tests to e2e
- Create new application specification YAMLs 
- Create ansible playbooks to execute test workflows
- Submit changes to fix bugs or improve e2e tests 
- Raise/fix issues on the CI framework 
- Raise/fix issues on the e2e and CI documentation

## GENERAL CONTRIBUTION GUIDELINES

Here are some general contribution guidelines. 

### Adding new tests/test-categories

To add new tests, please raise an issue describing the objective, pre-requisites, test steps, expected results and cleanup routines.
In case of proposals to add new test categories, add a generic description explaining the purpose and value addition

Once accepted, the issue can be assigned to interested contributors who can make relevant changes with a pull request. 

### Create new application YAMLs

To add new applications to e2e, please consider the points made here, if applicable: 

- https://kubernetes.io/docs/concepts/configuration/overview/
- https://www.mirantis.com/blog/introduction-to-yaml-creating-a-kubernetes-deployment/
- https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/

These can be placed here : https://github.com/openebs/openebs/tree/master/k8s/demo

### Create ansible playbooks to execute test workflows

The test playbooks can be placed in e2e/ansible/playbooks/<test-category>.Here are some considerations. 

- Each test playbook is recommended to be constructed with the following template.

  The main test playbook, statically "includes" following files :

  - Test variables YAML
  - Pre-requisite tasks YAML
  - Cleanup tasks YAML
  
  Auxiliary scripts that are invoked in the test playbook can be placed in the same directory. 

 You can view a sample test playbook [here](https://github.com/openebs/openebs/tree/master/e2e/ansible/playbooks/hyperconverged/test-k8s-percona-mysql-pod)

- Test playbooks that deploy applications are recommended to include steps to generate application-specfic workloads that
  will exercise the OpenEBS storage volume. 
  
- Here are some ansible best practices while constructing playbooks : 
 
  - https://www.jeffgeerling.com/blog/yaml-best-practices-ansible-playbooks-tasks 
  
  The OpenEBS ansible environment setup procedure is provided [here](https://github.com/openebs/openebs/blob/master/e2e/ansible/openebs-on-premise-deployment-guide.md)
  
### Submit changes to fix bugs or improve e2e tests 

Explain the fix in detail and add the verbose test playbook output that is run with the fixes (Run the playbook with a -v option for this). Also, consider the general ansible playbook best practices referenced in the previous section.

### Raise or fix issues on the CI framework 

As with other issues, please mention the bug/enhancements in detail with logs/references if possible.

The jenkins configuration used to setup OpenEBS e2e can be found [here](https://github.com/openebs/openebs/blob/master/e2e/jenkins/README.md)

### Raise or fix issues on the e2e, CI documentation

Getting Documentation Right is Hard! Please raise a PR with you proposed changes to the READMEs, tutorials and deployment guides in openebs/e2e

# HAPPY TESTING !!



  









