# ArgoCD HTTPS Implementation - Quick Reference Guide

This document provides a condensed reference for implementing ArgoCD with HTTPS support in a KIND cluster environment.

## Prerequisites Checklist

- [ ] KIND cluster running
- [ ] ingress-nginx installed
- [ ] cert-manager installed
- [ ] kubectl configured

## Installation Commands

### 1. Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.14.6/manifests/install.yaml

# Verify installation
kubectl get pods -n argocd
```

### 2. Configure Service

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}'
```

### 3. HTTPS Configuration

```bash
# Update ArgoCD ConfigMap
kubectl patch configmap argocd-cm -n argocd --patch='
data:
  url: "https://argocd.local"
  server.insecure: "false"
  application.instanceLabelKey: argocd.argoproj.io/instance'
```

### 4. Apply Certificates and Ingress

```bash
# Apply certificate configuration
kubectl apply -f infrastructure/argocd/argocd-certificate.yaml

# Apply HTTPS ingress
kubectl apply -f infrastructure/argocd/argocd-ingress-https.yaml

# Restart ArgoCD server
kubectl rollout restart deployment/argocd-server -n argocd
```

### 5. Access Setup

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forwarding for local access
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

## Access Information

- **URL**: `https://localhost:8443`
- **Username**: admin
- **Password**: (from step 5)

## File References

- `infrastructure/argocd/argocd-certificate.yaml` - TLS certificate configuration
- `infrastructure/argocd/argocd-ingress-https.yaml` - HTTPS ingress configuration
- `infrastructure/argocd/projects/` - ArgoCD project definitions
- `infrastructure/argocd/applications/` - Application definitions

## Validation Commands

```bash
# Check certificate status
kubectl get certificate argocd-server-tls -n argocd

# Check ingress
kubectl get ingress argocd-server-ingress -n argocd

# Check all applications
kubectl get applications -n argocd

# Check all pods
kubectl get pods --all-namespaces
```

## Troubleshooting

### Common Issues

1. **Port forwarding not working**: Check if process is running with `ps aux | grep port-forward`
2. **Certificate not ready**: Wait for cert-manager to generate certificate
3. **Ingress not accessible**: Verify ingress-nginx controller is running
4. **Application sync issues**: Check repository credentials and network connectivity

### Debug Commands

```bash
# ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Repository server logs
kubectl logs -n argocd deployment/argocd-repo-server

# Certificate status
kubectl describe certificate argocd-server-tls -n argocd

# Ingress events
kubectl get events -n argocd
```

This reference guide provides the essential steps for implementing ArgoCD with HTTPS support as documented in Chapter 5 of the thesis implementation.
