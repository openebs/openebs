# OpenEBS Release Management

OpenEBS follows a monthly release cadence. The scope of the release is determined by contributor availability and the pending items listed in the [roadmap](../../ROADMAP.md). The scope is published in the [Release Tracker Projects](https://github.com/orgs/openebs/projects).

## Overview

* Release Manager is identified at the beginning of each release from the contributor community, who will work with one of the maintainers of the OpenEBS project. Release manager is responsible for tracking the scope, coordinating with various stack holders and helping root out the risks to the release as early as possible. Release manager uses the [Daily Standup](https://github.com/openebs/openebs/tree/master/community#daily-standup-and-release-cadence-meetings) and the [Release Tracker](https://github.com/orgs/openebs/projects) to help everyone stay focused on the release.
* Each release has the following important milestones that have organically developed to help maintain the monthly release cadence.
  * First Week - Release planning is completed with leads identified for all the features targeted for the release. At the end of the first week, there should not be any "To do" items in the release tracker. If there are no leads available, the "To do" items will be pushed to the next release backlog. It is possible that some of the contributors will continue to work on the items that may not make it into current release, but will be pushed into the upcoming release.
  * Second Week - Depending on the feature status - alpha, beta or stable, the various tasks from development, review, e2e and docs are identified. Any blockers in terms of design or implementation are discussed and mitigated.
  * Third Week - [Release branch](#release-branch) is created and the first [Release candidate container images](#release-tagging) are made available. Post this stage only bug fixes are accepted into the release. Upgrades are tested. Staging documentation is updated. CI Pipelines are automated with new tests.
  * Fourth Week - Release notes are prepared. The final RC build is pushed to Dogfooding and beta testing with some of the users. The installers are updated. Release, Contributor and User Documentation are published.
  * Fifth Week - Post release activities like pushing the new release to the partner charts like Rancher Catalog, Amazon marketplace and so forth are worked on.


## Release Branch

OpenEBS Components are developed on several diffeernt code repositories. Active development happens on the master branch. When all the development activities scoped for a given release are completed or the deadline for code-freeze (third week) has approached, a release branch is created from the master. The branch is named after major and minor version of the release. Example for `1.10.0`, release, the release branch will be `v1.10.x`

Post creating the release branch, if any critical fixes are identified for the release, then the fixes will be pushed to master as well as cherry-picked into the corresponding release branches. 

Release Branch will be used for tagging the release belonging to a given major and minor version and all the subsequent patch releases. For example, `v1.10.0`, `v1.10.1` and so forth will be done from `v1.10.x` release branch. 

## Release Tagging

OpenEBS Components are released as container images with versioned tags.

OpenEBS components are spread across various repositories. Creating a release tag on the repository will trigger the build, integration tests and pushing of the docker image to [docker hub](https://hub.docker.com/u/openebs) and [quay](https://quay.io/organization/openebs/) container repositories.

The format of the GitHub release tag is either "Release-Name-RC1" or "Release-Name" depending on whether the tag is a release candidate or a release. (Example: v1.0.0-RC1 is a GitHub release tag for OpenEBS release candidate build. v1.0.0 is the release tag that is created after the release criteria are satisfied by the release candidate builds.)

Each repository has the automation scripts setup to push in the container images to docker and quay container repositories. The container image tag will be derived from GitHub release tag by truncating `v` from the release name. (Example: v1.0.0-RC1 will create container images for 1.0.0-RC1).

Once a relase made on a repository, Travis will trigger the release on the dependent repositories. The release tree looks as follows:

- openebs/linux-utils
  - openebs/jiva
  - openebs/libcstor
    - openebs/cstor
      - openebs/istgt
        - openebs/external-storage
          - openebs/maya
            - openebs/velero-plugin
            - openebs/cstor-csi
              - openebs/jiva-operator
                - openebs/jiva-csi

The following repositories currently follow a different release versioning than other components, so these are triggered parallely. 
- openebs/node-disk-manager
- openebs/zfs-localpv

Starting with v1.10.0, following new repositories are included into the release process. 
- openebs/api
- openebs/cstor-operators

Once the release is triggered, Travis build process has to be monitored. Once Travis builds are passed images are pushed to docker hub and quay.io. Images can be verified by going through docker hub and quay.io. Also the images shouldn't have any high level vulnerabilities.
Example:
https://quay.io/repository/openebs/cstor-pool?tab=tags
https://hub.docker.com/r/openebs/openebs-k8s-provisioner/tags

Once a release is created on a repository, update the release description with commit log. The following commands can be used:
```
git checkout <release-branch>
git log --pretty=format:'- %s (%h) (@%an)' --date=short  --since="1 month"
```

In case there are no changes, update it with "No changes"

For RC tags, update the commit log with changes since the last tag.
For Release tag, update the commit log with changes since the last release tag. This will ideally be sum of all the commits from the RC tags.

## Release Candidate Verification Checklist

Every release has release candidate builds that are created starting from the third week into the release. These release candidate builds help to freeze the scope and maintain the quality of the release. The release candidate builds will go through:
- Platform Verification
- Regression and Feature Verification Automated tests.
- Exploratory testing by QA engineers
- Strict security scanners on the container images
- Upgrade from previous releases
- Beta testing by users on issues that they are interested in.
- Dogfooding on OpenEBS workload and e2e infrastructure clusters

If any issues are found during the above stages, they are fixed and a new release candidate builds are generated.

Once all the above tests are completed, a main release tagged images, helm and operator YAMLs are published.


## Final Release Checklist
- There are no release blockers identified in the [Release Candidate Verification Checklist](#release-candidate-verification-checklist) on the final release tagged images.
- The updated Install and Feature documentation are verified.
- Release notes with changes summary, changelog are updated.
- Verify that releases under each individual repository are updated with commit and CHANGELOG.
- openebs-operator and helm charts are published.
- Release is tagged on openebs/openebs repository.
- Release is announced on slack, distribution lists and social media.

## Post Release Activities
- Blogs on new features are published
- Update the newsletter contents
- Release Webinar
- Update blogs, documentation with new content or examples. For example update the readme with change in status or process.
- Update the charts like Helm stable and other partner charts. (Rancher, OpenShift, IBM ICP Community Charts, Netapp NKS Trusted Charts (formerly StackPointCloud), AWS Marketplace, OperatorHub and DigitalOcean)

