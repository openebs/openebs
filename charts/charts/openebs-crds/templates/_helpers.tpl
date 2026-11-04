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

{{/*
    Should this chart install a given CSI VolumeSnapshot CRD?

    These CRDs are cluster-scoped and shared, so something else may already own them: OpenShift
    and several other distributions ship them as a platform component, and on any cluster
    another chart may have installed them first. Helm will not adopt a resource it does not own,
    so without this the release fails outright with "invalid ownership metadata" and the chart
    cannot be installed at all until the user knows to set csi.volumeSnapshots.enabled=false.

    So the CRD is installed when it is absent, or when it is already part of this release.
    It is left alone when it carries someone else's Helm ownership metadata, or none at all.
    Matching on the release is what makes this safe across upgrades: our own CRD comes back
    with our annotations, so it stays in the release rather than dropping out of it.

    `lookup` returns nothing when the renderer has no cluster to ask, in which case the CRD is
    installed exactly as it is today. `helm template`, `helm install --dry-run` without
    `=server`, and Argo CD all fall into that case; set the value explicitly there. Flux's
    helm-controller drives the Helm SDK against the live cluster, so it behaves as `helm
    install` does.

    Usage:
      {{- if (include "crds.installVolumeSnapshot" (dict "root" . "crd" "volumesnapshots.snapshot.storage.k8s.io")) -}}
*/}}

{{- define "crds.installVolumeSnapshot" -}}
{{- $root := .root -}}
{{- if $root.Values.csi.volumeSnapshots.enabled -}}
{{- $existing := lookup "apiextensions.k8s.io/v1" "CustomResourceDefinition" "" .crd -}}
{{- if not $existing -}}
true
{{- else -}}
{{- $annotations := default dict $existing.metadata.annotations -}}
{{- $owner := default "" (index $annotations "meta.helm.sh/release-name") -}}
{{- $ownerNamespace := default "" (index $annotations "meta.helm.sh/release-namespace") -}}
{{- if and (eq $owner $root.Release.Name) (eq $ownerNamespace $root.Release.Namespace) -}}
true
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
