#!/bin/bash

# Simple ArgoCD App-of-Apps Testing Script
# This script validates the entire infrastructure from scratch

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

echo "🚀 Starting Complete ArgoCD App-of-Apps Testing..."
echo "=================================================="

# Phase 1: Prerequisites
echo -e "${YELLOW}Phase 1: Prerequisites Validation${NC}"
check_command "kubectl installed" "kubectl version --client"
check_command "kind installed" "kind version"
check_command "docker installed" "docker version"
check_command "helm installed" "helm version"

echo "=================================================="
echo -e "${YELLOW}Test Summary${NC}"
echo "=================================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Prerequisites check passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: make clean-clusters"
    echo "2. Run: make setup-clusters"
    echo "3. Run: kubectl config use-context kind-dev-cluster"
    echo "4. Run: make setup-argocd"
    echo "5. Run: ./bootstrap.sh"
    echo "6. Validate: kubectl get applications -n argocd"
else
    echo -e "${RED}❌ Some prerequisites are missing. Please install them first.${NC}"
    exit 1
fi
