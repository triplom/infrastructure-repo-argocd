#!/bin/bash

# ArgoCD Repository Connection Fix Script
# This script fixes repository authentication and cleans up test applications

set -e

echo "🔧 ArgoCD Repository Connection Fix"
echo "==================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if GitHub token is set
check_github_token() {
    if [[ -z "${GITHUB_TOKEN}" ]]; then
        print_error "GITHUB_TOKEN environment variable is not set"
        print_status "Please set GITHUB_TOKEN with a valid GitHub Personal Access Token"
        print_status "export GITHUB_TOKEN=ghp_your_token_here"
        return 1
    fi
    print_success "GitHub token found"
    return 0
}

# Function to test repository access
test_repository_access() {
    local repo_url=$1
    local repo_name=$2
    
    print_status "Testing access to $repo_name ($repo_url)..."
    
    # Extract repo path from URL
    local repo_path=$(echo $repo_url | sed 's|https://github.com/||' | sed 's|\.git||')
    
    # Test API access
    if curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo_path}" > /dev/null; then
        print_success "$repo_name: API access working"
        return 0
    else
        print_error "$repo_name: API access failed"
        return 1
    fi
}

# Function to delete existing repository secrets
delete_existing_repo_secrets() {
    print_status "Removing existing repository secrets..."
    
    kubectl delete secret infrastructure-repo-argocd -n argocd --ignore-not-found=true
    kubectl delete secret infrastructure-repo-external -n argocd --ignore-not-found=true
    kubectl delete secret k8s-web-app-php-repo -n argocd --ignore-not-found=true
    
    print_success "Existing repository secrets removed"
}

# Function to create repository secret
create_repository_secret() {
    local secret_name=$1
    local repo_url=$2
    local repo_name=$3
    
    print_status "Creating repository secret: $secret_name"
    
    kubectl create secret generic $secret_name \
        --from-literal=type=git \
        --from-literal=url=$repo_url \
        --from-literal=password=${GITHUB_TOKEN} \
        --from-literal=username=triplom \
        --from-literal=name="$repo_name" \
        --from-literal=enableLfs=false \
        --from-literal=insecure=false \
        -n argocd
    
    # Add ArgoCD labels
    kubectl label secret $secret_name -n argocd argocd.argoproj.io/secret-type=repository
    kubectl annotate secret $secret_name -n argocd managed-by=argocd.argoproj.io
    
    print_success "Repository secret created: $secret_name"
}

# Function to setup all repository connections
setup_repository_connections() {
    print_status "Setting up repository connections..."
    
    # Repository configurations
    local repos=(
        "infrastructure-repo-argocd|https://github.com/triplom/infrastructure-repo-argocd.git|Infra-ArgoCD"
        "infrastructure-repo-external|https://github.com/triplom/infrastructure-repo.git|Infrastructure"
        "k8s-web-app-php-repo|https://github.com/triplom/k8s-web-app-php.git|K8S PHP App"
    )
    
    for repo_config in "${repos[@]}"; do
        IFS='|' read -r secret_name repo_url repo_name <<< "$repo_config"
        
        if test_repository_access "$repo_url" "$repo_name"; then
            create_repository_secret "$secret_name" "$repo_url" "$repo_name"
        else
            print_warning "Skipping $repo_name due to access issues"
        fi
    done
}

# Function to restart ArgoCD components
restart_argocd_components() {
    print_status "Restarting ArgoCD components to refresh repository connections..."
    
    kubectl rollout restart deployment/argocd-repo-server -n argocd
    kubectl rollout restart statefulset/argocd-application-controller -n argocd
    
    print_status "Waiting for components to be ready..."
    kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s
    kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=300s
    
    print_success "ArgoCD components restarted"
}

# Function to get list of all applications
get_all_applications() {
    kubectl get applications -n argocd --no-headers -o custom-columns="NAME:.metadata.name"
}

# Function to identify test applications to remove
identify_test_applications() {
    print_status "Identifying test applications to remove..."
    
    # Get all applications
    local all_apps=$(get_all_applications)
    
    # Define applications to KEEP (based on the three repositories)
    local keep_apps=(
        "root-app"
        "app-of-apps"
        "app-of-apps-infra"
        "app-of-apps-monitoring"
        "app1-dev"
        "app1-qa" 
        "app1-prod"
        "app2-dev"
        "app2-qa"
        "app2-prod"
        "external-app-dev"
        "external-app-qa"
        "external-app-prod"
        "php-web-app-dev"
        "php-web-app-qa"
        "php-web-app-prod"
        "ingress-nginx"
        "cert-manager"
        "monitoring"
        "monitoring-stack"
    )
    
    # Identify apps to remove
    local apps_to_remove=()
    
    while IFS= read -r app; do
        [[ -z "$app" ]] && continue
        
        local should_keep=false
        for keep_app in "${keep_apps[@]}"; do
            if [[ "$app" == "$keep_app" ]]; then
                should_keep=true
                break
            fi
        done
        
        if [[ "$should_keep" == "false" ]]; then
            apps_to_remove+=("$app")
        fi
    done <<< "$all_apps"
    
    # Display results
    echo ""
    print_status "Applications to KEEP (from repositories):"
    for app in "${keep_apps[@]}"; do
        if echo "$all_apps" | grep -q "^$app$"; then
            echo "  ✅ $app"
        fi
    done
    
    echo ""
    if [[ ${#apps_to_remove[@]} -gt 0 ]]; then
        print_warning "Test applications to REMOVE:"
        for app in "${apps_to_remove[@]}"; do
            echo "  🗑️  $app"
        done
    else
        print_success "No test applications found to remove"
    fi
    
    echo ""
    
    # Return the apps to remove
    printf '%s\n' "${apps_to_remove[@]}"
}

# Function to remove test applications
remove_test_applications() {
    local apps_to_remove=($(identify_test_applications))
    
    if [[ ${#apps_to_remove[@]} -eq 0 ]]; then
        print_success "No test applications to remove"
        return
    fi
    
    print_status "Removing test applications..."
    
    for app in "${apps_to_remove[@]}"; do
        print_status "Removing application: $app"
        kubectl delete application "$app" -n argocd --ignore-not-found=true
        sleep 1
    done
    
    print_success "Test applications removed"
}

# Function to validate repository connections
validate_repository_connections() {
    print_status "Validating repository connections..."
    
    # Wait a moment for ArgoCD to refresh
    sleep 15
    
    print_status "Current repository secrets:"
    kubectl get secrets -n argocd | grep -E "(repo|git)" || echo "No repository secrets found"
    
    echo ""
    print_status "Checking application sync status..."
    kubectl get applications -n argocd -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status" | head -15
}

# Function to force sync critical applications
force_sync_applications() {
    print_status "Force syncing critical applications..."
    
    local critical_apps=("root-app" "app-of-apps" "app-of-apps-infra" "app-of-apps-monitoring")
    
    for app in "${critical_apps[@]}"; do
        if kubectl get application "$app" -n argocd >/dev/null 2>&1; then
            print_status "Force syncing: $app"
            kubectl patch application "$app" -n argocd --type='merge' \
                -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' || true
            sleep 2
        fi
    done
}

# Function to provide final instructions
provide_final_instructions() {
    print_status "Repository Fix Complete!"
    echo ""
    print_status "📋 What was done:"
    echo "  1. ✅ Refreshed repository authentication"
    echo "  2. ✅ Recreated repository secrets with current token"  
    echo "  3. ✅ Restarted ArgoCD components"
    echo "  4. ✅ Removed test applications"
    echo "  5. ✅ Force synced critical applications"
    echo ""
    print_status "🔍 Next steps:"
    echo "  1. Check ArgoCD UI repositories page - should show 'Successful'"
    echo "  2. Monitor application sync status - should improve over next few minutes"
    echo "  3. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "  4. URL: https://localhost:8080 (admin/SZLptHkIse0Pnuq7)"
    echo ""
    print_status "🛠️ If repositories still show 'Failed':"
    echo "  1. Verify GITHUB_TOKEN has repo access permissions"
    echo "  2. Check network connectivity to github.com"
    echo "  3. Run: kubectl logs -n argocd deployment/argocd-repo-server"
    echo ""
}

# Main execution
main() {
    echo "Starting ArgoCD repository connection fix..."
    echo ""
    
    if ! check_github_token; then
        exit 1
    fi
    
    delete_existing_repo_secrets
    sleep 5
    setup_repository_connections
    sleep 5
    restart_argocd_components
    sleep 10
    remove_test_applications
    sleep 5
    force_sync_applications
    sleep 10
    validate_repository_connections
    provide_final_instructions
    
    print_success "✅ ArgoCD repository fix completed!"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
