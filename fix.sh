#!/bin/bash
# create-project-scaffolding.sh - Example script to enhance your repository structure

# Create a .gitignore for better repository management
cat > .gitignore << EOF
# Kubernetes & Docker
kubeconfig
*.kubeconfig
*.kubeconfig.bak
.kube/
.docker/
*.pem
*.key
*.crt

# Development tools
.vscode/*
!.vscode/extensions.json
.idea/
*.swp
*.swo

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Base64 encoded secrets
*-base64.txt
EOF

# Create Makefile for simplified operations
cat > Makefile << EOF
.PHONY: setup-dev deploy-dev setup-registry validate-manifests

# Setup development environment
setup-dev:
	./kind/setup-kind.sh dev

# Setup local registry
setup-registry:
	./infrastructure/local-registry/setup-registry.sh

# Deploy app to development
deploy-dev:
	kubectl apply --validate=false -k apps/app1/overlays/dev

# Validate Kubernetes manifests (requires kubeconform)
validate-manifests:
	find ./apps -name "*.yaml" -not -path "*/kustomization.yaml" | xargs kubeconform -kubernetes-version 1.25.0

# Run tests
test-app:
	cd src/app1 && python -m pytest
EOF

# Create pre-commit hook configuration
cat > .pre-commit-config.yaml << EOF
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.4.0
  hooks:
  - id: trailing-whitespace
  - id: end-of-file-fixer
  - id: check-yaml
    exclude: '.*/templates/.*'

- repo: https://github.com/adrienverge/yamllint.git
  rev: v1.32.0
  hooks:
  - id: yamllint
    args: ['-d', '{extends: relaxed, rules: {line-length: {max: 120}}}']

- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: v1.83.5
  hooks:
  - id: terraform_fmt
    files: \.tf$

- repo: https://github.com/zricethezav/gitleaks
  rev: v8.18.0
  hooks:
  - id: gitleaks
EOF

# Create contributions guide
mkdir -p docs
cat > docs/CONTRIBUTING.md << EOF
# Contributing Guide

## Development Workflow

1. **Setup local environment**
   \`\`\`bash
   make setup-dev
   make setup-registry
   \`\`\`

2. **Make changes and test**
   \`\`\`bash
   make test-app
   make validate-manifests
   \`\`\`

3. **Deploy your changes**
   \`\`\`bash
   make deploy-dev
   \`\`\`

4. **Submit PR**
   Ensure CI passes before requesting review.

## Repository Structure

- \`apps/\`: Kubernetes manifests for applications
- \`infrastructure/\`: Infrastructure components
- \`src/\`: Application source code
- \`kind/\`: Local Kubernetes cluster configuration

## Best Practices

1. Use Kustomize for environment-specific configs
2. Keep secrets out of the repository
3. Test locally before committing
4. Use feature branches and PRs for changes
EOF