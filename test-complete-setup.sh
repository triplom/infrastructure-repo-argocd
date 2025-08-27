#!/bin/bash

# Complete ArgoCD App-of-Apps Testing Script
# This script validates the entire infrastructure from scratch

# Remove set -e to continue on errors and show all issues
# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test status
print_test_result() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        ((TESTS_FAILED++))
    fi
}

# Function to check if command succeeds
check_command() {
    local test_name="$1"
    local command="$2"
    
    echo "🔍 Testing: $test_name"
    echo "   Command: $command"
    
    if eval "$command" &>/dev/null; then
        print_test_result "$test_name" "PASS"
        return 0
    else
        echo "   Error output:"
        eval "$command" 2>&1 || true
        print_test_result "$test_name" "FAIL"
        return 1
    fi
}

# Function to wait for application to be synced
wait_for_app_sync() {
    local app_name="$1"
    local timeout=${2:-300}
    
    echo "⏳ Waiting for $app_name to sync..."
    
    for i in $(seq 1 $timeout); do
        if kubectl get application "$app_name" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null | grep -q "Synced"; then
            return 0
        fi
        sleep 1
    done
    
    return 1
}

echo "🚀 Starting Complete ArgoCD App-of-Apps Testing..."
echo "=================================================="

# Phase 1: Prerequisites
echo -e "${YELLOW}Phase 1: Prerequisites Validation${NC}"
check_command "kubectl installed" "kubectl version --client"
check_command "kind installed" "kind version"
check_command "docker installed" "docker version"
check_command "helm installed" "helm version"

# Phase 2: Environment Setup
echo -e "${YELLOW}Phase 2: Environment Setup${NC}"
echo "🧹 Cleaning existing clusters..."
make clean-clusters || true

echo "🏗️ Creating KIND clusters..."
make setup-clusters
check_command "KIND clusters created" "kind get clusters | grep -E '(dev|qa|prod)-cluster'"

# Switch to dev cluster
kubectl config use-context kind-dev-cluster

# Phase 3: ArgoCD Installation
echo -e "${YELLOW}Phase 3: ArgoCD Installation${NC}"
make setup-argocd
check_command "ArgoCD namespace created" "kubectl get namespace argocd"
check_command "ArgoCD pods running" "kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s"

# Phase 4: Bootstrap App-of-Apps
echo -e "${YELLOW}Phase 4: Bootstrap App-of-Apps${NC}"
./bootstrap.sh
check_command "Root application created" "kubectl get application root-app -n argocd"

# Wait for root app to sync
if wait_for_app_sync "root-app"; then
    print_test_result "Root application sync" "PASS"
else
    print_test_result "Root application sync" "FAIL"
fi

# Phase 5: Validate Child Applications
echo -e "${YELLOW}Phase 5: Child Applications Validation${NC}"
sleep 10  # Allow time for child apps to be created

check_command "app-of-apps created" "kubectl get application app-of-apps -n argocd"
check_command "app-of-apps-monitoring created" "kubectl get application app-of-apps-monitoring -n argocd"
check_command "app-of-apps-infra created" "kubectl get application app-of-apps-infra -n argocd"

# Phase 6: Multi-Environment Applications
echo -e "${YELLOW}Phase 6: Multi-Environment Applications${NC}"
sleep 20  # Allow more time for ApplicationSets to generate apps

# Check for app1 and app2 in all environments
for app in app1 app2; do
    for env in dev qa prod; do
        if kubectl get application "${app}-${env}" -n argocd &>/dev/null; then
            print_test_result "${app}-${env} application exists" "PASS"
        else
            print_test_result "${app}-${env} application exists" "FAIL"
        fi
    done
done

# Phase 7: Infrastructure Components
echo -e "${YELLOW}Phase 7: Infrastructure Components${NC}"
sleep 30  # Allow time for infrastructure apps to sync

check_command "cert-manager application" "kubectl get application cert-manager -n argocd"
check_command "ingress-nginx application" "kubectl get application ingress-nginx -n argocd"

# Phase 8: Monitoring Components
echo -e "${YELLOW}Phase 8: Monitoring Components${NC}"
check_command "prometheus application" "kubectl get application prometheus -n argocd"
check_command "grafana application" "kubectl get application grafana -n argocd"

# Phase 9: Resource Validation
echo -e "${YELLOW}Phase 9: Resource Validation${NC}"
sleep 60  # Allow time for all resources to be deployed

# Check if namespaces are created
for env in dev qa prod; do
    check_command "app1-$env namespace" "kubectl get namespace app1-$env"
    check_command "app2-$env namespace" "kubectl get namespace app2-$env"
done

# Check infrastructure namespaces
check_command "cert-manager namespace" "kubectl get namespace cert-manager"
check_command "ingress-nginx namespace" "kubectl get namespace ingress-nginx"
check_command "monitoring namespace" "kubectl get namespace monitoring"

# Phase 10: Application Health Check
echo -e "${YELLOW}Phase 10: Application Health Check${NC}"

# Check if applications are healthy
for app in app1 app2; do
    for env in dev qa prod; do
        if kubectl get application "${app}-${env}" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null | grep -q "Healthy"; then
            print_test_result "${app}-${env} health status" "PASS"
        else
            print_test_result "${app}-${env} health status" "FAIL"
        fi
    done
done

# Final Results
echo "=================================================="
echo -e "${YELLOW}Test Summary${NC}"
echo "=================================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Infrastructure is ready.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the output above.${NC}"
    exit 1
fi
