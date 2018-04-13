{{/* pod helper templates */}}


{{- define "podspec" -}}
{{- $controller := index . 0 -}}
{{- $name := index . 1 -}}

{{- with $controller.pod }}
restartPolicy: {{ .restart | quote }}
dnsPolicy: {{ .dns | quote }}
hostname: {{ .hostname | quote }}
subdomain: {{ .subdomain | quote }}
terminationGracePeriodSeconds: {{ .termination }}
serviceAccountName: {{ .serviceAccountName | quote }}
{{- with .host }}
hostNetwork: {{ .network }}
hostPID: {{ .pid }}
hostIPC: {{ .ipc }}
{{- end }}
{{- end }}
{{- with $controller.schedule }}
{{- template "schedule" $controller.schedule }}
{{- end }}
{{- with $controller.volumes }}
volumes:
{{- template "volumes" (list $controller.volumes $name) }}
{{- end }}
{{- with $controller.initContainers }}
initContainers:
{{- template "containers" (list $controller.initContainers "i") }}
{{- end }}
{{- with $controller.containers }}
containers:
{{- template "containers" (list $controller.containers "c") }}
{{- end }}
{{- end -}}




{{/* containers generates all containers for a pod */}}
{{- define "containers" -}}
{{- $containers := index . 0 -}}
{{- $prefix := index . 1 -}}

{{- range $index, $container := $containers -}}
{{- with $container }}
- name: {{ .name | default (printf "%s%d" $prefix $index) | quote }}
  image: {{ .image | quote }}
  imagePullPolicy: {{ .imagePullPolicy | quote }}
  tty: {{ .tty }}
  command:
  {{- range .command }}
  - {{ . | quote }}
  {{- end }}
  args:
  {{- range .args }}
  - {{ . | quote }}
  {{- end }}
  workingDir: {{ .workingDir | quote }}
  {{- with .securityContext }}
  securityContext:
    privileged: {{ .privileged }}
    {{- with .capabilities }}
    capabilities:
      add: 
      {{- range .add }}
      - {{ . | quote }}
      {{- end }}
      drop: 
      {{- range .drop }}
      - {{ . | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
  ports:
  {{- range .ports }}
  - name: {{ (printf "%s-%.0f" .protocol .port) | lower | quote }}
    {{- if eq .protocol "UDP" }}
    protocol: "UDP"
    {{- else }}
    protocol: "TCP"
    {{- end }}
    containerPort: {{ .port }}
    hostPort: {{ .hostPort }}
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
  - name: {{ .name | quote }}
    readOnly: {{ .readonly }}
    mountPath: {{ .path | quote }}
    subPath: {{ .subpath | quote }}
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
- prefix: {{ .prefix | quote }}
  {{ if eq .type "Config" -}}
  configMapRef:
  {{- else }}
  secretRef:
  {{- end }}
    optional: {{ .optional }}
    name: {{ .name | quote }}
{{- end -}}
{{- end -}}


{{- define "env" -}}
{{- range . }}
- name: {{ .name | quote }}
  value: {{ .value | quote }}
  {{- with .from }}
  valueFrom:
    {{ if eq .type  "Config" -}}
    configMapKeyRef:
    {{- else }}
    secretKeyRef:
    {{- end }}
      name: {{ .name | quote }}
      key: {{ .key | quote }}
      optional: {{ .optional }}
  {{- end -}}
{{- end -}}
{{- end -}}


{{- define "downwardenv" -}}
{{- $prefix := . | default "" }}
- name: {{ printf "%sPOD_NAMESPACE" $prefix | quote }}
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: {{ printf "%sPOD_NAME" $prefix | quote }}
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: {{ printf "%sPOD_IP" $prefix | quote }}
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: {{ printf "%sNODE_NAME" $prefix | quote }}
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
  "nvidia.com/gpu": {{ .gpu }}
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
  "nvidia.com/gpu": {{ .gpu }}
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
  - {{ . | quote }}
  {{- end }}
{{- end }}
{{- if eq .type "HTTP" }}
httpGet:
  scheme: {{ .method.scheme | quote }}
  host: {{ .method.host | quote }}
  port: {{ .method.port }}
  path: {{ .method.path | quote }}
  httpHeaders:
  {{- range .method.headers }}
  - name: {{ .name | quote }}
    value: {{ .value | quote }}
  {{- end }}
{{- end }}
{{- if eq .type "TCP" }}
tcpSocket:
  port: {{ .method.port }}
{{- end }}
{{- end -}}

