# Contributing to OpenEBS Developer Documentation

This document describes the process for improving developer documentation by creating PRs at OpenEBS.

Developer documentation is available under the folder: [openebs/contribute](https://github.com/openebs/openebs/tree/master/contribute)

The developer documentation includes anything that will help the community like:

- Architecture and Design documentation
- Technical or Research Notes
- FAQ
- Process Documentation
- Generic / Miscellaneous Notes

We are also looking for an explainer video or presentation from the community that helps new developers in understanding the OpenEBS Architecture, it's use cases, and installation procedure locally.

At a very high level, the process to contributing and improving the code is pretty simple:

- Submit an issue describing your proposed change
- Create your development branch
- Commit your changes
- Submit your Pull Request

The following sections describe some guidelines that can come in handy with the above process.
*Followed by the guidelines, is a [cheatsheet](https://github.com/openebs/openebs/blob/master/contribute/git-cheatsheet.md) with frequently used git commands.*

## Submit an issue describing your proposed change

Some general guidelines when submitting issues for developer documentation:

- If the proposed change requires an update to the existing page, please provide a link to the page in the issue.
- If you want to add a new page, then go ahead and open an issue describing the requirement for the new page.

You can also help with some existing issues under this category available at [developer documentation issues list](https://github.com/openebs/openebs/labels/documentation%2Fdevel)

## Create your development branch

- Fork the [OpenEBS](www.github.com/openebs/openebs) repository and if you have forked it already, rebase with master branch to fetch latest changes to your local system.
- Create a new development branch in your forked repository with the following naming convention: *"task description-#issue"*

  **Example:** This change is being developed with the branch named: *OpenEBS-DevDoc-PR-Workflow-#213*

## Commit your changes

- Reference the issue number along with a brief description in your commits
- Set your commit.template to the `COMMIT_TEMPLATE` given in the `.github` directory.
  `git config --local commit.template $GOPATH/src/github.com/openebs/openebs/.github`

## Submit a Pull request

- Rebase your development branch
- Submit the PR from the development branch to the openebs/openebs:master
- Incorporate review comments, if any, in the development branch.
- Once the PR is accepted, close the branch.
- After the PR is merged the development branch in the forked repository can be deleted.

If you need any help with git, refer to this [git cheat sheet](./git-cheatsheet.md) and go back to the [**contributing to OpenEBS Documentation**](../CONTRIBUTING.md) guide to proceed.
