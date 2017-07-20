{{/* volumes helper templates */}}

{{/* volumes generates all volumes for pod */}}
{{- define "volumes" -}}
{{- $volumes := index . 0 -}}
{{- $cname := index . 1 -}}
{{- range $volumes -}}
{{- if ne .type "Isolated" }}
- name: {{ .name }}
{{- if eq .type "Dynamic" }}
  persistentVolumeClaim: 
    claimName: {{ $cname }}-{{ .name }}
{{- end -}}
{{- if eq .type "Static" }}
  persistentVolumeClaim: 
    claimName: {{ .source.target }}
    readOnly: {{ .source.readonly }}
{{- end -}}
{{- if eq .type "Temp" }}
  emptyDir:
    medium: {{ .source.medium }}
{{- end -}}
{{- if eq .type "Config" }}
  configMap:
    name: {{ .source.target }}
    defaultMode: {{ .source.default }}
    optional: {{ .source.optional }}
    items:
    {{- range .source.items }}
    - key: {{ .key }}
      path: {{ .path }}
      mode: {{ .mode }}
    {{- end -}}
{{- end -}}
{{- if eq .type "Secret" }}
  secret:
    secretName: {{ .source.target }}
    defaultMode: {{ .source.default }}
    optional: {{ .source.optional }}
    items:
    {{- range .source.items }}
    - key: {{ .key }}
      path: {{ .path }}
      mode: {{ .mode }}
    {{- end -}}
{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/* isolated generates volume templates for StatefulSet */}}
{{- define "isolated" -}}
{{- range . -}}
{{- if eq .type "Isolated" }}
- metadata:
    name: {{ .name }}
  spec:
    accessModes:
    {{- range .source.modes }}
    - {{ . }}
    {{- end }}
    storageClassName: {{ .source.class }}
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


