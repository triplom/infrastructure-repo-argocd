# Makefile Usage Guide

This document provides instructions for using the Makefile to manage the GitOps infrastructure and deployment workflows.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Available Commands](#available-commands)
- [Common Workflows](#common-workflows)
- [Development Workflow](#development-workflow)
- [Cluster Management](#cluster-management)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before using the Makefile, ensure you have the following tools installed:

- Docker
- kubectl
- kind (Kubernetes in Docker)
- Git
- helm (v3+)
- GitHub Personal Access Token with `packages:read` and `packages:write` permissions

## Available Commands

View all available commands with:

```bash
make help
```

### Core Commands

| Command | Description |
| --- | --- |
| `make setup-clusters` | Create KIND clusters for all environments (dev, qa, prod) |
| `make setup-argocd` | Install ArgoCD on the current cluster |
| `make bootstrap-argocd` | Bootstrap ArgoCD with the root application |
| `make get-argocd-password` | Get the ArgoCD admin password |
| `make port-forward-argocd` | Port forward ArgoCD UI to localhost:8080 |
| `make build-app` | Build and push app1 Docker image |
| `make clean-clusters` | Delete all KIND clusters |

### Infrastructure Commands

| Command | Description |
| --- | --- |
| `make setup-infra` | Install all infrastructure components |
| `make setup-ingress` | Install ingress controller |
| `make setup-cert-manager` | Install cert-manager |
| `make setup-monitoring` | Install monitoring stack |
| `make setup-registry` | Configure GitHub Container Registry access |

### Application Commands

| Command | Description |
| --- | --- |
| `make port-forward-app` | Port forward app1 to localhost:8081 |
| `VERSION=v1.0.0 make update-image` | Update app1 image to specified version |

### Monitoring Commands

| Command | Description |
| --- | --- |
| `make port-forward-grafana` | Port forward Grafana to localhost:3000 |

## Common Workflows

### Initial Setup

To set up the entire infrastructure from scratch:

```bash
# Create all clusters
make setup-clusters

# Switch to dev cluster
kubectl config use-context kind-dev-cluster

# Install all infrastructure components
make setup-infra

# Bootstrap ArgoCD
make bootstrap-argocd

# Get the ArgoCD admin password
make get-argocd-password

# Access ArgoCD UI (in a separate terminal)
make port-forward-argocd
```

### Container Registry Setup

To configure access to the GitHub Container Registry:

```bash
# Provide your GitHub Personal Access Token
GITHUB_PAT=your_github_token make setup-registry
```

## Development Workflow

### Building and Updating Applications

```bash
# Build and push the latest version of app1
make build-app

# Build and push a specific version
VERSION=v1.2.3 make update-image
```

### Testing Applications

```bash
# Port forward the application to test locally
make port-forward-app

# Access the application at http://localhost:8081
```

### Viewing Deployment Status

```bash
# Access ArgoCD UI to monitor deployment status
make port-forward-argocd

# Open http://localhost:8080 in your browser
# Login with username: admin, password: (from get-argocd-password)
```

## Cluster Management

### Working with Different Clusters

```bash
# Switch to development cluster
kubectl config use-context kind-dev-cluster

# Switch to QA cluster
kubectl config use-context kind-qa-cluster

# Switch to production cluster
kubectl config use-context kind-prod-cluster
```

### Cleaning Up

```bash
# Delete all KIND clusters
make clean-clusters
```

## Monitoring

### Accessing Dashboards

```bash
# Port forward Grafana
make port-forward-grafana

# Access Grafana at http://localhost:3000
# Default credentials: admin/prom-operator
```

## Troubleshooting

### Container Registry Access Issues

If you encounter authentication errors with the GitHub Container Registry:

```bash
# Ensure your PAT has the required permissions
GITHUB_PAT=your_updated_token make setup-registry
```

### ArgoCD Connection Issues

If ArgoCD can't connect to the Git repository:

1. Check your Git credentials are correctly configured
2. Verify that ArgoCD has the necessary permissions
3. Check the ArgoCD logs:

   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
   ```

### Application Not Deploying

If your application isn't deploying:

1. Check the application status in ArgoCD UI
2. Verify the image exists in the container registry
3. Check for any errors in the application logs:

   ```bash
   kubectl logs -n app1-dev -l app=app1
   ```

### Cluster Creation Failures

If cluster creation fails:

1. Ensure Docker has sufficient resources allocated
2. Check if Docker is running properly
3. Try creating clusters individually:

   ```bash
   kind create cluster --name dev-cluster --config kind/clusters/dev-cluster-config.yaml
   ```

---
