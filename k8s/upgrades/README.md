# Upgrade OpenEBS

## Overview

This document describes the steps for the following OpenEBS Upgrade paths:

- Upgrade from 1.8.0 or later to the latest release.

For other upgrade paths of earlier releases, please refer to the respective directories.
Example: 
- the steps to upgrade from 0.9.0 to 1.0.0 will be under [0.9.0-1.0.0](./0.9.0-1.0.0/).
- the steps to upgrade from 1.0.0 or later to a newer release up to 1.12.x will be under [1.x.0-1.12.x](./1.x.0-1.12.x/README.md).
- the steps to upgrade from 1.12.0 or later to a newer release up to 2.12.x will be under [1.12.x-2.12.x](./1.12.x-2.12.x/README.md).

## Important Notice

- The community e2e pipelines verify upgrade testing only from non-deprecated releases (1.8.0 and higher) to 3.0.0. If you are running on release older than 1.8.0, OpenEBS recommends you upgrade to the latest version as soon as possible.

- OpenEBS 3.0.0 deprecates the external provisioned volumes and suggest users to move towards CSI implementations of the respective storage engines (cStor/jiva). The guides below detail the steps to migrate from external-provisioned volumes and upgrade CSI based volumes.

### Migration of cStor Pools/Volumes to latest CSPC Pools/CSI based Volumes

OpenEBS 2.0.0 moves the cStor engine towards `v1` schema and CSI based provisioning. To migrate from old SPC based pools and cStor external-provisioned volume to CSPC based pools and cStor CSI volumes follow the steps mentioned in the [Migration documentation](https://github.com/openebs/upgrade/blob/develop/docs/migration.md#migrate-cstor-pools-and-volumes-from-spc-to-cspc). 

This migration can be performed after upgrading the old OpenEBS resources to `2.0.0` or above. 

### Upgrading CSPC pools and cStor CSI volumes

If already using CSPC pools and cStor CSI volumes they can be upgraded from `1.10.0` or later to the latest release via steps mentioned in the [Upgrade documentation](https://github.com/openebs/upgrade/blob/master/docs/upgrade.md).

### Migration of jiva Volumes to latest CSI based Volumes

OpenEBS 2.7.0 introduces the jiva-operator for CSI based provisioning. To migrate from old jiva external-provisioned volume to jiva CSI volumes follow the steps mentioned in the [Migration documentation](https://github.com/openebs/upgrade/blob/develop/docs/migration.md#migrating-jiva-external-provisioned-volumes-to-jiva-csi-volumes). 

This migration can be performed after upgrading the old OpenEBS resources to `2.0.0` or above. 

### Upgrading jiva CSI volumes

If already using jiva CSI volumes they can be upgraded from `2.7.0` or later to the latest release via steps mentioned in the [Upgrade documentation](https://github.com/openebs/upgrade/blob/develop/docs/upgrade.md#jiva-csi-volumes).
