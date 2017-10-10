
OpenEBS Contribution Guide
=========================================

You can access the latest documents at http://openebs.readthedocs.io/en/latest/. 

Automated builds are setup for OpenEBS documentation at https://readthedocs.org/projects/openebs/

Sphinx is used for building the OpenEBS documentation - http://www.sphinx-doc.org/en/stable/tutorial.html


1. If you would like to give feedback on existing content, create an issue on documentation (see, `Creating an Issue`_).

2. If you would like to contribute to new content, 

     -  create an issue (see, `Creating an Issue`_), 
     -  create your own branch (see, `Creating a Branch`_), 
     -  work on the content by creating an RST file, and 
     -  create a pull request (see, `Creating a Pull Request`_).

Review Process for Documentation Issues and Pull Requests
---------------------------------------------------------

1. OpenEBS Lead receives documentation issues/pull requests raised by Documentation/Internal contributors. 
2. Lead will tag issues to relevant labels which start with the name **documentation** and assign             reviewers and approvers such as feature owner, doc person, and approver. 
3. The assignee works on the issue either developing content in RST files or editing the content. 
4. The assignee can get the content from other collaborators of the OpenEBS project either as rst/md file     or as a comment in the issue. The assignee can also use the "OpenEBS Slack" channel to collect             additional information from the community.
   
   Documentation content is located under documentation/source in reStructured (rst) files. documentation/source/index.rst contains the high level documentation structure (Table of Contents), which links to the content provided in other rst files either in the same directory or in child directories.
   
   **Note:**
   
   Before editing the files, familiarize yourself with the reStructured markup.


5. Once you are done with your edits and ready for review, you must create a PR (see `Creating a Pull          Request`_).
6. The documents must be approved. (see, `PR Approval Process`_).


Creating an Issue
------------------

1. Go to https://github.com/openebs/openebs/issues.
2. Click **New issue**.
3. Add a short description in the **Title**.
4. You can enter a detailed description in the edit box below.
5. Click **Submit new issue**.

Creating a Branch
-----------------

1. Create your openebs fork from (https://github.com/openebs/openebs). If you already have a forked           openebs, rebase with the master to get the latest changes. 
2. Create a branch on the openebs fork using the following command.
   ::
   git checkout -b <issue name>-#<issue number>


Creating a Pull Request
-----------------------

1. Go to your fork on Github.
2. Under Branch: master select the branch you created.
3. Click **New pull request**.
4. Add "Fixes #<*Issue number*>" in the commit message.

PR Approval Process
--------------------

1. Once the assignee is ready with the final draft, the reviewers have to approve the content. 
2. Open the pull request and click on **Review changes**. 
3. Click **Approve** and **Submit review**.
4. The approver sees that the document is approved by all the reviewers and closes the issue. The issue gets merged and the documentation is available  at http://openebs.readthedocs.io/en/latest/.

*********
TODO List
*********

.. todolist::
