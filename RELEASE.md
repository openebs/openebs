### **OpenEBS Release Process Overview**

The OpenEBS release process follows a structured approach to ensure stability, reliability, and quality of the storage solutions provided. The process typically includes the following steps:

---
### **Planning & Feature Freeze**
- The release cyclqaae begins with a planning phase, where maintainers and contributors define the roadmap and key features for the upcoming release.
- A feature freeze is enforced to ensure only bug fixes and critical changes are allowed beyond this point.

### **Development & Code Merging**
- Developers work on new features, improvements, and bug fixes.
- Changes are reviewed via GitHub pull requests (PRs), passing automated tests before merging across all subprojects.

### **Pre-Release**
- OpenEBS uses continuous integration (CI) to run unit tests, integration tests, and end-to-end (E2E) tests.
- Performance and compatibility testing is conducted across multiple Kubernetes versions and storage backends.
- Since OpenEBS has multiple Sub-Projects each of the individual subprojects follow their own pre-release process. Refer to the below ones for more detail:
   * ZFS LocalPV - https://github.com/openebs/zfs-localpv/blob/develop/RELEASE.md
   * LVM LocalPV - https://github.com/openebs/lvm-localpv/blob/develop/RELEASE.md
   * Hostpath LocalPV - https://github.com/openebs/dynamic-localpv-provisioner/blob/develop/RELEASE.md
   * Mayastor - https://github.com/openebs/mayastor/blob/develop/RELEASE.md
- Once all the Sub-Projects pre-release tags are available, on OpenEBS umbrella repository the respective release branch is created. Ex `release/x.y`.
- On the `release/x.y` branch the respective subproject `pre-release` tags are updated, so that an Umbrella `pre-release` build can be used for e2e testing.

### **Final Release & Tagging**
- Once all the Sub-Projects are released, on OpenEBS umbrella repository the respective release branch ex `release/x.y`, is updated with the final tags of the subprojects.
- Then a final release tag ex. `x.y.z` is created. This process triggers the actions for Umbrella Chart build and the unified kubectl plugin.
- Post the success of the action the Unified chart is hosted on openebs/openebs repository and the kubectl plugin is available on the release artifacts as well as krew index.
- Post the release the `pre-release` version of on the `release/x.y` branch is bumped up, ex `x.y.z+1-prerelease`, which makes the cycle ready for a possible patch release.

### **Patch Releases**
- For patch releases all the Sub-Projects whose patch is to be release is released prior to Umbrella patch release as per their release process, on OpenEBS umbrella repository the respective release branch ex `release/x.y`, is updated with the tags of the patch releases of the subprojects.
- Then a final release tag ex. `x.y.z+1` is created. This process triggers the actions for Umbrella Chart build and the unified kubectl plugin.
- Post the success of the action the Unified chart is hosted on openebs/openebs repository and the kubectl plugin is available on the release artifacts as well as krew index.

The process ensures that OpenEBS remains a **stable, production-ready** Kubernetes-native storage solution. 🚀
