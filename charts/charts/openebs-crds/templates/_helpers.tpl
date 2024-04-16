{{/* vim: set filetype=mustache: */}}

{{/*
    Adds extra annotations to CRDs. This targets two scenarios: preventing CRD recycling in case
    the chart is removed; and adding custom annotations.
    NOTE: This function assumes the element `metadata.annotations` already exists.
    Usage:
      {{- include "crds.extraAnnotations" .Values.csi.volumeSnapshots | nindent 4 }}
*/}}

{{- define "crds.extraAnnotations" -}}
{{- if .keep -}}
helm.sh/resource-policy: keep
{{ end }}
{{- with .annotations }}
  {{- toYaml . }}
{{- end }}
{{- end -}}