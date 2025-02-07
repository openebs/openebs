---
oep-number: OEP 3796
title: Expose OpenEBS HelmChart's Container Images
authors:
  - "@tiagolobocastro"
owners:
  - "@tiagolobocastro"
editor: TBD
creation-date: 03/10/2024
last-updated: 07/02/2025
status: implemented
---

# Expose OpenEBS HelmChart's Container Images

## Table of Contents

* [Summary](#summary)
* [Motivation](#motivation)
  * [Goals](#goals)
  * [Non-Goals](#non-goals)
* [Proposal](#proposal)
  * [User Stories](#user-stories)
    * [Story 1](#story-1)
    * [Story 2](#story-2)
  * [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
    * [Discoverable images](#discoverable-images)
      * [Regex Explanation](#regex-explanation)
    * [Expose Images](#expose-images)
    * [Non-Discoverable/Runtime images](#non-discoverableruntime-images)
  * [Test Plan](#test-plan)
  * [Risks and Mitigations](#risks-and-mitigations)
    * [Mitigations](#mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks [optional]](#drawbacks-optional)
* [Alternatives [optional]](#alternatives-optional)

## Summary

This proposal aims to add a comprehensive list of all possible container images required by OpenEBS charts. This will help users and developers to easily identify and pull the necessary images for deploying OpenEBS.

## Motivation

The motivation behind this proposal is to simplify the deployment process of OpenEBS by providing a clear and concise list of all required container images. This will reduce the time and effort needed to search for and pull the correct images, thereby improving the user experience, especially for air gapped environments where the images must be downloaded a priori.
Another OEP can be built on top of this, for creating an easily downloadable tar file, comprised of all required container images.

### Goals

Providing a detailed list of all container images required by each OpenEBS chart.
An automated mechanism must be in place, ensuring the list is kept up-to-date with any changes in the charts.

### Non-Goals

Creating a downloadable bundle of all container images (to be addressed by another OEP)
Building or maintaining container images.
Correlating images to specific functionality (ie may contain images a given user would not required for their configuration).

## Proposal

The proposal is to add an annotation images in the Chart.yaml (or doc.yaml) file of each OpenEBS chart. This annotation will contain a list of all container images required by the chart. The list will be automatically updated to reflect any changes in the charts, when those changes are made.
Each OpenEBS chart will use the annotation from the charts it depends on, thus facilitating and relegating some of the work to the respective chart which is in a better position to generate the image reliably.

Here's a very simple example:

```text
project:
  name: OpenEBS Mayastor
annotations:
  images: |
    - name: mayastor-agent-core
      image: docker.io/openebs/mayastor-agent-core:v2.7.1
    - name: linux-utils
      image: docker.io/openebs/linux-utils:4.1.0
    - name: promtail
      image: docker.io/grafana/promtail:2.8.3
```

### User Stories

#### Story 1

As a user, I want to have a single source of truth for all container images required by OpenEBS charts so that I can easily pull the necessary images for deployment.

#### Story 2

As a user, I want to have a single source of truth for all container images required by OpenEBS charts, which can allow me to pull the necessary images in an automatable manner.

### Implementation Details/Notes/Constraints

#### Discoverable images

Some images can be easily discovered by templating the helm chart and finding all image entries through the key `image:`.
In order to do this we can use a regular expression:\
`^[ \t]*image: \K(.*:.*)$`

##### Regex Explanation

* `^` asserts position at start of a line
* Match a single character present in the list below `[ \t]`
  * `*` matches the previous token between zero and unlimited times, as many times as possible, giving back as needed (greedy)
  * ` ` matches a space character (ASCII 32) literally
  * `\t` matches a tab character (ASCII 9)
* `image: ` matches the characters `image: ` literally (case sensitive)
* `\K` resets the starting point of the reported match. Any previously consumed characters are no longer included in the final match
* 1st Capturing Group `(.*:.*)`
  * `.` matches any character (except for line terminators)
  * `*` matches the previous token between zero and unlimited times, as many times as possible, giving back as needed (greedy)
  * `:` matches the character `:` with index 5810 (3A16 or 728) literally (case sensitive)
  * `.` matches any character (except for line terminators)
  * `*` matches the previous token between zero and unlimited times, as many times as possible, giving back as needed (greedy)
* `$` asserts position at the end of a line

\
This regex can be used in combination with helm template and grep, example:

```bash
> helm template . --set "$ENABLE_ALL_FEATURES" | grep -Po "^[ \t]*image: \K(.*:.*)$" | tr -d \"
```

> **_NOTE:_** Here we must enable all features to ensure we have a comprehensive list of images.

#### Expose Images

Once a list of images is obtained, we may add these as annotations (see above).

#### Non-Discoverable/Runtime images

Deployments which are not configured in a helm chart, but rather deployed at runtime will not have their images discoverable.\
In such cases, we may need to manually find and "hardcode" these images

### Test Plan

We should validate the list of images, ensuring they are correct and kept up to date as the project develops.
This can be done on a cluster, either by white-listing images or by disabling image pull altogether and pre-loading the cluster
with the list of images we've obtained.

### Risks and Mitigations

There's a risk we may pick up images which are not required as we're enabling all features.
It would be difficult to address this because the images will vary depending on which features a user wants to enable.
Non-discoverable images must be manually added to the list.

#### Mitigations

We should aim to automate as much of possible.
Make use of automated tests to ensure the list is kept up-to-date.

## Graduation Criteria

## Implementation History

* the `Summary` and `Motivation` sections being merged signaling owner acceptance

## Drawbacks [optional]

Some additional maintenance effort may be required to keep the list up-to-date, in case we can't automatically generate the entire list of container images.

## Alternatives [optional]

Continue without a centralized list, requiring users to manually discover the necessary container images.
