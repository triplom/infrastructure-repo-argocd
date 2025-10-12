#!/bin/bash

# Chapter 6 Test Metrics Collection Script
# Pull-Based GitOps with ArgoCD Evaluation

echo "=================================================="
echo "    CHAPTER 6 - PULL-BASED GITOPS METRICS"
echo "    ArgoCD Infrastructure Performance Evaluation"
echo "=================================================="
echo "Timestamp: $(date)"
echo "Test Environment: KIND Cluster with ArgoCD"
echo ""

# GitOps Configuration Metrics
echo "=== GitOps Architecture Metrics ==="
echo "GitOps Pattern: Pull-Based with ArgoCD"
echo "App-of-Apps Pattern: $(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.metadata.name | contains("app-of-apps")) | .metadata.name' | wc -l) levels"
echo "Repository: git@github.com:triplom/infrastructure-repo-argocd.git"
echo "Sync Policy: Automated with self-heal enabled"
echo ""

# Application Deployment Metrics
echo "=== Application Deployment Metrics ==="
echo "Total Applications: $(kubectl get applications -n argocd --no-headers | wc -l)"
echo "Healthy Applications: $(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.health.status == "Healthy") | .metadata.name' | wc -l)"
echo "Synced Applications: $(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.sync.status == "Synced") | .metadata.name' | wc -l)"
echo "Progressing Applications: $(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.health.status == "Progressing") | .metadata.name' | wc -l)"
echo "Degraded Applications: $(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.health.status == "Degraded") | .metadata.name' | wc -l)"
echo ""

# Infrastructure Resource Metrics  
echo "=== Infrastructure Resource Metrics ==="
echo "Cluster Nodes: $(kubectl get nodes --no-headers | wc -l)"
echo "Total Namespaces: $(kubectl get namespaces --no-headers | wc -l)"
echo "Running Pods: $(kubectl get pods -A --no-headers | grep -c Running)"
echo "Active Services: $(kubectl get services -A --no-headers | wc -l)"
echo "Active Deployments: $(kubectl get deployments -A --no-headers | wc -l)"
echo ""

# ArgoCD Controller Performance
echo "=== ArgoCD Controller Performance ==="
echo "ArgoCD Pods Running: $(kubectl get pods -n argocd --no-headers | grep -c Running)"
ARGOCD_MEMORY=$(kubectl top pods -n argocd --no-headers 2>/dev/null | awk '{memory += $3} END {print memory "Mi"}' 2>/dev/null || echo "Metrics unavailable")
echo "ArgoCD Memory Usage: $ARGOCD_MEMORY"
echo "Sync Frequency: 3 minutes (default ArgoCD polling)"
echo ""

# Multi-Environment Deployment Status
echo "=== Multi-Environment Deployment Status ==="
echo "Development Environment:"
echo "  - app1-dev: $(kubectl get application app1-dev -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "  - app2-dev: $(kubectl get application app2-dev -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "QA Environment:"
echo "  - app1-qa: $(kubectl get application app1-qa -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "  - app2-qa: $(kubectl get application app2-qa -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "Production Environment:"
echo "  - app1-prod: $(kubectl get application app1-prod -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "  - app2-prod: $(kubectl get application app2-prod -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo ""

# Infrastructure Services Status
echo "=== Infrastructure Services Status ==="
echo "cert-manager: $(kubectl get application cert-manager -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "ingress-nginx: $(kubectl get application ingress-nginx -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "prometheus: $(kubectl get application prometheus-dev -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "grafana: $(kubectl get application grafana-dev -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo "alertmanager: $(kubectl get application alertmanager-dev -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo 'Not found')"
echo ""

# Deployment Time Metrics (for comparison with push-based)
echo "=== Deployment Performance Metrics ==="
echo "Last Sync Times (Pull-Based GitOps):"
kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.operationState.finishedAt != null) | "\(.metadata.name): \(.status.operationState.finishedAt)"' | head -5
echo ""

# GitOps Efficiency Summary
echo "=== GitOps Efficiency Summary ==="
TOTAL_APPS=$(kubectl get applications -n argocd --no-headers | wc -l)
HEALTHY_APPS=$(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.health.status == "Healthy") | .metadata.name' | wc -l)
SYNCED_APPS=$(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.sync.status == "Synced") | .metadata.name' | wc -l)

HEALTH_PERCENTAGE=$(echo "scale=2; $HEALTHY_APPS * 100 / $TOTAL_APPS" | bc -l 2>/dev/null || echo "N/A")
SYNC_PERCENTAGE=$(echo "scale=2; $SYNCED_APPS * 100 / $TOTAL_APPS" | bc -l 2>/dev/null || echo "N/A")

echo "Health Success Rate: $HEALTH_PERCENTAGE% ($HEALTHY_APPS/$TOTAL_APPS)"
echo "Sync Success Rate: $SYNC_PERCENTAGE% ($SYNCED_APPS/$TOTAL_APPS)"
echo "GitOps Pattern: App-of-Apps with hierarchical management"
echo "Deployment Method: Declarative configuration with continuous reconciliation"
echo ""

echo "=================================================="
echo "Metrics collection complete for Chapter 6 evaluation"
echo "Ready for pull-based vs push-based GitOps comparison"
echo "=================================================="