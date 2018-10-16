# Add examples of applications using OpenEBS

This document describes the process for adding or improving the existing examples of applications using OpenEBS Volumes.

Kubernetes YAML files for running application using OpenEBS Volumes are located under the folder [openebs/k8s/demo](https://github.com/openebs/openebs/tree/master/k8s/demo)

Each application example should comprise of the following:

- K8s YAML file(s) for starting the application and its associated components. The volumes should point to the OpenEBS Storage Class. If the existing storage-classes does not suit the need, create a new storage class at [openebs-storageclasses.yaml](../k8s/openebs-storageclasses.yaml).
- K8s YAML file(s) for starting a client that accesses the application. This is optional, in case the application itself provides a mechanism like in Jupyter, Wordpress, etc.

  When demonstrating a database-like application like Apache Cassandra, Redis, and so on, it is recommended to have such a mechanism to test that the application has been launched.
- An instruction guide, that will help in launch and verification of the application.

At a very high level, the process to contribute and improve is pretty simple:

- Submit an Issue describing your proposed change. Or pick an existing issue tagged as [applications](https://github.com/openebs/openebs/labels/application).
- Create your development branch.
- Commit your changes.
- Submit your Pull Request.
- Submit an issue to update the User Documentation.

***Note:** You could also help by just adding new issues for applications that are currently missing in the examples or by raising issues on existing applications for further enhancements.*

The following sections describe some guidelines that are helpful with the above process.

*Following the guidelines, here is a [cheatsheet for Git](./git-cheatsheet.md) with frequently used git commands.*

## Submit an issue describing your proposed change

Some general guidelines when submitting issues for example applications:

- If the proposed change requires an update to the existing example, please provide a link to the example in the issue.

## Create your development branch

- Fork the openebs repository and if you had previously forked, rebase with master to fetch latest changes.
- Create a new development branch in your forked repository with the following naming convention: *"task description-#issue"*

  **Example:** *OpenEBS-Support-Kafka-Application-#538*

## Commit your changes

- Reference the issue number along with a brief description in your commits.
- Set your commit.template to the `COMMIT_TEMPLATE` given in the `.github` directory.
  `git config --local commit.template $GOPATH/src/github.com/openebs/openebs/.github`

## Submit a Pull request

- Rebase your development branch.
- Submit the PR from the development branch to the openebs/openebs:master
- Incorporate review comments, if any, in the development branch.
- Once the PR is accepted, close the branch.
- After the PR is merged the development branch in the forked repository can be deleted.

If you need any help with git, refer to this [git cheat sheet](./git-cheatsheet.md) and go back to the [**contributing to OpenEBS Documentation**](../CONTRIBUTING.md) guide to proceed.