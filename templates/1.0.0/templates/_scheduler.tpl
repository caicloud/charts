{{/* scheduler helper templates */}}

{{/* schelabels generates schedule labels */}}
{{- define "schelabels" -}}
{{- range $k, $v := .labels }}
"schedule.caicloud.io/{{ $k }}": {{ $v | quote}}
{{- end }}
{{- end -}}


{{- define "schedule" }}
schedulerName: {{ .scheduler }}
affinity:
  {{- with .affinity }}
  {{- with .node }}
  nodeAffinity:
    {{- if eq .type "Required" }}
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      {{- range .terms }}
      - matchExpressions:
        {{- range .expressions }}
        - key: {{ .key }}
          operator: {{ .operator | quote }}
          values:
          {{- range .values }}
          - {{ . | quote }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- else }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- range .terms }}
    - weight: {{ .weight }}
      preference:
        matchExpressions:
        {{- range .expressions }}
        - key: {{ .key }}
          operator: {{ .operator | quote }}
          values:
          {{- range .values }}
          - {{ . | quote }}
          {{- end }}
        {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- with .pod }}
  podAffinity:
  {{- include "podaffinity" . | indent 4 }}
  {{- end }}
  {{- end }}
  {{- with .antiaffinity }}
  {{- with .pod }}
  podAntiAffinity:
  {{- include "podaffinity" . | indent 4 }}
  {{- end }}
  {{- end }}
tolerations:
{{- range .tolerations }} 
- key: {{ .key }}
  operator: {{ .operator }}
  value: {{ .value }}
  effect: {{ .effect }}
  tolerationSeconds: {{ .tolerationSeconds }}
{{- end -}}
{{- end -}}


{{/* podaffinity */}}
{{- define "podaffinity" -}}
{{- if eq .type "Required" }}
requiredDuringSchedulingIgnoredDuringExecution:
{{- range .terms }}
- labelSelector:
    {{- if hasKey .selector "labels" }}
    matchLabels:
    {{- range $k, $v := .selector.labels }}
      "schedule.caicloud.io/{{ $k }}": {{ $v | quote }}
    {{- end }}
    {{- end }}
    {{- if hasKey .selector "expressions" }}
    matchExpressions:
    {{- range .selector.expressions }}
    - key: "schedule.caicloud.io/{{ .key }}"
      operator: {{ .operator | quote }}
      values:
      {{- range .values }}
      - {{ . | quote }}
      {{- end }}
    {{- end }}
    {{- end }}
  namespaces:
  {{- range .namespaces }}
  - {{ . }}
  {{- end }}
  topologyKey: {{ .topologyKey | default "kubernetes.io/hostname" }}
{{- end }}
{{- else }}
preferredDuringSchedulingIgnoredDuringExecution:
{{- range .terms }}
- weight: {{ .weight }}
  podAffinityTerm:
    labelSelector:
      {{- if hasKey .selector "labels" }}
      matchLabels:
      {{- range $k, $v := .selector.labels }}
        "schedule.caicloud.io/{{ $k }}": {{ $v | quote }}
      {{- end }}
      {{- end }}
      {{- if hasKey .selector "expressions" }}
      matchExpressions:
      {{- range .selector.expressions }}
      - key: "schedule.caicloud.io/{{ .key }}"
        operator: {{ .operator | quote }}
        values:
        {{- range .values }}
        - {{ . | quote }}
        {{- end }}
      {{- end }}
      {{- end }}
    namespaces:
    {{- range .namespaces }}
    - {{ . }}
    {{- end }}
    topologyKey: {{ .topologyKey | default "kubernetes.io/hostname" }} 
{{- end }}
{{- end }}
{{- end -}}


