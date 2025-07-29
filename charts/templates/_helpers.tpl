{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "openebs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openebs.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openebs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "openebs.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "openebs.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}


{{/*
Define meta labels for openebs components
*/}}
{{- define "openebs.common.metaLabels" -}}
chart: {{ template "openebs.chart" . }}
heritage: {{ .Release.Service }}
openebs.io/version: {{ .Values.release.version | quote }}
{{- end -}}

{{/*
Returns matched if the Hostpath Localpv Deployment is of v3.x
Usage:
  {{- if include "hostpath_is_v3" . }}
    Do something
  {{- end }}
*/}}
{{- define "hostpath_is_v3" -}}
  {{/* Name from https://github.com/openebs/charts/blob/openebs-3.10.0/charts/openebs/templates/localprovisioner/deployment-local-provisioner.yaml#L8 */}}
  {{- $name1 := printf "%s-localpv-provisioner" (include "openebs.fullname" .) -}}
  {{/* Name from https://github.com/openebs/dynamic-localpv-provisioner/blob/v4.3.0/deploy/helm/charts/templates/deployment.yaml#L5 */}}
  {{- $sub   := index .Subcharts "localpv-provisioner" -}}
  {{- $name2 := include "localpv.fullname" $sub -}}

  {{/* Lookup Deployment by name1, fallback to name2 */}}
  {{- $deploy := lookup "apps/v1" "Deployment" .Release.Namespace $name1 -}}
  {{- if not $deploy -}}
    {{- $deploy = lookup "apps/v1" "Deployment" .Release.Namespace $name2 -}}
  {{- end -}}

  {{- if not $deploy -}}
    {{/* There just is no localpv-provisioner deployment. This is unexpected. We err on the side caution and match */}}
    matched
  {{- end -}}

  {{/* Validate chart label matches v3.x.y */}}
  {{- $chart := index $deploy.metadata.labels "chart" | default "" -}}
  {{- if regexMatch "^(openebs|localpv-provisioner)-3\\.[0-9]+\\.[0-9]+.*$" $chart -}}
    matched
  {{- end -}}
{{- end -}}
