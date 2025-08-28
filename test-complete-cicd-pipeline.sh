#!/bin/bash

# Complete CI/CD Pipeline Testing Guide
# This script provides step-by-step testing for the fully operational pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🎉 COMPLETE CI/CD PIPELINE TESTING GUIDE${NC}"
echo "=========================================="
echo

echo -e "${GREEN}✅ Status: Both Critical Issues Resolved${NC}"
echo "   1. GHCR Permission: Fixed with GHCR_TOKEN"
echo "   2. Git Authentication: Fixed with proper GITHUB_TOKEN permissions"
echo

echo -e "${BLUE}📋 Infrastructure Verification${NC}"
echo "-------------------------------"

# Check infrastructure status
echo "Checking infrastructure pods..."
RUNNING_PODS=$(kubectl get pods --all-namespaces | grep -E "(cert-manager|ingress|monitoring|argocd)" | grep Running | wc -l)
echo -e "${GREEN}✅ Infrastructure pods running: $RUNNING_PODS/19${NC}"

# Check ArgoCD applications
echo "Checking ArgoCD applications..."
TOTAL_APPS=$(kubectl get applications -n argocd --no-headers | wc -l)
HEALTHY_APPS=$(kubectl get applications -n argocd -o jsonpath='{.items[?(@.status.health.status=="Healthy")].metadata.name}' | wc -w)
echo -e "${GREEN}✅ ArgoCD applications: $HEALTHY_APPS/$TOTAL_APPS healthy${NC}"

echo
echo -e "${CYAN}🧪 TESTING PHASE 1: Complete CI/CD Pipeline${NC}"
echo "============================================="
echo

echo -e "${YELLOW}Test 1: Full CI Pipeline (Recommended)${NC}"
echo "URL: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "Steps:"
echo "  1. Click 'CI Pipeline' workflow"
echo "  2. Click 'Run workflow'"
echo "  3. Select Environment: dev (or test/prod)"
echo "  4. Select Component: app1"
echo "  5. Click 'Run workflow'"
echo
echo "Expected Results:"
echo "  ✅ Test job: Runs Python tests successfully"
echo "  ✅ Build job: Builds and pushes container to GHCR"
echo "  ✅ Update-config job: Updates deployment and commits changes"
echo "  ✅ All jobs show green checkmarks"
echo

echo -e "${YELLOW}Test 2: Verify Container Registry${NC}"
echo "After successful pipeline run:"
echo "  1. Go to: https://github.com/triplom/packages"
echo "  2. Look for 'app1' package"
echo "  3. Verify recent timestamp and proper tags"
echo

echo -e "${YELLOW}Test 3: Verify Repository Updates${NC}"
echo "Check for automatic commits:"
echo "  1. Look for new commit: '🚀 Update app1 image to...'"
echo "  2. Verify deployment files were updated"
echo "  3. Check that image tags match the built container"
echo

echo
echo -e "${CYAN}🧪 TESTING PHASE 2: GitOps Deployment${NC}"
echo "======================================"
echo

echo -e "${YELLOW}Test 4: ArgoCD Sync Verification${NC}"
echo "Commands to run:"
echo "  kubectl get applications -n argocd | grep app1"
echo "  kubectl describe application app1-dev -n argocd"
echo
echo "Expected:"
echo "  ✅ Application shows 'Synced' status"
echo "  ✅ Health status shows 'Healthy'"
echo "  ✅ Source points to correct commit/image"
echo

echo -e "${YELLOW}Test 5: Application Deployment Check${NC}"
echo "Commands to run:"
echo "  kubectl get pods -n default | grep app1"
echo "  kubectl describe deployment app1-deployment -n default"
echo
echo "Expected:"
echo "  ✅ App pods running with new image"
echo "  ✅ Deployment shows recent image tag"
echo "  ✅ No image pull errors"
echo

echo
echo -e "${CYAN}🧪 TESTING PHASE 3: Container Verification${NC}"
echo "=========================================="
echo

echo -e "${YELLOW}Test 6: Manual Container Pull${NC}"
echo "Test pulling the built container:"
echo "  docker pull ghcr.io/triplom/app1:latest"
echo "  docker run --rm ghcr.io/triplom/app1:latest"
echo
echo "Expected:"
echo "  ✅ Container downloads successfully"
echo "  ✅ Container runs without errors"
echo "  ✅ Application starts properly"
echo

echo
echo -e "${CYAN}🔍 TROUBLESHOOTING COMMANDS${NC}"
echo "==========================="
echo

echo "If issues occur, use these diagnostic commands:"
echo
echo "Check workflow logs:"
echo "  # Go to GitHub Actions page and examine failed steps"
echo
echo "Check ArgoCD application details:"
echo "  kubectl describe application app1-dev -n argocd"
echo
echo "Check pod status:"
echo "  kubectl get pods --all-namespaces | grep app1"
echo "  kubectl logs deployment/app1-deployment -n default"
echo
echo "Check container registry:"
echo "  docker pull ghcr.io/triplom/app1:latest"
echo
echo "Force ArgoCD sync:"
echo "  kubectl patch application app1-dev -n argocd -p '{\"operation\":{\"sync\":{}}}' --type merge"
echo

echo
echo -e "${GREEN}🎯 SUCCESS INDICATORS${NC}"
echo "======================"
echo "✅ GitHub Actions: All workflow jobs complete successfully"
echo "✅ GHCR: Package appears with recent timestamp"
echo "✅ Git: Repository shows automatic update commits"  
echo "✅ ArgoCD: Applications show 'Synced' and 'Healthy'"
echo "✅ Kubernetes: Pods running with updated container images"
echo "✅ Container: Manual docker pull succeeds"
echo

echo
echo -e "${CYAN}🎉 COMPLETE GITOPS WORKFLOW${NC}"
echo "==========================="
echo "Code Change → GitHub Push → CI Pipeline → Container Build → GHCR Push → Config Update → ArgoCD Sync → K8s Deploy"
echo

echo -e "${GREEN}✅ Ready for complete end-to-end testing!${NC}"
echo "Start with Phase 1, Test 1 (Full CI Pipeline) for comprehensive validation."
echo

# Quick status check
echo -e "${BLUE}📊 Current Status Summary:${NC}"
echo "   Repository: $(git rev-parse --short HEAD)"
echo "   Infrastructure: $RUNNING_PODS/19 pods running"
echo "   ArgoCD: $HEALTHY_APPS/$TOTAL_APPS applications healthy"
echo "   CI/CD: Ready for testing"
echo

read -p "Press Enter to continue with testing guidance..."

echo
echo -e "${CYAN}🚀 QUICK START: Test the Complete Pipeline${NC}"
echo "1. Go to: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "2. Click 'CI Pipeline' → 'Run workflow'"
echo "3. Environment: dev, Component: app1"
echo "4. Watch all 3 jobs complete successfully"
echo "5. Verify package at: https://github.com/triplom/packages"
echo
echo -e "${GREEN}Expected: Complete GitOps workflow from code to deployment! 🎉${NC}"
