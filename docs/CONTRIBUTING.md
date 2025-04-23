# Contributing Guide

This document provides guidelines and instructions for contributing to the Push-Based GitOps project with KIND and Prometheus Monitoring.

## Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Repository Structure](#repository-structure)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Development Environment Setup

### Prerequisites

Ensure you have the following tools installed:

- Docker (v20.10+)
- kubectl (v1.24+)
- kind (v0.20+)
- Helm (v3.12+)
- yq for YAML processing
- Git
- Make

### Initial Setup

1. **Fork and clone the repository**

   ```bash
   git clone https://github.com/your-username/infrastructure-repo.git
   cd infrastructure-repo
   ```

2. **Install development tools**

   ```bash
   # Install pre-commit hooks
   pip install pre-commit
   pre-commit install
   
   # Install other development dependencies
   pip install yamllint kubectl-neat kubeconform
   ```

3. **Setup your local environment**

   ```bash
   make setup-dev
   make setup-registry
   ```

## Development Workflow

1. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test locally**

   ```bash
   # Run unit tests
   make test-app
   
   # Validate Kubernetes manifests
   make validate-manifests
   
   # Lint YAML files
   make lint-yaml
   
   # Deploy to dev environment
   make deploy-dev
   ```

3. **Commit your changes**

   ```bash
   git add .
   git commit -m "Your descriptive commit message"
   ```

4. **Push changes and create a Pull Request**

   ```bash
   git push origin feature/your-feature-name
   ```

5. **Address review feedback**

   After submitting your PR, address any feedback from reviewers.

## Code Standards

### YAML Files

- Use 2-space indentation
- Follow Kubernetes best practices
- Use consistent naming conventions
  - Resources: lowercase with hyphens (kebab-case)
  - Variables: camelCase
- Document all key configurations with comments

### Shell Scripts

- Include shebang line (`#!/usr/bin/env bash`)
- Set error handling with `set -euo pipefail`
- Add usage documentation
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### Python Code

- Follow PEP 8 style guide
- Include docstrings
- Add type hints
- Use pytest for testing

## Testing Guidelines

### Infrastructure Testing

- Test resource deployment in isolation before integration
- Verify all configurations against schema using kubeconform
- Test against multiple Kubernetes versions

### Application Testing

- Write unit tests for all application code
- Use mocks for external dependencies
- Include integration tests for APIs
- Test against all supported Python versions

## Pull Request Process

1. **Before submitting**
   - Ensure all tests pass
   - Update documentation as needed
   - Rebase onto latest main branch

2. **PR Guidelines**
   - Use descriptive PR titles
   - Fill out the PR template completely
   - Link related issues
   - Include before/after screenshots for UI changes

3. **Review Process**
   - PRs require at least one approval
   - Address all review comments
   - CI pipeline must pass

4. **After Merge**
   - Delete the feature branch
   - Verify deployment in dev environment

## Repository Structure

```bash
infrastructure-repo/
├── .github/workflows/     # CI/CD pipeline definitions
├── apps/                  # Application manifests
│   └── <app-name>/        # Application-specific manifests
│       ├── base/          # Base Kustomize configuration
│       └── overlays/      # Environment-specific overlays
├── docs/                  # Documentation
├── infrastructure/        # Infrastructure components
│   ├── cert-manager/      # Certificate management
│   ├── ingress-nginx/     # Ingress controller
│   ├── monitoring/        # Prometheus stack
│   └── local-registry/    # Local container registry
├── kind/                  # KIND cluster configurations
└── src/                   # Application source code
    └── <app-name>/        # Application-specific code
```

## Best Practices

### GitOps

1. **Infrastructure as Code**
   - All infrastructure changes must be committed to Git
   - No manual changes to environments
   - Use Kustomize for environment-specific configurations

2. **Security**
   - Never commit secrets to the repository
   - Use Sealed Secrets or external secret management
   - Follow principle of least privilege
   - Regularly update dependencies

3. **Kubernetes**
   - Use namespaces for isolation
   - Set resource limits and requests
   - Implement proper health checks
   - Use labels and annotations consistently

4. **Testing**
   - Test locally before committing
   - Write defensive code with proper error handling
   - Include both positive and negative test cases

5. **Git Workflow**
   - Use feature branches for all changes
   - Keep PRs focused and small
   - Write clear commit messages
   - Rebase instead of merge when possible

## Troubleshooting

### Common Issues

1. **KIND cluster issues**

   ```bash
   # Restart a cluster
   kind delete cluster --name dev-cluster
   ./kind/setup-kind.sh dev
   ```

2. **Registry connectivity**

   ```bash
   # Check registry connection
   docker exec dev-cluster-control-plane crictl pull localhost:5000/test-image:latest
   ```

3. **Manifest validation failures**

   ```bash
   # Validate specific manifest
   kubeconform -kubernetes-version 1.25.0 apps/app1/base/deployment.yaml
   ```

4. **GitHub Actions failures**
   - Add `--validate=false` to kubectl commands
   - Check if KUBECONFIG secrets are properly formatted

### Getting Help

If you encounter issues not covered here:

1. Check existing GitHub issues
2. Join the project Discord/Slack channel
3. Reach out to maintainers

---

Thank you for contributing to the project! Your efforts help make this infrastructure better for everyone.
