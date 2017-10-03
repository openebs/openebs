# PR workflow for contributing to OpenEBS kubernetes provisioner

This document describes process for creating contributing to [openebs/external-storage](https://github.com/openebs/external-storage) project.
At a very high level, the process to contribute and improve is pretty simple:
- Submit an Issue describing your proposed change
- Create your development branch
- Commit your changes
- Submit your Pull Request
- Sync  `openebs/external-storage`  repository


### Submit an Issue describing your proposed change
Some general guidelines when submitting issues for openebs volume provisioner:
   - It is advisable to perform search on the already existing issues related to openebs-provisioner at [issues related to openebs-provisioner](https://github.com/openebs/openebs/issues?utf8=%E2%9C%93&q=label%3Aarea%2Fvolume-provisioning%20label%3Arepo%2Fk8s-provisioner%20) if your issue isn't listed there then you can move to the next step.
    - If you encounter any issue/bug or have feature request then raise an issue in [openebs/openebs](https://github.com/openebs/openebs/issues) and label it as `area/volume-provisioning` & `repo/k8s-provisioner`.

### Create your development branch
   - Fork the [kubernetes-incubator/external-storage](https://github.com/kubernetes-incubator/external-storage) repository.
   - Create development branch in your forked repository with the following name convention: "task-description-#issue".

### Commit your changes
   - Reference the issue number along with a brief description in your commits.

### Submit a Pull request
   - If you are contributing to the kubernetes project for the first time then you need to sign [CNCF CLA](https://identity.linuxfoundation.org/projects/cncf) otherwise you can proceed to the next steps.
   - Rebase your development branch
   - Submit the PR from the development branch to the `kubernetes-incubator/external-storage:master`
   - Update the PR as per comments given by reviewers.
   - Once the PR is accepted, close the branch.

### Sync openebs/external-storage repository
   - You can request to `openebs/external-storage` maintainer/Owners to sync up the `openebs/external-storage` repository.
   - Your changes will appear in `openebs/external-storage` once it is synced.

## Git cheat sheet:
Fork the `kubernetes-incubator/external-storage` repository into your account, referred in the below instructions as $user.

### Setting up Development Environment for OpenEBS volume provisioner

```
working_dir=$GOPATH/src/github.com/kubernetes-incubator
mkdir -p $working_dir
cd $working_dir

```

### Clone your repo 
 
Clone your fork inside `$working_dir`

```
git clone https://github.com/$user/external-storage.git   # Clone your fork $user/external-storage
cd external-storage
git remote add upstream https://github.com/kubernetes-incubator/external-storage.git
git remote set-url --push upstream no_push
git remote -v    # check info on remote repos

```

### Synchronizing your local master(i.e. your `$user/external-storage` project) with upstream master (i.e `kubernetes-incubator/external-storage`)

```
git checkout master
git fetch upstream master
git rebase upstream/master
git status
git push origin master

```

### Create Branch (based on feature or bug name)

```
git checkout -b <branch_name>
git branch
```

### Synchronizing (i.e rebase) your local branch with upstream master

```
git checkout <branch-name>
git fetch upstream master
git rebase upstream/master
git status
git push origin <branch-name>  #After this changes will appear in your $user/external-storage:<branch-name>

```
### Create pull request to `kubernetes-incubator/external-storage`

Once above steps are done, then you shall see your changes in branch `<branch-name>` of `$user/external-storage` on github. You can create a PR to `kubernetes-incubator/external-storage`. 
You can add label `area/openebs` to your PR by commenting `/area openebs` in the comment section of your PR. 


### Fetching latest changes to `openebs/external-storage`
Once, Pull Request is merged in `kubernetes-incubator/external-storage` then ask one of the OpenEBS owner to fetch latest changes to `openebs/external-storage`.
Owners will fetch latest changes from `kubernetes-incubator/external-storage` to `openebs/external-storage`repo. Your changes shall appear here! :smile:
