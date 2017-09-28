# PR workflow for contributing to OpenEBS kubernetes provisioner

This document describes process for creating contributing to [openebs/external-storage](https://github.com/openebs/external-storage) project.
At a very high level, the process to contribute and improve is pretty simple:
- Submit an Issue describing your proposed change
- Create your development branch
- Commit your changes
- Submit your Pull Request
- Sync  `openebs/external-storage`  repository


## Submit an Issue describing your proposed change
Some general guidelines when submitting issues for openebs volume provisioner:
   - It is advisable to perform search on the already existing issues related to openebs-provisioner at [issues related to openebs-provisioner](https://github.com/openebs/openebs/issues?utf8=%E2%9C%93&q=label%3Aarea%2Fvolume-provisioning%20label%3Arepo%2Fk8s-provisioner%20) if your issue isn't listed there then you can move to the next step.
    - If you encounter any issue/bug or have feature request then raise an issue in [openebs/openebs](https://github.com/openebs/openebs/issues) and label it as `area/volume-provisioning` & `repo/k8s-provisioner`.

## Create your development branch
   - Fork the [kubernetes-incubator/external-storage](https://github.com/kubernetes-incubator/external-storage) repository.
   - Create development branch in your forked repository with the following name convention: "task-description-#issue".

## Commit your changes
   - Reference the issue number along with a brief description in your commits.

## Submit a Pull request
   - If you are contributing to the kubernetes project for the first time then you need to sign [CNCF CLA](https://identity.linuxfoundation.org/projects/cncf) otherwise you can proceed to the next steps.
   - Rebase your development branch
   - Submit the PR from the development branch to the `kubernetes-incubator/external-storage:master`
   - Update the PR as per comments given by reviewers.
   - Once the PR is accepted, close the branch.

## Sync openebs/external-storage repository
   - You can request to `openebs/external-storage` maintainer/Owners to sync up the `openebs/external-storage` repository.
   - Your changes will appear in `openebs/external-storage` once it is synced.

### Git cheat sheet:
You can follow the steps required (git commands) to create branch, sync the changes etc [here](https://github.com/openebs/openebs/blob/master/contribute/process/pr-workflow-developer-doc.md#git-cheat-sheet)
