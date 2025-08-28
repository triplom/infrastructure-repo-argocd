#!/bin/bash

# GitHub Container Registry Setup Helper Script
# This script guides you through resolving GHCR permission issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🐳 GitHub Container Registry (GHCR) Setup Helper${NC}"
echo "=================================================="
echo

echo -e "${YELLOW}❌ Issue Detected: permission_denied: write_package${NC}"
echo "This error indicates repository-level configuration is needed."
echo

echo -e "${BLUE}📋 Required Manual Steps (Complete in GitHub Web Interface):${NC}"
echo

echo -e "${GREEN}Step 1: Enable Repository Packages${NC}"
echo "   1. Go to: https://github.com/triplom/infrastructure-repo-argocd/settings"
echo "   2. Scroll to 'Features' section"
echo "   3. ✅ Enable 'Packages' checkbox"
echo "   4. Click 'Save'"
echo

echo -e "${GREEN}Step 2: Configure Actions Permissions${NC}"
echo "   1. Go to: https://github.com/triplom/infrastructure-repo-argocd/settings/actions"
echo "   2. Under 'Workflow permissions':"
echo "      ✅ Select 'Read and write permissions'"
echo "      ✅ Check 'Allow GitHub Actions to create and approve pull requests'"
echo "   3. Click 'Save'"
echo

echo -e "${GREEN}Step 3: Alternative - Personal Access Token (Recommended)${NC}"
echo "   1. Create PAT:"
echo "      - Go to: https://github.com/settings/tokens/new"
echo "      - Note: 'GHCR Token for infrastructure-repo-argocd'"
echo "      - Scopes: ✅ write:packages, ✅ read:packages"
echo "      - Click 'Generate token' and COPY the token"
echo
echo "   2. Add Repository Secret:"
echo "      - Go to: https://github.com/triplom/infrastructure-repo-argocd/settings/secrets/actions"
echo "      - Click 'New repository secret'"
echo "      - Name: GHCR_TOKEN"
echo "      - Value: [paste your PAT token]"
echo "      - Click 'Add secret'"
echo

echo -e "${GREEN}Step 4: Test the Fix${NC}"
echo "   Option A: Use existing workflow with GITHUB_TOKEN (after Steps 1 & 2)"
echo "   Option B: Use PAT workflow (after Step 3)"
echo "      - Go to: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo "      - Click 'CI Pipeline (PAT Version)' → 'Run workflow'"
echo

echo -e "${BLUE}🔧 Quick Test Commands:${NC}"
echo

# Check if we're in the right directory
if [ ! -f ".github/workflows/ci-pipeline.yaml" ]; then
    echo -e "${RED}⚠️  Please run this script from the repository root directory${NC}"
    exit 1
fi

echo "Testing repository structure..."
if [ -f ".github/workflows/ci-pipeline-pat.yaml" ]; then
    echo -e "${GREEN}✅ PAT-based workflow available${NC}"
else
    echo -e "${YELLOW}⚠️  Creating PAT-based workflow...${NC}"
fi

if [ -f "src/app1/Dockerfile" ]; then
    echo -e "${GREEN}✅ Application Dockerfile found${NC}"
else
    echo -e "${YELLOW}⚠️  Application source not found${NC}"
fi

echo
echo -e "${BLUE}📊 Current Git Status:${NC}"
git log --oneline -3 | sed 's/^/   /'

echo
echo -e "${BLUE}🌐 Useful URLs:${NC}"
echo "   Repository Settings: https://github.com/triplom/infrastructure-repo-argocd/settings"
echo "   Actions Settings: https://github.com/triplom/infrastructure-repo-argocd/settings/actions"
echo "   Create PAT: https://github.com/settings/tokens/new"
echo "   Repository Secrets: https://github.com/triplom/infrastructure-repo-argocd/settings/secrets/actions"
echo "   Workflow Runs: https://github.com/triplom/infrastructure-repo-argocd/actions"
echo

echo -e "${CYAN}🎯 Next Steps Summary:${NC}"
echo "1. Complete manual configuration steps above"
echo "2. Test with either existing or PAT workflow"
echo "3. Verify package appears at: https://github.com/triplom/packages"
echo "4. Check for successful push to: ghcr.io/triplom/app1"
echo

echo -e "${GREEN}💡 Pro Tip:${NC} Personal Access Token method is often more reliable"
echo "   for GHCR publishing than GITHUB_TOKEN in some repository configurations."
echo

read -p "Press Enter to continue after completing the manual steps..."

echo
echo -e "${CYAN}🔍 Validation Helper:${NC}"
echo "After completing the steps, you can:"
echo "1. Run the workflow manually"
echo "2. Check workflow logs for success"
echo "3. Verify package creation"
echo

echo -e "${GREEN}✅ GHCR Setup Helper Complete!${NC}"
echo "Complete the manual steps and test the workflow."
