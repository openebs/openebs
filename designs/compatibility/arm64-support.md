---

oep-number: OEP 3817
title: Support `arm64` OpenEBS Deployments
authors:  
  - "@maxwnewcomer"
owners:
  - "@maxwnewcomer"
  - "@tiagolobocastro"
editor: TBD
creation-date: 2024-12-13
last-updated: 2024-12-13
status: provisional
see-also:
replaces:
superseded-by:

---

# Supporting `arm64` OpenEBS Deployments

## Table of Contents

- [Supporting `arm64` OpenEBS Deployments](#supporting-arm64-openebs-deployments)
  - [Table of Contents](#table-of-contents)
  - [Summary](#summary)
  - [Motivation](#motivation)
    - [Goals](#goals)
    - [Non-Goals](#non-goals)
  - [Proposal](#proposal)
    - [User Stories](#user-stories)
      - [Story 1](#story-1)
      - [Story 2](#story-2)
    - [Implementation Details/Notes/Constraints](#implementation-detailsnotesconstraints)
    - [Risks and Mitigations](#risks-and-mitigations)
  - [Graduation Criteria](#graduation-criteria)
  - [Implementation History](#implementation-history)
  - [Drawbacks \[optional\]](#drawbacks-optional)
  - [Alternatives \[optional\]](#alternatives-optional)
  - [Infrastructure Needed \[optional\]](#infrastructure-needed-optional)

## Summary

As the Arm ecosystem matures and grows in popularity—driven by the performance, cost, and energy efficiency benefits that `arm64` architectures offer—many users and organizations are seeking to standardize their infrastructure on Arm-based platforms. OpenEBS, as a storage solution for stateful workloads in Kubernetes, currently provides robust `amd64` binaries and containers. However, the absence of official, fully-tested `arm64` support has started to pose challenges for users running on environments like AWS Graviton, Local Development machines, and on-premise Arm servers.

This OEP aims to introduce and formalize official support for `arm64` architectures within the OpenEBS ecosystem. Specifically, it proposes building multi-architecture container images, extending CI pipelines to validate `arm64` builds, and ensuring parity in functionality and performance between `amd64` and `arm64` deployments. By doing so, we will enable the broader OpenEBS community to benefit from Arm-based infrastructures confidently, without resorting to third-party forks or uncertain workarounds.

## Motivation

The growing prevalence of `arm64` servers in both cloud and edge environments has made Arm architectures a strategic choice for cost optimization, performance-per-watt improvements, and scalability. As more Kubernetes workloads move towards Arm, storage layers must keep pace. Official `arm64` support in OpenEBS will ensure users can rely on the same stable, production-grade storage capabilities across architectures, fostering an inclusive ecosystem and expanding OpenEBS’s reach and adoption.

### Goals

- **Multi-Architecture Container Images**: Provide official `arm64` container images for all OpenEBS control-plane and data-plane components.
- **CI Validation and Testing**: Integrate `arm64` tests into the existing CI pipelines to ensure feature parity, performance metrics validation, and interoperability.
- **Documentation and Guidance**: Update official documentation to clearly state which architectures are supported and provide guidance on deploying OpenEBS clusters on `arm64` environments.
- **Community Feedback Loop**: Establish channels (e.g., Slack, GitHub discussions, mailing lists) to gather early feedback from users running on `arm64` and continuously improve support.

### Non-Goals

- **Architecture-Specific Optimizations**: This OEP does not focus on deep, architecture-specific optimizations tailored for `arm64` (e.g., using ARM-specific CPU instructions). The goal is baseline parity, not heavily optimized builds.
- **Retroactive Support for Legacy Architectures**: We will not extend support to other architectures beyond `arm64` and `amd64`.
- **Performance Guarantees**: While we aim for parity, we will not provide strict performance guaranatees specific to `arm64` at this stage.
- **Immediate Full Feature Set Validation on `arm64`**: We will start with core components and eventually roll out to all official modules. Some pre-release/non-official engines (Local Rawfile) or features may come later.

## Proposal

This proposal involves extending current build and release workflows to produce `arm64` images and validate them through CI/CD. It includes adding `arm64` test runners, ensuring that Helm charts and manifests work on `arm64` clusters, and validating that all dependencies are functional on Arm architecture.

### User Stories

#### Story 1

**As a developer** running a test Kubernetes cluster on my local M-series MacBook, I want to deploy OpenEBS to manage my local storage. Without official `arm64` images, I feel boxed out of developing on top of OpenEBS. Official support ensures I can quickly deploy and maintain OpenEBS on my machine without custom tooling, virtualization, or complicated workarounds.

#### Story 2

**As an operator** managing AWS Graviton-based EKS clusters, I need a storage solution that runs natively and efficiently on `arm64`. With official `arm64` support in OpenEBS, I can deploy OpenEBS alongside my other Arm-native applications, simplifying my environment and reducing operational overhead related to mixed-architecture maintenance.

### Implementation Details/Notes/Constraints
  
- **Dependency Checks**:
  - Verify that all external dependencies (`spdk-rs`, `bitnami-shell`, etc.) provide `arm64` binaries or have acceptable fallbacks.

- **Control-plane Builds**:
  - Update control-plane builds to support `arm64`.

- **Data-plane build**:
  - Update data-plane builds to support `arm64`.
    - LocalPV-HostPath
    - LocalPV-ZFS
    - LocalPV-LVM
    - ReplicatedPV-Mayastor
  
- **Testing Strategy**:
  - Introduce `arm64` test nodes for integration tests.
  - Run key conformance tests and functional tests on `arm64` platforms to ensure feature parity.

- **Documentation and Examples**:
  - Update the official OpenEBS docs to include instructions for deploying on `arm64` clusters.
  - Provide example manifests and Helm chart values showing how to install and verify `arm64` deployments.

### Risks and Mitigations

- **Risk: CI Complexity**: Adding `arm64` pipelines may increase build time and complexity.
  - *Mitigation*: Use cloud-based ARM runners or Arm-enabled CI platforms, and possibly maintain separate test schedules for `arm64` to reduce load.
  
- **Risk: Limited Community Hardware**: Some maintainers and community members might not have immediate access to native `arm64` hardware for debugging.
  - *Mitigation*: Utilize public cloud credits for temporary Arm instances or rely on well-supported emulation to replicate issues.

- **Risk: External Dependencies**: Some upstream dependencies may lack `arm64` builds.
  - *Mitigation*: Work closely with dependency maintainers or find equivalents that support `arm64`. Document any known gaps or compatibility issues.

## Graduation Criteria

- **Alpha (Initial Support)**:
  - `arm64` images are built and published for all primary OpenEBS components.
  - Basic integration tests pass on an `arm64` test cluster.
  - Documentation updated to reflect `arm64` availability.

- **Beta (Expanded Support)**:
  - Comprehensive integration tests and end-to-end tests run regularly on `arm64`.
  - Users have reported successful deployments without critical issues.
  - Helm charts and manifests verified for `arm64` environments.

- **General Availability (GA)**:
  - `arm64` support is included in stable OpenEBS releases.
  - Formal support commitments are documented (e.g., backporting critical fixes).

## Implementation History

- **2024-12-13**: Draft OEP with summary and motivation created (provisional status).

## Drawbacks [optional]

- Increased continuous integration resources and compute time.
- Additional maintenance overhead and potential for new `arm64`-specific issues.
- Broader testing matrix may slow down release cadence.

## Alternatives [optional]

- Continue supporting only `amd64`.
- Partial support with unofficial or best-effort builds without rigorous testing.
- Wait for broader industry support and proven `arm64` tooling maturity before investing in this effort.

## Infrastructure Needed [optional]

- `arm64` CI runners or cloud-based environments for testing.
- Potentially additional storage or caching layers to handle multi-arch image builds.
- Automated testbeds (e.g., a small `arm64` Kubernetes cluster) for integration and performance benchmarking.
