# ArgoCD GitOps Infrastructure - AI Agent Instructions

## Architecture Overview

This is a **pull-based GitOps** repository implementing ArgoCD's **App-of-Apps pattern** for a master's thesis comparing GitOps efficiency. The repository manages Kubernetes workloads across multiple KIND clusters using ArgoCD for continuous deployment.

### Key Components
- **Root App**: `root-app/` - Top-level ArgoCD application managing three app-of-apps
- **App-of-Apps Pattern**: Three separate Helm charts managing different concerns:
  - `app-of-apps/` - Business applications (app1, app2)
  - `app-of-apps-infra/` - Infrastructure services (cert-manager, ingress-nginx)
  - `app-of-apps-monitoring/` - Monitoring stack (prometheus, grafana)
- **Applications**: `apps/` - Kustomize-based apps with base + overlays per environment
- **Infrastructure**: `infrastructure/` - Core cluster services and ArgoCD configuration

## Critical Workflows

### Development Workflow
```bash
# Set up complete environment
make setup-clusters        # Creates kind-dev/qa/prod-cluster
make setup-argocd          # Installs ArgoCD
make bootstrap-argocd      # Deploys root-app which creates all app-of-apps
make get-argocd-password   # Gets admin password for UI access
```

### CI/CD Pipeline Pattern
The `.github/workflows/ci-pipeline.yaml` implements a **GitOps configuration update pattern**:
1. Build container images → Push to GHCR (`ghcr.io/triplom/app1:latest`)
2. Update Kustomize image references in `apps/*/base/deployment.yaml`
3. ArgoCD detects Git changes and deploys automatically

**Key workflow dispatch inputs**: `environment` (dev/qa/prod), `component` (all/app1/app2)

### Multi-Environment Strategy
- **Kustomize Structure**: `apps/{app}/base/` + `apps/{app}/overlays/{env}/`
- **KIND Clusters**: `kind-dev-cluster`, `kind-qa-cluster`, `kind-prod-cluster`
- **Environment-specific**: Resource limits, replica counts, ingress hosts

## Project-Specific Patterns

### ArgoCD App-of-Apps Hierarchy & Validation
```
root-app (ArgoCD Application) - Bootstrap entry point
├── app-of-apps (Helm) → Business Applications
│   ├── app1 (Kustomize) → GHCR image + multi-env overlays  
│   └── app2 (Kustomize) → GHCR image + multi-env overlays
├── app-of-apps-infra (Helm) → Infrastructure Services
│   ├── cert-manager → TLS certificate automation
│   ├── ingress-nginx → Traffic routing
│   └── github-registry → GHCR authentication
└── app-of-apps-monitoring (Helm) → Observability Stack
    ├── prometheus → Metrics collection
    ├── grafana → Dashboard visualization  
    └── alertmanager → Alert routing
```

**Validation Commands**:
```bash
# Verify app-of-apps deployment order and dependencies
kubectl get applications -n argocd --sort-by=.metadata.creationTimestamp
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
# Test cascading updates: root-app → app-of-apps → individual applications
```

### Application Structure Convention
```
apps/{app-name}/
├── base/                    # Base Kustomize resources
│   ├── deployment.yaml     # GHCR image references
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/{env}/         # Environment-specific patches
    ├── kustomization.yaml  # References ../base
    └── deployment-patch.yaml
```

### Repository References
- **Main Config Repo**: This repository (infrastructure-repo-argocd)
- **External Infrastructure**: `/home/marcel/ISCTE/THESIS/push-based/infrastructure-repo`  
- **External PHP App**: `/home/marcel/sfs-sca-projects/kubernetes-nginx-phpfpm-app`
- **Reference Implementation**: `/home/marcel/Descomplicando_ArgoCD/descomplicando-gitops-no-kubernetes-argocd`

## Integration Points

### GitHub Container Registry (GHCR)
- Images: `ghcr.io/triplom/{app}:latest`
- Authentication: `infrastructure/github-registry/github-setup.sh`
- Secrets: `GITHUB_TOKEN`, `CONFIG_REPO_PAT` in GitHub Actions

### Cross-Repository Updates
External repositories trigger updates to this config repository via GitHub Actions using `CONFIG_REPO_PAT` token to update image references.

### ArgoCD Management
- **Bootstrap Script**: `bootstrap.sh` - Sets up initial root application
- **Sync Scripts**: `argocd-sync-resolver.sh`, `validate-argocd-system.sh`
- **Multi-repo Testing**: `test-complete-multi-repo-pipeline.sh`

## Academic Context Notes

### Thesis Research Focus: Pull-Based vs Push-Based GitOps Efficiency

**Current Phase**: Chapter 6 Evaluation (Pull-Based Scenario with ArgoCD)

#### Key Research Questions to Validate:
1. **Efficiency**: How does ArgoCD's pull-based approach compare to push-based deployment times?
2. **Reliability**: Does continuous reconciliation improve system reliability vs event-driven pushes?
3. **Scalability**: How does app-of-apps pattern handle multi-repository, multi-environment complexity?
4. **Resource Usage**: ArgoCD controller overhead vs push-based agent resource consumption

#### Evaluation Requirements:
- **Reproducible Test Environment**: KIND clusters must be consistently recreatable
- **Measurable Metrics**: Capture deployment times, resource usage, failure rates
- **Comparative Analysis**: Same applications/infrastructure tested in both GitOps approaches
- **Documentation**: All test results feed into Chapter 6 evaluation analysis

#### Implementation Validation (Chapter 5 Review):
When working on this codebase:
- Preserve the app-of-apps pattern demonstrating ArgoCD's hierarchical management
- Maintain clear separation between infrastructure/monitoring/applications  
- Keep KIND cluster setup simple for academic reproducibility
- Document all architectural decisions that impact GitOps efficiency comparison
- Ensure pipeline scripts capture performance metrics for thesis evaluation

## Testing Patterns & Evaluation Scenarios

### Chapter 6 Evaluation - Pull-Based GitOps Testing
The following test scenarios validate ArgoCD's pull-based GitOps efficiency vs push-based approaches:

#### End-to-End Infrastructure Testing
```bash
# Complete cluster recreation and deployment pipeline
./test-complete-setup.sh                    # Full KIND cluster + ArgoCD setup
./test-complete-cicd-pipeline.sh           # Single repository CI/CD validation
./test-complete-multi-repo-pipeline.sh     # Multi-repository GitOps validation
./quick-multi-repo-status.sh               # Cross-repository sync validation
```

#### App-of-Apps Pattern Validation
```bash
# Bootstrap and validate hierarchical deployment
make bootstrap-argocd                       # Deploy root-app → triggers app-of-apps
./validate-argocd-system.sh               # Verify all applications sync properly
./argocd-sync-resolver.sh                 # Fix any sync conflicts
```

#### Automated Deployment (CD) Testing
- **Application Changes**: Trigger builds from `src/app1/`, `src/app2/` → GHCR → ArgoCD sync
- **Infrastructure Changes**: Updates to `infrastructure/` → ArgoCD infrastructure apps
- **External Repository Integration**: PHP app updates → Config repo updates → ArgoCD deployment
- **Multi-Environment Progression**: dev → qa → prod promotion workflows

#### Performance & Efficiency Metrics
- **Deployment Time**: Time from Git commit to running pods
- **Sync Frequency**: ArgoCD polling vs webhook-triggered deployments  
- **Resource Utilization**: ArgoCD controller overhead vs push-based agents
- **Failure Recovery**: Self-healing capabilities and drift detection

### Pipeline Automation Requirements
All scripts must handle:
- KIND cluster recreation with persistent configs
- GHCR authentication and image pull secrets
- Cross-repository token management (`CONFIG_REPO_PAT`)
- ArgoCD application dependency ordering
- Environment-specific overlay deployment

### Academic Documentation Integration

#### Chapter 6 Evaluation Focus
When testing, document:
- **Pull-based Benefits**: Continuous reconciliation, drift detection, declarative state
- **Comparison Metrics**: Deploy time, resource usage, complexity vs push-based
- **App-of-Apps Efficiency**: Hierarchical management vs flat application deployment
- **Multi-Repository Orchestration**: External app integration patterns

#### Chapter 5 Implementation Validation  
Scripts should demonstrate:
- **GitOps Principles**: Git as single source of truth, declarative configuration
- **ArgoCD Architecture**: Controller pattern, sync policies, health checks
- **Kustomize Integration**: Base + overlay pattern, environment promotion
- **CI/CD Integration**: Image builds → manifest updates → automatic deployment

When modifying this codebase for thesis evaluation, ensure all test scenarios are reproducible and measure the key efficiency metrics comparing pull-based (ArgoCD) vs push-based GitOps approaches.