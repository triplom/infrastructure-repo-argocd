#!/bin/bash

# Multi-cluster ArgoCD setup script
# Configures SSH keys, GHCR secrets, and bootstrap ArgoCD on all clusters

CLUSTERS=("kind-dev-cluster" "kind-qa-cluster" "kind-prod-cluster")

echo "=== Multi-Cluster ArgoCD Configuration ==="
echo "Configuring SSH keys and secrets for all clusters..."

for cluster in "${CLUSTERS[@]}"; do
    echo ""
    echo "🔧 Configuring cluster: $cluster"
    kubectl config use-context $cluster
    
    # Apply SSH repository secret
    echo "  - Applying SSH repository secret..."
    kubectl apply -f infrastructure/argocd/ssh/argocd-ssh-repo-secret.yaml
    
    # Apply ArgoCD projects
    echo "  - Applying ArgoCD projects..."
    kubectl apply -f infrastructure/argocd/projects/
    
    # Create GHCR secrets for all namespaces
    echo "  - Creating GHCR secrets for application namespaces..."
    for ns in app1-dev app1-qa app1-prod app2-dev app2-qa app2-prod container-auth; do
        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
        kubectl create secret docker-registry github-registry \
            --docker-server=ghcr.io \
            --docker-username=triplom \
            --docker-password=${GITHUB_TOKEN:-ghp_YOUR_TOKEN_HERE} \
            --namespace=$ns \
            --dry-run=client -o yaml | kubectl apply -f -
    done
    
    # Bootstrap ArgoCD with root application
    echo "  - Bootstrapping ArgoCD..."
    make bootstrap-argocd
    
    echo "  ✅ Cluster $cluster configured successfully"
done

echo ""
echo "🎉 Multi-cluster setup complete!"
echo ""
echo "Access ArgoCD UIs:"
echo "  Dev cluster:  kubectl config use-context kind-dev-cluster && kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  QA cluster:   kubectl config use-context kind-qa-cluster && kubectl port-forward svc/argocd-server -n argocd 8081:443"
echo "  Prod cluster: kubectl config use-context kind-prod-cluster && kubectl port-forward svc/argocd-server -n argocd 8082:443"
echo ""
echo "Get admin passwords:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"