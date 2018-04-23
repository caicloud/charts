{{/* annotations helper templates */}}

{{- define "releaseLabels" -}}
{{- $release := index . 0 -}}
{{- $chart:= index . 1 }}
"controller.caicloud.io/release": {{ $release | quote }}
"controller.caicloud.io/chart": {{ $chart | quote }}
{{- end -}}

{{- define "controllerLabels" -}}
{{- if . }}
"controller.caicloud.io/name": {{ . | quote }}
{{- end -}}
{{- end -}}
