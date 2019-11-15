# OpenEBS Release Management

OpenEBS Components are released as container images with versioned tags. The release process is triggered by creating a Release Tag on the repository. For major releases, the Release Tag is created on the master branch and for minor release, the release tag is triggered on the corresponding release branch.

The release process involves the following stages:
- Release Candidate Builds
- Update Installer and Documentation
- Update the charts like Helm stable and other partner charts. (Rancher, OpenShift, IBM ICP Community Charts, Netapp NKS Trusted Charts (formerly StackPointCloud), AWS Marketplace, OperatorHub and DigitalOcean)
- Update the openebs-operator.yaml
- Final Release

Release Candidate Builds
On reaching the feature freeze date, the repositories are tagged with "Release-Name-RC1" tag. (Example 1.0.0-RC1).
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

The e2e pipeline and exploratory tests are executed using the RC tagged images. Any issues identified during this RC testing are tagged as release blockers.
After the issues are fixed and verified by the CI, next RC is triggered.(Example: 1.0.0-RC2)
The above process is repeated till a RC has been arrived with all the release blockers fixed.
After the final RC, a release tag is created. (Example 1.0.0) in the same order as the release candidate builds. The e2e pipeline and exploratory tests are repeated on the release tagged builds.

Once the release is triggered, travis build process has to be monitored. Once travis builds are passed images are pushed to docker hub and quay.io.
Images can be verified by going through docker hub and quay.io. Also the images shouldn't have any high level vulnerabilities.
Example:
https://quay.io/repository/openebs/cstor-pool?tab=tags
https://hub.docker.com/r/openebs/openebs-k8s-provisioner/tags
