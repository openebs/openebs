# Contributing a Patch to Developer Documentation

Developer documentation is available under the openebs/openebs/contribute folder. 

The developer documenation includes:
- Architecture and Design documentation
- Technical or Research Notes
- FAQ
- Process Documentation 
- Generic / Miscellaneous Notes 

Anything that will help other developers!

## Submit an Issue describing your proposed change.

Some general guidelines when submitting issues for developer documentation:
- If the proposed change requires an update to the existing page, please provide a link to the page in the issue. 

You can also help with some existing issues under this category available at [developer documentation issues list](https://github.com/openebs/openebs/labels/documentation%2Fdevel)

## Create your development branch. 

- Fork the openebs repository and rebase with master
- Create a new development branch in your forked repository with the following naming convention: *"task description-#issue"*

  Example:
     This change is being developed with the branch named : OpenEBS-DevDoc-PR-Workflow-#213

## Commit your changes
- Reference the issue along with a brief description in your commits 
- The commit summary should be within 50 characters
- A detailed commit message COULD be included explaining details in each file. 

## Submit a Pull request. 
- Rebase your development branch 
- Submit the PR from the development branch to the openebs/openebs:master
- Incorporate review comments if any in the development branch. 
- Once the PR is accepted, close the branch. 


