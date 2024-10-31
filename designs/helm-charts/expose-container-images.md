---
oep-number: OEP 3796
title: Expose OpenEBS HelmChart's Container Images
authors:
  - "@tiagolobocastro"
owners:
  - "@tiagolobocastro"
editor: TBD
creation-date: 2024-10-03
last-updated: 2024-10-31
status: provisional
---

# Expose OpenEBS HelmChart's Container Images

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Summary](#summary)
* [Motivation](#motivation)
    * [Goals](#goals)
    * [Non-Goals](#non-goals)
* [Proposal](#proposal)
    * [User Stories [optional]](#user-stories-optional)
      * [Story 1](#story-1)
      * [Story 2](#story-2)
    * [Implementation Details/Notes/Constraints [optional]](#implementation-detailsnotesconstraints-optional)
    * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
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
```
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

### Risks and Mitigations

The list of images might get outdated.

#### Mitigations

We should aim to automate as much of possible.
Make use of automated tests to ensure the list is kept up-to-date.

## Graduation Criteria

## Implementation History

- the `Summary` and `Motivation` sections being merged signaling owner acceptance

## Drawbacks [optional]

Some additional maintenance effort may be required to keep the list up-to-date, in case we can't automatically generate the entire list of container images.

## Alternatives [optional]

Continue without a centralized list, requiring users to manually discover the necessary container images.
