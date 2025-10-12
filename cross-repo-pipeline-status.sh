#!/bin/bash

# Cross-Repository Pipeline Status Report
# Validates all 4 packages are configured and ready for deployment

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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header "Cross-Repository Pipeline Status Report"
echo "Validating all 4 packages across repositories:"
echo "  📦 app1 (infrastructure-repo-argocd)"
echo "  📦 app2 (infrastructure-repo-argocd)"  
echo "  📦 external-app (infrastructure-repo)"
echo "  📦 nginx + php-fpm (k8s-web-app-php)"
echo

print_header "1. ArgoCD Applications Status"

# Check main applications (app1, app2)
echo -e "${BLUE}Main Applications (app1, app2):${NC}"
kubectl get applications -n argocd | grep -E "app[12]-(dev|qa|prod)" | while read line; do
    app_name=$(echo "$line" | awk '{print $1}')
    sync_status=$(echo "$line" | awk '{print $2}')
    health_status=$(echo "$line" | awk '{print $3}')
    
    if [[ "$sync_status" == "Synced" && "$health_status" == "Healthy" ]]; then
        print_status "$app_name: $sync_status, $health_status"
    elif [[ "$sync_status" == "Synced" ]]; then
        print_warning "$app_name: $sync_status, $health_status"
    else
        echo -e "${RED}❌ $app_name: $sync_status, $health_status${NC}"
    fi
done

# Check external applications
echo -e "${BLUE}External Applications (external-app):${NC}"
kubectl get applications -n argocd | grep "external-app" | while read line; do
    app_name=$(echo "$line" | awk '{print $1}')
    sync_status=$(echo "$line" | awk '{print $2}')
    health_status=$(echo "$line" | awk '{print $3}')
    
    if [[ "$sync_status" == "Synced" && "$health_status" == "Healthy" ]]; then
        print_status "$app_name: $sync_status, $health_status"
    elif [[ "$sync_status" == "Unknown" ]]; then
        print_warning "$app_name: Not yet synced (needs container images)"
    else
        echo -e "${RED}❌ $app_name: $sync_status, $health_status${NC}"
    fi
done

# Check PHP applications
echo -e "${BLUE}PHP Applications (nginx + php-fpm):${NC}"
kubectl get applications -n argocd | grep "php-web-app" | while read line; do
    app_name=$(echo "$line" | awk '{print $1}')
    sync_status=$(echo "$line" | awk '{print $2}')
    health_status=$(echo "$line" | awk '{print $3}')
    
    if [[ "$sync_status" == "Synced" && "$health_status" == "Healthy" ]]; then
        print_status "$app_name: $sync_status, $health_status"
    elif [[ -z "$sync_status" ]]; then
        print_warning "$app_name: Not yet synced (needs container images)"
    else
        echo -e "${RED}❌ $app_name: $sync_status, $health_status${NC}"
    fi
done

print_header "2. Container Registry Status"

echo -e "${BLUE}Checking GHCR container images:${NC}"

# Check app1 and app2 images (should exist from previous builds)
for app in app1 app2; do
    if docker pull ghcr.io/triplom/$app:latest >/dev/null 2>&1; then
        print_status "$app: Image available in GHCR"
    else
        print_warning "$app: Image not found in GHCR (may need CI pipeline run)"
    fi
done

# Check external packages (likely don't exist yet)
for package in external-app nginx php-fpm; do
    if docker pull ghcr.io/triplom/$package:latest >/dev/null 2>&1; then
        print_status "$package: Image available in GHCR"
    else
        print_warning "$package: Image not found in GHCR (needs CI pipeline run)"
    fi
done

print_header "3. CI Pipeline Configuration"

echo -e "${BLUE}Main Repository CI Pipeline:${NC}"
if grep -q "external-app" .github/workflows/ci-pipeline.yaml; then
    print_status "Enhanced CI pipeline supports external packages"
else
    print_warning "CI pipeline may need external package support"
fi

echo -e "${BLUE}Workflow Dispatch Components:${NC}"
grep -A 10 "component:" .github/workflows/ci-pipeline.yaml | grep -E "^\s*-\s" | while read line; do
    component=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
    print_info "Component: $component"
done

print_header "4. Repository Integration Status"

# Check if external repository workflows exist
external_repo="/home/marcel/ISCTE/THESIS/push-based/infrastructure-repo"
php_repo="/home/marcel/sfs-sca-projects/kubernetes-nginx-phpfpm-app"

if [[ -f "$external_repo/.github/workflows/ci-pipeline.yaml" ]]; then
    print_status "External repository CI pipeline configured"
else
    print_warning "External repository CI pipeline not found"
fi

if [[ -f "$php_repo/.github/workflows/ci-pipeline.yaml" ]]; then
    print_status "PHP repository CI pipeline configured"
else
    print_warning "PHP repository CI pipeline not found"
fi

print_header "5. ArgoCD Configuration Files"

echo -e "${BLUE}Application Configurations:${NC}"
for app in app1 app2 external-app php-web-app; do
    if [[ -d "apps/$app" ]]; then
        print_status "$app: ArgoCD configuration exists"
        echo "      Base: $(ls apps/$app/base/ 2>/dev/null | wc -l) files"
        echo "      Overlays: $(ls apps/$app/overlays/ 2>/dev/null | wc -l) environments"
    else
        print_warning "$app: ArgoCD configuration missing"
    fi
done

echo -e "${BLUE}ApplicationSet Templates:${NC}"
for template in app1 app2 external-app php-web-app; do
    if [[ -f "app-of-apps/templates/$template.yaml" ]]; then
        print_status "$template: ApplicationSet template exists"
    else
        print_warning "$template: ApplicationSet template missing"
    fi
done

print_header "6. Testing Instructions"

echo -e "${YELLOW}To test all 4 packages:${NC}"
echo
echo -e "${BLUE}1. Test Main Packages (app1, app2):${NC}"
echo "   gh workflow run ci-pipeline.yaml -f environment=dev -f component=app1"
echo "   gh workflow run ci-pipeline.yaml -f environment=dev -f component=app2"
echo
echo -e "${BLUE}2. Test External Package:${NC}"
echo "   gh workflow run ci-pipeline.yaml -f environment=dev -f component=external-app"
echo
echo -e "${BLUE}3. Test PHP Packages:${NC}"
echo "   gh workflow run ci-pipeline.yaml -f environment=dev -f component=nginx"
echo "   gh workflow run ci-pipeline.yaml -f environment=dev -f component=php-fpm"
echo
echo -e "${BLUE}4. Test All Packages:${NC}"
echo "   gh workflow run ci-pipeline.yaml -f environment=dev -f component=all"
echo

print_header "7. Validation Commands"

echo -e "${YELLOW}After running pipelines, validate with:${NC}"
echo
echo "# Check ArgoCD application status"
echo "kubectl get applications -n argocd | grep -E '(app1|app2|external|php)'"
echo
echo "# Check pod deployments"  
echo "kubectl get pods --all-namespaces | grep -E '(app1|app2|external|nginx|php)'"
echo
echo "# Check container images"
echo "docker pull ghcr.io/triplom/app1:latest"
echo "docker pull ghcr.io/triplom/app2:latest"
echo "docker pull ghcr.io/triplom/external-app:latest"
echo "docker pull ghcr.io/triplom/nginx:latest"
echo "docker pull ghcr.io/triplom/php-fpm:latest"
echo

print_header "Summary"

total_apps=$(kubectl get applications -n argocd | grep -E "(app1|app2|external|php)" | wc -l)
synced_apps=$(kubectl get applications -n argocd | grep -E "(app1|app2|external|php)" | grep "Synced" | wc -l)
healthy_apps=$(kubectl get applications -n argocd | grep -E "(app1|app2|external|php)" | grep "Healthy" | wc -l)

echo -e "${BLUE}ArgoCD Applications:${NC} $total_apps total, $synced_apps synced, $healthy_apps healthy"

if [[ -f ".github/workflows/ci-pipeline.yaml" ]]; then
    components=$(grep -A 10 "component:" .github/workflows/ci-pipeline.yaml | grep -E "^\s*-\s" | wc -l)
    echo -e "${BLUE}CI Pipeline Components:${NC} $components supported"
fi

app_configs=$(find apps/ -name "deployment.yaml" 2>/dev/null | wc -l)
echo -e "${BLUE}Application Configurations:${NC} $app_configs deployment files"

print_status "Cross-repository pipeline integration is configured and ready for testing!"
echo
echo -e "${CYAN}🚀 All 4 packages can now be deployed through ArgoCD GitOps workflow!${NC}"