{{/* pod helper templates */}}


{{- define "podspec" -}}
{{- $controller := index . 0 -}}
{{- $name := index . 1 -}}

{{- with $controller.pod }}
restartPolicy: {{ .restart }}
dnsPolicy: {{ .dns }}
hostname: {{ .hostname }}
subdomain: {{ .subdomain }}
terminationGracePeriodSeconds: {{ .termination }}
hostNetwork: {{ .host.network }}
hostPID: {{ .host.pid }}
hostIPC: {{ .host.ipc }}
{{- end }}
{{- template "schedule" $controller.schedule }}
volumes:
{{- template "volumes" (list $controller.volumes $name) }}
initContainers:
{{- template "containers" $controller.initializers }}
containers:
{{- template "containers" $controller.containers }}
{{- end -}}




{{/* containers generates all containers for a pod */}}
{{- define "containers" -}}
{{- range $index, $container := . -}}
{{- with $container }}
- name: {{ .name | default (printf "c%d" $index) }}
  image: {{ .image }}
  imagePullPolicy: {{ .imagePullPolicy }}
  tty: {{ .tty }}
  command:
  {{- range .command }}
  - {{ . }}
  {{- end }}
  args:
  {{- range .args }}
  - {{ . }}
  {{- end }}
  workingDir: {{ .workingDir }}
  ports:
  {{- range .ports }}
  - name: {{ (printf "%s-%.0f" .protocol .port) | lower | quote }}
    {{- if eq .protocol "UDP" }}
    protocol: "UDP"
    {{- else }}
    protocol: "TCP"
    {{- end }}
    containerPort: {{ .port }}
  {{- end }}
  envFrom:
  {{- include "envfile" .envFrom | indent 2 }}
  env:
  {{- include "downwardenv" .downwardPrefix | indent 2 }}
  {{- include "env" .env | indent 2 }}
  resources:
  {{- include "resources" .resources | indent 4 }}
  volumeMounts:
  {{- range .mounts}}
  - name: {{ .name }}
    readOnly: {{ .readonly }}
    mountPath: {{ .path }}
    subPath: {{ .subpath }}
  {{- end }}
  {{- if .probe }}
  {{- if .probe.liveness }}
  livenessProbe:
    {{- include "probe" .probe.liveness | indent 4}}
  {{- end }}
  {{- if .probe.readiness }}
  readinessProbe:
    {{- include "probe" .probe.readiness | indent 4}}
  {{- end }}
  {{- end }}
  {{- if .lifecycle }}
  lifecycle:
    {{- if .lifecycle.postStart }}
    postStart:
    {{- include "handler" .lifecycle.postStart | indent 6}}
    {{- end }}
    {{- if .lifecycle.preStop }}
    preStop:
    {{- include "handler" .lifecycle.preStop | indent 6}}
    {{- end }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}



{{- define "envfile" -}}
{{- range . }}
- prefix: {{ .prefix }}
  {{ if eq .type "Config" -}}
  configMapRef:
  {{- else }}
  secretRef:
  {{- end }}
    optional: {{ .optional }}
    name: {{ .name }}
{{- end -}}
{{- end -}}


{{- define "env" -}}
{{- range . }}
- name: {{ .name }}
  value: {{ .value }}
  {{- with .from }}
  valueFrom:
    {{- if eq .type  "Config" -}}
    configMapKeyRef:
    {{- else -}}
    secretKeyRef:
    {{- end -}}
      name: {{ .name }}
      key: {{ .key }}
      optional: {{ .optional }}
  {{- end -}}
{{- end -}}
{{- end -}}


{{- define "downwardenv" -}}
{{- $prefix := . | default "ENV" | upper }}
- name: {{ $prefix }}_POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: {{ $prefix }}_POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: {{ $prefix }}_POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: {{ $prefix }}_NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
{{- end -}}

{{- define "resources" -}}
{{- with .requests }}
requests:
  {{- if hasKey . "cpu" }}
  "cpu": {{ .cpu }}
  {{- end }}
  {{- if hasKey . "memory" }}
  "memory": {{ .memory }}
  {{- end }}
  {{- if hasKey . "storage" }}
  "storage": {{ .storage }}
  {{- end }}
  {{- if hasKey . "gpu" }}
  "alpha.kubernetes.io/nvidia-gpu": {{ .gpu }}
  {{- end }}
{{- end }}
{{- with .limits }}
limits:
  {{- if hasKey . "cpu" }}
  "cpu": {{ .cpu }}
  {{- end }}
  {{- if hasKey . "memory" }}
  "memory": {{ .memory }}
  {{- end }}
  {{- if hasKey . "storage" }}
  "storage": {{ .storage }}
  {{- end }}
  {{- if hasKey . "gpu" }}
  "alpha.kubernetes.io/nvidia-gpu": {{ .gpu }}
  {{- end }}
{{- end }}
{{- end -}}




{{- define "probe" }}
initialDelaySeconds: {{ .delay }}
timeoutSeconds: {{ .timeout }}
periodSeconds: {{ .period }}
{{- if .threshold }}
successThreshold: {{ .threshold.success }}
failureThreshold: {{ .threshold.failure }}
{{- end }}
{{- template "handler" .handler }}
{{- end -}}

{{- define "handler" -}}
{{- if eq .type "EXEC" }}
exec: 
  command:
  {{- range .method.command }}
  - {{ . }}
  {{- end }}
{{- end }}
{{- if eq .type "HTTP" }}
httpGet:
  scheme: {{ .method.scheme }}
  host: {{ .method.host }}
  port: {{ .method.port }}
  path: {{ .method.path }}
  httpHeaders:
  {{- range .method.headers }}
  - name: {{ .name }}
    value: {{ .value }}
  {{- end }}
{{- end }}
{{- if eq .type "TCP" }}
tcpSocket:
  port: {{ .method.port }}
{{- end }}
{{- end -}}

