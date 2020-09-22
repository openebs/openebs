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

OpenEBS Components are developed on several different code repositories. Active development happens on the master branch. When all the development activities scoped for a given release are completed or the deadline for code-freeze (third week) has approached, a release branch is created from the master. The branch is named after major and minor version of the release. Example for `1.10.0`, release, the release branch will be `v1.10.x`

Post creating the release branch, if any critical fixes are identified for the release, then the fixes will be pushed to master as well as cherry-picked into the corresponding release branches. 

Release Branch will be used for tagging the release belonging to a given major and minor version and all the subsequent patch releases. For example, `v1.10.0`, `v1.10.1` and so forth will be done from `v1.10.x` release branch. 

Release branches need to be created for the following repositories:
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
- openebs/api
- openebs/cstor-operators
- openebs/upgrade

The following repositories currently follow a custom release version.
- openebs/node-disk-manager
- openebs/zfs-localpv

The following repositories are under active development and releases are created from master branch.
- openebs/Mayastor
- openebs/linux-utils
- openebs/rawfile-localpv
- openebs/monitor-pv

To verify that release branches are created, you can run the following script:

```
git clone https://github.com/openebs/charts
cd charts
git checkout gh-pages

cd scripts/release
./check-release-branch.sh <release-branch>
```

## Release Tagging

OpenEBS Components are released as container images with versioned tags.

OpenEBS components are spread across various repositories. Creating a release tag on the repository will trigger the build, integration tests and pushing of the docker image to [docker hub](https://hub.docker.com/u/openebs) and [quay](https://quay.io/organization/openebs/) container repositories.

The format of the GitHub release tag is either "Release-Name-RC1" or "Release-Name" depending on whether the tag is a release candidate or a release. (Example: v1.0.0-RC1 is a GitHub release tag for OpenEBS release candidate build. v1.0.0 is the release tag that is created after the release criteria are satisfied by the release candidate builds.)

Each repository has the automation scripts setup to push the container images to docker and quay container repositories. The container image tag will be derived from GitHub release tag by truncating `v` from the release name. (Example: v1.0.0-RC1 will create container images for 1.0.0-RC1).

Once a release made on a repository, Travis will trigger the release on the dependent repositories. The release tree looks as follows:

- openebs/linux-utils
  - openebs/jiva
  - openebs/cstor
  - openebs/libcstor
    - openebs/istgt
      - openebs/cstor-operators
      - openebs/external-storage
        - openebs/maya
          - openebs/velero-plugin
          - openebs/cstor-csi
          - openebs/upgrade
          - openebs/jiva-operator
            - openebs/jiva-csi

The following repositories currently follow a different release versioning than other components, so these are triggered parallely. 
- openebs/node-disk-manager
- openebs/zfs-localpv
- openebs/Mayastor

The following repositories are under active development and are not yet added into the release process. These needs to be manually tagged on-demand.
- openebs/api
- openebs/rawfile-localpv
- openebs/monitor-pv

Once the release is triggered, Travis build process has to be monitored. Once Travis builds are passed, images are pushed to docker hub and quay.io. Images can be verified by going through docker hub and quay.io. Also the images shouldn't have any critical security vulnerabilities.
Example:
https://quay.io/repository/openebs/cstor-pool?tab=tags
https://hub.docker.com/r/openebs/openebs-k8s-provisioner/tags

## E2e Testing on Release Builds

Each minor and major release comprises of one or more release candidate builds, followed by a final release. 

Release Candidate builds are started from the third week into the release cycle. These release candidate builds help to freeze the scope and maintain the quality of the release. A release branch is created prior to generating the first release candidate build. Any issues found during the verification of the release candidate build are fixed in the master and cherry-picked into the release branch, prior to next release candidate build or the release build. 

Once the release candidate or release images are generated, raise a [request for running e2e pipeline](https://github.com/openebs/e2e-tests/issues/new/choose) to kick-start the build validation via automated and manual e2e tests. 

The e2e tests include the following:
- Platform Verification
- Regression and Feature Verification Automated tests.
- Exploratory testing by QA engineers
- Strict security scanners on the container images
- Upgrade from previous releases
- Beta testing by users on issues that they are interested in.
- Dogfooding on OpenEBS workload and e2e infrastructure clusters

Once all the above tests are completed successfully on release candidate builds, the final release build is triggered.  

E2e tests are repeated on the final release build. 

The status of the E2e on the release builds can be tracked in [openebs/e2e-tests](https://github.com/openebs/e2e-tests/issues?q=is%3Aissue+is%3Aopen+label%3Arelease-checklist)

Once the release build validation is complete, helm and operator YAMLs are published to [openebs/charts](https://github.com/openebs/charts).


## Release Checklist
- All release blockers found by [e2e testing on Release Candidate builds](#e2e-testing-on-release-builds) are resolved.
- The updated Install and Feature documentation are verified.
- Release notes with changes summary, changelog are updated.
- Verify that releases under each individual repository are updated with commit and CHANGELOG.
- openebs-operator and helm charts are published.
- Release is tagged on openebs/openebs repository.
- Release is announced on slack, distribution lists and social media.

## Generating Changelog and Release Summary

- For each individual repositories:
  * Update the Github releases with the commit log. The following commands can be used:

    ```
    git checkout <release-branch>
    git log --pretty=format:'- %s (%h) (@%an)' --date=short  --since="1 month"
    ```
    In case there are no changes, update it with "No changes".

    For RC tags, update the commit log with changes since the last tag.

    For Release tag, update the commit log with changes since the last release tag. This will ideally be sum of all the commits from the RC tags.

  * Raise a PR to update the CHANGELOG.md.

- Create an aggregate Change Summary for the release under [openebs/wiki](https://github.com/openebs/openebs/wiki).

- Create an Release Summary with highlights from the release that will be used with [openebs/releases](https://github.com/openebs/openebs/releases).

## Post Release Activities
- Blogs on new features are published
- Update the newsletter contents
- Release Webinar
- Update blogs, documentation with new content or examples. For example update the readme with change in status or process.
- Update the charts like Helm stable and other partner charts. (Rancher, OpenShift, IBM ICP Community Charts, Netapp NKS Trusted Charts (formerly StackPointCloud), AWS Marketplace, OperatorHub and DigitalOcean)

