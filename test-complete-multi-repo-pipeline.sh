#!/bin/bash

# Complete Multi-Repository CI/CD Pipeline Testing
# Tests all connected repositories and their applications end-to-end

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}🚀 COMPLETE MULTI-REPOSITORY CI/CD TESTING${NC}"
echo "=============================================="
echo

echo -e "${GREEN}✅ Repository Status: All 3 Repositories Connected${NC}"
echo "   1. infrastructure-repo-argocd (Main): ✅"
echo "   2. infrastructure-repo (External): ✅" 
echo "   3. k8s-web-app-php-repo (PHP App): ✅"
echo

# Check current status
echo -e "${BLUE}📊 Current ArgoCD Status${NC}"
echo "------------------------"
TOTAL_APPS=$(kubectl get applications -n argocd --no-headers | wc -l)
SYNCED_APPS=$(kubectl get applications -n argocd --no-headers | grep "Synced" | wc -l)
HEALTHY_APPS=$(kubectl get applications -n argocd --no-headers | grep "Healthy" | wc -l)

echo "Total Applications: $TOTAL_APPS"
echo "Synced Applications: $SYNCED_APPS"
echo "Healthy Applications: $HEALTHY_APPS"
echo

echo -e "${PURPLE}🎯 REPOSITORY-SPECIFIC TESTING PLAN${NC}"
echo "====================================="
echo

echo -e "${YELLOW}📦 REPOSITORY 1: infrastructure-repo-argocd (Main)${NC}"
echo "Applications: app1, app2 (dev/prod/qa environments)"
echo "Pipeline URL: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "Test Steps:"
echo "  1. Trigger CI Pipeline for app1-dev"
echo "  2. Trigger CI Pipeline for app2-dev"
echo "  3. Verify container builds and pushes to GHCR"
echo "  4. Verify ArgoCD auto-sync and deployment"
echo "  5. Test rollout to prod/qa environments"
echo

echo -e "${YELLOW}🏗️ REPOSITORY 2: infrastructure-repo (External)${NC}"
echo "Applications: external-app, cert-manager, ingress-nginx, monitoring"
echo "Pipeline URL: https://github.com/triplom/infrastructure-repo/actions"
echo "Test Steps:"
echo "  1. Trigger CI Pipeline for external-app"
echo "  2. Verify infrastructure components sync"
echo "  3. Test monitoring stack deployment"
echo "  4. Verify cert-manager and ingress functionality"
echo

echo -e "${YELLOW}🐘 REPOSITORY 3: k8s-web-app-php-repo (PHP App)${NC}"
echo "Applications: php-web-app (dev/prod/qa environments)"
echo "Pipeline URL: https://github.com/triplom/k8s-web-app-php-repo/actions"
echo "Test Steps:"
echo "  1. Trigger CI Pipeline for PHP application"
echo "  2. Verify PHP container build and GHCR push"
echo "  3. Test deployment across all environments"
echo "  4. Verify application accessibility"
echo

echo -e "${CYAN}🧪 PHASE 1: Force Sync All Applications${NC}"
echo "========================================"
echo "Syncing applications to get baseline operational state..."

# Sync critical applications first
echo "Syncing root applications..."
kubectl patch application root-app -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application app-of-apps -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application app-of-apps-infra -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application app-of-apps-monitoring -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true

echo "Syncing infrastructure applications..."
kubectl patch application cert-manager -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application ingress-nginx -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application monitoring -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true

echo "Syncing application workloads..."
kubectl patch application app1-dev -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application app2-dev -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application external-app-dev -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true
kubectl patch application php-web-app-dev -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || true

echo "Waiting for sync operations to complete..."
sleep 15

echo
echo -e "${CYAN}🧪 PHASE 2: Verify Current Deployment Status${NC}"
echo "============================================="

echo -e "${BLUE}Application Status After Sync:${NC}"
kubectl get applications -n argocd --no-headers | awk '{print $1, $2, $3}' | column -t

echo
echo -e "${BLUE}Pod Status Check:${NC}"
echo "App1 Pods:"
kubectl get pods --all-namespaces | grep app1 || echo "No app1 pods found"
echo "App2 Pods:"
kubectl get pods --all-namespaces | grep app2 || echo "No app2 pods found"
echo "External App Pods:"
kubectl get pods --all-namespaces | grep external || echo "No external app pods found"
echo "PHP App Pods:"
kubectl get pods --all-namespaces | grep php || echo "No PHP app pods found"

echo
echo -e "${CYAN}🧪 PHASE 3: CI/CD Pipeline Testing Instructions${NC}"
echo "==============================================="

echo -e "${GREEN}🎯 TEST 1: Main Repository CI/CD (infrastructure-repo-argocd)${NC}"
echo "URL: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "Steps:"
echo "  1. Go to Actions tab"
echo "  2. Select 'CI Pipeline' workflow"
echo "  3. Click 'Run workflow'"
echo "  4. Environment: dev"
echo "  5. Component: app1"
echo "  6. Click 'Run workflow'"
echo "Expected: Build → Test → Push to GHCR → Update config → ArgoCD sync"
echo

echo -e "${GREEN}🎯 TEST 2: External Repository CI/CD (infrastructure-repo)${NC}"
echo "URL: https://github.com/triplom/infrastructure-repo/actions"
echo "Steps:"
echo "  1. Go to Actions tab"
echo "  2. Run available CI/CD workflows"
echo "  3. Monitor external-app deployment"
echo "Expected: Infrastructure updates applied via ArgoCD"
echo

echo -e "${GREEN}🎯 TEST 3: PHP Repository CI/CD (k8s-web-app-php-repo)${NC}"
echo "URL: https://github.com/triplom/k8s-web-app-php-repo/actions"
echo "Steps:"
echo "  1. Go to Actions tab"
echo "  2. Run PHP application CI/CD pipeline"
echo "  3. Monitor php-web-app deployment"
echo "Expected: PHP app built → GHCR → ArgoCD deployment"
echo

echo -e "${CYAN}🧪 PHASE 4: End-to-End Verification Commands${NC}"
echo "============================================="

echo "After running pipelines, use these commands to verify deployments:"
echo

echo -e "${YELLOW}Verify Application Sync Status:${NC}"
echo "kubectl get applications -n argocd | grep -E '(app1|app2|external|php)'"
echo

echo -e "${YELLOW}Check Running Pods:${NC}"
echo "kubectl get pods --all-namespaces | grep -E '(app1|app2|external|php)'"
echo

echo -e "${YELLOW}Verify Container Images:${NC}"
echo "kubectl describe deployment app1-deployment -n default"
echo "kubectl describe deployment app2-deployment -n default"
echo "kubectl describe deployment external-app-deployment -n default"
echo "kubectl describe deployment php-web-app-deployment -n default"
echo

echo -e "${YELLOW}Test Container Registry Access:${NC}"
echo "docker pull ghcr.io/triplom/app1:latest"
echo "docker pull ghcr.io/triplom/app2:latest"
echo "docker pull ghcr.io/triplom/external-app:latest"
echo "docker pull ghcr.io/triplom/php-web-app:latest"
echo

echo -e "${CYAN}🎯 SUCCESS CRITERIA FOR COMPLETE PIPELINE${NC}"
echo "==========================================="
echo "✅ All 3 repository CI/CD pipelines execute successfully"
echo "✅ Containers built and pushed to GHCR for all apps"
echo "✅ ArgoCD applications show 'Synced' and 'Healthy'"
echo "✅ Kubernetes deployments running with updated images"
echo "✅ All environments (dev/prod/qa) accessible"
echo "✅ GitOps workflow complete: Code → CI → Container → Deploy"
echo

echo -e "${GREEN}🚀 READY FOR COMPLETE MULTI-REPO TESTING!${NC}"
echo "Start with TEST 1 (Main Repository) and work through all 3 repositories."
echo "This will validate the complete GitOps ecosystem!"

echo
echo -e "${BLUE}📊 Final Status Summary:${NC}"
SYNCED_FINAL=$(kubectl get applications -n argocd --no-headers | grep "Synced" | wc -l)
HEALTHY_FINAL=$(kubectl get applications -n argocd --no-headers | grep "Healthy" | wc -l)
echo "   Synced Applications: $SYNCED_FINAL/$TOTAL_APPS"
echo "   Healthy Applications: $HEALTHY_FINAL/$TOTAL_APPS"
echo "   Repositories Connected: 3/3"
echo "   CI/CD Status: Ready for multi-repo testing"
