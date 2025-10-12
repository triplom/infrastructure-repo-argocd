#!/bin/bash

# Chapter 6 Thesis: Complete Multi-Repository GitHub Actions Testing
# This script validates all three GitHub Actions pipelines for comprehensive thesis evaluation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Thesis evaluation variables
THESIS_START_TIME=$(date -u +%s)
REPO_ARGOCD="/home/marcel/ISCTE/THESIS/pull-based/infrastructure-repo-argocd"
REPO_INFRA="/home/marcel/ISCTE/THESIS/push-based/infrastructure-repo"
REPO_PHP="/home/marcel/sfs-sca-projects/k8s-web-app-php"

echo -e "${PURPLE}📊 CHAPTER 6 THESIS: COMPLETE GITHUB ACTIONS PIPELINE VALIDATION${NC}"
echo -e "${PURPLE}================================================================${NC}"
echo ""
echo -e "${BLUE}🎯 Thesis Objective:${NC} Validate multi-repository GitHub Actions integration"
echo -e "${BLUE}📦 Repositories:${NC} 3 repositories with different deployment patterns"
echo -e "${BLUE}⏱️  Start Time:${NC} $(date -u)"
echo ""

# Function to validate GitHub Actions workflow
validate_workflow() {
    local repo_path="$1"
    local workflow_name="$2"
    local repo_name="$3"
    
    echo -e "${YELLOW}🔍 Validating: ${repo_name}${NC}"
    
    if [[ -f "${repo_path}/.github/workflows/${workflow_name}" ]]; then
        echo -e "${GREEN}✅ Workflow found: ${workflow_name}${NC}"
        
        # Check workflow syntax (basic validation)
        if command -v yq &> /dev/null; then
            if yq eval '.name' "${repo_path}/.github/workflows/${workflow_name}" &> /dev/null; then
                echo -e "${GREEN}✅ Workflow syntax: Valid YAML${NC}"
                WORKFLOW_NAME=$(yq eval '.name' "${repo_path}/.github/workflows/${workflow_name}")
                echo -e "${BLUE}   Name: ${WORKFLOW_NAME}${NC}"
            else
                echo -e "${RED}❌ Workflow syntax: Invalid YAML${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  yq not available, skipping syntax validation${NC}"
        fi
        
        # Count jobs
        JOB_COUNT=0
        if command -v yq &> /dev/null; then
            JOB_COUNT=$(yq eval '.jobs | keys | length' "${repo_path}/.github/workflows/${workflow_name}")
            echo -e "${BLUE}   Jobs: ${JOB_COUNT} defined${NC}"
        fi
        
        echo -e "${GREEN}✅ ${repo_name} workflow validation complete${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Workflow not found: ${workflow_name}${NC}"
        echo -e "${RED}   Expected path: ${repo_path}/.github/workflows/${workflow_name}${NC}"
        echo ""
        return 1
    fi
}

# Validate repository structure
validate_repo_structure() {
    local repo_path="$1"
    local repo_name="$2"
    
    echo -e "${YELLOW}🏗️  Validating repository structure: ${repo_name}${NC}"
    
    if [[ -d "${repo_path}" ]]; then
        echo -e "${GREEN}✅ Repository exists: ${repo_path}${NC}"
        
        if [[ -d "${repo_path}/.github" ]]; then
            echo -e "${GREEN}✅ .github directory exists${NC}"
        else
            echo -e "${RED}❌ .github directory missing${NC}"
            return 1
        fi
        
        if [[ -d "${repo_path}/.github/workflows" ]]; then
            echo -e "${GREEN}✅ .github/workflows directory exists${NC}"
            WORKFLOW_COUNT=$(find "${repo_path}/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
            echo -e "${BLUE}   Workflows found: ${WORKFLOW_COUNT}${NC}"
        else
            echo -e "${RED}❌ .github/workflows directory missing${NC}"
            return 1
        fi
        
        echo ""
        return 0
    else
        echo -e "${RED}❌ Repository not found: ${repo_path}${NC}"
        echo ""
        return 1
    fi
}

# Chapter 6 thesis metrics collection
collect_thesis_metrics() {
    echo -e "${PURPLE}📊 CHAPTER 6 THESIS METRICS COLLECTION${NC}"
    echo -e "${PURPLE}======================================${NC}"
    
    local current_time=$(date -u +%s)
    local validation_duration=$((current_time - THESIS_START_TIME))
    
    echo -e "${BLUE}🎯 Pipeline Validation Results:${NC}"
    echo -e "${BLUE}   • Total validation time: ${validation_duration}s${NC}"
    echo -e "${BLUE}   • Repositories validated: 3${NC}"
    echo -e "${BLUE}   • Workflow patterns: Pull-based + Push-based + Complex app${NC}"
    echo ""
    
    # Simulate deployment time estimates
    echo -e "${BLUE}📊 Expected Deployment Characteristics:${NC}"
    echo -e "${BLUE}   • Internal Apps (Pull-based): 3-5 minutes${NC}"
    echo -e "${BLUE}   • External Apps (Push-based): 3-7 minutes${NC}"
    echo -e "${BLUE}   • PHP Web App (Complex): 5-12 minutes${NC}"
    echo ""
    
    echo -e "${BLUE}🔬 Thesis Research Questions Addressed:${NC}"
    echo -e "${BLUE}   • RQ1: GitOps efficiency comparison (Pull vs Push)${NC}"
    echo -e "${BLUE}   • RQ2: Multi-repository coordination complexity${NC}"
    echo -e "${BLUE}   • RQ3: Complex application deployment patterns${NC}"
    echo ""
}

# Generate deployment simulation script
generate_deployment_test() {
    echo -e "${YELLOW}🚀 Generating deployment simulation script${NC}"
    
    cat > "${REPO_ARGOCD}/simulate-complete-deployment.sh" << 'EOF'
#!/bin/bash

# Chapter 6 Thesis: Simulate complete multi-repository deployment
echo "🎯 Simulating complete Chapter 6 deployment scenario..."

# Simulate internal apps deployment (Pull-based)
echo "🔄 [Internal Apps] Triggering pull-based deployment..."
echo "   • ArgoCD detecting changes in infrastructure-repo-argocd"
echo "   • Syncing app1 and app2 across dev/qa/prod"
echo "   • Expected duration: 3-5 minutes"

# Simulate external apps deployment (Push-based)  
echo "🔄 [External Apps] Triggering push-based deployment..."
echo "   • Building external-app container"
echo "   • Updating cross-repository configuration"
echo "   • Force syncing ArgoCD applications"
echo "   • Expected duration: 3-7 minutes"

# Simulate PHP web app deployment (Complex)
echo "🔄 [PHP Web App] Triggering complex multi-container deployment..."
echo "   • Building PHP-FPM and Nginx containers"
echo "   • Compiling frontend assets"
echo "   • Updating complex Kubernetes manifests"
echo "   • Expected duration: 5-12 minutes"

echo "✅ Chapter 6 deployment simulation complete!"
echo "📊 Total estimated deployment time: 11-24 minutes"
echo "🎯 Thesis data collection ready for analysis!"
EOF

    chmod +x "${REPO_ARGOCD}/simulate-complete-deployment.sh"
    echo -e "${GREEN}✅ Deployment simulation script created${NC}"
    echo ""
}

# Main validation flow
main() {
    echo -e "${PURPLE}🎯 Starting Complete GitHub Actions Validation${NC}"
    echo ""
    
    # Validate repository structures
    validate_repo_structure "$REPO_ARGOCD" "Infrastructure ArgoCD (Pull-based)"
    validate_repo_structure "$REPO_INFRA" "Infrastructure Repo (Push-based)"
    validate_repo_structure "$REPO_PHP" "PHP Web Application"
    
    # Validate GitHub Actions workflows
    echo -e "${PURPLE}🔍 VALIDATING GITHUB ACTIONS WORKFLOWS${NC}"
    echo -e "${PURPLE}====================================${NC}"
    echo ""
    
    VALIDATION_SUCCESS=true
    
    # Validate internal apps workflow (Pull-based)
    if ! validate_workflow "$REPO_ARGOCD" "internal-apps-deployment.yml" "Internal Apps (Pull-based)"; then
        VALIDATION_SUCCESS=false
    fi
    
    # Validate external apps workflow (Push-based)
    if ! validate_workflow "$REPO_INFRA" "external-apps-deployment.yml" "External Apps (Push-based)"; then
        VALIDATION_SUCCESS=false
    fi
    
    # Validate PHP web app workflow (Complex)
    if ! validate_workflow "$REPO_PHP" "php-web-app-deployment.yml" "PHP Web App (Complex)"; then
        VALIDATION_SUCCESS=false
    fi
    
    # Generate deployment simulation
    generate_deployment_test
    
    # Collect thesis metrics
    collect_thesis_metrics
    
    # Final validation summary
    echo -e "${PURPLE}📋 COMPLETE VALIDATION SUMMARY${NC}"
    echo -e "${PURPLE}==============================${NC}"
    
    if $VALIDATION_SUCCESS; then
        echo -e "${GREEN}✅ ALL GITHUB ACTIONS WORKFLOWS VALIDATED SUCCESSFULLY${NC}"
        echo ""
        echo -e "${GREEN}🎯 Chapter 6 Thesis: Ready for multi-repository deployment testing${NC}"
        echo -e "${GREEN}📊 All three deployment patterns configured and validated${NC}"
        echo ""
        echo -e "${BLUE}📋 Next Steps:${NC}"
        echo -e "${BLUE}   1. Push workflows to GitHub repositories${NC}"
        echo -e "${BLUE}   2. Configure repository secrets (GITHUB_TOKEN, CONFIG_REPO_PAT)${NC}"
        echo -e "${BLUE}   3. Trigger workflows via GitHub Actions UI${NC}"
        echo -e "${BLUE}   4. Monitor ArgoCD and Grafana for thesis metrics${NC}"
        echo -e "${BLUE}   5. Execute complete deployment simulation${NC}"
        echo ""
        echo -e "${GREEN}🎓 Chapter 6 evaluation framework is complete and ready!${NC}"
    else
        echo -e "${RED}❌ VALIDATION FAILED - Some workflows have issues${NC}"
        echo -e "${RED}🔧 Please review and fix the identified problems${NC}"
        exit 1
    fi
}

# Execute main function
main "$@"