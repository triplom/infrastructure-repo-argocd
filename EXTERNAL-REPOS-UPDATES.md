# External Repository GitHub Actions Updates

## Repositories to Update

Based on the conversation summary, these external repositories also need GitHub Actions pipeline updates:

1. **https://github.com/triplom/infrastructure-repo.git**
2. **https://github.com/triplom/k8s-web-app-php.git**

## Required Changes for GHCR Permission Fix

### 1. Update Docker Build Workflows

Apply these changes to any workflow files that build and push Docker images:

#### Before (Problematic):
```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/app-name

jobs:
  build:
    permissions:
      contents: read
      packages: write
    steps:
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
```

#### After (Fixed):
```yaml
env:
  REGISTRY: ghcr.io
  # Note: IMAGE_NAME construction moved to workflow steps

jobs:
  build:
    permissions:
      contents: read
      packages: write
      id-token: write  # Enhanced security
    steps:
      # Convert repository owner to lowercase for GHCR
      - name: Set lowercase repository owner
        id: lowercase
        run: echo "REPO_OWNER=$(echo ${{ github.repository_owner }} | tr '[:upper:]' '[:lower:]')" >> $GITHUB_OUTPUT
      
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3  # Updated version
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3  # Updated version
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ steps.lowercase.outputs.REPO_OWNER }}/app-name  # Use lowercase
          tags: |
            type=sha,format=short
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=raw,value=latest,enable=${{ github.ref == format('refs/heads/{0}', 'main') }}
      
      - name: Build and push
        uses: docker/build-push-action@v5  # Updated version
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          provenance: false  # Avoid attestation issues
```

### 2. Repository-Specific Updates

#### infrastructure-repo.git
If this repository builds infrastructure-related containers:
- Apply the GHCR fixes above
- Update any image references to use lowercase repository owner
- Ensure CI/CD pipelines reference the correct ArgoCD repository URL

#### k8s-web-app-php.git
For the PHP web application:
- Apply the GHCR fixes above
- Update image name to match application (e.g., `php-web-app`)
- Ensure deployment manifests use the correct image registry format

### 3. Repository Settings Verification

For each external repository, verify these settings:

#### Package Settings
1. Go to **Repository Settings → General → Features**
2. Ensure **"Packages"** is enabled
3. Check package visibility settings

#### Actions Permissions
1. Go to **Repository Settings → Actions → General**
2. Set **"Read and write permissions"** for GITHUB_TOKEN
3. Enable **"Allow GitHub Actions to create and approve pull requests"**

### 4. Testing the Fixes

Create a test workflow in each repository (`.github/workflows/test-ghcr.yaml`):

```yaml
name: Test GHCR Setup

on:
  workflow_dispatch:

env:
  REGISTRY: ghcr.io

jobs:
  test-ghcr:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Convert repository owner to lowercase
        id: lowercase
        run: echo "REPO_OWNER=$(echo ${{ github.repository_owner }} | tr '[:upper:]' '[:lower:]')" >> $GITHUB_OUTPUT
      
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Test connectivity
        run: |
          echo "Testing GHCR connectivity..."
          echo "Repository owner (lowercase): ${{ steps.lowercase.outputs.REPO_OWNER }}"
          echo "✅ Login successful!"
```

### 5. Image Reference Updates

After fixing the pipelines, update any references to the container images:

#### In ArgoCD Applications
Update image references in deployment manifests to use lowercase:
```yaml
# Before
image: ghcr.io/Triplom/app-name:latest

# After  
image: ghcr.io/triplom/app-name:latest
```

#### In Kustomize Overlays
Update image transformations:
```yaml
# kustomization.yaml
images:
- name: app-name
  newName: ghcr.io/triplom/app-name
  newTag: latest
```

### 6. Common Troubleshooting

If issues persist in external repositories:

1. **Check Token Scopes**: Ensure GITHUB_TOKEN has package permissions
2. **Verify Repository Visibility**: Private repos may have different package permissions
3. **Test Manual Push**: Try pushing manually with the same credentials
4. **Check Package Permissions**: Verify package settings allow the repository to write

### 7. Coordination with ArgoCD

After fixing external repository pipelines:

1. **Update ApplicationSets**: Ensure ArgoCD can pull from the new image locations
2. **Test Image Pull**: Verify Kubernetes can pull from GHCR with correct image names
3. **Monitor Deployments**: Check ArgoCD sync status after pipeline updates

## Summary of Required Actions

1. ✅ **infrastructure-repo-argocd** - COMPLETED (current repository)
2. 🔄 **infrastructure-repo** - Apply GHCR fixes
3. 🔄 **k8s-web-app-php** - Apply GHCR fixes and test PHP app deployment

All repositories should use the same lowercase repository owner format and enhanced permissions for successful GHCR integration.
