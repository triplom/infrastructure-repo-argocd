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

#### 3. Enhanced Permissions
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
```
Error: denied: permission_denied: write_package
```

#### After Fix
```
✅ Successfully pushed to ghcr.io/[username]/app1:latest
✅ Package available at: https://github.com/[username]/packages
```

### Repository Package URL
After successful deployment, packages will be available at:
- **URL**: `https://github.com/triplom/packages`
- **Registry**: `ghcr.io/triplom/app1`

### Troubleshooting Steps

If the issue persists:

1. **Check Repository Settings**:
   - Go to Settings → General → Features
   - Ensure "Packages" is enabled
   - Check package permissions

2. **Verify Token Permissions**:
   - Repository → Settings → Actions → General
   - Ensure "Read and write permissions" is selected
   - Check "Allow GitHub Actions to create and approve pull requests"

3. **Manual GHCR Test**:
   - Run the `setup-ghcr.yaml` workflow manually
   - Check output for specific error messages

4. **Alternative Token Setup**:
   If GITHUB_TOKEN doesn't work, create a Personal Access Token:
   - GitHub → Settings → Developer settings → Personal access tokens
   - Create token with `write:packages` scope
   - Add as repository secret named `GHCR_TOKEN`
   - Update pipeline to use `${{ secrets.GHCR_TOKEN }}`

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
