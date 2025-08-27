#!/bin/bash

# Cleanup ArgoCD App-of-Apps Infrastructure
# This script removes all applications managed by the app-of-apps pattern

set -e

NAMESPACE="argocd"

echo "🧹 Cleaning up ArgoCD App-of-Apps Infrastructure..."

# Remove root application (this will cascade delete all child applications)
echo "🗑️  Removing root application..."
kubectl delete -f infrastructure/argocd/applications/root-new.yaml --ignore-not-found=true

# Wait for cascading deletion
echo "⏳ Waiting for applications to be removed..."
sleep 15

# Remove any remaining applications
echo "🔍 Checking for remaining applications..."
APPS=$(kubectl get applications -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" 2>/dev/null | grep -E "(app-of-apps|app1|app2|prometheus|grafana|cert-manager|ingress-nginx|monitoring)" || true)

if [ ! -z "$APPS" ]; then
    echo "🗑️  Removing remaining applications..."
    echo "$APPS" | xargs -I {} kubectl delete application {} -n $NAMESPACE --ignore-not-found=true
fi

# Remove application namespaces (optional - uncomment if needed)
# echo "🗑️  Removing application namespaces..."
# kubectl delete namespace app1-dev app1-qa app1-prod --ignore-not-found=true
# kubectl delete namespace app2-dev app2-qa app2-prod --ignore-not-found=true
# kubectl delete namespace monitoring --ignore-not-found=true
# kubectl delete namespace cert-manager --ignore-not-found=true
# kubectl delete namespace ingress-nginx --ignore-not-found=true

echo "✅ Cleanup complete!"
echo ""
echo "📊 Remaining applications:"
kubectl get applications -n $NAMESPACE 2>/dev/null || echo "No applications found"
