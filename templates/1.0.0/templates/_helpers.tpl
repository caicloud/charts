{{/* common helper templates */}}


{{/* fullname returns the name of a controller */}}
{{- define "fullname" -}}
  {{- $global := index . 0 -}}
  {{- $index := index . 1 -}}
  {{- $release := $global.Release.Name | trunc 40 | trimSuffix "-" | lower -}}
  {{- $chart := include "cid" $global -}}
  {{- printf "%s-c%s-%d" $release $chart $index -}}
{{- end -}}


{{/* cid gets unique chart id in a release */}}
{{/* All charts in a release should have different name */}}
{{/* It strongly depends on a ordered template engine */}}
{{- define "cid" -}}
  {{- if not (hasKey .Release "cids") -}}
    {{- $_ := set .Release "cids" dict -}}
    {{- $_ := set .Release "counter" -1 -}}
  {{- end -}}
  {{- if not (hasKey .Release.cids .Chart.Name) -}}
    {{- $counter := add1 .Release.counter -}}
    {{- $_ := set .Release "counter" $counter -}}
    {{- $_ := set .Release.cids .Chart.Name $counter -}}
  {{- end -}}
  {{- index .Release.cids .Chart.Name -}}
{{- end -}}

{{/* required checks target object */}}
{{- define "required" -}}
  {{- $target := index . 0 -}}
  {{- $prefix := index . 1 -}}
  {{- $field := index . 2 -}}
  {{- $type := index . 3 -}}

  {{- $fields := splitList "." $field -}}
  {{- $temp := list | dict "fields" -}}
  {{- range $fields -}}
    {{- $f := $temp.fields -}}
    {{- $f := append $f . -}}
    {{- $_ := set $temp "fields" $f -}}
  {{- end -}}
  {{- template "check" list $target $temp.fields $type $prefix -}}
{{- end -}}

{{- define "check" -}}
  {{- $target := index . 0 -}}
  {{- $fields := index . 1 -}}
  {{- $type := index . 2 -}}
  {{- $prefix := index . 3 -}}

  {{- $first := first $fields -}}
  {{- $rest := rest $fields -}}
  {{- $restLen := len $rest -}}

  {{- $existing := hasKey $target $first -}}
  {{- if not $existing -}}
    {{- printf "field %s.%s not found" $prefix $first | fail -}}
  {{- end -}}

  {{- $target := index $target $first -}}
  {{- if eq $restLen 0 -}}
    {{- if eq $type "dict" -}}
      {{- if not (typeIs "map[string]interface {}" $target) -}}
        {{- printf "field %s.%s is not dict" $prefix $first | fail -}}
      {{- end -}}
    {{- end -}}
    {{- if eq $type "list" -}}
      {{- if not (typeIs "[]interface {}" $target) -}}
        {{- printf "field %s.%s is not list" $prefix $first | fail -}}
      {{- end -}}
    {{- else -}}
      {{- if not (typeIs $type $target) -}}
        {{- printf "field %s.%s is not %s" $prefix $first $type | fail -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- $prefix := printf "%s.%s" $prefix $first -}}
    {{- template "check" list $target $rest $type $prefix -}}
  {{- end -}}
{{- end -}}
