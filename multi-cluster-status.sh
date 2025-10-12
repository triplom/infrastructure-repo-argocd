#!/bin/bash

# Multi-cluster status and access script for Chapter 6 testing

CLUSTERS=("kind-dev-cluster" "kind-qa-cluster" "kind-prod-cluster")
PORTS=(8080 8081 8082)

echo "=================================================="
echo "    MULTI-CLUSTER GITOPS STATUS"
echo "    Chapter 6 - Pull-Based GitOps Evaluation"
echo "=================================================="
echo "Timestamp: $(date)"
echo ""

# Check cluster status
echo "=== Cluster Status ==="
for cluster in "${CLUSTERS[@]}"; do
    if kubectl config get-contexts | grep -q "$cluster"; then
        echo "✅ ${cluster}: Available"
    else
        echo "❌ ${cluster}: Not found"
    fi
done
echo ""

# ArgoCD application status per cluster
for i in "${!CLUSTERS[@]}"; do
    cluster="${CLUSTERS[$i]}"
    port="${PORTS[$i]}"
    
    echo "=== ${cluster} ArgoCD Status ==="
    kubectl config use-context $cluster > /dev/null 2>&1
    
    # Check if ArgoCD is running
    argocd_pods=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
    if [ "$argocd_pods" -gt 0 ]; then
        echo "ArgoCD Pods: $argocd_pods running"
        
        # Application status
        total_apps=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l || echo "0")
        healthy_apps=$(kubectl get applications -n argocd -o json 2>/dev/null | jq -r '.items[] | select(.status.health.status == "Healthy") | .metadata.name' 2>/dev/null | wc -l || echo "0")
        synced_apps=$(kubectl get applications -n argocd -o json 2>/dev/null | jq -r '.items[] | select(.status.sync.status == "Synced") | .metadata.name' 2>/dev/null | wc -l || echo "0")
        
        echo "Total Applications: $total_apps"
        echo "Healthy Applications: $healthy_apps"
        echo "Synced Applications: $synced_apps"
        
        # Environment-specific apps
        echo "Environment Applications:"
        kubectl get applications -n argocd --no-headers 2>/dev/null | grep -E "(app1|app2)" | while read line; do
            name=$(echo $line | awk '{print $1}')
            sync=$(echo $line | awk '{print $2}')
            health=$(echo $line | awk '{print $3}')
            echo "  - $name: $sync/$health"
        done
        
        echo "UI Access: https://localhost:$port (admin/$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo 'password-not-found'))"
    else
        echo "❌ ArgoCD not running"
    fi
    echo ""
done

# Switch back to dev cluster
kubectl config use-context kind-dev-cluster > /dev/null 2>&1

echo "=== Monitoring Access (Dev Cluster) ==="
if kubectl get services -n monitoring prometheus > /dev/null 2>&1; then
    echo "📊 Prometheus:    http://localhost:9090"
    echo "📈 Grafana:       http://localhost:3000 (admin/admin)"
    echo "🚨 AlertManager:  http://localhost:9093"
else
    echo "❌ Monitoring services not found"
fi
echo ""

echo "=== Quick Commands ==="
echo "Start ArgoCD UI access:"
echo "  Dev:  kubectl config use-context kind-dev-cluster && kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
echo "  QA:   kubectl config use-context kind-qa-cluster && kubectl port-forward svc/argocd-server -n argocd 8081:443 &"
echo "  Prod: kubectl config use-context kind-prod-cluster && kubectl port-forward svc/argocd-server -n argocd 8082:443 &"
echo ""
echo "Access monitoring (Dev cluster):"
echo "  ./access-monitoring.sh"
echo ""
echo "Collect test metrics:"
echo "  ./test-metrics-chapter6.sh"
echo ""
echo "=================================================="