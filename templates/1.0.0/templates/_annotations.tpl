{{/* annotations helper templates */}}

{{- define "annotations" -}}
{{- if . -}}
{{- range .annotations }}
{{.key | quote}}: {{.value | quote}}
{{ end -}}
{{- end -}}
{{- end -}}
