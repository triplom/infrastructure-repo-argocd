#!/bin/bash

# Fix ArgoCD installation on QA and Prod clusters
# Complete reinstallation with proper configuration

CLUSTERS=("kind-qa-cluster" "kind-prod-cluster")

echo "=== Fixing ArgoCD on QA and Prod Clusters ==="

for cluster in "${CLUSTERS[@]}"; do
    echo ""
    echo "🔧 Fixing ArgoCD on: $cluster"
    kubectl config use-context $cluster
    
    # Force delete ArgoCD namespace
    echo "  - Removing existing ArgoCD installation..."
    kubectl delete namespace argocd --ignore-not-found=true --force --grace-period=0
    
    # Wait for namespace deletion
    echo "  - Waiting for namespace deletion..."
    while kubectl get namespace argocd >/dev/null 2>&1; do
        echo "    Waiting for argocd namespace to be deleted..."
        sleep 5
    done
    
    # Clean install ArgoCD
    echo "  - Installing ArgoCD fresh..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f infrastructure/argocd/base/
    
    # Wait for ArgoCD to be ready
    echo "  - Waiting for ArgoCD pods to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s || true
    
    # Apply projects
    echo "  - Applying ArgoCD projects..."
    kubectl apply -f infrastructure/argocd/projects/
    
    # Check status
    echo "  - Checking ArgoCD status..."
    kubectl get pods -n argocd | grep -E "(argocd-server|argocd-application-controller)"
    
    echo "  ✅ ArgoCD setup complete for $cluster"
done

echo ""
echo "🎉 ArgoCD fix complete!"
echo ""
echo "Get admin passwords:"
for cluster in "${CLUSTERS[@]}"; do
    echo "  $cluster:"
    kubectl config use-context $cluster
    password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "Not ready yet")
    echo "    Password: $password"
done

kubectl config use-context kind-dev-cluster