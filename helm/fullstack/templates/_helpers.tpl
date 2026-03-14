{{/*
Expand the name of the chart.
*/}}
{{- define "fullstack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fullstack.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "fullstack.backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fullstack.name" . }}-backend
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "fullstack.frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fullstack.name" . }}-frontend
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
