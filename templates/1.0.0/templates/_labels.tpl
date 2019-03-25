{{/* annotations helper templates */}}

{{- define "releaselabels" -}}
{{- $release := index . 0 -}}
{{- $chart:= index . 1 }}
"controller.caicloud.io/release": {{ $release | quote }}
"controller.caicloud.io/chart": {{ $chart | quote }}
{{- end -}}

{{- define "controllerlabels" -}}
{{- if . }}
"controller.caicloud.io/name": {{ . | quote }}
{{- end -}}
{{- end -}}

{{- define "appLabels" -}}
{{- $app := index . 0 -}}
{{- $version := index . 1 | default "v1"}}
"app": {{ $app | quote }}
"version": {{ $version | quote }}
{{- end -}}
