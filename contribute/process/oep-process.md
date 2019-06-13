---
oep-number: draft-20190605
title: OpenEBS Enhancement Proposal Process
authors:
  - "@amitkumardas"
owners:
  - "@kmova"
  - "@vishnuitta"
editor: "@amitkumardas"
creation-date: 2019-06-05
last-updated: 2019-06-05
status: provisional
---

# OpenEBS Enhancement Proposal Process

## Table of Contents

* [OpenEBS Enhancement Proposal Process](#openebs-enhancement-proposal-process)
  * [Metadata](#metadata)
  * [Table of Contents](#table-of-contents)
  * [Summary](#summary)
  * [Motivation](#motivation)
  * [Reference-level explanation](#reference-level-explanation)
      * [What type of work should be tracked by a OEP](#what-type-of-work-should-be-tracked-by-a-oep)
      * [OEP Template](#oep-template)
      * [OEP Metadata](#oep-metadata)
      * [OEP Workflow](#oep-workflow)
      * [Git and GitHub Implementation](#git-and-github-implementation)
      * [OEP Editor Role](#oep-editor-role)
      * [Important Metrics](#important-metrics)
      * [Prior Art](#prior-art)
  * [Graduation Criteria](#graduation-criteria)
  * [Drawbacks](#drawbacks)
  * [Alternatives](#alternatives)
  * [Unresolved Questions](#unresolved-questions)
  * [Mentors](#mentors)

## Summary

A standardized development process for OpenEBS is proposed in order to

- provide a common structure for proposing changes to OpenEBS
- ensure that the motivation for a change is clear
- allow for the enumeration stability milestones and stability graduation
  criteria
- persist project information in a Version Control System (VCS) for future
  OpenEBS contributors & users
- support the creation of _high value user facing_ information such as:
  - an overall project development roadmap
  - motivation for impactful user facing changes
- reserve GitHub issues for tracking work in flight rather than creating "umbrella"
  issues
- ensure community participants are successfully able to drive changes to
  completion across one or more releases while stakeholders are adequately
  represented throughout the process

This process is supported by a unit of work called a OpenEBS Enhancement Proposal
or OEP. A OEP attempts to combine aspects of a

- feature, and effort tracking document
- a product requirements document
- design document

into one file which is created incrementally in collaboration with one or more
owners.

## Motivation

A single GitHub Issue or Pull request seems to be required in order to understand
and communicate upcoming changes to OpenEBS. In a blog post describing the
[road to Go 2][], Russ Cox explains

> that it is difficult but essential to describe the significance of a problem
> in a way that someone working in a different environment can understand

as a project it is vital to be able to track the chain of custody for a proposed
enhancement from conception through implementation.

Without a standardized mechanism for describing important enhancements our
talented technical writers and product managers struggle to weave a coherent
narrative explaining why a particular release is important. Additionally for
critical infrastructure such as OpenEBS adopters need a forward looking road
map in order to plan their adoption strategy.

The purpose of the OEP process is to reduce the amount of "tribal knowledge" in
our community. By moving decisions from a smattering of mailing lists, video
calls and hallway conversations into a well tracked artifact this process aims
to enhance communication and discoverability.

A OEP is broken into sections which can be merged into source control
incrementally in order to support an iterative development process. An important
goal of the OEP process is ensuring that the process for submitting the content
contained in [design proposals][] is both clear and efficient. The OEP process
is intended to create high quality uniform design and implementation documents
for OWNERs to deliberate.

[road to Go 2]: https://blog.golang.org/toward-go2
[design proposals]: /contribute/design


## Reference-level explanation

### What type of work should be tracked by a OEP

The definition of what constitutes an "enhancement" is a foundational concern
for the OpenEBS project. Roughly any OpenEBS user or operator facing
enhancement should follow the OEP process: if an enhancement would be described
in either written or verbal communication to anyone besides the OEP author or
developer then consider creating a OEP.

Similarly, any technical effort (refactoring, major architectural change) that
will impact a large section of the development community should also be
communicated widely. The OEP process is suited for this even if it will have
zero impact on the typical user or operator.

As the local bodies of governance, OWNERSs should have broad latitude in describing
what constitutes an enhancement which should be tracked through the OEP process.
OWNERs may find that helpful to enumerate what _does not_ require a OEP rather
than what does. OWNERs also have the freedom to customize the OEP template
according to their OWNER specific concerns. For example the OEP template used to
track FEATURE changes will likely have different subsections than the template for
proposing governance changes. However, as changes start impacting other aspects or
the larger developer community, the OEP process should be used
to coordinate and communicate.

Enhancements that have major impacts on multiple OWNERs should use the OEP process.
A single OWNER will own the OEP but it is expected that the set of approvers will
span the impacted OWNERs. The OEP process is the way that OWNERs can negotiate 
and communicate changes that cross boundaries.

OEPs will also be used to drive large changes that will cut across all parts of 
the project. These OEPs will be owned among the OWNERs and should be seen as a 
way to communicate the most fundamental aspects of what OpenEBS is.

### OEP Template

The template for a OEP is precisely defined [here](oep-template.md)

### OEP Metadata

There is a place in each OEP for a YAML document that has standard metadata.
This will be used to support tooling around filtering and display.  It is also
critical to clearly communicate the status of a OEP.

Metadata items:
* **oep-number** Required
  * Each proposal has a number.  This is to make all references to proposals as
    clear as possible.  This is especially important as we create a network
    cross references between proposals.
  * Before having the `Approved` status, the number for the OEP will be in the
    form of `draft-YYYYMMDD`.  The `YYYYMMDD` is replaced with the current date
    when first creating the OEP.  The goal is to enable fast parallel merges of
    pre-acceptance OEPs.
  * On acceptance a sequential dense number will be assigned.  This will be done
    by the editor and will be done in such a way as to minimize the chances of
    conflicts.  The final number for a OEP will have no prefix.
* **title** Required
  * The title of the OEP in plain language.  The title will also be used in the
    OEP filename.  See the template for instructions and details.
* **status** Required
  * The current state of the OEP.
  * Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
* **authors** Required
  * A list of authors for the OEP.
    This is simply the Github ID.
    In the future we may enhance this to include other types of identification.
* **owners** Required
  * An OWNER is the person or entity that works on the proposal.
  * OWNERs consist of `approvers` and `reviewers` joined from the [MAINTAINERS](https://github.com/openebs/openebs/blob/master/MAINTAINERS) file
  * OWNERs are listed as `@owner` where the name matches up with the Github ID.
  * The OWNER that is most closely associated with this OEP. If there is code or
    other artifacts that will result from this OEP, then it is expected that
    this OWNER will take responsibility for the bulk of those artifacts.
* **editor** Required
  * Someone to keep things moving forward.
  * If not yet chosen replace with `TBD`
  * Same name/contact scheme as `authors`
* **creation-date** Required
  * The date that the OEP was first submitted in a PR.
  * In the form `yyyy-mm-dd`
  * While this info will also be in source control, it is helpful to have the set of OEP files stand on their own.
* **last-updated** Optional
  * The date that the OEP was last changed significantly.
  * In the form `yyyy-mm-dd`
* **see-also** Optional
  * A list of other OEPs that are relevant to this OEP.
  * In the form `OEP 123`
* **replaces** Optional
  * A list of OEPs that this OEP replaces.  Those OEPs should list this OEP in
    their `superseded-by`.
  * In the form `OEP 123`
* **superseded-by**
  * A list of OEPs that supersede this OEP. Use of this should be paired with
    this OEP moving into the `Replaced` status.
  * In the form `OEP 123`


### OEP Workflow

A OEP has the following states

- `provisional`: The OEP has been proposed and is actively being defined.
  This is the starting state while the OEP is being fleshed out and actively defined and discussed.
  The OWNER has accepted that this is work that needs to be done.
- `implementable`: The approvers have approved this OEP for implementation and OWNERs create, if appropriate, 
  a [milestone](https://github.com/openebs/openebs/milestones) to track implementation work.
- `implemented`: The OEP has been implemented and is no longer actively changed. OWNERs reflect
  the status change and close its matching milestone, if appropriate.
- `deferred`: The OEP is proposed but not actively being worked on.
- `rejected`: The approvers and authors have decided that this OEP is not moving forward.
  The OEP is kept around as a historical document.
- `withdrawn`: The OEP has been withdrawn by the authors.
- `replaced`: The OEP has been replaced by a new OEP.
  The `superseded-by` metadata value should point to the new OEP.

### Git and GitHub Implementation

OEPs are checked into under the `/contribute/design/feature` directory.

New OEPs can be checked in with a file name in the form of `draft-YYYYMMDD-my-title.md`.
As significant work is done on the OEP the authors can assign a OEP number.
No other changes should be put in that PR so that it can be approved quickly and minimize merge conflicts.
The OEP number can also be done as part of the initial submission if the PR is likely to be uncontested and merged quickly.

### OEP Editor Role

Taking a cue from the [Python PEP process][], we define the role of a OEP editor.
The job of an OEP editor is likely very similar to the [PEP editor responsibilities][] and will hopefully provide another opportunity for people who do not write code daily to contribute to OpenEBS.

In keeping with the OEP editors which

> Read the OEP to check if it is ready: sound and complete. The ideas must make
> technical sense, even if they don't seem likely to be accepted.
> The title should accurately describe the content.
> Edit the OEP for language (spelling, grammar, sentence structure, etc.), markup
> (for yaml, schema naming conventions), code style (examples should match 
idiomatic maya standards).

OEP editors should generally not pass judgement on a OEP beyond editorial corrections.
OEP editors can also help inform authors about the process and otherwise help things move smoothly.

[Python PEP process]: https://www.python.org/dev/peps/pep-0001/
[PEP editor responsibilities]: https://www.python.org/dev/peps/pep-0001/#pep-editor-responsibilities-workflow

### Important Metrics

It is proposed that the primary metrics which would signal the success or
failure of the OEP process are

- how many "enhancements" are tracked with a OEP
- distribution of time a OEP spends in each state
- OEP rejection rate
- PRs referencing a OEP merged per week
- number of issues open which reference a OEP
- number of contributors who authored a OEP
- number of contributors who authored a OEP for the first time
- number of orphaned OEPs
- number of retired OEPs
- number of superseded OEPs

### Prior Art

The OEP process as proposed was essentially stolen from the KUDO project which has references to Kubernetes process that also is the [Rust RFC process][] which itself seems to be very similar to the [Python PEP process][]

[Rust RFC process]: https://github.com/rust-lang/rfcs

## Drawbacks

Any additional process has the potential to engender resentment within the
community. There is also a risk that the OEP process as designed will not
sufficiently address the scaling challenges we face today. PR review bandwidth is
already at a premium and we may find that the OEP process introduces an unreasonable
bottleneck on our development velocity.

It certainly can be argued that the lack of a dedicated issue/defect tracker
beyond GitHub issues contributes to our challenges in managing a project like
OpenEBS, however, given that other large organizations, including GitHub
itself, make effective use of GitHub issues perhaps the argument is overblown.

The centrality of Git and GitHub within the OEP process also may place too high
a barrier to potential contributors, however, given that both Git and GitHub are
required to contribute code changes to OpenEBS today perhaps it would be reasonable
to invest in providing support to those unfamiliar with this tooling.

Expanding the proposal template beyond the single sentence description currently
required in the [features issue template][] may be a heavy burden for non native
English speakers and here the role of the OEP editor combined with kindness and
empathy will be crucial to making the process successful.

[features issue template]: https://github.com/openebs/openebs/tree/master/.github/ISSUE_TEMPLATE

### GitHub issues vs. OEPs

The use of GitHub issues when proposing changes does not provide OWNERs good
facilities for signaling approval or rejection of a proposed change to OpenEBS
since anyone can open a GitHub issue at any time. Additionally managing a proposed
change across multiple releases is somewhat cumbersome as labels and milestones
need to be updated for every release that a change spans. These long lived GitHub
issues lead to an ever increasing number of issues open against
`kubernetes/features` which itself has become a management problem in the Kubernetes community.

In addition to the challenge of managing issues over time, searching for text
within an issue can be challenging. The flat hierarchy of issues can also make
navigation and categorization tricky. While not all community members might
not be comfortable using Git directly, it is imperative that as a community we
work to educate people on a standard set of tools so they can take their
experience to other projects they may decide to work on in the future. While
git is a fantastic version control system (VCS), it is not a project management
tool nor a cogent way of managing an architectural catalog or backlog; this
proposal is limited to motivating the creation of a standardized definition of
work in order to facilitate project management. This primitive for describing
a unit of work may also allow contributors to create their own personalized
view of the state of the project while relying on Git and GitHub for consistency
and durable storage.

## Unresolved Questions

- How reviewers and approvers are assigned to a OEP
- Example schedule, deadline, and time frame for each stage of a OEP
- Communication/notification mechanisms
- Review meetings and escalation procedure
