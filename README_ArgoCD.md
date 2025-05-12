# Pull-Based GitOps with ArgoCD, KIND, and Prometheus Monitoring

<img src="gitops.png" alt="gitops" width="100" align="center"/> 

A complete implementation of pull-based GitOps using ArgoCD, KIND (Kubernetes IN Docker) clusters, and comprehensive monitoring through the kube-prometheus-stack.

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [Setting Up KIND Clusters](#setting-up-kind-clusters)
  - [GitHub Container Registry Setup](#github-container-registry-setup)
  - [GitHub Repository Setup](#github-repository-setup)
  - [Installing ArgoCD](#installing-argocd)
- [Repository Structure](#-repository-structure)
- [ArgoCD App-of-Apps Pattern](#-argocd-app-of-apps-pattern)
  - [Root Application](#root-application)
  - [Infrastructure Applications](#infrastructure-applications)
  - [Business Applications](#business-applications)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Monitoring & Observability](#-monitoring--observability)
  - [Accessing Dashboards](#accessing-dashboards)
  - [Metrics & Alerts](#metrics--alerts)
- [Multi-Environment Strategy](#-multi-environment-strategy)
- [Troubleshooting](#-troubleshooting)
- [Security Best Practices](#-security-best-practices)
- [Contributing](#-contributing)
- [License](#-license)

## 🌐 Overview

This repository implements a pull-based GitOps approach using ArgoCD to deploy infrastructure and applications to Kubernetes clusters. Unlike push-based GitOps solutions that trigger deployments through CI/CD pipelines, this approach uses ArgoCD controllers inside the cluster that continuously monitor Git repositories and reconcile the actual cluster state with the desired state defined in Git.

**Key Features:**

- Local KIND clusters for development, QA, and production environments
- Pull-based GitOps using ArgoCD for continuous reconciliation
- App-of-Apps pattern for managing complex deployments
- Comprehensive monitoring with Prometheus, Grafana, and AlertManager
- Multi-environment deployment strategy with proper separation of concerns
- Ingress management with cert-manager for SSL/TLS
- GitHub Container Registry for storing container images

## 🏛️ Architecture

![Architecture Diagram](KIND_CICD_flow.png)

The architecture consists of three main components:

1. **Source of Truth**: Git repositories containing infrastructure and application configurations
2. **CI Pipeline**: GitHub Actions workflows that build, test, and update image references
3. **CD Process**: ArgoCD running inside Kubernetes that detects changes and applies them

**Workflow:**

1. Developer commits code changes to the application repository
2. CI pipeline builds, tests, and pushes container image to GitHub Container Registry
3. CI pipeline updates the configuration repository with new image tag
4. ArgoCD continuously monitors the configuration repository
5. When changes are detected, ArgoCD pulls the new configuration
6. ArgoCD applies changes to the Kubernetes cluster
7. ArgoCD continuously reconciles cluster state with Git repository state

## 🧰 Prerequisites

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.24+)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (v0.20+)
- [Helm](https://helm.sh/docs/intro/install/) (v3.12+)
- [GitHub account](https://github.com/) with repository access
- [yq](https://github.com/mikefarah/yq) for YAML processing
- [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) (v2.7+)
- [GitHub CLI](https://cli.github.com/) (optional, for workflow triggering)

## 🚀 Getting Started

### Setting Up KIND Clusters

Clone the repository and run the KIND setup script:

```bash
git clone https://github.com/your-username/infrastructure-repo.git
cd infrastructure-repo
chmod +x kind/setup-kind.sh

# Create all clusters (dev, qa, prod)
./kind/setup-kind.sh

# Or create a specific environment
./kind/setup-kind.sh dev
```

This creates Kubernetes clusters based on your selection:

- `dev-cluster`: For development and testing
- `qa-cluster`: For quality assurance and pre-production
- `prod-cluster`: For production workloads

### GitHub Container Registry Setup

Set up the GitHub Container Registry authentication:

```bash
chmod +x infrastructure/github-registry/github-setup.sh

# Set GitHub credentials as environment variables
export GITHUB_USERNAME="your-username"
export GITHUB_TOKEN="your-personal-access-token"
export GITHUB_EMAIL="your-email@example.com"

# Run the GitHub Container Registry setup
./infrastructure/github-registry/github-setup.sh

# Verify setup
kubectl get secrets -n container-auth
```

### GitHub Repository Setup

1. Push the repository to GitHub
2. Configure GitHub Secrets for the CI process:
   - Go to your GitHub repository → Settings → Secrets and Variables → Actions
   - Add the following secrets:
     - `GITHUB_TOKEN`: Your GitHub personal access token with `packages:write` permission
     - `CONFIG_REPO_PAT`: Personal access token to update configuration repository

### Installing ArgoCD

Install ArgoCD on each cluster:

```bash
# Switch to the target cluster
kubectl config use-context kind-dev-cluster

# Create namespace for ArgoCD
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Get the initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Initial admin password: $ARGOCD_PASSWORD"

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access the ArgoCD UI at [https://localhost:8080](https://localhost:8080) with username: `admin` and the password from the previous command.

## 📂 Repository Structure

```bash
infrastructure-repo/
├── .github/workflows/         # GitHub Actions workflow definitions
│   └── ci-pipeline.yaml       # Build and push images to GitHub Container Registry
├── apps/                      # Application manifests
│   └── app1/                  # Sample application
│       ├── base/              # Base manifests
│       └── overlays/          # Environment-specific overlays
├── infrastructure/            # Infrastructure components
│   ├── argocd/                # ArgoCD configuration
│   │   ├── projects/          # ArgoCD projects
│   │   └── applications/      # ArgoCD applications
│   ├── cert-manager/          # TLS certificate management
│   ├── github-registry/       # GitHub Container Registry setup
│   ├── ingress-nginx/         # Ingress controller
│   └── monitoring/            # Prometheus & Grafana stack
├── kind/                      # KIND cluster configurations
│   ├── clusters/              # Cluster config files
│   └── setup-kind.sh          # Cluster creation script
└── src/                       # Application source code
```

## 🔄 ArgoCD App-of-Apps Pattern

The implementation uses ArgoCD's App-of-Apps pattern for managing complex deployments:

### Root Application

```bash
# Apply the root application
kubectl apply -f infrastructure/argocd/applications/root.yaml
```

This bootstraps ArgoCD to manage all other applications.

### Infrastructure Applications

Infrastructure components are defined in ArgoCD applications:

```bash
# View infrastructure applications
kubectl get applications -n argocd

# Check synchronization status
argocd app get infrastructure
```

Infrastructure includes:

- Cert-manager for TLS certificates
- NGINX Ingress Controller
- Monitoring stack with Prometheus and Grafana

### Business Applications

Business applications are deployed using the same pattern:

```bash
# Promote applications from development to QA
sed -i 's|include: "*/overlays/dev/kustomization.yaml"|include: "*/overlays/qa/kustomization.yaml"|g' infrastructure/argocd/applications/apps.yaml
git add .
git commit -m "Promote applications from DEV to QA"
git push

# ArgoCD automatically detects the change and updates the target environment
```

## 🔄 CI/CD Pipeline

The CI/CD pipeline consists of:

1. **CI Pipeline (GitHub Actions)**
   - Triggered on pushes to `main` and feature branches
   - Runs tests on application code
   - Builds Docker images and pushes to GitHub Container Registry
   - Updates application manifests with new image tags

2. **CD Process (ArgoCD)**
   - Continuously monitors the Git repository
   - Detects configuration changes
   - Applies changes to the Kubernetes cluster
   - Ensures the cluster state matches the desired state in Git
   - Provides self-healing capabilities through continuous reconciliation

## 📊 Monitoring & Observability

### Accessing Dashboards

After deployment, access the dashboards using ArgoCD or port-forwarding:

#### ArgoCD Dashboard

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Visit [https://localhost:8080](https://localhost:8080) in your browser

#### Grafana

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
```

Visit [http://localhost:3000](http://localhost:3000) in your browser (default credentials: admin/gitops-admin)

#### Prometheus

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
```

Visit [http://localhost:9090](http://localhost:9090) in your browser

### Metrics & Alerts

The monitoring stack includes:

- **System metrics**: CPU, memory, disk, network usage
- **Kubernetes metrics**: Pod status, deployment status
- **Application metrics**: Custom metrics exposed by applications
- **ArgoCD metrics**: Sync status, health status, reconciliation times
- **Pre-configured alerts**: High CPU/memory usage, pod crashes, sync failures

## 🌍 Multi-Environment Strategy

This repository follows a multi-environment strategy with ArgoCD:

1. **Development** (`dev`):
   - Fast iterations with automated synchronization
   - Minimal resources for development
   - Debug-level logging
   - Automatic synchronization with Git repository

2. **QA/Testing** (`qa`):
   - More resources for testing
   - More replicas for resilience testing
   - Integration tests
   - Manual promotion from development

3. **Production** (`prod`):
   - Maximum resources
   - Multiple replicas
   - Production-level logging
   - Stricter security settings
   - Required approvals for synchronization

## 🔍 Troubleshooting

### Common Issues

#### ArgoCD Application Not Syncing

1. Check if the application is properly defined: `argocd app get <app-name>`
2. Verify the Git repository is accessible: `argocd repo list`
3. Check for errors in the application: `kubectl logs -n argocd deploy/argocd-application-controller`
4. Force a sync if needed: `argocd app sync <app-name>`

#### Image Pulling Issues

1. Ensure the GitHub Container Registry secret is correctly set up:
```bash
kubectl get secret github-registry-secret -n container-auth -o yaml
```
2. Verify imagePullSecrets is correctly referenced in deployments
3. Check if the image exists in GHCR: `docker pull ghcr.io/your-username/app1:latest`

#### Monitoring Stack Issues

1. Verify the Helm release: `helm list -n monitoring`
2. Check Prometheus pods: `kubectl -n monitoring get pods | grep prometheus`
3. Check Grafana logs: `kubectl -n monitoring logs deploy/kube-prometheus-stack-grafana -c grafana`
4. Verify ConfigMaps are properly created: `kubectl -n monitoring get cm`

## 🔒 Security Best Practices

1. **Secure Secrets Management**:
   - Never commit kubeconfig files or credentials to the repository
   - Use GitHub Secrets for sensitive information
   - Consider tools like Sealed Secrets for Kubernetes secrets

2. **Access Control**:
   - Implement RBAC in ArgoCD with project restrictions
   - Set appropriate environment protections in GitHub
   - Require approvals for production deployments

3. **Container Security**:
   - Scan images for vulnerabilities
   - Use minimal base images
   - Don't run containers as root

4. **Network Security**:
   - Use network policies to restrict traffic
   - Expose services only when necessary
   - Configure proper TLS with cert-manager

5. **ArgoCD Security**:
   - Regularly update ArgoCD
   - Use SSO integration for authentication
   - Enable audit logging

## 👨‍💻 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-new-feature`
3. Make your changes and commit: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

Check the [CONTRIBUTING](docs/CONTRIBUTING.md) file for details

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This README describes a GitOps implementation where ArgoCD continuously synchronizes the desired state defined in your Git repository with the actual state in your Kubernetes clusters. For production use, consider additional security measures and proper CI/CD pipelines with appropriate approvals.