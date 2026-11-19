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
{{- if .Values.engines.replicated.mayastor.enabled -}}
  {{- $lokiMode := .Values.mayastor.eventing.aggregator.lokiMode | toString -}}
  {{- if and .Values.loki.enabled (eq $lokiMode "false") -}}
    {{- fail `

CONFIGURATION ERROR: loki.enabled=true but mayastor.eventing.aggregator.lokiMode=false

  The eventing-aggregator would write events to a local emptyDir instead of
  logging them for Loki, so events would not reach the openebs loki.

  To fix, choose one of:
    1. --set mayastor.eventing.aggregator.lokiMode=true
    2. --set loki.enabled=false
` -}}
  {{- end -}}
  {{- if and (not .Values.loki.enabled) (not .Values.mayastor.loki.enabled) (eq $lokiMode "true") -}}
    {{- fail `

CONFIGURATION ERROR: no loki is deployed but mayastor.eventing.aggregator.lokiMode=true

  The eventing-aggregator would log events for Loki, but neither the openebs
  loki (loki.enabled) nor mayastor's loki (mayastor.loki.enabled) is deployed,
  and the events would not be persisted.

  To fix, choose one of:
    1. --set mayastor.eventing.aggregator.lokiMode=false
    2. --set loki.enabled=true
` -}}
  {{- end -}}
{{- end -}}
{{- end -}}
