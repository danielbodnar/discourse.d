# Helm and Kubernetes Documentation

## Overview
Complete Helm chart and Kubernetes manifests for deploying Discourse in production environments, with support for scaling, monitoring, and high availability.

## Table of Contents
1. [Helm Chart Structure](#helm-chart-structure)
2. [Kubernetes Resources](#kubernetes-resources)
3. [Deployment Configurations](#deployment-configurations)
4. [Monitoring & Logging](#monitoring-logging)
5. [Scaling & HA](#scaling-ha)

## Helm Chart Structure

```plaintext
discourse/
├── Chart.yaml
├── values.yaml
├── values.schema.json
├── templates/
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── secrets.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   ├── pvc.yaml
│   └── hpa.yaml
└── charts/
    ├── postgresql/
    └── redis/
```

### Chart Configuration

```yaml
# Chart.yaml
apiVersion: v2
name: discourse
description: A Helm chart for Discourse
type: application
version: 1.0.0
appVersion: "3.2.1"

dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

### Values Configuration

```yaml
# values.yaml
global:
  imageRegistry: ""
  storageClass: ""
  postgresql:
    auth:
      username: discourse
      password: discourse
      database: discourse
  redis:
    auth:
      password: discourse

image:
  repository: discourse/base
  tag: 3.2.1
  pullPolicy: IfNotPresent

replicaCount: 2

resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 2000m
    memory: 4Gi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

persistence:
  uploads:
    enabled: true
    size: 50Gi
  backups:
    enabled: true
    size: 20Gi

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: discourse.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: discourse-tls
      hosts:
        - discourse.example.com

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

## Kubernetes Resources

### Deployment Configuration

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "discourse.fullname" . }}
  labels:
    {{- include "discourse.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "discourse.selectorLabels" . | nindent 6 }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 3000
          livenessProbe:
            httpGet:
              path: /-/healthy
              port: http
          readinessProbe:
            httpGet:
              path: /-/ready
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - name: uploads
              mountPath: /opt/discourse/public/uploads
            - name: backups
              mountPath: /opt/discourse/public/backups
      volumes:
        - name: uploads
          persistentVolumeClaim:
            claimName: {{ include "discourse.fullname" . }}-uploads
```

### Service Configuration

```yaml
# templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "discourse.fullname" . }}
  labels:
    {{- include "discourse.labels" . | nindent 4 }}
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "discourse.selectorLabels" . | nindent 4 }}
```

### Ingress Configuration

```yaml
# templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "discourse.fullname" . }}
  annotations:
    {{- with .Values.ingress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "discourse.fullname" $ }}
                port:
                  number: 80
          {{- end }}
    {{- end }}
```

## Deployment Configurations

### Production Deployment

```bash
# Install chart
helm upgrade --install discourse ./discourse \
  --namespace discourse \
  --create-namespace \
  --values ./values/production.yaml

# Scale deployment
kubectl scale deployment discourse --replicas=4 -n discourse

# Rolling update
helm upgrade discourse ./discourse \
  --namespace discourse \
  --values ./values/production.yaml \
  --set image.tag=3.2.2
```

### Development Deployment

```bash
# Install with development values
helm upgrade --install discourse ./discourse \
  --namespace discourse-dev \
  --create-namespace \
  --values ./values/development.yaml \
  --set global.environment=development
```

## Monitoring & Logging

### Prometheus ServiceMonitor

```yaml
# templates/servicemonitor.yaml
{{- if .Values.monitoring.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "discourse.fullname" . }}
spec:
  selector:
    matchLabels:
      {{- include "discourse.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: http
      interval: {{ .Values.monitoring.serviceMonitor.interval }}
      path: /metrics
{{- end }}
```

### Grafana Dashboard

```yaml
# templates/configmap-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "discourse.fullname" . }}-dashboard
  labels:
    grafana_dashboard: "true"
data:
  discourse-dashboard.json: |-
    {
      "dashboard": {
        "id": null,
        "title": "Discourse Dashboard",
        "panels": [
          // Dashboard panels configuration
        ]
      }
    }
```

## Scaling & HA

### Horizontal Pod Autoscaling

```yaml
# templates/hpa.yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "discourse.fullname" . }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "discourse.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end }}
```

### Pod Disruption Budget

```yaml
# templates/pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "discourse.fullname" . }}
spec:
  minAvailable: 1
  selector:
    matchLabels:
      {{- include "discourse.selectorLabels" . | nindent 6 }}
```

## Security

### Network Policies

```yaml
# templates/networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "discourse.fullname" . }}
spec:
  podSelector:
    matchLabels:
      {{- include "discourse.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
    - ports:
        - protocol: TCP
          port: 3000
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgresql
    - to:
        - podSelector:
            matchLabels:
              app: redis
```

### Pod Security Context

```yaml
# templates/deployment.yaml (partial)
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
```
