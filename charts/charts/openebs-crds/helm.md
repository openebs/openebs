# openebs-crds

![Version: 4.1.0](https://img.shields.io/badge/Version-4.1.0-informational?style=flat-square)

A Helm chart that collects CustomResourceDefinitions (CRDs) from OpenEBS.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| csi.volumeSnapshots.enabled | bool | `true` | Install Volume Snapshot CRDs |
| csi.volumeSnapshots.keep | bool | `true` | Keep CRDs on chart uninstall |

