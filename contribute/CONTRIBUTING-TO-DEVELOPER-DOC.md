# Improve Developer Documentation

This document describes the process for improving developer documentation by creating PRs.

Developer documentation is available under the folder: [openebs/contribute](https://github.com/openebs/openebs/tree/master/contribute)

The developer documentation includes anything that will help the community like:
- Architecture and Design documentation
- Technical or Research Notes
- FAQ
- Process Documentation 
- Generic / Miscellaneous Notes

At a very high level, the process to contribute and improve is pretty simple:
- Submit an Issue describing your proposed change
- Create your development branch
- Commit your changes
- Submit your Pull Request

The following sections describe some guidelines that can come in handy with the above process. 
*Followed by the guidelines, is a cheat sheet with frequently used git commands.*

## Submit an Issue describing your proposed change.

Some general guidelines when submitting issues for developer documentation:
- If the proposed change requires an update to the existing page, please provide a link to the page in the issue. 

You can also help with some existing issues under this category available at [developer documentation issues list](https://github.com/openebs/openebs/labels/documentation%2Fdevel)

## Create your development branch. 

- Fork the openebs repository and if you had previously forked, rebase with master to fetch latest changes
- Create a new development branch in your forked repository with the following naming convention: *"task description-#issue"*

  Example:
     This change is being developed with the branch named : OpenEBS-DevDoc-PR-Workflow-#213

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

