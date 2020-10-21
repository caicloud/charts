{{/* annotations helper templates */}}

{{- define "releaselabels" -}}
{{- $release := index . 0 -}}
{{- $chart:= index . 1 }}
{{- $project := index . 2 }}
{{- $component := index . 3 }}
"controller.caicloud.io/release": {{ $release | quote }}
"controller.caicloud.io/chart": {{ $chart | quote }}
{{- if $project }}
"project.cmdb.caicloud.io/name": {{ $project | quote }}
{{- end -}}
{{- if $component }}
"component.cmdb.caicloud.io/name": {{ $component | quote }}
{{- end -}}
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

