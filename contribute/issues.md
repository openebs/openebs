# List of labels for issues and PRs on OpenEBS Project

This document provides list of labels and their purpose. These labels can be attached to issues and PRs. Aim behind having such list of labels is, we can sort and distinguish issues. This list will help new community members to dive-in OpenEBS if they wish to contribute to project or investigate the problem.

Use case:
> I am beginner, I want to contribute to OpenEBS project and I am not sure from where to begin?

Answer:
>Start looking into the issues tagged with labels such as `help/small` , `size/XS`, `kind/unit-test` etc. Solve such issues and raise PR.

---

### Kind

Labels prefixed with *kind* indicate the type of issue and PR. Suppose, you want to report a bug then you can tag your issue with `kind/bug` label.

| Label | Description |
|---|---|
| kind/api  | Issue/PR related to API  |
| kind/bug |  If there’s an error, failure in workflow, fault etc.|
| kind/feature  | New / existing / required feature or enhancement |
| kind/improve | Needs improvement |
| kind/e2e-test | Need/Add end to end test |
| kind/unit-test | Need/Add Unit test|
| kind/security  | Security related concerns  |
| kind/testing  |  Needs/Adds tests |

---

### Help

Labels prefixed with *help* implies that issue needs some help from community/users. Further, you can adjust the level of help required, by specifying small, medium, large etc.

| Label | Description |
|---|---|
| help/small  | Need small help on docs (beginner level)|
| help/medium | Need help to fix code ( Intermediate level) |
| help/large | Need help on design changes and code review (Expert level) |

---

## Area

Labels prefixed with *area* indicates that which area issue or PR belong. Here, area implies component of the OpenEBS project. It will be easier to sort an issue based on the area of user's interest.

| Label | Description |
|---|---|
| area/maya  | Maya Specific  |
| area/k8s | Kubernetes specific   |
| area/ci  | Continuous integration specific  |
| area/high-availability  | High availability  |
| area/storage | Storage specific  |
| area/machine-learning  |  Machine learning specific |

---

### Size

Labels prefixed with *size* defines the size of change done in particular PR.

| Label | Description |
|---|---|
| size/L | Size of change is large/7 commits probably |
| size/M | Size of change is medium/5 commits probably |
| size/S | Size of change is small/3 commits probably |
| size/XL | Size of change is extra large/10 commits probably |
| size/XS | Size of change is extra small/1 commit probably |
| size/XXL | Size of change is very large/15 commits probably |

#### NOTE:

```
Please do not club major changes into single PR. It'll be difficult for reviewer to review big PR. In that case, reviewer may discard your PR and will ask you create multiple PRs.
```

---

### Priority

Labels with prefix *priority* defines the severity of the issue. Severity level of an issue can be given as a suffix.

| Label | Description |
|---|---|
| priority/0 | Urgent : Must be fixed in the next build |
| priority/1 | High  : Must be fixed in any of the upcoming builds but should be included in the release. |
| priority/2 | Medium: May be fixed after the release / in the next release |
| priority/3 | Low: May or may not be fixed at all |

---

### Repo

Labels with prefix *repo* points the repository where given issue needs to be fixed. If users have no idea where to file the issue then they can file issue in `openebs/openebs` later OpenEBS contributors/authors/owners will tag issue with appropriate repository using *repo* label.

| Label | Description |
|---|---|
| repo/maya | Related to openebs/maya repository |
| repo/mayaserver | Related to openebs/mayaserver repository |
| repo/jiva | Related to openebs/jiva repository |
| repo/k8s-provisioner|  Related to openebs/k8s-provisioner repository|

---

### General

As name suggests, this contains general category labels and they are self explanatory.

| Label | Description |
|---|---|
| architecting | If something needs design changes/brainstorming |
| documentation  |  Related to documentation |
| work-in-progress | Means work in progress |
| website | Issues related to website  |
| release-note | Need release note|
| ready-for-review | PR is ready for review |