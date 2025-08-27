# ArgoCD App-of-Apps Infrastructure Repository

This repository implements the ArgoCD app-of-apps pattern for managing applications and infrastructure components. It serves as the control plane that references configurations from the external [infrastructure-repo](https://github.com/triplom/infrastructure-repo).

## Architecture Overview

This repository follows the app-of-apps pattern with the following structure:

```bash
├── root-app/                    # Root application managing all app-of-apps
├── app-of-apps/                 # Application deployments (app1, app2)
├── app-of-apps-monitoring/      # Monitoring stack (Prometheus, Grafana)
├── app-of-apps-infra/          # Infrastructure components (cert-manager, ingress-nginx)
└── infrastructure/argocd/       # ArgoCD configuration and projects
```

## App-of-Apps Pattern

### Root Application

The `root-app` manages three main app-of-apps:

- **app-of-apps**: Manages application deployments
- **app-of-apps-monitoring**: Manages monitoring stack
- **app-of-apps-infra**: Manages infrastructure components

### External Repository

All actual application and infrastructure definitions are stored in the external `infrastructure-repo`. This repository only contains:

- ArgoCD application definitions
- Helm charts for app-of-apps pattern
- Project definitions and RBAC

## Repository Structure

### app-of-apps/

Manages application deployments using ApplicationSets for multi-environment support:

- `app1`: Main application with dev/qa/prod environments
- `app2`: Secondary application with dev/qa/prod environments

### app-of-apps-monitoring/

Manages monitoring components:

- `prometheus`: Metrics collection
- `grafana`: Metrics visualization

### app-of-apps-infra/

Manages infrastructure components:

- `cert-manager`: SSL certificate management
- `ingress-nginx`: Ingress controller
- `monitoring`: Monitoring infrastructure

## Configuration

### Values

Each app-of-apps has its own `values.yaml` for configuration:

```yaml
# app-of-apps/values.yaml
argocd:
  app1:
    enabled: true
  app2:
    enabled: true
targetRepo: https://github.com/triplom/infrastructure-repo.git
```

### Enabling/Disabling Components

Components can be enabled or disabled by updating the respective values files:

```yaml
# app-of-apps-infra/values.yaml
argocd:
  certManager:
    enabled: true
  ingressNginx:
    enabled: true
  monitoring:
    enabled: false  # Disable monitoring infra
```

## Deployment

### Bootstrap ArgoCD

1. Install ArgoCD in your cluster
2. Apply the root application:

   ```bash
   kubectl apply -f infrastructure/argocd/applications/root-new.yaml
   ```

### Manual Application Management

Individual app-of-apps can be managed separately:

```bash
# Deploy applications only
kubectl apply -f root-app/templates/app-of-apps.yaml

# Deploy monitoring only
kubectl apply -f root-app/templates/app-of-apps-monitoring.yaml

# Deploy infrastructure only
kubectl apply -f root-app/templates/app-of-apps-infra.yaml
```

## CI/CD Integration

The CI/CD pipeline updates the external `infrastructure-repo` with new image tags. ArgoCD automatically detects changes and deploys applications accordingly.

### Environment-specific Deployments

The pipeline supports environment-specific deployments:

- `dev`: Development environment
- `qa`: Quality assurance environment  
- `prod`: Production environment

## Projects and RBAC

ArgoCD projects provide:

- **applications**: Manages app1 and app2 across all environments
- **monitoring**: Manages monitoring stack components
- **infrastructure**: Manages infrastructure components

## Benefits of This Architecture

1. **Separation of Concerns**: Configuration and control plane are separated
2. **Multi-Environment Support**: ApplicationSets provide easy multi-env deployments
3. **Centralized Management**: Single root app manages all components
4. **Security**: Project-based RBAC for different component types
5. **Scalability**: Easy to add new applications or infrastructure components
6. **GitOps**: All changes tracked through Git commits

## Adding New Applications

To add a new application:

1. Add application definition to `app-of-apps/templates/`
2. Update `app-of-apps/values.yaml`
3. Create application manifests in the external `infrastructure-repo`
4. Update the applications project if needed

## Troubleshooting

### Check Application Status

```bash
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd
```

### Check ApplicationSets

```bash
kubectl get applicationsets -n argocd
kubectl describe applicationset <appset-name> -n argocd
```

### Sync Applications

```bash
argocd app sync <app-name>
argocd app sync --all
```
