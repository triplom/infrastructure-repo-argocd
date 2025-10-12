#!/bin/bash

# Multi-cluster ArgoCD access script
# Provides access to all ArgoCD UIs with passwords

echo "=== Multi-Cluster ArgoCD Access ==="
echo ""

# Kill existing port-forwards
echo "🧹 Cleaning up existing ArgoCD port-forwards..."
pkill -f "port-forward.*svc/argocd-server" || true
sleep 2

# Start port-forwards for each cluster
echo "🚀 Starting ArgoCD UI access for all clusters..."

# Dev cluster (port 8080)
kubectl config use-context kind-dev-cluster > /dev/null 2>&1
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
DEV_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "Not ready")

# QA cluster (port 8081)
kubectl config use-context kind-qa-cluster > /dev/null 2>&1
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &
QA_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "Not ready")

# Prod cluster (port 8082)
kubectl config use-context kind-prod-cluster > /dev/null 2>&1 
kubectl port-forward svc/argocd-server -n argocd 8082:443 > /dev/null 2>&1 &
PROD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "Not ready")

# Wait for services to start
sleep 5

echo ""
echo "🎉 ArgoCD UIs are now accessible:"
echo ""
echo "🔧 Development Cluster:"
echo "   URL:      https://localhost:8080"
echo "   Username: admin" 
echo "   Password: $DEV_PASSWORD"
echo ""
echo "🧪 QA Cluster:"
echo "   URL:      https://localhost:8081"
echo "   Username: admin"
echo "   Password: $QA_PASSWORD"
echo ""
echo "🏭 Production Cluster:"
echo "   URL:      https://localhost:8082"
echo "   Username: admin"
echo "   Password: $PROD_PASSWORD"
echo ""
echo "📝 Notes:"
echo "   - Accept self-signed certificates in your browser"
echo "   - Dev cluster has 19 applications (full GitOps demo)"
echo "   - QA/Prod clusters have infrastructure ready for deployments"
echo ""
echo "To stop all ArgoCD port-forwards:"
echo "   pkill -f 'port-forward.*svc/argocd-server'"
echo ""

# Show active processes
echo "Active ArgoCD port-forward processes:"
ps aux | grep "port-forward.*svc/argocd-server" | grep -v grep

# Switch back to dev cluster
kubectl config use-context kind-dev-cluster > /dev/null 2>&1