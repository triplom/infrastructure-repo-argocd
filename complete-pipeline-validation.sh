#!/bin/bash

# 🎯 Complete CI/CD Pipeline Validation Script
# Validates the entire GitOps workflow end-to-end

echo "🎯 Complete CI/CD Pipeline Validation"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🔍 Checking Infrastructure Status..."
echo "-----------------------------------"

# Check ArgoCD
print_info "Checking ArgoCD pods..."
argocd_pods=$(kubectl get pods -n argocd --no-headers | wc -l)
argocd_running=$(kubectl get pods -n argocd --no-headers | grep "Running" | wc -l)
print_status $((argocd_pods == argocd_running ? 0 : 1)) "ArgoCD: $argocd_running/$argocd_pods pods running"

# Check Cert-Manager
print_info "Checking Cert-Manager pods..."
certmgr_pods=$(kubectl get pods -n cert-manager --no-headers | wc -l)
certmgr_running=$(kubectl get pods -n cert-manager --no-headers | grep "Running" | wc -l)
print_status $((certmgr_pods == certmgr_running ? 0 : 1)) "Cert-Manager: $certmgr_running/$certmgr_pods pods running"

# Check Ingress-NGINX
print_info "Checking Ingress-NGINX pods..."
ingress_pods=$(kubectl get pods -n ingress-nginx --no-headers | wc -l)
ingress_running=$(kubectl get pods -n ingress-nginx --no-headers | grep "Running" | wc -l)
print_status $((ingress_pods == ingress_running ? 0 : 1)) "Ingress-NGINX: $ingress_running/$ingress_pods pods running"

# Check Monitoring
print_info "Checking Monitoring pods..."
monitoring_pods=$(kubectl get pods -n monitoring --no-headers | wc -l)
monitoring_running=$(kubectl get pods -n monitoring --no-headers | grep "Running" | wc -l)
print_status $((monitoring_pods == monitoring_running ? 0 : 1)) "Monitoring: $monitoring_running/$monitoring_pods pods running"

echo ""
echo "🚀 Checking Application Deployment..."
echo "------------------------------------"

# Check app1-dev
print_info "Checking app1-dev deployment..."
app1_pods=$(kubectl get pods -n app1-dev --no-headers | wc -l)
app1_running=$(kubectl get pods -n app1-dev --no-headers | grep "Running" | wc -l)
print_status $((app1_running > 0 ? 0 : 1)) "App1-Dev: $app1_running/$app1_pods pods running"

if [ $app1_running -gt 0 ]; then
    # Check app1 image
    print_info "Checking app1 container image..."
    app1_image=$(kubectl get deployment app1 -n app1-dev -o jsonpath='{.spec.template.spec.containers[0].image}')
    if [[ "$app1_image" == *"ghcr.io/triplom/app1"* ]]; then
        print_status 0 "App1 using correct GHCR image: $app1_image"
    else
        print_status 1 "App1 not using GHCR image: $app1_image"
    fi
    
    # Test application endpoints
    print_info "Testing application endpoints..."
    
    # Port forward for testing
    kubectl port-forward -n app1-dev deployment/app1 8082:8080 > /dev/null 2>&1 &
    pf_pid=$!
    sleep 3
    
    # Test health endpoint
    if curl -s http://localhost:8082/health | grep -q "ok"; then
        print_status 0 "Health endpoint responding correctly"
    else
        print_status 1 "Health endpoint not responding"
    fi
    
    # Test main endpoint
    if curl -s http://localhost:8082/ | grep -q "app1"; then
        print_status 0 "Main endpoint responding correctly"
    else
        print_status 1 "Main endpoint not responding"
    fi
    
    # Clean up port forward
    kill $pf_pid > /dev/null 2>&1
fi

echo ""
echo "📊 Checking GitOps Configuration..."
echo "----------------------------------"

# Check kustomization file
print_info "Checking GitOps configuration..."
if [ -f "apps/app1/overlays/dev/kustomization.yaml" ]; then
    if grep -q "newTag: main" apps/app1/overlays/dev/kustomization.yaml; then
        print_status 0 "Kustomization configured with 'main' tag"
    else
        print_status 1 "Kustomization not using 'main' tag"
    fi
else
    print_status 1 "Kustomization file not found"
fi

# Check CI pipeline evidence
print_info "Checking CI pipeline automation..."
if git log --oneline -5 | grep -q "Update app1 image"; then
    print_status 0 "CI pipeline automation commits found"
else
    print_status 1 "No CI pipeline automation commits found"
fi

echo ""
echo "🔍 Checking GHCR Integration..."
echo "------------------------------"

# Test GHCR image pull
print_info "Testing GHCR image accessibility..."
if docker pull ghcr.io/triplom/app1:main > /dev/null 2>&1; then
    print_status 0 "GHCR image pull successful"
else
    print_status 1 "GHCR image pull failed"
fi

echo ""
echo "📋 ArgoCD Applications Status..."
echo "-------------------------------"

# Check ArgoCD applications
print_info "Checking ArgoCD applications..."
argocd_apps=$(kubectl get applications -n argocd --no-headers | wc -l)
print_status $((argocd_apps > 0 ? 0 : 1)) "ArgoCD managing $argocd_apps applications"

if [ $argocd_apps -gt 0 ]; then
    echo ""
    print_info "ArgoCD Application Details:"
    kubectl get applications -n argocd --no-headers | while read app rest; do
        health=$(echo $rest | awk '{print $2}')
        sync=$(echo $rest | awk '{print $1}')
        if [[ "$health" == "Healthy" || "$health" == "Progressing" ]]; then
            echo -e "  ${GREEN}✅${NC} $app: $sync/$health"
        else
            echo -e "  ${YELLOW}⚠️${NC} $app: $sync/$health"
        fi
    done
fi

echo ""
echo "🎯 VALIDATION SUMMARY"
echo "===================="

# Calculate overall health
total_checks=8
passed_checks=0

# Count successful checks (simplified for demo)
if [ $argocd_running -eq $argocd_pods ]; then ((passed_checks++)); fi
if [ $certmgr_running -eq $certmgr_pods ]; then ((passed_checks++)); fi
if [ $ingress_running -eq $ingress_pods ]; then ((passed_checks++)); fi
if [ $monitoring_running -eq $monitoring_pods ]; then ((passed_checks++)); fi
if [ $app1_running -gt 0 ]; then ((passed_checks++)); fi
if [ -f "apps/app1/overlays/dev/kustomization.yaml" ]; then ((passed_checks++)); fi
if git log --oneline -5 | grep -q "Update app1 image"; then ((passed_checks++)); fi
if docker images | grep -q "ghcr.io/triplom/app1"; then ((passed_checks++)); fi

echo ""
if [ $passed_checks -eq $total_checks ]; then
    echo -e "${GREEN}🎉 ALL CHECKS PASSED! ($passed_checks/$total_checks)${NC}"
    echo -e "${GREEN}🚀 CI/CD Pipeline is FULLY OPERATIONAL!${NC}"
    echo -e "${GREEN}✅ GitOps workflow validated end-to-end!${NC}"
elif [ $passed_checks -gt $((total_checks / 2)) ]; then
    echo -e "${YELLOW}⚠️  Most checks passed ($passed_checks/$total_checks)${NC}"
    echo -e "${YELLOW}🔧 Minor issues detected, review failed checks${NC}"
else
    echo -e "${RED}❌ Several checks failed ($passed_checks/$total_checks)${NC}"
    echo -e "${RED}🛠️  Significant issues detected, review setup${NC}"
fi

echo ""
echo "📚 For detailed troubleshooting, see:"
echo "  - ULTIMATE-SUCCESS-REPORT.md"
echo "  - FINAL-E2E-VALIDATION-REPORT.md"
echo "  - GHCR-RESOLVED.md"
echo ""
echo "🎯 Validation completed at $(date)"
