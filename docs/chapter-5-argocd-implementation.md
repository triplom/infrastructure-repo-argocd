# Chapter 5: Implementation - ArgoCD Installation and Configuration

## 5.1 Overview

This chapter details the complete implementation of ArgoCD as the pull-based GitOps continuous delivery tool for the thesis evaluation environment. The implementation covers installation, HTTPS configuration, and the app-of-apps pattern setup for managing Kubernetes applications across multiple environments.

## 5.2 Environment Setup

### 5.2.1 Prerequisites

- **Kubernetes Cluster**: KIND (Kubernetes in Docker) cluster for local development
- **kubectl CLI**: Configured to access the cluster
- **Helm**: For managing Kubernetes packages
- **cert-manager**: For TLS certificate management
- **ingress-nginx**: For ingress traffic routing

### 5.2.2 Cluster Preparation

```bash
# Create KIND cluster with ingress support
kind create cluster --name dev-cluster --config kind-cluster-config.yaml

# Install ingress-nginx controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
```

## 5.3 ArgoCD Installation

### 5.3.1 Namespace Creation

```bash
# Create dedicated namespace for ArgoCD
kubectl create namespace argocd
```

### 5.3.2 ArgoCD Deployment

Install ArgoCD using the official high-availability manifest:

```bash
# Install ArgoCD core components
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.14.6/manifests/install.yaml
```

### 5.3.3 Verification of Installation

```bash
# Verify all ArgoCD pods are running
kubectl get pods -n argocd

# Expected output should show:
# - argocd-application-controller (StatefulSet)
# - argocd-applicationset-controller (Deployment)
# - argocd-dex-server (Deployment)
# - argocd-notifications-controller (Deployment)
# - argocd-redis (Deployment)
# - argocd-repo-server (Deployment)
# - argocd-server (Deployment)
```

### 5.3.4 Service Configuration

Ensure ArgoCD server uses ClusterIP for ingress compatibility:

```bash
# Patch ArgoCD server service to use ClusterIP
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}'

# Verify service configuration
kubectl get svc argocd-server -n argocd
```

## 5.4 HTTPS Configuration for ArgoCD UI

### 5.4.1 ArgoCD Base Configuration

Configure ArgoCD with proper base URL and security settings:

```bash
# Update ArgoCD ConfigMap for HTTPS support
kubectl patch configmap argocd-cm -n argocd --patch='
data:
  url: "https://argocd.local"
  server.insecure: "false"
  oidc.config: |
    name: OIDC
    issuer: https://argocd.local/api/dex
    clientId: argo-cd
    clientSecret: $oidc.clientSecret
    requestedScopes: ["openid", "profile", "email", "groups"]
    requestedIDTokenClaims: {"groups": {"essential": true}}
  application.instanceLabelKey: argocd.argoproj.io/instance'
```

### 5.4.2 TLS Certificate Management

Create self-signed certificate issuer for local development environment:

```yaml
# File: infrastructure/argocd/argocd-certificate.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-server-tls
  namespace: argocd
spec:
  secretName: argocd-server-tls
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  commonName: argocd.local
  dnsNames:
  - argocd.local
  - localhost
  ipAddresses:
  - 127.0.0.1
```

Apply certificate configuration:

```bash
kubectl apply -f infrastructure/argocd/argocd-certificate.yaml
```

### 5.4.3 HTTPS Ingress Configuration

Create ingress resource for secure HTTPS access:

```yaml
# File: infrastructure/argocd/argocd-ingress-https.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    # Backend protocol is HTTPS
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    
    # SSL redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Enable gRPC for ArgoCD CLI
    nginx.ingress.kubernetes.io/grpc-backend: "true"
    
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - argocd.local
    secretName: argocd-server-tls
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

Apply ingress configuration:

```bash
kubectl apply -f infrastructure/argocd/argocd-ingress-https.yaml
```

### 5.4.4 Certificate Verification

```bash
# Check certificate status
kubectl get certificate argocd-server-tls -n argocd

# Verify ingress configuration
kubectl get ingress argocd-server-ingress -n argocd
```

### 5.4.5 Service Restart

Restart ArgoCD server to apply new configuration:

```bash
kubectl rollout restart deployment/argocd-server -n argocd

# Wait for deployment to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=60s
```

## 5.5 Access Configuration

### 5.5.1 Administrative Access

Retrieve the initial admin password:

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 5.5.2 Local Access Setup

For local development environment, establish port forwarding:

```bash
# Set up HTTPS port forwarding
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

### 5.5.3 Web UI Access

**Access Credentials:**

- **URL**: `https://localhost:8443`
- **Username**: `admin`
- **Password**: (retrieved from step 5.5.1)

### 5.5.4 CLI Access

Configure ArgoCD CLI for secure access:

```bash
# Login via CLI
argocd login localhost:8443 --username admin --password <admin-password> --insecure
```

## 5.6 Project and Repository Configuration

### 5.6.1 ArgoCD Projects Setup

Create projects for different application categories:

```bash
# Apply ArgoCD projects
kubectl apply -f infrastructure/argocd/projects/

# Projects created:
# - applications: For business applications (app1, app2)
# - infrastructure: For infrastructure services
# - monitoring: For monitoring stack
```

### 5.6.2 Repository Access Configuration

Configure GitHub repository access with authentication:

```bash
# Create repository credentials secret
kubectl create secret generic github-repo-creds \
  --from-literal=type=git \
  --from-literal=url=https://github.com/triplom/infrastructure-repo-argocd \
  --from-literal=username=triplom \
  --from-literal=password=<github-token> \
  -n argocd

# Label secret for ArgoCD recognition
kubectl label secret github-repo-creds -n argocd argocd.argoproj.io/secret-type=repository
```

## 5.7 App-of-Apps Pattern Implementation

### 5.7.1 Root Application Deployment

Deploy the root application that manages all app-of-apps:

```bash
# Apply root application
kubectl apply -f infrastructure/argocd/applications/root-new.yaml
```

### 5.7.2 Application Structure

The app-of-apps pattern implements three main categories:

1. **Applications App-of-Apps** (`app-of-apps/`):
   - Manages internal applications (app1, app2 from `src/` directory)
   - Manages external applications (k8s-web-app-php from GitHub)
   - Handles multi-environment deployments (dev/qa/prod)

2. **Infrastructure App-of-Apps** (`app-of-apps-infra/`):
   - Manages infrastructure services only
   - Includes cert-manager and ingress-nginx controllers
   - References infrastructure configurations from `infrastructure/` directory

3. **Monitoring App-of-Apps** (`app-of-apps-monitoring/`):
   - Manages complete monitoring stack via kube-prometheus-stack
   - Provides integrated Prometheus, Grafana, and Alertmanager
   - Configured for persistent storage and development access

## 5.8 Validation and Troubleshooting

### 5.8.1 System Validation

```bash
# Check all applications status
kubectl get applications -n argocd

# Check all pods across namespaces
kubectl get pods --all-namespaces

# Verify ingress functionality
kubectl get ingress --all-namespaces
```

### 5.8.2 Common Issues and Solutions

#### HTTPS Connectivity Problems

```bash
# Configure ArgoCD for development environment
kubectl patch configmap argocd-cm -n argocd --patch='
data:
  timeout.reconciliation: "300s"
  timeout.hard.reconciliation: "300s"
  server.insecure: "true"
  server.enable.grpc.web: "true"'
```

#### Network Policy Restrictions

```bash
# Temporarily remove network policies for development
kubectl delete networkpolicies --all -n argocd
```

#### Certificate Trust

- Accept self-signed certificate in browser for local development
- Use `--insecure` flag for CLI operations in development

## 5.9 Security Considerations

### 5.9.1 Development Environment

- Self-signed certificates are acceptable for local development
- Network policies can be relaxed for development environments
- Administrative access should be secured in production environments

### 5.9.2 Production Recommendations

- Use proper CA-signed certificates
- Implement network policies for pod-to-pod communication
- Configure SSO integration for authentication
- Set up RBAC for fine-grained access control

## 5.10 Implementation Summary

The ArgoCD implementation provides:

✅ **Secure HTTPS Access**: TLS-encrypted web UI and API access
✅ **App-of-Apps Pattern**: Hierarchical application management
✅ **Multi-Environment Support**: Development, QA, and production configurations
✅ **Automated Certificate Management**: cert-manager integration
✅ **GitOps Workflow**: Pull-based continuous deployment
✅ **CLI and Web Access**: Multiple interfaces for management

This implementation establishes the foundation for the pull-based GitOps evaluation in Chapter 6, providing a complete ArgoCD deployment with secure access and comprehensive application management capabilities.

## 5.11 Next Steps

Following this implementation:

1. **Application Deployment**: Deploy sample applications using the app-of-apps pattern
2. **CI/CD Integration**: Connect GitHub Actions for automated image builds
3. **Monitoring Setup**: Configure observability stack
4. **Performance Testing**: Prepare for Chapter 6 comparative analysis

The ArgoCD installation and HTTPS configuration provide the essential infrastructure for evaluating pull-based GitOps efficiency and reliability in the thesis research.
