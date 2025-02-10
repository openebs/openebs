# Overview

OpenEBS is the umbrella project repository that houses:
1. The OpenEBS Umbrella helm chart.
2. The Unified Kubectl Plugin, `kubectl-openebs` for management and observability of OpenEBS Storage Engines.<br>
   **NOTE**: The Unified Plugin is currently in [openebsctl](https://github.com/openebs/openebsctl), which is undergoing overhaul and would eventually be available from `openebs/openebs` repository.

## Release Tagging

1. OpenEBS Release process currently includes release of the umbrella helm chart. Once all the subprojects are released. The respective chart versions are updated on the umbrella helm chart.
2. A release is created and a tag is created against the `develop` branch.
3. Once the release is created the helm chart is published and available for end users.

The release notes are updated on the release page. It consists of summary and information across all sub-projects. Check [here](https://github.com/openebs/openebs/releases)