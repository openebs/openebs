# Commit Message Guidelines for OpenEBS Projects

This document borrows concepts, conventions, and text mainly from the following sources, extending them in order to provide a sensible guideline for writing commit messages for OpenEBS projects.
- Tim Pope's [article](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) on readable commit messages
- Thanks to @stephenparish https://gist.github.com/stephenparish/9941e89d80e2bc58a153
- Thanks to @abravalheri https://gist.github.com/abravalheri/34aeb7b18d61392251a2

These conventions are aimed at tools to automatically generate useful documentation, or by developers during debugging process.

## Proposed Commit Message Format

Any line of the commit message cannot be longer than 80 characters! This allows the message to be easier to read on github as well as in various git tools.

```
[TICKET] <type>(<scope>): <subject> <meta>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Allowed `[TICKET]` (Optional)

Subject line may be prefixed for continuous integration purposes
 or better project management with a ticket id. The ticket id could 
 be a Github Issue, Rally Id, JIRA Id, etc.,  For example,
 if you use Rally to track your development, the subject could be
 "[TA-1234] test(mayactl): add unit tests for cstor volume list"

### Allowed `<type>`
* **feat**: A new feature
* **fix**: A bug fix
* **docs**: Documentation only changes
* **style**: Changes that do not affect the meaning of the code 
  (white-space, formatting, missing semi-colons, etc)
* **refactor**: A code change that neither fixes a bug nor adds a feature
* **perf**: A code change that improves performance
* **test**: Adding missing tests
* **chore**: Changes to the build process or auxiliary tools and libraries
   such as documentation generation

### Allowed `<scope>`
Scope could be anything specifying impacted module/package.
For example: when committing to openebs/maya repo, the scope can be
- components : mayactl, m-apiserver, spc-watcher, cast, install, util, etc.
- generic    : compile, travis-ci, etc.

### `<subject>` text
Subject line should contains succinct description of the change. 

* use imperative, present tense: “change” not “changed” nor “changes”
* don't capitalize first letter
* no dot (.) at the end

### Allowed `<meta>` (Optional)
Additionally, the end of subject-line may contain twitter-inspired markup

* `#wip` - indicate for contributors the feature being implemented is not 
   complete yet. Should not be included in changelogs (just the last commit 
   for a feature goes to the changelog).
* `#nitpick` - the commit does not add useful information. Used when fixing 
   typos, etc... Should not be included in changelogs.

### Message body
* just as in `<subject>` use imperative, present tense: “change” not “changed” nor “changes”
* includes motivation for the change and contrasts with previous behavior


### Message footer

#### Breaking changes
All breaking changes have to be mentioned in footer with the description of the 
change, justification and migration notes

```
BREAKING CHANGE: DEFAULT_REPLICA_NODE_SELECTOR will be ignored
    The support for using this ENV has been removed. 

    To migrate you are required to mention the node selector in StorageClass

    Before: Specified as a string in the m-apiserver ENV as follows:

    - name: DEFAULT_REPLICA_NODE_SELECTOR
      value: "nodetype=storage"

    After: Specify in the StorageClass
    
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: openebs-jiva-nodeselector
      annotations:
        cas.openebs.io/config: |
          - name: ReplicaNodeSelector
            value: |-
              nodetype: storage

    User feedback was to have node-selector configurable per StorageClass to
    allow scheduling volumes based on the storage attached to the nodes. 
```

#### Referencing issues
Fixed bugs should be listed on a separate line in the footer prefixed with "Fixes" keyword like this:
```
Fixes #234
```

or in case of multiple issues:
```
Fixes #123, #246, #333
```

### Revert

If the commit reverts a previous commit, it should begin with revert:, followed by the header of the reverted commit. In the body it should say: This reverts commit <hash>., where the hash is the SHA of the commit being reverted.

### Examples

Here are some PRs that follow the convention proposed in this document.
- https://github.com/openebs/openebs/pull/1876
- https://github.com/openebs/maya/pull/502
- https://github.com/openebs/jiva/pull/110
- https://github.com/openebs/cstor/pull/38

