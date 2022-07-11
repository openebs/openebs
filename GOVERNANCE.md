# Governance 

OpenEBS is a collection of [multiple sub-projects](./contribute/design#source-code-and-dependencies)
that can either be used independently or as combination of multiple sub-projects by end-users 
to run Stateful workloads in Kubernetes. This document outlines how these projects are governed,
while abiding by the [CNCF Code of Conduct](./CODE_OF_CONDUCT.md).

## Maintainership

There are different levels of maintainers, with different responsibilities, but
all maintainers have 3 things in common:

1) They share responsibility in the project's success.
2) They have made a long-term, recurring time investment to improve the project.
3) They spend that time doing whatever needs to be done, not necessarily what
is the most interesting or fun.

Maintainers are often under-appreciated, because their work is harder to appreciate.
It's easy to appreciate a really cool and technically advanced feature. It's harder
to appreciate the absence of bugs, the slow but steady improvement in stability,
or the reliability of a release process. But those things distinguish a great
project from a good one.

The levels of maintainership as maintained in the OpenEBS GitHub organization are
explained in the following sub-sections. 

### Community Contributor

OpenEBS is a very welcoming community and is eager to onboard and help anyone
from the OpenSource community to contribute to the project. To facilitate onboarding
of the community members, OpenEBS maintainers participate in Hackthon events and are
responsive on the [slack, community meetings and github](./community/). 

Any individual with intent to contribute to open source in general or fix a specific
issue they are having the OpenEBS project can contribute. If anyone is looking for 
ideas for contributing, the open issue backlog maintained under the 
[OpenEBS GitHub projects](https://github.com/orgs/openebs/projects) is a great place to start. 

Community Contributors are typically outside of the OpenEBS GitHub organization. 

### Contributors 

Becoming an OpenEBS contributor demonstrates that the individual has started to make 
regular contributors to the project and is progressing up the levels of maintainership. 

The contributors get a write access to the GitHub project to allow them to directly request 
other org members as reviewers for their PRs and to help them being added as reviewers for
contributions coming from other community contributors or OpenEBS org members. 

### Reviewers

A reviewer is a core role within the project. Becoming a reviewer is a core aspect in
the journey to becoming a maintainer.

Reviewers has gained expertise in one or more of the sub projects and they can influence the
planning of the release and review pull requests and their LGTM counts towards the
required LGTM count to merge a code change into the project.

Reviewers are part of the organization and have maintain access to the projects they lead.


### Maintainers

Maintainers are first and foremost contributors that have shown they are
committed to the long term success of a project. Anyone wanting to become
maintainers are expected to be deeply involved in contributing code, pull
request review, and triage of issues in the project for more than three months.

Just contributing does not make you a maintainer, it is about building trust
with the current maintainers of the project and being a person that they can
depend on and trust to make decisions in the best interest of the project.

Maintainers have admin access to the GitHub organization.

## Adding a reviewer or maintainer 

Periodically, the existing maintainers curate a list of contributors that have
shown regular activity on the project over the prior months. From this list,
maintainer candidates are selected and proposed maintainers slack channel.

After a candidate has been announced on the maintainers slack channel, the
existing maintainers are given five business days to discuss the candidate,
raise objections and cast their vote. The Votes take place via the pull request 
comment. Candidates must be approved by at least 66% of the
current maintainers by adding their vote on the mailing list. The reviewer role
has the same process but only requires 33% of current maintainers. Only
maintainers of the repository that the candidate is proposed for are allowed to
vote.

If a candidate is approved, a maintainer will contact the candidate to invite
the candidate to open a pull request that adds the contributor to the
MAINTAINERS file. The voting process may take place inside a pull request if a
maintainer has already discussed the candidacy with the candidate and a
maintainer is willing to be a sponsor by opening the pull request. The candidate
becomes a maintainer once the pull request is merged.

A contributor can be added to the sub-project at the discretion of the reviewers or
maintainers of the sub project and take help from any of the maintainers to add the
contributor to the OpenEBS Github project. 

## Adding sub-projects

Similar to adding maintainers, new sub projects can be added to OpenEBS
GitHub organization as long as they adhere to the OpenEBS vision and mission. 
New projects are discussed in either the Contributor Meeting or the Community 
slack and requires at least 1 maintainer approval.

If a project is approved, a maintainer will add the project to the OpenEBS
GitHub organization, and make an announcement on a public forum.

## Stepping down policy

Life priorities, interests, and passions can change. If you're a maintainer but
feel you must remove yourself from the list, inform other maintainers that you
intend to step down, and if possible, help find someone to pick up your work.
At the very least, ensure your work can be continued where you left off.

After you've informed other maintainers, create a pull request to remove
yourself from the MAINTAINERS file.

## Removal of inactive maintainers

Similar to the procedure for adding new maintainers, existing maintainers can
be removed from the list if they do not show significant activity on the
project. Periodically, the maintainers review the list of maintainers and their
activity over the last three months.

If a maintainer has shown insufficient activity over this period, a neutral
person will contact the maintainer to ask if they want to continue being
a maintainer. If the maintainer decides to step down as a maintainer, they
open a pull request to be removed from the MAINTAINERS file.

## How are decisions made?

OpenEBS is an open-source project with an open design philosophy. This means
that the repository is the source of truth for EVERY aspect of the project,
including its philosophy, design, road map, and APIs. *If it's part of the
project, it's in the repo. If it's in the repo, it's part of the project.*

As a result, all decisions can be expressed as changes to the repository. An
implementation change is a change to the source code. An API change is a change
to the API specification. A philosophy change is a change to the philosophy
manifesto, and so on.

All decisions affecting OpenEBS, big and small, follow the same 3 steps:

* Step 1: Open a pull request. Anyone can do this.
* Step 2: Discuss the pull request. Anyone can do this.
* Step 3: Merge or refuse the pull request. Who does this depends on the nature
of the pull request and which areas of the project it affects.

## Helping contributors with the DCO

The [DCO or `Sign your work`](./CONTRIBUTING.md#sign-your-work)
requirement is not intended as a roadblock or speed bump.

Some OpenEBS contributors are not as familiar with `git`, or have used a web
based editor, and thus asking them to `git commit --amend -s` is not the best
way forward.

In this case, maintainers can update the commits based on clause (c) of the DCO.
The most trivial way for a contributor to allow the maintainer to do this, is to
add a DCO signature in a pull request's comment, or a maintainer can simply
note that the change is sufficiently trivial that it does not substantially
change the existing contribution - i.e., a spelling change.

When you add someone's DCO, please also add your own to keep a log.

## I'm a maintainer. Should I make pull requests too?

Yes. Nobody should ever push to master directly. All changes should be
made through a pull request.

## Conflict Resolution

If you have a technical dispute that you feel has reached an impasse with a
subset of the community, any contributor may open an issue, specifically
calling for a resolution vote of the current maintainers to resolve the dispute.
The same voting quorums required (2/3) for adding and removing maintainers
will apply to conflict resolution.
