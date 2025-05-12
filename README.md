# Push-Based GitOps with KIND and Prometheus Monitoring

<img src="gitops.png" alt="gitops" width="100" align="center"/> 

A complete implementation of push-based GitOps using KIND (Kubernetes IN Docker) clusters with comprehensive monitoring through the kube-prometheus-stack.

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [Setting Up KIND Clusters](#setting-up-kind-clusters)
  - [Local Registry Configuration](#local-registry-configuration)
  - [GitHub Repository Setup](#github-repository-setup)
- [Repository Structure](#-repository-structure)
- [Deployment Workflows](#-deployment-workflows)
  - [Infrastructure Deployment](#infrastructure-deployment)
  - [Monitoring Stack Deployment](#monitoring-stack-deployment)
  - [Application Deployment](#application-deployment)
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

This repository implements a push-based GitOps approach using GitHub Actions to deploy infrastructure and applications to Kubernetes clusters. Unlike pull-based GitOps solutions (like ArgoCD or Flux), this approach triggers deployments through CI/CD pipelines when changes are detected in the Git repository.

**Key Features:**

- Local KIND clusters for development, QA, and production environments
- Push-based GitOps using GitHub Actions workflows
- Comprehensive monitoring with Prometheus, Grafana, and AlertManager
- Multi-environment deployment strategy with proper separation of concerns
- Ingress management with cert-manager for SSL/TLS
- GitHub Container Registry for storing container images

## 🏛️ Architecture

![Architecture Diagram](KIND_CICD_flow.png)

The architecture consists of three main components:

1. **Source of Truth**: Git repository containing infrastructure and application configurations
2. **CI/CD Pipeline**: GitHub Actions workflows that detect changes and apply them
3. **Runtime**: KIND clusters running in Docker containers

**Workflow:**

1. Developer commits changes to the repository
2. GitHub Actions detects changes and triggers appropriate workflows
3. CI/CD pipeline applies changes to the appropriate environment
4. Monitoring stack collects metrics and displays them in Grafana

## 🧰 Prerequisites

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.24+)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (v0.20+)
- [Helm](https://helm.sh/docs/intro/install/) (v3.12+)
- [GitHub account](https://github.com/) with repository access
- [yq](https://github.com/mikefarah/yq) for YAML processing
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

# Force recreation of clusters
./kind/setup-kind.sh --force
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
2. Configure GitHub Secrets for cluster access
   - Go to your GitHub repository → Settings → Secrets and Variables → Actions
   - Add the following secrets:
     - `KUBECONFIG_DEV`: Base64-encoded kubeconfig for dev cluster
     - `KUBECONFIG_QA`: Base64-encoded kubeconfig for QA cluster
     - `KUBECONFIG_PROD`: Base64-encoded kubeconfig for production cluster

   To encode your kubeconfig files:

```bash
# Linux
base64 -w 0 dev-cluster-kubeconfig > dev-cluster-kubeconfig-base64.txt

# macOS
base64 -i dev-cluster-kubeconfig -o dev-cluster-kubeconfig-base64.txt

# Copy the contents of dev-cluster-kubeconfig-base64.txt to the KUBECONFIG_DEV secret
```

## 📂 Repository Structure

```bash
infrastructure-repo/
├── .github/workflows/         # GitHub Actions workflow definitions
│   ├── ci-pipeline.yaml       # Build and test applications
│   ├── deploy-apps.yaml       # Deploy applications to clusters
│   ├── deploy-infrastructure.yaml # Deploy core infrastructure
│   └── deploy-monitoring.yaml # Deploy monitoring stack
├── apps/                      # Application manifests
│   └── app1/                  # Sample application
│       ├── base/              # Base manifests
│       └── overlays/          # Environment-specific overlays
├── infrastructure/            # Infrastructure components
│   ├── cert-manager/          # TLS certificate management
│   ├── ingress-nginx/         # Ingress controller
│   ├── monitoring/            # Prometheus & Grafana stack
│   └── github-registry/       # GitHub Container Registry setup
├── kind/                      # KIND cluster configurations
│   ├── clusters/              # Cluster config files
│   ├── setup-kind.sh          # Cluster creation script
│   └── monitoring-stack.sh    # Monitoring deployment script
└── src/                       # Application source code
```

## 🔄 Deployment Workflows

### Infrastructure Deployment

Deploy core infrastructure components:

```bash
# Manual trigger through GitHub UI
# Go to Actions → Deploy Infrastructure → Run workflow

# Or from command line (requires GitHub CLI)
gh workflow run deploy-infrastructure.yaml --ref main -F environment=dev -F component=all

# Deploy specific components
gh workflow run deploy-infrastructure.yaml --ref main -F environment=dev -F component=cert-manager
gh workflow run deploy-infrastructure.yaml --ref main -F environment=dev -F component=ingress-nginx
```

### Monitoring Stack Deployment

Deploy the Prometheus monitoring stack:

```bash
# Manual trigger
gh workflow run deploy-monitoring.yaml --ref main -F environment=dev
```

This deploys:

- Prometheus for metrics collection
- Grafana for visualization
- AlertManager for alerts
- Node Exporter and Kube State Metrics for enhanced monitoring

### Application Deployment

Deploy sample applications:

```bash
# Deploy all applications to dev
gh workflow run deploy-apps.yaml --ref main -F environment=dev

# Deploy a specific application to qa
gh workflow run deploy-apps.yaml --ref main -F environment=qa -F application=app1
```

## 🔄 CI/CD Pipeline

The CI/CD pipeline consists of several workflows:

1. **CI Pipeline (`ci-pipeline.yaml`)**
   - Triggered on pushes to `main` and feature branches
   - Runs tests on application code
   - Builds Docker images and pushes to registry
   - Updates application manifests with new image tags

2. **Application Deployment (`deploy-apps.yaml`)**
   - Deploys applications to Kubernetes clusters
   - Can deploy specific applications or all applications
   - Supports different environments (dev/qa/prod)

3. **Infrastructure Deployment (`deploy-infrastructure.yaml`)**
   - Deploys core infrastructure components
   - Manages cert-manager and ingress-nginx
   - Support for multiple environments

4. **Monitoring Stack Deployment (`deploy-monitoring.yaml`)**
   - Deploys Prometheus, Grafana, and AlertManager
   - Configures dashboards and alerting rules
   - Environment-specific configurations

## 📊 Monitoring & Observability

### Accessing Dashboards

After deployment, access the dashboards using port-forwarding:

#### Grafana

```bash
# Using the service
kubectl --context kind-dev-cluster -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

# Direct pod access (if service access fails)
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kube-prometheus-stack" -oname)
kubectl --namespace monitoring port-forward $POD_NAME 3000
```

Then visit <http://localhost:3000> in your browser (default credentials: admin/gitops-admin)

#### Prometheus

```bash
kubectl --context kind-dev-cluster -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Then visit <http://localhost:9090> in your browser

#### AlertManager

```bash
kubectl --context kind-dev-cluster -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
```

Then visit <http://localhost:9093> in your browser

### Metrics & Alerts

The monitoring stack includes:

- **System metrics**: CPU, memory, disk, network usage
- **Kubernetes metrics**: Pod status, deployment status
- **Application metrics**: Custom metrics exposed by applications
- **Pre-configured alerts**: High CPU/memory usage, pod crashes, etc.

## 🌍 Multi-Environment Strategy

This repository follows a multi-environment strategy:

1. **Development** (`dev`):
   - Fast deployments
   - Minimal resources
   - Debug-level logging
   - Automatic deployments on main branch changes

2. **QA/Testing** (`qa`):
   - More resources for testing
   - More replicas for resilience testing
   - Integration tests
   - Manual approval for deployments

3. **Production** (`prod`):
   - Maximum resources
   - Multiple replicas
   - Production-level logging
   - Stricter security settings
   - Required approvals for deployments

## 🔍 Troubleshooting

### Common Issues

#### Workflow Failure

1. Check if the kubeconfig secrets are properly configured
2. Verify the cluster is running with `kind get clusters`
3. Check workflow logs in GitHub Actions
4. Add `--validate=false` to kubectl commands in CI/CD environments
5. Verify namespace exists before deploying resources

#### Image Pulling Issues

1. Ensure the local registry is running: `docker ps | grep registry`
2. Check if the image exists: `docker images | grep app1`
3. Verify registry connectivity from clusters: `curl -X GET http://localhost:5000/v2/_catalog`
4. Check if container runtime is configured correctly: `docker exec <node-name> cat /etc/containerd/certs.d/localhost:5000/hosts.toml`

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
   - Use least privilege principle for CI/CD workflows
   - Set appropriate environment protections in GitHub
   - Implement proper approvals for production deployments

3. **Container Security**:
   - Scan images for vulnerabilities
   - Use minimal base images
   - Don't run containers as root

4. **Network Security**:
   - Use network policies to restrict traffic
   - Expose services only when necessary
   - Configure proper TLS with cert-manager

## 👨‍💻 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-new-feature`
3. Make your changes and commit: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

For local development, you can use the provided scripts:

```bash
# Setup development environment
./kind/setup-kind.sh dev
./infrastructure/local-registry/setup-registry.sh

# Validate code
# Install pre-commit hooks for validation
pip install pre-commit
pre-commit install
```

Check the [CONTRIBUTING](docs/CONTRIBUTING.md) file for details

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This documentation assumes you're using the repository locally or in a private GitHub repository. For production use, consider additional security measures and proper CI/CD pipelines with appropriate approvals.
