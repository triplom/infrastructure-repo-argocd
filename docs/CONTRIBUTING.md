# Contributing Guide

## Development Workflow

1. **Setup local environment**

   ```bash
   make setup-dev
   make setup-registry
   ```

2. **Make changes and test**

   ```bash
   make test-app
   make validate-manifests
   ```

3. **Deploy your changes**

   ```bash
   make deploy-dev
   ```

4. **Submit PR**
   Ensure CI passes before requesting review.

## Repository Structure

- `apps/`: Kubernetes manifests for applications
- `infrastructure/`: Infrastructure components
- `src/`: Application source code
- `kind/`: Local Kubernetes cluster configuration

## Best Practices

1. Use Kustomize for environment-specific configs
2. Keep secrets out of the repository
3. Test locally before committing
4. Use feature branches and PRs for changes
