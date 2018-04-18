{{/* volumes helper templates */}}

{{/* volumes generates all volumes for pod */}}
{{- define "volumes" -}}
{{- $volumes := index . 0 -}}
{{- $cname := index . 1 -}}
{{- range $volumes -}}
{{- if ne .type "Dedicated" }}
- name: {{ .name | quote }}
{{- if eq .type "Dynamic" }}
  persistentVolumeClaim: 
    claimName: {{ printf "%s-%s" $cname .name | quote }}
{{- end -}}
{{- if eq .type "Static" }}
  persistentVolumeClaim: 
    claimName: {{ .source.target | quote }}
    readOnly: {{ .source.readonly }}
{{- end -}}
{{- if eq .type "Scratch" }}
  emptyDir:
    medium: {{ .source.medium | quote }}
{{- end -}}
{{- if eq .type "HostPath" }}
  hostPath:
    path: {{ .source.path | quote }}
{{- end -}}
{{- if eq .type "Config" }}
  configMap:
    name: {{ .source.target | quote }}
    defaultMode: {{ .source.default }}
    optional: {{ .source.optional }}
    items:
    {{- range .source.items }}
    - key: {{ .key | quote }}
      path: {{ .path | quote }}
      mode: {{ .mode }}
    {{- end -}}
{{- end -}}
{{- if eq .type "Secret" }}
  secret:
    secretName: {{ .source.target | quote }}
    defaultMode: {{ .source.default }}
    optional: {{ .source.optional }}
    items:
    {{- range .source.items }}
    - key: {{ .key | quote }}
      path: {{ .path | quote }}
      mode: {{ .mode }}
    {{- end -}}
{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/* dedicated generates volume templates for StatefulSet */}}
{{- define "dedicated" -}}
{{- $g := index . 0 -}}
{{- $name := index . 1 -}}
{{- $volumes := index . 2 -}}
{{- range $volumes -}}
{{- if eq .type "Dedicated" }}
- metadata:
    name: {{ .name | quote }}
    labels:
      "controller.caicloud.io/release": {{ $g.Release.Name | quote }}
      "controller.caicloud.io/chart": {{ $g.Chart.Name | quote }}
      "controller.caicloud.io/name": {{ $name | quote }}
  spec:
    accessModes:
    {{- range .source.modes }}
    - {{ . | quote }}
    {{- end }}
    storageClassName: {{ .source.class | quote }}
    resources:
      requests:
        storage: {{ .storage.request }}
      {{- if hasKey .storage "limit" }}
      limits:
        storage: {{ .storage.limit }}
      {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}


