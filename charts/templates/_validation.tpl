{{/* vim: set filetype=mustache: */}}

{{/*
Validate that localpv-dependent components are not configured to create
StorageClasses when the Dynamic LocalPV Provisioner is disabled.

Usage:
  {{ include "openebs.validate.localpv" . }}
*/}}
{{- define "openebs.validate.localpv" -}}
{{- if not .Values.engines.local.hostpath.enabled -}}
  {{- if and .Values.loki.enabled .Values.loki.localpvScConfig.enabled -}}
    {{- fail `

CONFIGURATION ERROR: engines.local.hostpath.enabled=false but loki.localpvScConfig.enabled=true

  The Dynamic LocalPV Provisioner is disabled, but Loki's localpv
  StorageClass configuration is enabled. This would create StorageClasses
  with provisioner "openebs.io/local" that cannot be fulfilled.

  To fix, choose one of:
    1. Enable the provisioner:
         --set engines.local.hostpath.enabled=true
    2. Disable localpv StorageClass creation and provide alternate storage classes:
         --set loki.localpvScConfig.enabled=false
         --set loki.singleBinary.persistence.storageClass=<your-storage-class>
         --set loki.minio.persistence.storageClass=<your-storage-class>
` -}}
  {{- end -}}
  {{- if and .Values.engines.replicated.mayastor.enabled .Values.mayastor.etcd.localpvScConfig.enabled -}}
    {{- fail `

CONFIGURATION ERROR: engines.local.hostpath.enabled=false but mayastor.etcd.localpvScConfig.enabled=true

  The Dynamic LocalPV Provisioner is disabled, but Mayastor's etcd localpv
  StorageClass configuration is enabled. This would create a StorageClass
  with provisioner "openebs.io/local" that cannot be fulfilled.

  To fix, choose one of:
    1. Enable the provisioner:
         --set engines.local.hostpath.enabled=true
    2. Disable localpv StorageClass creation and provide an alternate storage class:
         --set mayastor.etcd.localpvScConfig.enabled=false
         --set mayastor.etcd.persistence.storageClass=<your-storage-class>
` -}}
  {{- end -}}
{{- end -}}
{{- end -}}
