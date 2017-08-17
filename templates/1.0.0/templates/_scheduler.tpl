{{/* scheduler helper templates */}}

{{/* schelabels generates schedule labels */}}
{{- define "schelabels" -}}
{{- range $k, $v := .labels }}
"schedule.caicloud.io/{{ $k }}": {{ $v | quote}}
{{- end }}
{{- end -}}


{{- define "schedule" }}
schedulerName: {{ .scheduler }}
affinity: {{ .scheduler }}
  nodeAffinity:
    {{- if eq .affinity.node.type "Required" }}
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      {{- range .affinity.node.terms }}
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
    {{- range .affinity.node.terms }}
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
  podAffinity:
  {{- include "podaffinity" .affinity.pod | indent 4 }}
  podAntiAffinity:
  {{- include "podaffinity" .antiaffinity.pod | indent 4 }}
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
      {{ $k | quote }}: {{ $v | quote }}
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
        {{ $k | quote }}: {{ $v | quote }}
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


