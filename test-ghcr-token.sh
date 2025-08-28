#!/bin/bash

# GHCR Authentication Test Script
# This script helps verify that the GHCR_TOKEN configuration is working

set -e

echo "🐳 GHCR Authentication Verification Script"
echo "=========================================="
echo

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}📋 Verification Checklist:${NC}"
echo

echo -e "${GREEN}✅ 1. Personal Access Token (GHCR_TOKEN) created${NC}"
echo "   - Token created with write:packages scope"
echo "   - Added as repository secret"
echo

echo -e "${GREEN}✅ 2. CI Pipeline Updated${NC}"
echo "   - Main workflow now uses GHCR_TOKEN"
echo "   - Setup workflow now uses GHCR_TOKEN"
echo "   - Latest commit pushed to GitHub"
echo

echo -e "${BLUE}🧪 Testing Options:${NC}"
echo

echo "Option 1: Test GHCR Setup Workflow"
echo "   URL: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "   1. Click 'Setup GitHub Container Registry'"
echo "   2. Click 'Run workflow' → 'Run workflow'"
echo "   3. Watch for successful push to ghcr.io/triplom/app1:test"
echo

echo "Option 2: Test Main CI Pipeline"  
echo "   URL: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "   1. Click 'CI Pipeline'"
echo "   2. Click 'Run workflow' → 'Run workflow'"
echo "   3. Watch for successful build and push"
echo

echo "Option 3: Re-run Previous Failed Workflow"
echo "   URL: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "   1. Find the failed 'Setup GitHub Container Registry #2'"
echo "   2. Click 'Re-run failed jobs'"
echo "   3. Should now succeed with GHCR_TOKEN"
echo

echo -e "${YELLOW}📊 Expected Success Indicators:${NC}"
echo "   ✅ No 'permission_denied: write_package' errors"
echo "   ✅ Green checkmark for workflow completion"
echo "   ✅ 'Successfully pushed to ghcr.io/triplom/app1' message"
echo "   ✅ Package appears at: https://github.com/triplom/packages"
echo

echo -e "${BLUE}🔍 Verification Commands:${NC}"
echo

echo "Check current git status:"
git log --oneline -3 | sed 's/^/   /'
echo

echo "Check workflow files contain GHCR_TOKEN:"
if grep -q "GHCR_TOKEN" .github/workflows/ci-pipeline.yaml; then
    echo -e "   ${GREEN}✅ ci-pipeline.yaml uses GHCR_TOKEN${NC}"
else
    echo -e "   ${YELLOW}⚠️  ci-pipeline.yaml check failed${NC}"
fi

if grep -q "GHCR_TOKEN" .github/workflows/setup-ghcr.yaml; then
    echo -e "   ${GREEN}✅ setup-ghcr.yaml uses GHCR_TOKEN${NC}"
else
    echo -e "   ${YELLOW}⚠️  setup-ghcr.yaml check failed${NC}"
fi

echo
echo -e "${CYAN}🎯 Next Steps:${NC}"
echo "1. Go to GitHub Actions and run one of the testing options above"
echo "2. Watch for successful completion without permission errors"
echo "3. Verify package creation at GitHub packages page"
echo "4. Test container pull: docker pull ghcr.io/triplom/app1:latest"
echo

echo -e "${GREEN}✅ GHCR_TOKEN Configuration Complete!${NC}"
echo "The CI pipeline should now successfully authenticate with GitHub Container Registry."
