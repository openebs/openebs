# OpenEBS Release Management

OpenEBS follows a monthly release cadence. The scope of the release is determined by contributor availability and the pending items listed in the [roadmap](../../ROADMAP.md). The scope is published in the [Release Tracker Projects](https://github.com/openebs/openebs/projects). 

## Overview

* Release Manager is identified at the begining of each release from the contributor community, who will work with one of the maintainers of the OpenEBS project. Release manager is responsible for tracking the scope, co-ordinating with various stack holders and helping root out the risks to the release as early as possible. Release manager uses the [Daily Standup](https://github.com/openebs/openebs/tree/master/community#regular-standup-and-release-cadence-meetings) and the [Release Tracker](https://github.com/openebs/openebs/projects) to help everyone stay focused on the release.  
* Each release has the following important milestones that have organically developed to help maintain the montly release cadence. 
  * First Week - Release planning is completed with leads identified for all the features targetted for the release. At the end of the first week, there should not be any "To do" items in the release tracker. If there are no leads available, the "To do" items will be pushed to the next release backlog. It is possible that some of the contributors will continue to work on the items that may not make it into current release, but will be pushed into the upcoming release. 
  * Second Week - Depending on the feature status - alpha, beta or stable, the various tasks from development, review, e2e and docs are identified. Any blockers in terms of design or implementation are discussed and mitigated.
  * Third Week - Release branch is created and the first Release candidate build is made available. Post this stage only bug fixes are accepted into the release. Upgrades are tested. Staging documentation is updated. CI Pipelines are automated with new tests. 
  * Fourth Week - Release notes are prepared. The final RC build is pushed to Dogfooding and beta testing with some of the users. The installers are updated. Release, Contributor and User Documentation are published. 
  * Fifth Week - Post release activities like pushing the new release to the partner charts like Rancher Catelog, Amazon marketplace and so forth are worked on. 

## Release Candidate Verification Checklist

Every release has release candidate builds that are created starting from the third week into the release. These release candidate builds help to freeze the scope and maintain the quality of the release. The release candidate builds will go through:
- Platform Verification 
- Regression and Feature Verification Automated tests.
- Exploratory testing by QA engineers
- Strict security scanners on the container images
- Upgrade from previous releases
- Beta testing by users on issues that they are interested in. 
- Dogfooding on workload and MayaData OpenEBS Director staging cluster. 

If any issues are found during the above stages, they are fixed and a new release candidate builds are generated. 

Once all the above tests are completed, a main release tagged images, helm and operator YAMLs are published.

## Release Tagging

OpenEBS Components are released as container images with versioned tags. 

OpenEBS components are spread across various repositories. Creating a release tag on the repository will trigger the build, integration tests and pushing of the docker image to [docker hub](https://hub.docker.com/u/openebs) and [quay](https://quay.io/organization/openebs/) container repositories. 

The format of the release tag is either "Release-Name-RC1" or "Release-Name" depending on whether the tag is a release candidate or a release. (Example: 1.0.0-RC1 is a github release tag for openebs release candidate build. 1.0.0 is the release tag that is created after the release criteria is statisfied by the release candidate builds.)

Each of the respository has the automation scripts setup to push in the container images to docker and quay container repositories. 

The release tags are applied in the following order:
- openebs/libcstor
- openebs/cstor
- openebs/istgt
- openebs/jiva
- openebs/node-disk-manager
- openebs/external-storage
- openebs/velero-plugin
- openebs/maya
- openebs/cstor-csi
- openebs/zfs-localpv

Once the release is triggered, travis build process has to be monitored. Once travis builds are passed images are pushed to docker hub and quay.io. Images can be verified by going through docker hub and quay.io. Also the images shouldn't have any high level vulnerabilities.
Example:
https://quay.io/repository/openebs/cstor-pool?tab=tags
https://hub.docker.com/r/openebs/openebs-k8s-provisioner/tags

## Final Release Checklist
- There are no release blockers identified in the [Release Candidate Verification Checklist](#release-candidate-verification-checklist) on the final release tagged images.
- The updated Install and Feature documentation are verified. 
- Release notes with changes summary, changelog are updated. 
- openebs-operator and helm charts are published.
- Release is tagged on openebs/openebs repository.
- Release is announced on slack, distribution lists and social media

## Post Release Activites
- Blogs on new features are published
- Update the news letter contents
- Release Webinar
- Update blogs, documentation with new content or examples. For example update the readme with change in status or process. 
- Update the charts like Helm stable and other partner charts. (Rancher, OpenShift, IBM ICP Community Charts, Netapp NKS Trusted Charts (formerly StackPointCloud), AWS Marketplace, OperatorHub and DigitalOcean)

