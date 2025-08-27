#!/bin/bash

# Bootstrap ArgoCD App-of-Apps Infrastructure
# This script sets up the complete app-of-apps pattern

set -e

NAMESPACE="argocd"
REPO_URL="https://github.com/triplom/infrastructure-repo-argocd.git"

echo "🚀 Bootstrapping ArgoCD App-of-Apps Infrastructure..."

# Check if ArgoCD is installed
if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    echo "❌ ArgoCD namespace '$NAMESPACE' not found. Please install ArgoCD first."
    exit 1
fi

echo "✅ ArgoCD namespace found"

# Apply ArgoCD projects first
echo "📁 Creating ArgoCD projects..."
kubectl apply -f infrastructure/argocd/projects/

# Wait a moment for projects to be created
sleep 5

# Apply the root application
echo "🌳 Deploying root application..."
kubectl apply -f infrastructure/argocd/applications/root-new.yaml

echo "⏳ Waiting for root application to sync..."
sleep 10

# Check status
echo "📊 Checking application status..."
kubectl get applications -n $NAMESPACE

echo ""
echo "🎉 Bootstrap complete!"
echo ""
echo "🔍 To monitor progress:"
echo "  kubectl get applications -n $NAMESPACE -w"
echo ""
echo "🌐 To access ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"
echo "  Then visit: https://localhost:8080"
echo ""
echo "🔧 To sync all applications:"
echo "  argocd app sync --all"
echo ""
echo "📝 Applications will be deployed to the following namespaces:"
echo "  - app1-dev, app1-qa, app1-prod"
echo "  - app2-dev, app2-qa, app2-prod"
echo "  - monitoring"
echo "  - cert-manager"
echo "  - ingress-nginx"
