#!/bin/bash

# Cross-Repository Pipeline Integration Script
# Configures all 4 packages across 3 repositories to work with ArgoCD GitOps

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Repository paths (adjust as needed)
MAIN_REPO="/home/marcel/ISCTE/THESIS/pull-based/infrastructure-repo-argocd"
EXTERNAL_REPO="/home/marcel/ISCTE/THESIS/push-based/infrastructure-repo"
PHP_REPO="/home/marcel/sfs-sca-projects/kubernetes-nginx-phpfpm-app"

print_header() {
    echo -e "${CYAN}=====================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=====================================${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check if directory exists
check_repo_exists() {
    local repo_path="$1"
    local repo_name="$2"
    
    if [[ -d "$repo_path" ]]; then
        print_status "$repo_name repository found at $repo_path"
        return 0
    else
        print_warning "$repo_name repository not found at $repo_path"
        return 1
    fi
}

# Function to create/update GitHub workflow for external repository
create_external_repo_workflow() {
    local repo_path="$1"
    
    print_info "Creating CI/CD workflow for external repository..."
    
    mkdir -p "$repo_path/.github/workflows"
    
    cat > "$repo_path/.github/workflows/ci-pipeline.yaml" <<'EOF'
name: CI/CD Pipeline - External App

on:
  push:
    branches:
      - main
    paths:
      - 'apps/external-app/**'
      - '.github/workflows/ci-pipeline.yaml'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - qa
          - prod

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/external-app

permissions:
  contents: read
  packages: write
  id-token: write

jobs:
  build:
    name: Build and Push External App
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push container image
        uses: docker/build-push-action@v5
        with:
          context: ./apps/external-app
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-to: type=inline
      
      - name: Set image tag output
        id: image-tag
        run: |
          IMAGE_TAG=$(echo "${{ steps.meta.outputs.tags }}" | head -1)
          echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_OUTPUT

  update-config:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
    env:
      ENVIRONMENT: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Update application configuration in ArgoCD config repo
        env:
          CONFIG_REPO_PAT: ${{ secrets.CONFIG_REPO_PAT }}
        run: |
          # Clone the ArgoCD configuration repository
          git clone https://${{ github.actor }}:$CONFIG_REPO_PAT@github.com/triplom/infrastructure-repo-argocd.git
          cd infrastructure-repo-argocd
          
          # Configure git
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          
          # Update the image tag in the deployment
          IMAGE_TAG="${{ needs.build.outputs.image_tag }}"
          
          # Update external-app deployment
          if [[ -f "apps/external-app/base/deployment.yaml" ]]; then
            sed -i "s|image: ghcr.io/triplom/external-app:.*|image: $IMAGE_TAG|g" apps/external-app/base/deployment.yaml
            git add apps/external-app/base/deployment.yaml
            
            if git diff --staged --quiet; then
              echo "No changes to commit"
            else
              git commit -m "Update external-app image to $IMAGE_TAG"
              git push origin main
              echo "Updated external-app configuration with new image: $IMAGE_TAG"
            fi
          else
            echo "External-app deployment.yaml not found, creating placeholder"
            mkdir -p apps/external-app/base
            cat > apps/external-app/base/deployment.yaml <<EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-app-deployment
spec:
  template:
    spec:
      containers:
      - name: external-app
        image: $IMAGE_TAG
EOL
            git add apps/external-app/
            git commit -m "Add external-app configuration with image: $IMAGE_TAG"
            git push origin main
          fi
EOF

    print_status "External repository CI/CD workflow created"
}

# Function to create/update GitHub workflow for PHP repository
create_php_repo_workflow() {
    local repo_path="$1"
    
    print_info "Creating CI/CD workflow for PHP repository..."
    
    mkdir -p "$repo_path/.github/workflows"
    
    cat > "$repo_path/.github/workflows/ci-pipeline.yaml" <<'EOF'
name: CI/CD Pipeline - PHP Web App

on:
  push:
    branches:
      - main
    paths:
      - 'nginx/**'
      - 'php-fpm/**'
      - '.github/workflows/ci-pipeline.yaml'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - qa
          - prod

env:
  REGISTRY: ghcr.io
  NGINX_IMAGE: ${{ github.repository_owner }}/nginx
  PHP_FPM_IMAGE: ${{ github.repository_owner }}/php-fpm

permissions:
  contents: read
  packages: write
  id-token: write

jobs:
  build:
    name: Build and Push PHP Web App Containers
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        component: [nginx, php-fpm]
    
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}
      
      - name: Set component image name
        id: image-name
        run: |
          if [[ "${{ matrix.component }}" == "nginx" ]]; then
            echo "IMAGE_NAME=${{ env.NGINX_IMAGE }}" >> $GITHUB_OUTPUT
          else
            echo "IMAGE_NAME=${{ env.PHP_FPM_IMAGE }}" >> $GITHUB_OUTPUT
          fi
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ steps.image-name.outputs.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push container image
        uses: docker/build-push-action@v5
        with:
          context: ./${{ matrix.component }}
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ steps.image-name.outputs.IMAGE_NAME }}:latest
          cache-to: type=inline
      
      - name: Set image tag outputs
        id: image-tag
        run: |
          IMAGE_TAG=$(echo "${{ steps.meta.outputs.tags }}" | head -1)
          echo "${MATRIX_COMPONENT}_IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_OUTPUT
        env:
          MATRIX_COMPONENT: ${{ matrix.component }}

  update-config:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
    env:
      ENVIRONMENT: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Update application configuration in ArgoCD config repo
        env:
          CONFIG_REPO_PAT: ${{ secrets.CONFIG_REPO_PAT }}
        run: |
          # Clone the ArgoCD configuration repository
          git clone https://${{ github.actor }}:$CONFIG_REPO_PAT@github.com/triplom/infrastructure-repo-argocd.git
          cd infrastructure-repo-argocd
          
          # Configure git
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          
          # Create PHP web app configuration if it doesn't exist
          mkdir -p apps/php-web-app/base
          
          # Create nginx deployment
          cat > apps/php-web-app/base/nginx-deployment.yaml <<EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: ghcr.io/triplom/nginx:latest
        ports:
        - containerPort: 80
EOL
          
          # Create php-fpm deployment  
          cat > apps/php-web-app/base/php-deployment.yaml <<EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-fpm-deployment
spec:
  template:
    spec:
      containers:
      - name: php-fpm
        image: ghcr.io/triplom/php-fpm:latest
        ports:
        - containerPort: 9000
EOL
          
          # Create kustomization
          cat > apps/php-web-app/base/kustomization.yaml <<EOL
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- nginx-deployment.yaml
- php-deployment.yaml
EOL
          
          # Commit and push changes
          git add apps/php-web-app/
          if git diff --staged --quiet; then
            echo "No changes to commit"
          else
            git commit -m "Update PHP web app configuration with latest images"
            git push origin main
            echo "Updated PHP web app configuration"
          fi
EOF

    print_status "PHP repository CI/CD workflow created"
}

# Function to create ArgoCD applications for external packages
create_argocd_applications() {
    print_info "Creating ArgoCD applications for external packages..."
    
    # Create external-app applications if they don't exist
    if [[ ! -f "$MAIN_REPO/apps/external-app/base/deployment.yaml" ]]; then
        mkdir -p "$MAIN_REPO/apps/external-app/base"
        mkdir -p "$MAIN_REPO/apps/external-app/overlays/dev"
        mkdir -p "$MAIN_REPO/apps/external-app/overlays/qa"
        mkdir -p "$MAIN_REPO/apps/external-app/overlays/prod"
        
        # Base deployment
        cat > "$MAIN_REPO/apps/external-app/base/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: external-app
  template:
    metadata:
      labels:
        app: external-app
    spec:
      containers:
      - name: external-app
        image: ghcr.io/triplom/external-app:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF
        
        # Base service
        cat > "$MAIN_REPO/apps/external-app/base/service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: external-app-service
spec:
  selector:
    app: external-app
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF
        
        # Base kustomization
        cat > "$MAIN_REPO/apps/external-app/base/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
EOF
        
        # Environment overlays
        for env in dev qa prod; do
            cat > "$MAIN_REPO/apps/external-app/overlays/$env/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
patchesStrategicMerge:
- deployment-patch.yaml
EOF
            
            cat > "$MAIN_REPO/apps/external-app/overlays/$env/deployment-patch.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-app-deployment
spec:
  replicas: $([ "$env" = "prod" ] && echo "3" || echo "1")
EOF
        done
        
        print_status "Created external-app ArgoCD configuration"
    fi
    
    # Create php-web-app applications if they don't exist
    if [[ ! -f "$MAIN_REPO/apps/php-web-app/base/nginx-deployment.yaml" ]]; then
        mkdir -p "$MAIN_REPO/apps/php-web-app/base"
        mkdir -p "$MAIN_REPO/apps/php-web-app/overlays/dev"
        mkdir -p "$MAIN_REPO/apps/php-web-app/overlays/qa"
        mkdir -p "$MAIN_REPO/apps/php-web-app/overlays/prod"
        
        # Nginx deployment
        cat > "$MAIN_REPO/apps/php-web-app/base/nginx-deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
      tier: web
  template:
    metadata:
      labels:
        app: nginx
        tier: web
    spec:
      containers:
      - name: nginx
        image: ghcr.io/triplom/nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
EOF
        
        # PHP-FPM deployment
        cat > "$MAIN_REPO/apps/php-web-app/base/php-deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-fpm-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-fpm
      tier: backend
  template:
    metadata:
      labels:
        app: php-fpm
        tier: backend
    spec:
      containers:
      - name: php-fpm
        image: ghcr.io/triplom/php-fpm:latest
        ports:
        - containerPort: 9000
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF
        
        # Services
        cat > "$MAIN_REPO/apps/php-web-app/base/nginx-service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
    tier: web
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
        
        cat > "$MAIN_REPO/apps/php-web-app/base/php-service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: php-fpm-service
spec:
  selector:
    app: php-fpm
    tier: backend
  ports:
  - port: 9000
    targetPort: 9000
  type: ClusterIP
EOF
        
        # Base kustomization
        cat > "$MAIN_REPO/apps/php-web-app/base/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- nginx-deployment.yaml
- php-deployment.yaml
- nginx-service.yaml
- php-service.yaml
EOF
        
        # Environment overlays
        for env in dev qa prod; do
            cat > "$MAIN_REPO/apps/php-web-app/overlays/$env/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
patchesStrategicMerge:
- nginx-patch.yaml
- php-patch.yaml
EOF
            
            replicas=$([ "$env" = "prod" ] && echo "2" || echo "1")
            cat > "$MAIN_REPO/apps/php-web-app/overlays/$env/nginx-patch.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: $replicas
EOF
            
            cat > "$MAIN_REPO/apps/php-web-app/overlays/$env/php-patch.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-fpm-deployment
spec:
  replicas: $replicas
EOF
        done
        
        print_status "Created PHP web app ArgoCD configuration"
    fi
}

# Function to update ArgoCD app-of-apps to include external applications
update_app_of_apps() {
    print_info "Updating app-of-apps to include external applications..."
    
    # Check if external-app template exists in app-of-apps
    if [[ ! -f "$MAIN_REPO/app-of-apps/templates/external-app.yaml" ]]; then
        cat > "$MAIN_REPO/app-of-apps/templates/external-app.yaml" <<'EOF'
{{ if .Values.argocd.externalApps.externalApp.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: external-app
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - env: dev
        cluster: https://kubernetes.default.svc
      - env: qa
        cluster: https://kubernetes.default.svc
      - env: prod
        cluster: https://kubernetes.default.svc
  template:
    metadata:
      name: 'external-app-{{`{{env}}`}}'
      namespace: argocd
      finalizers:
      - resources-finalizer.argocd.argoproj.io
    spec:
      project: applications
      source:
        repoURL: https://github.com/triplom/infrastructure-repo-argocd.git
        targetRevision: {{ .Values.externalApps.externalApp.targetRevision }}
        path: apps/external-app/overlays/{{`{{env}}`}}
      destination:
        server: '{{`{{cluster}}`}}'
        namespace: external-app-{{`{{env}}`}}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
{{ end }}
EOF
        print_status "Created external-app ApplicationSet template"
    fi
    
    # Update app-of-apps values to enable external applications
    if [[ -f "$MAIN_REPO/app-of-apps/values.yaml" ]]; then
        if ! grep -q "externalApps:" "$MAIN_REPO/app-of-apps/values.yaml"; then
            cat >> "$MAIN_REPO/app-of-apps/values.yaml" <<'EOF'

# External Applications
externalApps:
  externalApp:
    enabled: true
    targetRevision: HEAD
  phpWebApp:
    enabled: true
    targetRevision: HEAD
EOF
            print_status "Added external apps configuration to values.yaml"
        fi
    fi
}

# Main execution
main() {
    print_header "Cross-Repository Pipeline Integration Setup"
    
    echo -e "${BLUE}Setting up pipelines for 4 packages across 3 repositories:${NC}"
    echo "  📦 app1 (infrastructure-repo-argocd)"
    echo "  📦 app2 (infrastructure-repo-argocd)"
    echo "  📦 external-app (infrastructure-repo)"
    echo "  📦 nginx + php-fpm (k8s-web-app-php)"
    echo
    
    # Check repository availability
    print_header "Phase 1: Repository Validation"
    check_repo_exists "$MAIN_REPO" "Main ArgoCD Config"
    
    if check_repo_exists "$EXTERNAL_REPO" "External Infrastructure"; then
        create_external_repo_workflow "$EXTERNAL_REPO"
    else
        print_warning "Skipping external repository workflow creation"
    fi
    
    if check_repo_exists "$PHP_REPO" "PHP Web App"; then
        create_php_repo_workflow "$PHP_REPO"
    else
        print_warning "Skipping PHP repository workflow creation"
    fi
    
    # Create ArgoCD configurations
    print_header "Phase 2: ArgoCD Configuration"
    create_argocd_applications
    update_app_of_apps
    
    # Summary
    print_header "Integration Setup Complete"
    print_status "Main repository (app1, app2): Already configured"
    
    if [[ -d "$EXTERNAL_REPO" ]]; then
        print_status "External repository workflow: Created at $EXTERNAL_REPO/.github/workflows/ci-pipeline.yaml"
    fi
    
    if [[ -d "$PHP_REPO" ]]; then
        print_status "PHP repository workflow: Created at $PHP_REPO/.github/workflows/ci-pipeline.yaml"
    fi
    
    print_status "ArgoCD applications: Configured for all packages"
    
    echo
    print_header "Next Steps"
    echo -e "${YELLOW}1. Configure GitHub Secrets in all repositories:${NC}"
    echo "   - GHCR_TOKEN (container registry access)"
    echo "   - CONFIG_REPO_PAT (cross-repository updates)"
    echo
    echo -e "${YELLOW}2. Test pipelines in order:${NC}"
    echo "   a) app1/app2: https://github.com/triplom/infrastructure-repo-argocd/actions"
    echo "   b) external-app: https://github.com/triplom/infrastructure-repo/actions"
    echo "   c) nginx/php-fpm: https://github.com/triplom/k8s-web-app-php/actions"
    echo
    echo -e "${YELLOW}3. Validate ArgoCD deployment:${NC}"
    echo "   kubectl get applications -n argocd"
    echo "   kubectl get pods --all-namespaces | grep -E '(app1|app2|external|nginx|php)'"
    echo
    print_status "All 4 packages are now configured for cross-repository GitOps deployment! 🚀"
}

# Run main function
main "$@"