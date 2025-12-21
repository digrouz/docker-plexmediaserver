{{/* Helper templates to render extra volumes and extra volume mounts.
   Supports hostPath, pvc, nfs, configMap and secret volume sources.
*/}}
{{- define "helper.extraVolumeMounts" -}}
{{- if .Values.extraVolumeMounts }}
{{- range .Values.extraVolumeMounts }}
- name: {{ .name }}
  mountPath: {{ .mountPath | quote }}
  {{- if .subPath }}
  subPath: {{ .subPath | quote }}
  {{- end }}
  {{- if .readOnly }}
  readOnly: {{ .readOnly }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "helper.extraVolumes" -}}
{{- if .Values.extraVolumes }}
{{- range .Values.extraVolumes }}
- name: {{ .name }}
  {{- if .hostPath }}
  hostPath:
    path: {{ .hostPath.path | quote }}
    {{- if .hostPath.type }}
    type: {{ .hostPath.type | quote }}
    {{- end }}
  {{- end }}
  {{- if .pvc }}
  persistentVolumeClaim:
    claimName: {{ .pvc.claimName | quote }}
  {{- end }}
  {{- if .nfs }}
  nfs:
    server: {{ .nfs.server | quote }}
    path: {{ .nfs.path | quote }}
  {{- end }}
  {{- if .configMap }}
  configMap:
    name: {{ .configMap.name | quote }}
    optional: {{ .configMap.optional | default false }}
  {{- end }}
  {{- if .secret }}
  secret:
    secretName: {{ .secret.secretName | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
