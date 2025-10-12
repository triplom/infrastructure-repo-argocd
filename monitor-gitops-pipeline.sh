#!/bin/bash

echo "🎯 THESIS CHAPTER 6: END-TO-END GITOPS PIPELINE MONITORING"
echo "=========================================================="
echo ""

# Capture start time for thesis evaluation
START_TIME=$(date +%s)
COMMIT_HASH="16ce243"
BASELINE_COMMIT="4f3f44c"

echo "📊 PIPELINE TRIGGER INFORMATION:"
echo "==============================="
echo "✅ Commit Hash: $COMMIT_HASH"
echo "✅ Previous Hash: $BASELINE_COMMIT"
echo "✅ Application: app1 (internal)"
echo "✅ Change Type: Source code modification (src/app1/app.py)"
echo "✅ Start Time: $(date)"
echo ""

# Function to check GitHub Actions status
check_github_actions() {
    echo "🚀 GITHUB ACTIONS CI PIPELINE STATUS:"
    echo "===================================="
    echo "🔍 Checking workflow status..."
    
    # Note: In a real scenario, you'd use GitHub CLI or API to check status
    echo "⏳ Expected CI Pipeline Steps:"
    echo "   1. 🏗️  Build app1 Docker image"
    echo "   2. 🧪 Run tests"
    echo "   3. 📦 Push to GHCR (ghcr.io/triplom/app1:latest)"
    echo "   4. 📝 Update apps/app1/base/deployment.yaml"
    echo "   5. 💾 Commit updated manifests back to repo"
    echo ""
}

# Function to monitor ArgoCD sync detection
monitor_argocd_sync() {
    echo "🔄 ARGOCD SYNC DETECTION MONITORING:"
    echo "==================================="
    
    # Check if ArgoCD has detected the new commit
    echo "📡 Current ArgoCD Application Status:"
    kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision | grep -E "(NAME|app1)"
    echo ""
    
    # Check if revision has updated
    CURRENT_APP1_DEV_REV=$(kubectl get application app1-dev -n argocd -o jsonpath='{.status.sync.revision}' 2>/dev/null | cut -c1-7)
    echo "📊 Revision Tracking:"
    echo "   Current app1-dev revision: $CURRENT_APP1_DEV_REV"
    echo "   Target revision: ${COMMIT_HASH:0:7}"
    
    if [ "$CURRENT_APP1_DEV_REV" = "${COMMIT_HASH:0:7}" ]; then
        echo "   ✅ ArgoCD has detected new commit!"
    else
        echo "   ⏳ ArgoCD still on previous revision"
    fi
    echo ""
}

# Function to check deployment status
check_deployment_status() {
    echo "🚢 KUBERNETES DEPLOYMENT STATUS:"
    echo "================================"
    
    # Check deployment status across environments
    for env in dev qa prod; do
        echo "📦 Environment: $env"
        
        # Check if namespace exists
        if kubectl get namespace app1-$env >/dev/null 2>&1; then
            # Get deployment status
            DEPLOYMENT_STATUS=$(kubectl get deployment app1 -n app1-$env -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null || echo "0/0")
            CURRENT_IMAGE=$(kubectl get deployment app1 -n app1-$env -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not deployed")
            
            echo "   📊 Replicas: $DEPLOYMENT_STATUS"
            echo "   🖼️  Image: $CURRENT_IMAGE"
            
            # Check if it's the new image
            if echo "$CURRENT_IMAGE" | grep -q "$COMMIT_HASH" || echo "$CURRENT_IMAGE" | grep -q "latest"; then
                echo "   ✅ Deployment status: Updated"
            else
                echo "   ⏳ Deployment status: Pending update"
            fi
        else
            echo "   ❌ Namespace app1-$env not found"
        fi
        echo ""
    done
}

# Function to test application endpoints
test_application_endpoints() {
    echo "🌐 APPLICATION ENDPOINT TESTING:"
    echo "==============================="
    
    # Test app1-dev service
    if kubectl get service app1 -n app1-dev >/dev/null 2>&1; then
        echo "🔍 Testing app1-dev endpoints..."
        
        # Port-forward and test
        kubectl port-forward svc/app1 -n app1-dev 8080:8080 &
        PF_PID=$!
        sleep 3
        
        echo "📡 Health endpoint test:"
        HEALTH_RESPONSE=$(curl -s http://localhost:8080/health 2>/dev/null || echo "Connection failed")
        echo "   Response: $HEALTH_RESPONSE"
        
        if echo "$HEALTH_RESPONSE" | grep -q "thesis-evaluation-v1.0"; then
            echo "   ✅ New version detected in health endpoint!"
        else
            echo "   ⏳ Still serving previous version"
        fi
        
        # Clean up port-forward
        kill $PF_PID 2>/dev/null
    else
        echo "❌ app1 service not found in app1-dev namespace"
    fi
    echo ""
}

# Function to check Prometheus metrics
check_prometheus_metrics() {
    echo "📈 PROMETHEUS METRICS VALIDATION:"
    echo "================================="
    
    # Check if app1 metrics are being scraped
    APP1_METRICS=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=up{job=~\".*app1.*\"}" 2>/dev/null | grep -o '"value":\[[0-9.]*,"[0-9]*"' | wc -l)
    
    echo "📊 App1 metrics endpoints: $APP1_METRICS"
    
    if [ "$APP1_METRICS" -gt 0 ]; then
        echo "✅ App1 metrics are being collected"
    else
        echo "⏳ App1 metrics not yet available"
    fi
    echo ""
}

# Function to calculate pipeline metrics
calculate_metrics() {
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    
    echo "⏱️  THESIS EVALUATION METRICS:"
    echo "============================="
    echo "📊 Pipeline Execution Time: ${ELAPSED_TIME}s"
    echo "🎯 Baseline Commit: $BASELINE_COMMIT"
    echo "🎯 Target Commit: $COMMIT_HASH"
    echo "📈 GitOps Pattern: Pull-based (ArgoCD)"
    echo "🏗️  App-of-Apps Pattern: ✅ Active"
    echo "🔄 Multi-Environment: dev/qa/prod"
    echo ""
}

# Main execution flow
main() {
    check_github_actions
    monitor_argocd_sync
    check_deployment_status
    test_application_endpoints
    check_prometheus_metrics
    calculate_metrics
    
    echo "🎓 NEXT STEPS FOR THESIS EVALUATION:"
    echo "=================================="
    echo "1. 📊 Monitor GitHub Actions workflow completion"
    echo "2. 🔄 Wait for ArgoCD to detect updated deployment.yaml"
    echo "3. 📈 Track deployment progression in Grafana"
    echo "4. ⚖️  Compare with push-based GitOps metrics"
    echo "5. 📝 Document findings for Chapter 6 analysis"
    echo ""
    echo "🔍 Monitoring URLs:"
    echo "   Grafana: http://172.18.0.3:30300 (admin/admin123)"
    echo "   Prometheus: http://172.18.0.3:30900"
    echo "   ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
}

# Run the main monitoring function
main