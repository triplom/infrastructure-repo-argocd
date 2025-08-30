#!/bin/bash

# ArgoCD Repository Connection Validation Script
# This script validates the repository connection fixes and overall ArgoCD health

set -e

echo "🔍 ArgoCD Repository Connection Validation Started"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() {
    echo -e "\n${BLUE}📋 $1${NC}"
    echo "----------------------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not available"
    exit 1
fi

# Validate ArgoCD namespace
print_section "ArgoCD Namespace Validation"
if kubectl get namespace argocd &> /dev/null; then
    print_success "ArgoCD namespace exists"
else
    print_error "ArgoCD namespace not found"
    exit 1
fi

# Validate ArgoCD pods health
print_section "ArgoCD Pods Health Check"
pods_status=$(kubectl get pods -n argocd --no-headers)
total_pods=$(echo "$pods_status" | wc -l)
running_pods=$(echo "$pods_status" | grep -c "Running" || true)

echo "Total ArgoCD pods: $total_pods"
echo "Running pods: $running_pods"

if [ "$total_pods" -eq "$running_pods" ]; then
    print_success "All ArgoCD pods are running ($running_pods/$total_pods)"
else
    print_warning "Some ArgoCD pods are not running ($running_pods/$total_pods)"
fi

# Validate repository secrets
print_section "Repository Secrets Validation"
expected_secrets=("infrastructure-repo-argocd" "infrastructure-repo-external" "k8s-web-app-php-repo")
secrets_found=0

for secret in "${expected_secrets[@]}"; do
    if kubectl get secret "$secret" -n argocd &> /dev/null; then
        print_success "Secret '$secret' exists"
        secrets_found=$((secrets_found + 1))
        
        # Check if secret has proper labels
        if kubectl get secret "$secret" -n argocd -o jsonpath='{.metadata.labels.argocd\.argoproj\.io/secret-type}' | grep -q "repository"; then
            print_success "Secret '$secret' has proper ArgoCD repository label"
        else
            print_warning "Secret '$secret' missing ArgoCD repository label"
        fi
    else
        print_error "Secret '$secret' not found"
    fi
done

if [ "$secrets_found" -eq "${#expected_secrets[@]}" ]; then
    print_success "All repository secrets are present (${secrets_found}/${#expected_secrets[@]})"
else
    print_warning "Some repository secrets are missing (${secrets_found}/${#expected_secrets[@]})"
fi

# Validate applications status
print_section "Applications Status Summary"
apps_output=$(kubectl get applications -n argocd --no-headers 2>/dev/null || echo "")

if [ -z "$apps_output" ]; then
    print_warning "No applications found or unable to retrieve applications"
else
    total_apps=$(echo "$apps_output" | wc -l)
    synced_apps=$(echo "$apps_output" | grep -c "Synced" || true)
    healthy_apps=$(echo "$apps_output" | grep -c "Healthy" || true)
    
    echo "Total applications: $total_apps"
    echo "Synced applications: $synced_apps"
    echo "Healthy applications: $healthy_apps"
    
    if [ "$synced_apps" -gt 0 ]; then
        print_success "$synced_apps applications are synced"
    fi
    
    if [ "$healthy_apps" -gt 0 ]; then
        print_success "$healthy_apps applications are healthy"
    fi
    
    # Check for test applications that should be removed
    test_apps=$(echo "$apps_output" | grep -E "(test|fixed|sample)" || true)
    if [ -n "$test_apps" ]; then
        print_warning "Found potential test applications that may need cleanup:"
        echo "$test_apps"
    else
        print_success "No test applications found"
    fi
fi

# Check ArgoCD server accessibility
print_section "ArgoCD Server Accessibility"
if kubectl get service argocd-server -n argocd &> /dev/null; then
    server_type=$(kubectl get service argocd-server -n argocd -o jsonpath='{.spec.type}')
    print_success "ArgoCD server service exists (Type: $server_type)"
    
    if [ "$server_type" = "NodePort" ]; then
        nodeport=$(kubectl get service argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')
        print_success "ArgoCD UI accessible on NodePort: $nodeport"
    fi
else
    print_error "ArgoCD server service not found"
fi

# Repository connectivity test via ArgoCD API
print_section "Repository Connectivity Test"
# Note: This would require ArgoCD CLI or API access which might not be available in all environments
print_warning "Manual verification required: Check ArgoCD UI -> Settings -> Repositories for connection status"

# Final summary
print_section "Validation Summary"
echo "Repository fix validation completed."
echo ""
echo "Next steps for manual verification:"
echo "1. Access ArgoCD UI"
echo "2. Navigate to Settings -> Repositories"
echo "3. Verify all repositories show 'Successful' connection status"
echo "4. Check Applications page for sync status improvements"
echo ""
echo "If repositories still show 'Failed' status:"
echo "1. Check GitHub token validity"
echo "2. Verify repository URLs are accessible"
echo "3. Review ArgoCD logs: kubectl logs -n argocd deployment/argocd-repo-server"

print_success "Repository validation script completed successfully"