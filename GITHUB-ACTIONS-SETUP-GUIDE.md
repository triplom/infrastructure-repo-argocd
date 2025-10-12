# GitHub Actions Setup Guide

This document describes the GitHub Secrets and configuration needed for the GitHub Actions pipelines to work with your ArgoCD GitOps setup.

## Required GitHub Secrets

### 1. Kubeconfig Files for Each Environment

You need to create GitHub Secrets for each cluster environment:

```bash
# For dev environment
KUBECONFIG_DEV=<base64-encoded content of dev-cluster-kubeconfig>

# For qa environment  
KUBECONFIG_QA=<base64-encoded content of qa-cluster-kubeconfig>

# For prod environment
KUBECONFIG_PROD=<base64-encoded content of prod-cluster-kubeconfig>
```

**How to create these secrets:**

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Use the exact names above
4. For the values, use the base64-encoded content from your existing files:

```bash
# Get the base64 content for each environment
cat dev-cluster-kubeconfig-base64.txt    # Copy this for KUBECONFIG_DEV
cat qa-cluster-kubeconfig-base64.txt     # Copy this for KUBECONFIG_QA  
cat prod-cluster-kubeconfig-base64.txt   # Copy this for KUBECONFIG_PROD
```

### 2. SSH Private Key for Repository Access

```bash
SSH_PRIVATE_KEY=<your-ssh-private-key>
```

This should be the same SSH private key you use locally to access the GitHub repository. You can get it with:

```bash
cat ~/.ssh/id_ed25519  # Copy the entire content including -----BEGIN and -----END lines
```

**Your SSH private key content:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACCNCE37veO2DsAX/FlEBK3QaZ/hMo9hg3eLe78HAIXBNgAAAJg8x4DQPMeA
0AAAAAtzc2gtZWQyNTUxOQAAACCNCE37veO2DsAX/FlEBK3QaZ/hMo9hg3eLe78HAIXBNg
AAAEC8MXlCduUcVP7+9BoS4Lr5zuLS3OKnhE9Xk6Ew6yv2ho0ITfu947YOwBf8WUQErdBp
n+Eyj2GDd4t7vwcAhcE2AAAAEldTTC1TaWVtZW5zLU1hcmNlbAECAw==
-----END OPENSSH PRIVATE KEY-----
```

### 3. GitHub Personal Access Token

```bash
CONFIG_REPO_PAT=<github-personal-access-token>
```

Create a GitHub Personal Access Token with these permissions:
- `repo` (Full control of private repositories)
- `workflow` (Update GitHub Action workflows)

**You already have a token! Use this:**

```
[YOUR_GITHUB_TOKEN_FROM_PREVIOUS_STEP]
```

**How to add it as a GitHub Secret:**
1. Go to your GitHub repository: `https://github.com/triplom/infrastructure-repo-argocd`
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `CONFIG_REPO_PAT`
5. Value: `[YOUR_GITHUB_TOKEN_HERE]`
6. Click **"Add secret"**

### 4. GitHub Token (Automatic)

The `GITHUB_TOKEN` is automatically provided by GitHub Actions, no setup needed.

## Pipeline Overview

### 1. `deploy-argocd.yaml` - ArgoCD Bootstrap Pipeline
- **Triggers:** Changes to ArgoCD configuration, manual dispatch
- **Purpose:** Install and configure ArgoCD on target clusters
- **Actions:** 
  - Install ArgoCD
  - Configure SSH repository access
  - Bootstrap root application (app-of-apps pattern)
  - Validate deployment

### 2. `deploy-apps.yaml` - Business Applications Pipeline  
- **Triggers:** Changes to apps/, manual dispatch
- **Purpose:** Sync business applications via ArgoCD
- **Actions:**
  - Connect to ArgoCD
  - Sync specific or all business applications
  - Wait for health confirmation

### 3. `deploy-infrastructure.yaml` - Infrastructure Pipeline
- **Triggers:** Changes to infrastructure/, manual dispatch  
- **Purpose:** Sync infrastructure components via ArgoCD
- **Actions:**
  - Sync cert-manager, ingress-nginx, github-registry
  - Sync app-of-apps-infra parent

### 4. `deploy-monitoring.yaml` - Monitoring Pipeline
- **Triggers:** Changes to monitoring config, manual dispatch
- **Purpose:** Sync monitoring stack via ArgoCD  
- **Actions:**
  - Sync prometheus, grafana, alertmanager
  - Sync app-of-apps-monitoring parent
  - Verify monitoring deployment

### 5. `ci-pipeline.yaml` - Complete CI/CD Pipeline
- **Triggers:** Changes to src/, manual dispatch
- **Purpose:** Build, deploy, and sync applications end-to-end
- **Actions:**
  - Build and push container images to GHCR
  - Update Kustomize image references
  - Trigger ArgoCD sync across all environments

## Testing the Pipelines

### Manual Testing
You can test each pipeline manually using the "Actions" tab in GitHub:

1. Go to Actions → Select workflow → Run workflow
2. Choose environment (dev/qa/prod) and component
3. Monitor the execution

### Automatic Triggers
- **File changes:** Push changes to trigger relevant pipelines
- **ArgoCD:** Will automatically detect and sync repository changes

## Pipeline Flow for Application Updates

1. **Developer pushes code** to `src/app1/` or `src/app2/`
2. **CI Pipeline triggers**:
   - Builds new container image
   - Pushes to GHCR (`ghcr.io/triplom/app1:latest`)
   - Updates Kustomize files with new image reference
   - Commits changes back to repository
3. **ArgoCD detects changes** and automatically syncs applications
4. **Applications deployed** across dev/qa/prod environments

## Troubleshooting

### Common Issues

1. **Kubeconfig errors**: Ensure base64 content is correct and cluster is accessible
2. **SSH key errors**: Verify SSH key has access to repository
3. **ArgoCD connection failures**: Check cluster connectivity and ArgoCD installation
4. **Image pull errors**: Verify GHCR permissions and authentication

### Debug Commands

```bash
# Test kubeconfig locally
echo "KUBECONFIG_DEV_CONTENT" | base64 -d > test-kubeconfig
export KUBECONFIG=test-kubeconfig
kubectl config get-contexts

# Test SSH access
ssh -T git@github.com

# Test ArgoCD access
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080
```

## Environment Setup Summary

To get your pipelines working:

1. ✅ Add the 4 GitHub Secrets (KUBECONFIG_*, SSH_PRIVATE_KEY, CONFIG_REPO_PAT)
2. ✅ Ensure your KIND clusters are running with ArgoCD installed
3. ✅ Verify SSH key access to repository
4. ✅ Test manual pipeline runs
5. ✅ Push changes to src/ to test automatic triggers

Your GitOps infrastructure is now ready for Chapter 6 evaluation with working CI/CD pipelines! 🚀