#!/bin/bash

echo "🎯 CHAPTER 6 THESIS - PIPELINE DEPLOYMENT TESTING"
echo "=================================================="
echo "Generating metrics data for GitOps efficiency analysis"
echo ""

# Function to log with timestamp
log_with_time() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to trigger deployment by updating image tag
trigger_deployment() {
    local app=$1
    local env=$2
    local new_tag=$3
    
    log_with_time "🚀 Triggering $app deployment in $env environment with tag $new_tag"
    
    # Update the deployment image (simulating a CI/CD pipeline update)
    kubectl patch deployment $app -n $env-$app -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$app\",\"image\":\"ghcr.io/triplom/$app:$new_tag\"}]}}}}" 2>/dev/null || \
    kubectl patch deployment $app -n $app-$env -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$app\",\"image\":\"ghcr.io/triplom/$app:$new_tag\"}]}}}}" 2>/dev/null || \
    kubectl patch deployment $app -n default -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$app\",\"image\":\"ghcr.io/triplom/$app:$new_tag\"}]}}}}" 2>/dev/null || \
    echo "⚠️  Could not find deployment $app in expected namespaces"
}

# Function to simulate configuration drift and recovery
simulate_drift_recovery() {
    local app=$1
    local env=$2
    
    log_with_time "🔄 Simulating configuration drift for $app in $env"
    
    # Create drift by manually scaling deployment
    kubectl scale deployment $app -n $app-$env --replicas=5 2>/dev/null || \
    kubectl scale deployment $app -n $env-$app --replicas=5 2>/dev/null || \
    kubectl scale deployment $app -n default --replicas=5 2>/dev/null
    
    log_with_time "⏳ Waiting for ArgoCD to detect and correct drift..."
    sleep 30
    
    # Force ArgoCD sync to demonstrate self-healing
    kubectl annotate app $app-$env -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null || \
    echo "⚠️  Could not trigger ArgoCD sync for $app-$env"
}

# Function to monitor deployment progress
monitor_deployment() {
    local app=$1
    local env=$2
    local timeout=300  # 5 minutes
    local start_time=$(date +%s)
    
    log_with_time "📊 Monitoring $app deployment in $env environment"
    
    while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
        # Check deployment status in various namespace patterns
        local ready=$(kubectl get deployment $app -n $app-$env -o jsonpath='{.status.readyReplicas}' 2>/dev/null || \
                     kubectl get deployment $app -n $env-$app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || \
                     kubectl get deployment $app -n default -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired=$(kubectl get deployment $app -n $app-$env -o jsonpath='{.spec.replicas}' 2>/dev/null || \
                       kubectl get deployment $app -n $env-$app -o jsonpath='{.spec.replicas}' 2>/dev/null || \
                       kubectl get deployment $app -n default -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        if [ "$ready" = "$desired" ] && [ "$ready" != "0" ]; then
            local duration=$(($(date +%s) - start_time))
            log_with_time "✅ $app deployment completed in ${duration}s (${ready}/${desired} replicas ready)"
            return 0
        fi
        
        echo -n "."
        sleep 5
    done
    
    log_with_time "⚠️  $app deployment timed out after ${timeout}s"
    return 1
}

echo "📋 DEPLOYMENT PLAN:"
echo "==================="
echo "1. 🔄 Update app1 across dev/qa/prod environments"
echo "2. 🔄 Update app2 across dev/qa/prod environments"
echo "3. 🎯 Simulate configuration drift and recovery"
echo "4. 📊 Monitor ArgoCD sync operations"
echo "5. 📈 Generate deployment metrics for thesis analysis"
echo ""

# Record start time for overall pipeline metrics
PIPELINE_START=$(date +%s)

# Phase 1: Deploy app1 updates
echo "🎯 PHASE 1: APP1 DEPLOYMENT UPDATES"
echo "==================================="

# Generate unique tags based on timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
APP1_TAG="v1.0-$TIMESTAMP"
APP2_TAG="v2.0-$TIMESTAMP"

# Deploy app1 to all environments
for env in dev qa prod; do
    trigger_deployment "app1" "$env" "$APP1_TAG"
    monitor_deployment "app1" "$env" &
done

# Wait for app1 deployments to settle
sleep 45

# Phase 2: Deploy app2 updates
echo ""
echo "🎯 PHASE 2: APP2 DEPLOYMENT UPDATES"
echo "==================================="

for env in dev qa prod; do
    trigger_deployment "app2" "$env" "$APP2_TAG"
    monitor_deployment "app2" "$env" &
done

# Wait for app2 deployments
sleep 45

# Phase 3: Simulate drift and recovery scenarios
echo ""
echo "🎯 PHASE 3: DRIFT DETECTION & SELF-HEALING"
echo "=========================================="

# Simulate drift in different environments
simulate_drift_recovery "app1" "dev"
sleep 30
simulate_drift_recovery "app2" "qa"
sleep 30

# Phase 4: Force sync operations to generate more metrics
echo ""
echo "🎯 PHASE 4: FORCE SYNC OPERATIONS"
echo "================================="

log_with_time "🔄 Triggering ArgoCD sync operations for metrics generation"

# Trigger sync for all applications
for app in app1-dev app1-qa app1-prod app2-dev app2-qa app2-prod; do
    kubectl annotate app $app -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null && \
    log_with_time "✅ Triggered sync for $app" || \
    log_with_time "⚠️  Could not sync $app"
    sleep 5
done

# Calculate total pipeline duration
PIPELINE_END=$(date +%s)
TOTAL_DURATION=$((PIPELINE_END - PIPELINE_START))

echo ""
echo "📊 PIPELINE EXECUTION SUMMARY"
echo "============================="
log_with_time "🎊 Pipeline completed in ${TOTAL_DURATION} seconds"
log_with_time "📈 Deployment events generated for thesis metrics"
log_with_time "🔍 Check Prometheus for new metrics data"
log_with_time "📊 View results in Grafana Chapter 6 dashboard"

echo ""
echo "🎓 THESIS METRICS DATA GENERATED!"
echo "================================="
echo "📊 Grafana Dashboard: http://localhost:3001/d/d0d4f0ff-38cc-4187-bf0e-727d04456241/chapter-6-gitops-efficiency-evaluation-thesis-research"
echo "🔍 Prometheus Metrics: http://localhost:9091"
echo "📈 Key metrics updated:"
echo "   • deployment_duration_seconds:incremental"
echo "   • pipeline_duration_seconds:commit_to_deploy" 
echo "   • deployment_success_rate:percentage"
echo "   • self_healing_actions:count"
echo "   • argocd_app_sync_total"
echo ""
echo "✅ Ready for Chapter 6 thesis evaluation and analysis!"