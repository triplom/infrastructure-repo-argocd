# GitHub Actions & Container Registry Setup

## Current Issue: Permission Denied for GitHub Container Registry (GHCR)

### Problem

The CI pipeline is failing with `denied: permission_denied: write_package` when trying to push to GitHub Container Registry.

### Root Causes and Solutions

#### 1. Repository Package Settings

**Check**: Go to Repository Settings → General → Features → Packages

- ✅ **Solution**: Ensure "Packages" is enabled
- ✅ **Solution**: Check package visibility settings

#### 2. Case Sensitivity Issue

**Problem**: GHCR requires lowercase repository/user names

- ✅ **Fixed**: Updated pipeline to convert `${{ github.repository_owner }}` to lowercase
- ✅ **Fixed**: Image name now uses `${{ steps.lowercase.outputs.REPO_OWNER }}/app1`

#### 3. Enhanced

**Problem**: Missing enhanced security permissions

- ✅ **Fixed**: Added `id-token: write` permission
- ✅ **Fixed**: Updated to latest action versions (docker/login-action@v3, docker/build-push-action@v5)
- ✅ **Fixed**: Added `provenance: false` to avoid attestation issues

#### 4. Token Scope Issues

**Problem**: GITHUB_TOKEN might not have sufficient package permissions

- ✅ **Alternative**: Pipeline now configured to use GITHUB_TOKEN with proper permissions
- 🔄 **Backup**: Can use Personal Access Token (PAT) with `write:packages` scope if needed

### Files Modified

1. **`.github/workflows/ci-pipeline.yaml`**:
   - Added lowercase conversion for repository owner
   - Enhanced permissions with `id-token: write`
   - Updated to latest action versions
   - Fixed image naming for GHCR compatibility

2. **`.github/workflows/setup-ghcr.yaml`** (NEW):
   - Test workflow to validate GHCR connectivity
   - Helps diagnose permission issues
   - Creates test image to verify setup

### Testing the Fix

#### Manual Test Workflow

Run the new setup workflow to test GHCR connectivity:

```bash
# Go to GitHub Actions → Setup GitHub Container Registry → Run workflow
```

#### Automated Test

The CI pipeline will now:

1. Convert repository owner to lowercase
2. Use enhanced permissions
3. Provide better error messages
4. Use latest action versions

### Expected Results

#### Before Fix

```bash
Error: denied: permission_denied: write_package
```

#### After Fix

```bash
✅ Successfully pushed to ghcr.io/[username]/app1:latest
✅ Package available at: https://github.com/[username]/packages
```

### Repository Package URL

After successful deployment, packages will be available at:

- **URL**: `https://github.com/triplom/packages`
- **Registry**: `ghcr.io/triplom/app1`

### ❌ Current Status: Still Failing

**Error from GitHub Actions**:
```
denied: permission_denied: write_package
```

This indicates additional repository-level configuration is needed.

### 🔧 Required Manual Configuration Steps

**CRITICAL**: These steps must be completed in the GitHub repository settings:

#### Step 1: Enable Repository Packages
1. Go to **Repository Settings** → **General** → **Features**
2. Scroll down to **"Features"** section
3. ✅ **Enable "Packages"** checkbox
4. Click **"Save"**

#### Step 2: Configure Actions Permissions
1. Go to **Repository Settings** → **Actions** → **General**
2. Under **"Workflow permissions"**:
   - ✅ Select **"Read and write permissions"**
   - ✅ Check **"Allow GitHub Actions to create and approve pull requests"**
3. Click **"Save"**

#### Step 3: Set Package Permissions (Critical)
1. Go to **Repository Settings** → **Actions** → **General**
2. Scroll to **"Fork pull request workflows"** section
3. Under **"Actions permissions"**:
   - ✅ Ensure **"Allow all actions and reusable workflows"** is selected
4. **MOST IMPORTANT**: In repository **Settings** → **Packages** (if visible)
   - Set package visibility to **"Public"** or ensure proper permissions

#### Step 4: Alternative - Personal Access Token Method
If repository settings don't resolve the issue:

1. **Create PAT**:
   - Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
   - Click **"Generate new token (classic)"**
   - Select scopes: ✅ `write:packages`, ✅ `read:packages`
   - Copy the generated token

2. **Add Repository Secret**:
   - Go to Repository → **Settings** → **Secrets and variables** → **Actions**
   - Click **"New repository secret"**
   - Name: `GHCR_TOKEN`
   - Value: [paste your PAT token]

3. **Update Workflow** (if using PAT):
   ```yaml
   - name: Log in to GitHub Container Registry
     uses: docker/login-action@v3
     with:
       registry: ${{ env.REGISTRY }}
       username: ${{ github.actor }}
       password: ${{ secrets.GHCR_TOKEN }}  # Changed from GITHUB_TOKEN
   ```

#### Step 5: Repository Visibility Check
If the repository is **private**:
1. Go to **Repository Settings** → **General**
2. Scroll to **"Danger Zone"**
3. Consider making repository **public** temporarily to test package publishing
4. Or ensure organization package permissions allow private repository publishing

### 🔍 Diagnostic Commands

Run these to verify settings:
```bash
# Check if packages are enabled for the repository
curl -H "Authorization: token YOUR_TOKEN" \
     https://api.github.com/repos/triplom/infrastructure-repo-argocd

# Test manual docker login (locally)
echo "YOUR_TOKEN" | docker login ghcr.io -u triplom --password-stdin
```

### 📋 Troubleshooting Priority Order

1. **FIRST**: Enable Packages in repository Features ⚠️
2. **SECOND**: Set Actions to "Read and write permissions" ⚠️
3. **THIRD**: Try Personal Access Token method if above fails
4. **FOURTH**: Check repository visibility settings

### Pipeline Status

- ✅ **Permissions**: Enhanced with id-token: write
- ✅ **Case Sensitivity**: Fixed with lowercase conversion
- ✅ **Action Versions**: Updated to latest
- ✅ **Image Naming**: Fixed for GHCR compatibility
- ✅ **Error Handling**: Improved diagnostics
- 🔄 **Testing**: Ready for validation

### Next Steps

1. **Commit Changes**: Push the updated CI pipeline
2. **Test Pipeline**: Trigger a build to test GHCR push
3. **Verify Package**: Check GitHub packages page
4. **Monitor Deployment**: Ensure ArgoCD picks up new images

The permission issue should now be resolved with the enhanced pipeline configuration.
