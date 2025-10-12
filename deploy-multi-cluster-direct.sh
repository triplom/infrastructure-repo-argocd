#!/bin/bash

# Comprehensive multi-cluster deployment script
# Deploys infrastructure and monitoring to all clusters

CLUSTERS=("kind-dev-cluster" "kind-qa-cluster" "kind-prod-cluster")
CURRENT_CLUSTER=$(kubectl config current-context)

echo "=== Multi-Cluster Infrastructure Deployment ==="
echo "Current cluster: $CURRENT_CLUSTER"
echo ""

# Deploy to each cluster
for cluster in "${CLUSTERS[@]}"; do
    echo "🚀 Deploying to cluster: $cluster"
    kubectl config use-context $cluster
    
    # Clean up local-path-storage if it exists
    echo "  - Cleaning up local-path-storage namespace..."
    kubectl delete namespace local-path-storage --ignore-not-found=true
    
    # Create necessary namespaces
    echo "  - Creating application namespaces..."
    for ns in cert-manager ingress-nginx monitoring; do
        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
    done
    
    # Deploy cert-manager
    echo "  - Deploying cert-manager..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    echo "  - Waiting for cert-manager to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-cainjector -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
    
    # Deploy cert-manager configuration
    echo "  - Applying cert-manager configuration..."
    kubectl apply -f infrastructure/cert-manager/
    
    # Deploy ingress-nginx using helm
    echo "  - Deploying ingress-nginx..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx > /dev/null 2>&1 || true
    helm repo update > /dev/null 2>&1
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --set controller.service.type=NodePort \
        --set controller.nodeSelector."ingress-ready"=true \
        --set controller.tolerations[0].key=node-role.kubernetes.io/control-plane \
        --set controller.tolerations[0].operator=Equal \
        --set controller.tolerations[0].effect=NoSchedule \
        --wait
    
    # Deploy monitoring stack
    echo "  - Deploying monitoring stack..."
    kubectl apply -f infrastructure/monitoring/base/
    
    echo "  ✅ Cluster $cluster deployment complete"
    echo ""
done

# Switch back to original cluster
kubectl config use-context $CURRENT_CLUSTER

echo "🎉 Multi-cluster deployment complete!"
echo ""
echo "Cluster status:"
for cluster in "${CLUSTERS[@]}"; do
    echo "  $cluster:"
    kubectl config use-context $cluster > /dev/null 2>&1
    echo "    - Namespaces: $(kubectl get namespaces --no-headers | wc -l)"
    echo "    - Running pods: $(kubectl get pods -A --no-headers | grep -c Running)"
    echo "    - Services: $(kubectl get services -A --no-headers | wc -l)"
done

kubectl config use-context $CURRENT_CLUSTER