# GitHub Actions KUBECONFIG Secret Setup Guide

**Date**: October 12, 2025  
**Purpose**: Optional setup for GitHub Actions direct cluster access (not required for pull-based GitOps demo)

## ⚠️ Important Note

**This setup is NOT required for the pull-based GitOps demonstration.** The workflows have been designed to work without KUBECONFIG secrets and will display an informative message explaining the pull-based GitOps flow when secrets are missing.

However, if you want to test direct deployment capabilities from GitHub Actions, follow this guide.

## 🔧 Setting Up KUBECONFIG Secrets

### Step 1: Generate Base64 Encoded Kubeconfig

For each environment (dev, qa, prod), you need to create a KUBECONFIG secret:

```bash
# For dev environment
kubectl config view --context=kind-dev-cluster --flatten > dev-kubeconfig.yaml
base64 -w 0 dev-kubeconfig.yaml > dev-kubeconfig-b64.txt

# For qa environment  
kubectl config view --context=kind-qa-cluster --flatten > qa-kubeconfig.yaml
base64 -w 0 qa-kubeconfig.yaml > qa-kubeconfig-b64.txt

# For prod environment
kubectl config view --context=kind-prod-cluster --flatten > prod-kubeconfig.yaml
base64 -w 0 prod-kubeconfig.yaml > prod-kubeconfig-b64.txt
```

### Step 2: Add Secrets to GitHub Repository

Using GitHub CLI:
```bash
# Add secrets for each environment
gh secret set KUBECONFIG_DEV < dev-kubeconfig-b64.txt
gh secret set KUBECONFIG_QA < qa-kubeconfig-b64.txt  
gh secret set KUBECONFIG_PROD < prod-kubeconfig-b64.txt
```

Or manually via GitHub web interface:
1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret:
   - Name: `KUBECONFIG_DEV`, Value: contents of `dev-kubeconfig-b64.txt`
   - Name: `KUBECONFIG_QA`, Value: contents of `qa-kubeconfig-b64.txt`
   - Name: `KUBECONFIG_PROD`, Value: contents of `prod-kubeconfig-b64.txt`

### Step 3: Verify Context Names

Ensure your kubeconfig contexts match the expected names:
```bash
kubectl config get-contexts
```

Expected context names:
- `kind-dev-cluster`
- `kind-qa-cluster`
- `kind-prod-cluster`

If your contexts have different names, update the workflows or rename your contexts:
```bash
kubectl config rename-context old-name kind-dev-cluster
```

## 🔍 Troubleshooting

### Common Issues

1. **"base64: invalid input" error**
   - Ensure the secret contains valid base64 content
   - Regenerate with `base64 -w 0` (no line wrapping)

2. **"Failed to get kubectl contexts" error**
   - Verify the kubeconfig file is valid
   - Check that the context names match

3. **Connection timeout errors**
   - KIND clusters might not be accessible from GitHub Actions runners
   - Consider using cloud-hosted clusters for GitHub Actions integration

### Validation Commands

Test locally before setting secrets:
```bash
# Test decoding
echo "your-base64-content" | base64 -d > test-kubeconfig.yaml
export KUBECONFIG=test-kubeconfig.yaml
kubectl config get-contexts
kubectl cluster-info
```

## 🎯 Pull-Based GitOps Workflow (Recommended)

Instead of setting up KUBECONFIG secrets, the recommended approach is to use the pure pull-based GitOps workflow:

1. **GitHub Actions**: Build images and update manifests only
2. **ArgoCD**: Monitors Git and deploys to clusters automatically
3. **No secrets needed**: GitHub Actions doesn't need cluster access

This approach provides:
- ✅ Better security (no cluster credentials in CI/CD)
- ✅ Git as single source of truth
- ✅ Continuous reconciliation and drift detection
- ✅ Simplified CI/CD pipeline

## 📊 Current Workflow Behavior

**Without KUBECONFIG secrets** (Current state):
- Workflow displays informative pull-based GitOps message
- Completes successfully without errors
- Demonstrates proper GitOps principles
- ArgoCD handles all deployments locally

**With KUBECONFIG secrets** (Optional):
- Workflow attempts direct cluster deployment
- Requires network connectivity to KIND clusters
- Useful for testing direct deployment scenarios
- May conflict with pull-based GitOps approach

## 🏆 Recommendation

For thesis evaluation and pull-based GitOps demonstration, **no action is required**. The current setup properly demonstrates pull-based GitOps principles without needing GitHub Actions to have direct cluster access.

Only set up KUBECONFIG secrets if you specifically need to test hybrid push/pull deployment scenarios for comparison purposes.