# openebs-crds

![Version: 4.5.0-develop](https://img.shields.io/badge/Version-4.5.0--develop-informational?style=flat-square)

A Helm chart that collects CustomResourceDefinitions (CRDs) from OpenEBS.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| csi.volumeSnapshots.enabled | bool | `true` | Install Volume Snapshot CRDs. Any the cluster already has are left to whoever owns them; set this to false to skip them entirely. |
| csi.volumeSnapshots.keep | bool | `true` | Keep CRDs on chart uninstall |
