{{/*
Named template snippets ("helper functions"). Nothing in this file renders
a manifest on its own — every block here is only materialized where another
template calls `{{ include "api-server.xxx" . }}`.
*/}}

{{/*
Expand the name of the chart, respecting nameOverride.
*/}}
{{- define "api-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name: <release-name>-<chart-name>.
Truncated to 63 chars because some Kubernetes name fields are limited to
that (by the DNS naming spec) and we leave room for a name suffix.
*/}}
{{- define "api-server.fullname" -}}
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
Standard labels applied to every object — used with `include ... | nindent 4`.
*/}}
{{- define "api-server.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "api-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels — deliberately a SUBSET of the full labels above. These go on
spec.selector.matchLabels and MUST stay immutable across upgrades (matchLabels
is an immutable field on Deployment/StatefulSet), so keep version/chart-hash
type labels out of this block or every chart bump breaks the selector.
*/}}
{{- define "api-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "api-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Name of the ServiceAccount to use — either the one we create, or a
pre-existing one the caller points us at via serviceAccount.name.
*/}}
{{- define "api-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "api-server.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
