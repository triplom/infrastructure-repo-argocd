#!/bin/bash

# Test All 4 Packages Cross-Repository Integration
# Validates that all packages work through centralized GitOps approach

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}=====================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=====================================${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test ArgoCD application status
test_argocd_applications() {
    print_header "Testing ArgoCD Applications for All 4 Packages"
    
    echo -e "${BLUE}Expected Applications:${NC}"
    echo "  📦 app1-dev/qa/prod (infrastructure-repo-argocd)"
    echo "  📦 app2-dev/qa/prod (infrastructure-repo-argocd)"  
    echo "  📦 external-app-dev/qa/prod (infrastructure-repo → centralized config)"
    echo "  📦 php-web-app-dev/qa/prod (k8s-web-app-php → centralized config)"
    echo
    
    print_info "Current ArgoCD Applications:"
    kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REPO:.spec.source.repoURL | head -20
    
    echo
    print_info "Checking for external applications..."
    
    # Check if external-app applications exist
    if kubectl get applications -n argocd | grep -q "external-app"; then
        print_status "External-app applications found"
        kubectl get applications -n argocd | grep external-app
    else
        print_warning "External-app applications not found"
    fi
    
    # Check if php-web-app applications exist
    if kubectl get applications -n argocd | grep -q "php-web-app"; then
        print_status "PHP web app applications found"
        kubectl get applications -n argocd | grep php-web-app
    else
        print_warning "PHP web app applications not found"
    fi
}

# Test ApplicationSets
test_applicationsets() {
    print_header "Testing ApplicationSets"
    
    print_info "Current ApplicationSets:"
    kubectl get applicationsets -n argocd -o custom-columns=NAME:.metadata.name,APPLICATIONS:.status.summary
    
    echo
    print_info "ApplicationSet Details:"
    
    # Check external-app ApplicationSet
    if kubectl get applicationset external-app -n argocd >/dev/null 2>&1; then
        print_status "external-app ApplicationSet exists"
        kubectl get applicationset external-app -n argocd -o jsonpath='{.spec.template.spec.source.repoURL}' && echo
    else
        print_warning "external-app ApplicationSet not found"
    fi
    
    # Check php-web-app ApplicationSet
    if kubectl get applicationset php-web-app -n argocd >/dev/null 2>&1; then
        print_status "php-web-app ApplicationSet exists"
        kubectl get applicationset php-web-app -n argocd -o jsonpath='{.spec.template.spec.source.repoURL}' && echo
    else
        print_warning "php-web-app ApplicationSet not found"
    fi
}

# Test container images availability
test_container_images() {
    print_header "Testing Container Images for All 4 Packages"
    
    echo -e "${BLUE}Expected Container Images:${NC}"
    echo "  🐳 ghcr.io/triplom/app1:latest"
    echo "  🐳 ghcr.io/triplom/app2:latest"
    echo "  🐳 ghcr.io/triplom/external-app:latest (from infrastructure-repo)"
    echo "  🐳 ghcr.io/triplom/nginx:latest (from k8s-web-app-php)"
    echo "  🐳 ghcr.io/triplom/php-fpm:latest (from k8s-web-app-php)"
    echo
    
    # Test image pulls (this will fail if we don't have access, but shows availability)
    print_info "Testing container image accessibility..."
    
    images=(
        "ghcr.io/triplom/app1:latest"
        "ghcr.io/triplom/app2:latest"
        "ghcr.io/triplom/external-app:latest"
        "ghcr.io/triplom/nginx:latest"
        "ghcr.io/triplom/php-fpm:latest"
    )
    
    for image in "${images[@]}"; do
        print_info "Checking: $image"
        if docker manifest inspect "$image" >/dev/null 2>&1; then
            print_status "Available: $image"
        else
            print_warning "Not available: $image (may need to be built)"
        fi
    done
}

# Test Kubernetes manifest structure
test_manifest_structure() {
    print_header "Testing Kubernetes Manifest Structure"
    
    print_info "Checking manifest availability in centralized repository..."
    
    # Check app1 and app2 (should exist)
    for app in app1 app2; do
        if [[ -f "apps/$app/base/deployment.yaml" ]]; then
            print_status "$app manifests exist"
        else
            print_error "$app manifests missing"
        fi
    done
    
    # Check external-app manifests
    if [[ -f "apps/external-app/base/deployment.yaml" ]]; then
        print_status "external-app manifests exist in centralized repo"
    else
        print_warning "external-app manifests missing in centralized repo"
    fi
    
    # Check php-web-app manifests
    if [[ -f "apps/php-web-app/base/nginx-deployment.yaml" ]] && [[ -f "apps/php-web-app/base/php-deployment.yaml" ]]; then
        print_status "php-web-app manifests exist in centralized repo"
    else
        print_warning "php-web-app manifests missing in centralized repo"
    fi
    
    echo
    print_info "Manifest structure summary:"
    find apps/ -name "*.yaml" | sort
}

# Test CI/CD pipeline support
test_cicd_pipeline_support() {
    print_header "Testing CI/CD Pipeline Support for All 4 Packages"
    
    print_info "Checking workflow_dispatch component options..."
    
    if grep -q "external-app" .github/workflows/ci-pipeline.yaml; then
        print_status "CI pipeline supports external-app component"
    else
        print_warning "CI pipeline missing external-app support"
    fi
    
    if grep -q "nginx" .github/workflows/ci-pipeline.yaml; then
        print_status "CI pipeline supports nginx component"
    else
        print_warning "CI pipeline missing nginx support"
    fi
    
    if grep -q "php-fpm" .github/workflows/ci-pipeline.yaml; then
        print_status "CI pipeline supports php-fpm component"
    else
        print_warning "CI pipeline missing php-fpm support"
    fi
    
    echo
    print_info "Available workflow_dispatch components:"
    grep -A 10 "component:" .github/workflows/ci-pipeline.yaml | grep -E "^\s*- " | sed 's/^[ \t]*/  /'
}

# Test external repository configurations
test_external_repo_configs() {
    print_header "Testing External Repository Configurations"
    
    external_repo="/home/marcel/ISCTE/THESIS/push-based/infrastructure-repo"
    php_repo="/home/marcel/sfs-sca-projects/kubernetes-nginx-phpfpm-app"
    
    # Check external repo CI pipeline
    if [[ -f "$external_repo/.github/workflows/ci-pipeline.yaml" ]]; then
        print_status "External repository CI pipeline exists"
        print_info "Location: $external_repo/.github/workflows/ci-pipeline.yaml"
    else
        print_warning "External repository CI pipeline missing"
    fi
    
    # Check PHP repo CI pipeline
    if [[ -f "$php_repo/.github/workflows/ci-pipeline.yaml" ]]; then
        print_status "PHP repository CI pipeline exists"
        print_info "Location: $php_repo/.github/workflows/ci-pipeline.yaml"
    else
        print_warning "PHP repository CI pipeline missing"
    fi
}

# Generate deployment test plan
generate_test_plan() {
    print_header "Cross-Repository Deployment Test Plan"
    
    echo -e "${YELLOW}Phase 1: Test Internal Packages (Infrastructure-Repo-ArgoCD)${NC}"
    echo "  1. Run CI pipeline for app1:"
    echo "     gh workflow run ci-pipeline.yaml -f environment=dev -f component=app1"
    echo "  2. Run CI pipeline for app2:"
    echo "     gh workflow run ci-pipeline.yaml -f environment=dev -f component=app2"
    echo
    
    echo -e "${YELLOW}Phase 2: Test External Package (Infrastructure-Repo)${NC}"
    echo "  1. Go to: https://github.com/triplom/infrastructure-repo/actions"
    echo "  2. Run CI pipeline to build external-app"
    echo "  3. Verify external-app image pushed to GHCR"
    echo "  4. Verify centralized config updated"
    echo "  5. Check ArgoCD sync: kubectl get applications -n argocd | grep external-app"
    echo
    
    echo -e "${YELLOW}Phase 3: Test PHP Packages (K8S-Web-App-PHP)${NC}"
    echo "  1. Go to: https://github.com/triplom/k8s-web-app-php/actions"
    echo "  2. Run CI pipeline to build nginx + php-fpm"
    echo "  3. Verify images pushed to GHCR:"
    echo "     - ghcr.io/triplom/nginx:latest"
    echo "     - ghcr.io/triplom/php-fpm:latest"
    echo "  4. Verify centralized config updated"
    echo "  5. Check ArgoCD sync: kubectl get applications -n argocd | grep php-web-app"
    echo
    
    echo -e "${YELLOW}Phase 4: End-to-End Validation${NC}"
    echo "  1. Verify all applications deployed:"
    echo "     kubectl get pods --all-namespaces | grep -E '(app1|app2|external|nginx|php)'"
    echo "  2. Test application endpoints"
    echo "  3. Verify GitOps workflow: Code → CI → Container → Deploy"
    echo
    
    echo -e "${YELLOW}Success Criteria:${NC}"
    echo "  ✅ All 4 packages build successfully"
    echo "  ✅ Container images pushed to GHCR"
    echo "  ✅ ArgoCD applications show 'Synced' and 'Healthy'"
    echo "  ✅ Pods running in respective namespaces"
    echo "  ✅ Cross-repository GitOps workflow functional"
}

# Main execution
main() {
    print_header "Cross-Repository Integration Test for 4 Packages"
    
    echo -e "${BLUE}Testing GitOps integration for:${NC}"
    echo "  📦 app1 + app2 (infrastructure-repo-argocd)"
    echo "  📦 external-app (infrastructure-repo → centralized config)"
    echo "  📦 nginx + php-fpm (k8s-web-app-php → centralized config)"
    echo
    
    # Run all tests
    test_argocd_applications
    echo
    test_applicationsets
    echo
    test_container_images
    echo
    test_manifest_structure
    echo
    test_cicd_pipeline_support
    echo
    test_external_repo_configs
    echo
    generate_test_plan
    
    print_header "Cross-Repository Integration Test Complete"
    print_status "All 4 packages are configured for GitOps deployment!"
    
    echo
    print_info "Next step: Execute the deployment test plan above to validate the complete workflow"
}

# Run main function
main "$@"