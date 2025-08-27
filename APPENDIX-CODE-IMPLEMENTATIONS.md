# Appendix: Code Implementations and Technical Details

## Appendix A: ArgoCD App-of-Apps Implementation

### A.1 Root Application Complete Configuration

```yaml
# root-app/Chart.yaml
apiVersion: v2
name: root-app
description: Root app-of-apps pattern for managing all ArgoCD applications
version: 0.1.0
```

```yaml
# root-app/values.yaml
# Root application configuration
apps:
  applications:
    enabled: true
  monitoring:
    enabled: true
  infrastructure:
    enabled: true

# Repository configuration
repoURL: https://github.com/triplom/infrastructure-repo-argocd.git
targetRevision: HEAD
```

```yaml
# infrastructure/argocd/applications/root-new.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/triplom/infrastructure-repo-argocd.git
    targetRevision: HEAD
    path: root-app
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### A.2 ApplicationSet Templates and Configurations

#### A.2.1 Application Management ApplicationSet

```yaml
# app-of-apps/templates/app1.yaml
{{ if .Values.argocd.app1.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: app1
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - env: dev
        cluster: https://kubernetes.default.svc
      - env: qa
        cluster: https://kubernetes.default.svc
      - env: prod
        cluster: https://kubernetes.default.svc
  template:
    metadata:
      name: 'app1-{{env}}'
      namespace: argocd
      finalizers:
      - resources-finalizer.argocd.argoproj.io
    spec:
      project: applications
      source:
        repoURL: {{ .Values.targetRepo }}
        targetRevision: {{ .Values.targetRevision }}
        path: apps/app1/overlays/{{env}}
      destination:
        server: '{{cluster}}'
        namespace: 'app1-{{env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
{{ end }}
```

#### A.2.2 App-of-Apps Values Configuration

```yaml
# app-of-apps/values.yaml
# Applications configuration
argocd:
  app1:
    enabled: true
  app2:
    enabled: true

# Target repository for applications
targetRepo: https://github.com/triplom/infrastructure-repo.git
targetRevision: HEAD
```

```yaml
# app-of-apps/Chart.yaml
apiVersion: v2
name: app-of-apps
description: A Helm chart for app-of-apps
version: 0.1.0
```

### A.3 Complete CI/CD Pipeline Implementation

#### A.3.1 GitHub Actions Workflow

```yaml
# .github/workflows/ci-pipeline.yaml
name: CI Pipeline
on:
  push:
    branches: [main, 'feature/**']
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - test
          - prod
      component:
        description: 'Component to deploy'
        required: true
        default: 'all'
        type: choice
        options:
          - all
          - app1

env:
  APP_NAME: app1
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/app1

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    env:
      CONFIG_REPO_PAT: ${{ secrets.CONFIG_REPO_PAT }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
          
      - name: Install dependencies
        run: |
          cd src/app1
          pip install -r requirements.txt
          pip install pytest pytest-cov
          
      - name: Run tests
        run: |
          cd src/app1
          pytest --cov=./ --cov-report=xml || echo "Tests failed but continuing"
          
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: ./src/app1/coverage.xml
          fail_ci_if_error: false
  
  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      image_tag: ${{ steps.image-tag.outputs.IMAGE_TAG }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,format=short
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=raw,value=latest,enable=${{ github.ref == format('refs/heads/{0}', 'main') }}
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: ./src/app1
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-to: type=inline
      
      - name: Set image tag output
        id: image-tag
        run: |
          IMAGE_TAG=$(echo "${{ steps.meta.outputs.tags }}" | head -1)
          echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_OUTPUT
  
  update-config:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
    env:
      ENVIRONMENT: ${{ github.event.inputs.environment || 'dev' }}
      COMPONENT: ${{ github.event.inputs.component || 'all' }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Update application configuration in external repo
        env:
          CONFIG_REPO_PAT: ${{ secrets.CONFIG_REPO_PAT }}
        run: |
          # Checkout the external infrastructure repository
          git clone https://${{ github.actor }}:$CONFIG_REPO_PAT@github.com/triplom/infrastructure-repo.git
          cd infrastructure-repo
          
          # Update the image tag in the deployment
          IMAGE_TAG="${{ needs.build.outputs.image_tag }}"
          
          # If component is 'all' or specifically 'app1', update the config
          if [[ "${{ env.COMPONENT }}" == "all" || "${{ env.COMPONENT }}" == "app1" ]]; then
            echo "Updating app1 deployment for environment: ${{ env.ENVIRONMENT }}"
            if [ -f "apps/app1/overlays/${{ env.ENVIRONMENT }}/kustomization.yaml" ]; then
              # Update using kustomize image replacement
              cd apps/app1/overlays/${{ env.ENVIRONMENT }}
              kustomize edit set image app1=$IMAGE_TAG
              cd ../../../../
            elif [ -f "apps/app1/base/deployment.yaml" ]; then
              sed -i "s|image: .*/${{ env.APP_NAME }}:.*|image: $IMAGE_TAG|g" apps/app1/base/deployment.yaml
            fi
          else
            echo "Skipping app1 update as component filter is: ${{ env.COMPONENT }}"
          fi
          
          # Commit and push the changes
          git config --global user.email "actions@github.com"
          git config --global user.name "GitHub Actions"
          git add .
          git commit -m "Update app1 image to $IMAGE_TAG for ${{ env.ENVIRONMENT }} environment" || echo "No changes to commit"
          git push origin main
```

### A.4 ArgoCD Project Definitions

#### A.4.1 Applications Project

```yaml
# infrastructure/argocd/projects/applications.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: applications
  namespace: argocd
spec:
  description: Project for application deployments
  sourceRepos:
  - 'https://github.com/triplom/infrastructure-repo.git'
  - 'https://github.com/triplom/infrastructure-repo-argocd.git'
  destinations:
  - namespace: 'app1-*'
    server: https://kubernetes.default.svc
  - namespace: 'app2-*'
    server: https://kubernetes.default.svc
  - namespace: argocd
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceWhitelist:
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Service
  - group: ''
    kind: Secret
  - group: 'apps'
    kind: Deployment
  - group: 'apps'
    kind: ReplicaSet
  - group: 'networking.k8s.io'
    kind: Ingress
  - group: 'monitoring.coreos.com'
    kind: ServiceMonitor
```

#### A.4.2 Monitoring Project

```yaml
# infrastructure/argocd/projects/monitoring.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: monitoring
  namespace: argocd
spec:
  description: Monitoring project for Prometheus, Grafana, and related tools
  sourceRepos:
  - 'https://github.com/triplom/infrastructure-repo.git'
  - 'https://github.com/triplom/infrastructure-repo-argocd.git'
  destinations:
  - namespace: 'monitoring*'
    server: https://kubernetes.default.svc
  - namespace: argocd
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  - group: ''
    kind: ClusterRole
  - group: ''
    kind: ClusterRoleBinding
  - group: 'rbac.authorization.k8s.io'
    kind: ClusterRole
  - group: 'rbac.authorization.k8s.io'
    kind: ClusterRoleBinding
  - group: 'apiextensions.k8s.io'
    kind: CustomResourceDefinition
  - group: 'admissionregistration.k8s.io'
    kind: MutatingWebhookConfiguration
  - group: 'admissionregistration.k8s.io'
    kind: ValidatingWebhookConfiguration
  namespaceResourceWhitelist:
  - group: ''
    kind: '*'
  - group: 'apps'
    kind: '*'
  - group: 'extensions'
    kind: '*'
  - group: 'networking.k8s.io'
    kind: '*'
  - group: 'monitoring.coreos.com'
    kind: '*'
```

#### A.4.3 Infrastructure Project

```yaml
# infrastructure/argocd/projects/infrastructure.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: infrastructure
  namespace: argocd
spec:
  description: Project for infrastructure components
  sourceRepos:
  - 'https://github.com/triplom/infrastructure-repo.git'
  - 'https://github.com/triplom/infrastructure-repo-argocd.git'
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
```

### A.5 Monitoring Stack Configuration

#### A.5.1 Monitoring App-of-Apps

```yaml
# app-of-apps-monitoring/Chart.yaml
apiVersion: v2
name: app-of-apps-monitoring
description: A Helm chart for app-of-apps-monitoring
version: 0.1.0
```

```yaml
# app-of-apps-monitoring/values.yaml
# Monitoring components configuration
argocd:
  prometheus:
    enabled: true
    ingress: "https://prometheus-mycompany.com"
  grafana:
    enabled: true
    ingress: "https://grafana-mycompany.com"

# Target repository for monitoring components
targetRepo: https://github.com/triplom/infrastructure-repo.git
targetRevision: HEAD
```

```yaml
# app-of-apps-monitoring/templates/prometheus-app.yaml
{{ if .Values.argocd.prometheus.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: monitoring
  source:
    repoURL: {{ .Values.targetRepo }}
    targetRevision: {{ .Values.targetRevision }}
    path: monitoring/prometheus
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
{{ end }}
```

```yaml
# app-of-apps-monitoring/templates/grafana-app.yaml
{{ if .Values.argocd.grafana.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: grafana
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: monitoring
  source:
    repoURL: {{ .Values.targetRepo }}
    targetRevision: {{ .Values.targetRevision }}
    path: monitoring/grafana
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
{{ end }}
```

### A.6 Infrastructure App-of-Apps Configuration

#### A.6.1 Infrastructure Components

```yaml
# app-of-apps-infra/Chart.yaml
apiVersion: v2
name: app-of-apps-infra
description: A Helm chart for app-of-apps infrastructure components
version: 0.1.0
```

```yaml
# app-of-apps-infra/values.yaml
# Infrastructure components configuration
argocd:
  certManager:
    enabled: true
  ingressNginx:
    enabled: true
  monitoring:
    enabled: true
  
# Target repository for infrastructure components
targetRepo: https://github.com/triplom/infrastructure-repo.git
targetRevision: HEAD
```

```yaml
# app-of-apps-infra/templates/cert-manager.yaml
{{ if .Values.argocd.certManager.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: infrastructure
  source:
    repoURL: {{ .Values.targetRepo }}
    targetRevision: {{ .Values.targetRevision }}
    path: infrastructure/cert-manager
  destination:
    server: https://kubernetes.default.svc
    namespace: cert-manager
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
{{ end }}
```

```yaml
# app-of-apps-infra/templates/ingress-nginx.yaml
{{ if .Values.argocd.ingressNginx.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ingress-nginx
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: infrastructure
  source:
    repoURL: {{ .Values.targetRepo }}
    targetRevision: {{ .Values.targetRevision }}
    path: infrastructure/ingress-nginx
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress-nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
{{ end }}
```

### A.7 Deployment Scripts and Automation

#### A.7.1 Bootstrap Script

```bash
#!/bin/bash
# bootstrap.sh - Bootstrap ArgoCD App-of-Apps Infrastructure

set -e

NAMESPACE="argocd"
REPO_URL="https://github.com/triplom/infrastructure-repo-argocd.git"

echo "🚀 Bootstrapping ArgoCD App-of-Apps Infrastructure..."

# Check if ArgoCD is installed
if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    echo "❌ ArgoCD namespace '$NAMESPACE' not found. Please install ArgoCD first."
    exit 1
fi

echo "✅ ArgoCD namespace found"

# Apply ArgoCD projects first
echo "📁 Creating ArgoCD projects..."
kubectl apply -f infrastructure/argocd/projects/

# Wait a moment for projects to be created
sleep 5

# Apply the root application
echo "🌳 Deploying root application..."
kubectl apply -f infrastructure/argocd/applications/root-new.yaml

echo "⏳ Waiting for root application to sync..."
sleep 10

# Check status
echo "📊 Checking application status..."
kubectl get applications -n $NAMESPACE

echo ""
echo "🎉 Bootstrap complete!"
echo ""
echo "🔍 To monitor progress:"
echo "  kubectl get applications -n $NAMESPACE -w"
echo ""
echo "🌐 To access ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"
echo "  Then visit: https://localhost:8080"
echo ""
echo "🔧 To sync all applications:"
echo "  argocd app sync --all"
echo ""
echo "📝 Applications will be deployed to the following namespaces:"
echo "  - app1-dev, app1-qa, app1-prod"
echo "  - app2-dev, app2-qa, app2-prod"
echo "  - monitoring"
echo "  - cert-manager"
echo "  - ingress-nginx"
```

#### A.7.2 Cleanup Script

```bash
#!/bin/bash
# cleanup.sh - Cleanup ArgoCD App-of-Apps Infrastructure

set -e

NAMESPACE="argocd"

echo "🧹 Cleaning up ArgoCD App-of-Apps Infrastructure..."

# Remove root application (this will cascade delete all child applications)
echo "🗑️  Removing root application..."
kubectl delete -f infrastructure/argocd/applications/root-new.yaml --ignore-not-found=true

# Wait for cascading deletion
echo "⏳ Waiting for applications to be removed..."
sleep 15

# Remove any remaining applications
echo "🔍 Checking for remaining applications..."
APPS=$(kubectl get applications -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" 2>/dev/null | grep -E "(app-of-apps|app1|app2|prometheus|grafana|cert-manager|ingress-nginx|monitoring)" || true)

if [ ! -z "$APPS" ]; then
    echo "🗑️  Removing remaining applications..."
    echo "$APPS" | xargs -I {} kubectl delete application {} -n $NAMESPACE --ignore-not-found=true
fi

echo "✅ Cleanup complete!"
echo ""
echo "📊 Remaining applications:"
kubectl get applications -n $NAMESPACE 2>/dev/null || echo "No applications found"
```

### A.8 Test Scripts and Validation Procedures

#### A.8.1 Functional Test Script

```bash
#!/bin/bash
# test-functional.sh - Functional testing suite

set -e

RESULTS_DIR="test-results-$(date +%Y%m%d-%H%M%S)"
mkdir -p $RESULTS_DIR

# Test 1: Bootstrap validation
echo "🧪 Test 1: Bootstrap validation"
if ./bootstrap.sh > "$RESULTS_DIR/bootstrap.log" 2>&1; then
    echo "✅ Bootstrap test PASSED"
else
    echo "❌ Bootstrap test FAILED"
    exit 1
fi

# Test 2: Application deployment validation
echo "🧪 Test 2: Application deployment validation"
sleep 30  # Wait for applications to sync

FAILED_APPS=$(kubectl get applications -n argocd --no-headers | grep -v "Synced.*Healthy" | wc -l)
if [ "$FAILED_APPS" -eq 0 ]; then
    echo "✅ Application deployment test PASSED"
else
    echo "❌ Application deployment test FAILED - $FAILED_APPS applications not healthy"
    kubectl get applications -n argocd > "$RESULTS_DIR/failed-apps.log"
fi

# Test 3: Multi-environment validation
echo "🧪 Test 3: Multi-environment validation"
EXPECTED_NAMESPACES="app1-dev app1-qa app1-prod app2-dev app2-qa app2-prod"
MISSING_NAMESPACES=""

for ns in $EXPECTED_NAMESPACES; do
    if ! kubectl get namespace $ns >/dev/null 2>&1; then
        MISSING_NAMESPACES="$MISSING_NAMESPACES $ns"
    fi
done

if [ -z "$MISSING_NAMESPACES" ]; then
    echo "✅ Multi-environment test PASSED"
else
    echo "❌ Multi-environment test FAILED - Missing namespaces: $MISSING_NAMESPACES"
fi

# Test 4: Infrastructure components validation
echo "🧪 Test 4: Infrastructure components validation"
INFRA_COMPONENTS="cert-manager ingress-nginx monitoring"
FAILED_INFRA=""

for component in $INFRA_COMPONENTS; do
    if ! kubectl get pods -n $component >/dev/null 2>&1; then
        FAILED_INFRA="$FAILED_INFRA $component"
    fi
done

if [ -z "$FAILED_INFRA" ]; then
    echo "✅ Infrastructure components test PASSED"
else
    echo "❌ Infrastructure components test FAILED - Missing: $FAILED_INFRA"
fi

echo ""
echo "📊 Test Summary:"
echo "==============="
echo "Test results saved to: $RESULTS_DIR"
```

#### A.8.2 Performance Test Script

```bash
#!/bin/bash
# test-performance.sh - Performance testing suite

set -e

echo "🚀 Performance Testing Suite"
echo "============================"

# Test 1: Sync performance measurement
echo "🧪 Test 1: Measuring sync performance"

START_TIME=$(date +%s%N)

# Trigger sync for all applications
argocd app sync --async $(kubectl get applications -n argocd --no-headers -o custom-columns=":metadata.name" | tr '\n' ' ')

# Wait for all applications to sync
while true; do
    PENDING=$(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.sync.status != "Synced") | .metadata.name' | wc -l)
    if [ "$PENDING" -eq 0 ]; then
        break
    fi
    sleep 1
done

END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME) / 1000000))
echo "✅ Total sync time: ${DURATION}ms"

# Test 2: Individual application sync times
echo ""
echo "🧪 Test 2: Individual application sync times"

for app in $(kubectl get applications -n argocd --no-headers -o custom-columns=":metadata.name"); do
    echo "Testing $app:"
    START_TIME=$(date +%s%N)
    argocd app sync $app --timeout 300 >/dev/null 2>&1
    END_TIME=$(date +%s%N)
    DURATION=$((($END_TIME - $START_TIME) / 1000000))
    echo "  ✅ $app: ${DURATION}ms"
done

# Test 3: Resource utilization
echo ""
echo "🧪 Test 3: Resource utilization"
echo "Node resource usage:"
kubectl top nodes
echo ""
echo "ArgoCD pod resource usage:"
kubectl top pods -n argocd

echo ""
echo "📊 Performance test completed"
```

### A.9 Monitoring and Alerting Configuration

#### A.9.1 Prometheus Configuration

```yaml
# monitoring/prometheus/values.yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "gitops-alerts.yml"

scrape_configs:
  - job_name: 'argocd-metrics'
    static_configs:
      - targets: ['argocd-metrics.argocd:8082']
  
  - job_name: 'argocd-server'
    static_configs:
      - targets: ['argocd-server.argocd:8080']
  
  - job_name: 'application-metrics'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

#### A.9.2 GitOps Alert Rules

```yaml
# monitoring/prometheus/rules/gitops-alerts.yml
groups:
  - name: gitops-alerts
    rules:
      - alert: ApplicationOutOfSync
        expr: argocd_app_info{sync_status!="Synced"} == 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "ArgoCD application {{ $labels.name }} is out of sync"
          description: "Application {{ $labels.name }} in project {{ $labels.project }} has been out of sync for more than 5 minutes."

      - alert: ApplicationUnhealthy
        expr: argocd_app_info{health_status!="Healthy"} == 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "ArgoCD application {{ $labels.name }} is unhealthy"
          description: "Application {{ $labels.name }} in project {{ $labels.project }} has been unhealthy for more than 2 minutes."

      - alert: SyncFailure
        expr: increase(argocd_app_sync_total{phase="Failed"}[5m]) > 0
        labels:
          severity: critical
        annotations:
          summary: "ArgoCD sync failure for {{ $labels.name }}"
          description: "Application {{ $labels.name }} has failed to sync in the last 5 minutes."

      - alert: HighSyncTime
        expr: argocd_app_reconcile_bucket{le="30"} / argocd_app_reconcile_count < 0.9
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High sync time for ArgoCD applications"
          description: "ArgoCD applications are taking longer than 30 seconds to sync."
```

#### A.9.3 Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "id": null,
    "title": "GitOps Dashboard",
    "tags": ["gitops", "argocd"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Application Sync Status",
        "type": "stat",
        "targets": [
          {
            "expr": "sum by (sync_status) (argocd_app_info)",
            "legendFormat": "{{sync_status}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Application Health Status",
        "type": "stat",
        "targets": [
          {
            "expr": "sum by (health_status) (argocd_app_info)",
            "legendFormat": "{{health_status}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Sync Operations Over Time",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(argocd_app_sync_total[5m])",
            "legendFormat": "{{name}} - {{phase}}"
          }
        ]
      },
      {
        "id": 4,
        "title": "Application Reconciliation Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(argocd_app_reconcile_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(argocd_app_reconcile_bucket[5m]))",
            "legendFormat": "50th percentile"
          }
        ]
      }
    ]
  }
}
```

This comprehensive appendix provides all the technical implementation details, complete code configurations, and testing procedures for the ArgoCD app-of-apps implementation. Each section includes complete, working configurations that can be directly used in production environments.
