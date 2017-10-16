# Add examples of applications using OpenEBS

This document describes the process for adding or improving examples of applications using OpenEBS Volumes.

Kubernetes YAML files for running application using OpenEBS Volumes are located under the folder: [openebs/k8s/demo](https://github.com/openebs/openebs/tree/master/k8s/demo)

Each application example should comprise of the following:
- K8s YAML file(s) for starting the application and its associated components. The volumes should point to OpenEBS Storage Class. If the existing storage-classes don't suit the need, create a new storage class in: [openebs-storageclasses.yaml](../k8s/openebs-storageclasses.yaml) 
- K8s YAML files for starting a client that access the application. This is optional, in case the Application itself provides a mechanism like in case of Jupyter, Wordpress etc., When demonstrating database like applications like Cassandra, Reddis, it is recommended to have a mechanism to test that application is launched.   
- Instruction Guide, that will help launch and verify the application

At a very high level, the process to contribute and improve is pretty simple:
- Submit an Issue describing your proposed change. Or pick an existing issue tagged as [applications](https://github.com/openebs/openebs/labels/application)
- Create your development branch
- Commit your changes
- Submit your Pull Request
- Submit an issue to update the [User Documentation](https://github.com/openebs/openebs/blob/master/documentation/source/install/install_usecases.rst)

*Note: You could also help by just adding new issues for applications that are currently missing in the examples or by raising issues on existing applications for further enhancements.*

The following sections describe some guidelines that can come in handy with the above process. 
*Followed by the guidelines, is a cheat sheet with frequently used git commands.*

## Submit an Issue describing your proposed change.

Some general guidelines when submitting issues for example applications:
- If the proposed change requires an update to the existing example, please provide a link to the example in the issue. 

## Create your development branch. 

- Fork the openebs repository and if you had previously forked, rebase with master to fetch latest changes
- Create a new development branch in your forked repository with the following naming convention: *"task description-#issue"*

  Example:
     OpenEBS-Support-Kafka-Application-#538

## Commit your changes
- Reference the issue number along with a brief description in your commits
- Set your commit.template to the `COMMIT_TEMPLATE` given in the `.github` directory.
  `git config --local commit.template $GOPATH/src/github.com/openebs/openebs/.github`

## Submit a Pull request. 
- Rebase your development branch 
- Submit the PR from the development branch to the openebs/openebs:master
- Incorporate review comments, if any, in the development branch. 
- Once the PR is accepted, close the branch.
- After the PR is merged the development branch in the forked repository can be deleted.

# Git Cheat Sheet 

Fork the openebs/openebs repository into your account, referred in the below instructions as $user. 

## Setting up Development Environment for OpenEBS projects
```
working_dir=$GOPATH/src/github.com/openebs
mkdir -p $working_dir
cd $working_dir
```

## The steps mentioned here are w.r.t contribution towards openebs/openebs project
```
git clone https://github.com/$user/openebs.git
cd openebs/
git remote add upstream https://github.com/openebs/openebs.git
git remote set-url --push upstream no_push
git remote -v
```

## Synchronizing your local master(i.e. your $user/openebs project) with upstream master(i.e. openebs/openebs)
```
git checkout master
git fetch upstream master
git rebase upstream/master
git status
git push origin master
```

## Create Branch (based on feature or bug name)
```
git branch <branch_name>
git checkout <branch_name>
git push --set-upstream origin <branch_name>
```

## Synchronizing (i.e rebase) your local branch with upstream master
```
git checkout <branch-name>
git fetch upstream master
git rebase upstream/master
git status
git push
```

## Make changes to your local branch
```
# make your changes
# keep fetching the commits from upstream master & rebase them here
git commit
git push

# submit the PR to upstream from browser link https://github.com/$user/openebs
```

## Delete Branch
```
git push origin --delete <branch_name>
git branch -d <branch_name>
```

