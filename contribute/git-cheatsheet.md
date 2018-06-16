# Git Cheat Sheet

Fork the [openebs/openebs](https://github.com/openebs/openebs) repository into your account, referred in the below instructions as $user.

## Setting up Development Environment for OpenEBS projects

```bash
working_dir=$GOPATH/src/github.com/openebs
mkdir -p $working_dir
cd $working_dir
```

Set `user` to match your Github profile name:

```bash
user={your Github profile name}
```

## The steps mentioned here are w.r.t contribution towards openebs/openebs project

```bash
git clone https://github.com/$user/openebs.git
cd openebs/
git remote add upstream https://github.com/openebs/openebs.git
git remote set-url --push upstream no_push
git remote -v
```

## Synchronizing your local master(i.e. your $user/openebs project) with upstream master(i.e. openebs/openebs)

```bash
git checkout master
git fetch upstream master
git rebase upstream/master
git status
git push origin master
```

## Create Branch (based on feature or bug name)

```bash
git branch <branch_name>
git checkout <branch_name>
git push --set-upstream origin <branch_name>
```

## Synchronizing (i.e rebase) your local branch with upstream master

```bash
git checkout <branch-name>
git fetch upstream master
git rebase upstream/master
git status
git push
```

## Make changes to your local branch

```bash
# make your changes
# keep fetching the commits from upstream master & rebase them here
git commit
git push

# submit the PR to upstream from browser link https://github.com/$user/openebs
```

## Delete Branch

```bash
git push origin --delete <branch_name>
git branch -d <branch_name>
```

## Writing a Unit Test

Though it is important to write unit tests, do not try to achieve 100% code coverage if it complicates writing these tests. If a unit test is simple to write & understand, most probably it will be extended when new code gets added. However, the reverse will lead to its removal on the whole. In other words, complicated unit tests will lead to decrease in the overall coverage in the long run.

OpenEBS being an OpenSource project will always try to experiment with new ideas and concepts. Hence, writing unit tests will provide the necessary checklist that reduces the scope for errors.

Go back to [**Contributing to OpenEBS**](../CONTRIBUTING.md).
