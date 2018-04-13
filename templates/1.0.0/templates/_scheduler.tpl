{{/* scheduler helper templates */}}

{{/* schelabels generates schedule labels */}}
{{- define "schelabels" -}}
{{- range $k, $v := .labels }}
{{ printf "schedule.caicloud.io/%s" $k | quote }}: {{ $v | quote}}
{{- end }}
{{- end -}}


{{- define "schedule" }}
schedulerName: {{ .scheduler | quote }}
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
        - key: {{ .key | quote }}
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
        - key: {{ .key | quote }}
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
- key: {{ .key | quote }}
  operator: {{ .operator | quote }}
  value: {{ .value | quote }}
  effect: {{ .effect | quote }}
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
      {{ printf "schedule.caicloud.io/%s" $k | quote }}: {{ $v | quote }}
    {{- end }}
    {{- end }}
    {{- if hasKey .selector "expressions" }}
    matchExpressions:
    {{- range .selector.expressions }}
    - key: {{ printf "schedule.caicloud.io/%s" .key | quote }}
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
  topologyKey: {{ .topologyKey | default "kubernetes.io/hostname" | quote }}
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
        {{ printf "schedule.caicloud.io/%s" $k | quote }}: {{ $v | quote }}
      {{- end }}
      {{- end }}
      {{- if hasKey .selector "expressions" }}
      matchExpressions:
      {{- range .selector.expressions }}
      - key: {{ printf "schedule.caicloud.io/%s" .key | quote }}
        operator: {{ .operator | quote }}
        values:
        {{- range .values }}
        - {{ . | quote }}
        {{- end }}
      {{- end }}
      {{- end }}
    namespaces:
    {{- range .namespaces }}
    - {{ . | quote }}
    {{- end }}
    topologyKey: {{ .topologyKey | default "kubernetes.io/hostname" | quote }} 
{{- end }}
{{- end }}
{{- end -}}


