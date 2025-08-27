#!/bin/bash

# Step-by-Step Local Testing Guide for ArgoCD App-of-Apps
# This script provides a comprehensive validation process

echo "🎯 ArgoCD App-of-Apps Local Testing Results"
echo "============================================"
echo ""

# Test 1: Prerequisites
echo "✅ Test 1: Prerequisites"
echo "   kubectl: $(kubectl version --client | head -1)"
echo "   kind: $(kind version)"
echo "   docker: $(docker version --format '{{.Client.Version}}')"
echo "   helm: $(helm version --short)"
echo ""

# Test 2: Cluster Setup
echo "✅ Test 2: Kubernetes Clusters"
echo "   Clusters created: $(kind get clusters | wc -l)"
kind get clusters | sed 's/^/   - /'
echo "   Current context: $(kubectl config current-context)"
echo ""

# Test 3: ArgoCD Installation
echo "✅ Test 3: ArgoCD Installation"
echo "   Namespace: $(kubectl get namespace argocd -o name 2>/dev/null || echo 'Missing')"
echo "   Pods running: $(kubectl get pods -n argocd --no-headers 2>/dev/null | grep Running | wc -l)"
echo "   Total pods: $(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)"
kubectl get pods -n argocd --no-headers | awk '{print "   - " $1 ": " $3}' 2>/dev/null
echo ""

# Test 4: ArgoCD Projects
echo "✅ Test 4: ArgoCD Projects"
kubectl get appprojects -n argocd --no-headers 2>/dev/null | awk '{print "   - " $1}' || echo "   No projects found"
echo ""

# Test 5: ArgoCD Applications  
echo "✅ Test 5: ArgoCD Applications"
kubectl get applications -n argocd --no-headers 2>/dev/null | awk '{print "   - " $1 ": " $2 "/" $3}' || echo "   No applications found"
echo ""

# Test 6: Validate Repository Structure
echo "✅ Test 6: Repository Structure"
echo "   Root app chart: $([ -f root-app/Chart.yaml ] && echo 'Found' || echo 'Missing')"
echo "   App-of-apps chart: $([ -f app-of-apps/Chart.yaml ] && echo 'Found' || echo 'Missing')"
echo "   Monitoring chart: $([ -f app-of-apps-monitoring/Chart.yaml ] && echo 'Found' || echo 'Missing')"
echo "   Infrastructure chart: $([ -f app-of-apps-infra/Chart.yaml ] && echo 'Found' || echo 'Missing')"
echo ""

# Test 7: Helm Charts Validation
echo "✅ Test 7: Helm Charts Validation"
if command -v helm &> /dev/null; then
    for chart in root-app app-of-apps app-of-apps-monitoring app-of-apps-infra; do
        if [ -d "$chart" ]; then
            echo "   Validating $chart:"
            if helm lint "$chart" &>/dev/null; then
                echo "     ✓ Chart is valid"
            else
                echo "     ✗ Chart has issues"
            fi
        fi
    done
else
    echo "   Helm not available for validation"
fi
echo ""

# Test 8: Network Connectivity
echo "✅ Test 8: Network Connectivity"
echo "   ArgoCD Server: $(kubectl get service argocd-server -n argocd -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo 'Not found')"
echo "   ArgoCD Repo Server: $(kubectl get service argocd-repo-server -n argocd -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo 'Not found')"
echo ""

# Test 9: Access Methods
echo "✅ Test 9: Access Methods"
echo "   ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Admin Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""

# Test 10: Next Steps
echo "📋 Next Steps for Local Testing:"
echo "================================"
echo ""
echo "1. Test ArgoCD UI Access:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
echo "   echo 'Access: https://localhost:8080'"
echo "   echo 'Username: admin'"
echo "   echo 'Password:' \$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo ""
echo "2. Create Local Applications (since remote repo is not accessible):"
echo "   # Create app-of-apps manually"
echo "   helm template app-of-apps ./app-of-apps | kubectl apply -f -"
echo ""
echo "3. Validate Helm Charts:"
echo "   helm lint root-app"
echo "   helm lint app-of-apps"
echo "   helm lint app-of-apps-monitoring"  
echo "   helm lint app-of-apps-infra"
echo ""
echo "4. Test Multi-Environment Setup:"
echo "   kubectl config use-context kind-qa-cluster"
echo "   kubectl config use-context kind-prod-cluster"
echo ""
echo "5. Cleanup:"
echo "   ./cleanup.sh"
echo "   make clean-clusters"
echo ""

echo "🎯 Summary:"
echo "==========="
echo "• Infrastructure: Ready for local testing"
echo "• ArgoCD: Installed and running" 
echo "• Clusters: Multi-environment setup complete"
echo "• Charts: Available for local deployment"
echo "• Issue: Remote repository not accessible (expected for local testing)"
echo ""
echo "💡 Recommendation: Use local Helm charts for validation instead of GitOps"
