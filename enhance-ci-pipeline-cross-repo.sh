#!/bin/bash

# Enhanced CI Pipeline Configuration for Cross-Repository Support
# Adds external package support to the existing CI pipeline

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Update the CI pipeline workflow_dispatch section to include external packages
update_workflow_dispatch() {
    print_info "Enhancing CI pipeline workflow_dispatch to support all 4 packages..."
    
    # Create a backup
    cp .github/workflows/ci-pipeline.yaml .github/workflows/ci-pipeline.yaml.backup
    
    # Update the component options in workflow_dispatch
    sed -i '/options:/,/- app2/{
        /- app2/a\
          - external-app\
          - nginx\
          - php-fpm
    }' .github/workflows/ci-pipeline.yaml
    
    print_status "Updated workflow_dispatch to include external packages"
}

# Add external package build jobs
add_external_package_jobs() {
    print_info "Adding external package build jobs to CI pipeline..."
    
    # Create external package build job
    cat >> .github/workflows/ci-pipeline.yaml <<'EOF'

  build-external:
    name: Build External Packages
    runs-on: ubuntu-latest
    if: |
      github.event_name == 'workflow_dispatch' && 
      (github.event.inputs.component == 'all' || 
       github.event.inputs.component == 'external-app' ||
       github.event.inputs.component == 'nginx' ||
       github.event.inputs.component == 'php-fpm')
    
    strategy:
      matrix:
        package: 
          - external-app
          - nginx
          - php-fpm
    
    steps:
      - name: Check if package should be built
        id: should-build
        run: |
          COMPONENT="${{ github.event.inputs.component }}"
          PACKAGE="${{ matrix.package }}"
          
          if [[ "$COMPONENT" == "all" || "$COMPONENT" == "$PACKAGE" ]]; then
            echo "build=true" >> $GITHUB_OUTPUT
            echo "Building $PACKAGE"
          else
            echo "build=false" >> $GITHUB_OUTPUT
            echo "Skipping $PACKAGE"
          fi
      
      - name: Checkout Repository
        if: steps.should-build.outputs.build == 'true'
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        if: steps.should-build.outputs.build == 'true'
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Container Registry
        if: steps.should-build.outputs.build == 'true'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}
      
      - name: Set package context and image
        if: steps.should-build.outputs.build == 'true'
        id: package-info
        run: |
          PACKAGE="${{ matrix.package }}"
          
          case $PACKAGE in
            "external-app")
              echo "context=./placeholder/external-app" >> $GITHUB_OUTPUT
              echo "image=ghcr.io/${{ github.repository_owner }}/external-app" >> $GITHUB_OUTPUT
              ;;
            "nginx")
              echo "context=./placeholder/nginx" >> $GITHUB_OUTPUT
              echo "image=ghcr.io/${{ github.repository_owner }}/nginx" >> $GITHUB_OUTPUT
              ;;
            "php-fpm")
              echo "context=./placeholder/php-fpm" >> $GITHUB_OUTPUT
              echo "image=ghcr.io/${{ github.repository_owner }}/php-fpm" >> $GITHUB_OUTPUT
              ;;
          esac
      
      - name: Create placeholder Dockerfile if needed
        if: steps.should-build.outputs.build == 'true'
        run: |
          CONTEXT="${{ steps.package-info.outputs.context }}"
          PACKAGE="${{ matrix.package }}"
          
          mkdir -p "$CONTEXT"
          
          if [[ ! -f "$CONTEXT/Dockerfile" ]]; then
            case $PACKAGE in
              "external-app")
                cat > "$CONTEXT/Dockerfile" <<EOL
FROM node:18-alpine
WORKDIR /app
RUN echo "console.log('External App - Package from infrastructure-repo');" > app.js
EXPOSE 8080
CMD ["node", "-e", "require('http').createServer((req,res) => { res.writeHead(200, {'Content-Type': 'text/plain'}); res.end('External App - Cross-repo package'); }).listen(8080, () => console.log('External app running on port 8080'));"]
EOL
                ;;
              "nginx")
                cat > "$CONTEXT/Dockerfile" <<EOL
FROM nginx:alpine
RUN echo '<h1>Nginx - Cross-repository package</h1>' > /usr/share/nginx/html/index.html
EXPOSE 80
EOL
                ;;
              "php-fpm")
                cat > "$CONTEXT/Dockerfile" <<EOL
FROM php:8.2-fpm-alpine
RUN echo '<?php echo "PHP-FPM - Cross-repository package\n"; ?>' > /var/www/html/index.php
EXPOSE 9000
EOL
                ;;
            esac
            echo "Created placeholder Dockerfile for $PACKAGE"
          fi
      
      - name: Extract metadata
        if: steps.should-build.outputs.build == 'true'
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ steps.package-info.outputs.image }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push container image
        if: steps.should-build.outputs.build == 'true'
        uses: docker/build-push-action@v5
        with:
          context: ${{ steps.package-info.outputs.context }}
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ steps.package-info.outputs.image }}:latest
          cache-to: type=inline
      
      - name: Output image information
        if: steps.should-build.outputs.build == 'true'
        run: |
          echo "Built and pushed: ${{ steps.meta.outputs.tags }}"
          echo "Package: ${{ matrix.package }}"
          echo "Context: ${{ steps.package-info.outputs.context }}"

  update-external-configs:
    name: Update External Package Configurations
    needs: build-external
    runs-on: ubuntu-latest
    if: |
      github.event_name == 'workflow_dispatch' && 
      (github.event.inputs.component == 'all' || 
       github.event.inputs.component == 'external-app' ||
       github.event.inputs.component == 'nginx' ||
       github.event.inputs.component == 'php-fpm')
    
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      
      - name: Update external package configurations
        run: |
          # Configure git
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          
          COMPONENT="${{ github.event.inputs.component }}"
          ENV="${{ github.event.inputs.environment }}"
          
          # Create configurations for external packages
          if [[ "$COMPONENT" == "all" || "$COMPONENT" == "external-app" ]]; then
            mkdir -p apps/external-app/base apps/external-app/overlays/$ENV
            
            # Update external-app deployment with latest image
            if [[ -f "apps/external-app/base/deployment.yaml" ]]; then
              sed -i "s|image: ghcr.io/${{ github.repository_owner }}/external-app:.*|image: ghcr.io/${{ github.repository_owner }}/external-app:latest|g" apps/external-app/base/deployment.yaml
            fi
            
            echo "Updated external-app configuration"
          fi
          
          if [[ "$COMPONENT" == "all" || "$COMPONENT" == "nginx" || "$COMPONENT" == "php-fpm" ]]; then
            mkdir -p apps/php-web-app/base apps/php-web-app/overlays/$ENV
            
            # Update nginx deployment with latest image
            if [[ -f "apps/php-web-app/base/nginx-deployment.yaml" ]]; then
              sed -i "s|image: ghcr.io/${{ github.repository_owner }}/nginx:.*|image: ghcr.io/${{ github.repository_owner }}/nginx:latest|g" apps/php-web-app/base/nginx-deployment.yaml
            fi
            
            # Update php-fpm deployment with latest image
            if [[ -f "apps/php-web-app/base/php-deployment.yaml" ]]; then
              sed -i "s|image: ghcr.io/${{ github.repository_owner }}/php-fpm:.*|image: ghcr.io/${{ github.repository_owner }}/php-fpm:latest|g" apps/php-web-app/base/php-deployment.yaml
            fi
            
            echo "Updated PHP web app (nginx + php-fpm) configuration"
          fi
          
          # Commit changes if any
          if git diff --quiet; then
            echo "No configuration changes to commit"
          else
            git add apps/
            git commit -m "Update external package configurations for $COMPONENT in $ENV environment
            
            Components updated: $COMPONENT
            Environment: $ENV
            Images: ghcr.io/${{ github.repository_owner }}/*:latest"
            
            # Use GitHub token for push (already available in workflow)
            git push origin main
            echo "Pushed external package configuration updates"
          fi
EOF

    print_status "Added external package build jobs to CI pipeline"
}

# Create placeholder directories for external packages
create_placeholder_structures() {
    print_info "Creating placeholder structures for external packages..."
    
    # Create placeholder directories for demonstration
    mkdir -p placeholder/external-app
    mkdir -p placeholder/nginx  
    mkdir -p placeholder/php-fpm
    
    # Create .gitkeep files to ensure directories are tracked
    touch placeholder/external-app/.gitkeep
    touch placeholder/nginx/.gitkeep
    touch placeholder/php-fpm/.gitkeep
    
    # Create README for placeholders
    cat > placeholder/README.md <<'EOF'
# Placeholder Directories for Cross-Repository Packages

This directory contains placeholder build contexts for external packages that are built from other repositories:

- `external-app/`: Placeholder for external-app package (normally built from infrastructure-repo)
- `nginx/`: Placeholder for nginx package (normally built from k8s-web-app-php)
- `php-fpm/`: Placeholder for php-fpm package (normally built from k8s-web-app-php)

These placeholders allow the CI pipeline to demonstrate cross-repository package building when the actual source repositories are not available.

In a real scenario, these packages would be built from their respective repositories:
- external-app: https://github.com/triplom/infrastructure-repo
- nginx + php-fpm: https://github.com/triplom/k8s-web-app-php

The CI pipeline supports building all packages through workflow_dispatch with component selection.
EOF
    
    print_status "Created placeholder structures for external packages"
}

# Main execution
main() {
    echo -e "${BLUE}Enhancing CI Pipeline for Cross-Repository Support${NC}"
    echo "Adding support for external packages: external-app, nginx, php-fpm"
    echo
    
    # Update workflow dispatch options
    update_workflow_dispatch
    
    # Add external package jobs
    add_external_package_jobs
    
    # Create placeholder structures
    create_placeholder_structures
    
    echo
    print_status "CI Pipeline enhanced with cross-repository support!"
    echo
    echo -e "${YELLOW}New capabilities added:${NC}"
    echo "  🔧 Workflow dispatch now supports: external-app, nginx, php-fpm"
    echo "  🏗️ External package build jobs with placeholder Dockerfiles"
    echo "  📦 Automatic configuration updates for external packages"
    echo "  🔄 Integration with existing app1/app2 workflows"
    echo
    echo -e "${YELLOW}To test external package builds:${NC}"
    echo "  1. Go to: https://github.com/triplom/infrastructure-repo-argocd/actions"
    echo "  2. Select 'CI/CD Pipeline' workflow"
    echo "  3. Click 'Run workflow'"
    echo "  4. Choose component: external-app, nginx, or php-fpm"
    echo "  5. Select environment: dev, qa, or prod"
    echo
    print_status "All 4 packages now supported in unified CI pipeline! 🚀"
}

# Run main function
main "$@"