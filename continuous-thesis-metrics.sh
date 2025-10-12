#!/bin/bash

echo "📊 CONTINUOUS METRICS GENERATION FOR THESIS ANALYSIS"
echo "===================================================="
echo "Running extended deployment scenarios to populate thesis metrics"
echo ""

# Function to log with timestamp
log_with_time() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to create realistic deployment scenarios
create_deployment_scenario() {
    local scenario_name=$1
    local duration=$2
    
    log_with_time "🎯 Starting scenario: $scenario_name (${duration}m duration)"
    
    local end_time=$(($(date +%s) + duration * 60))
    local iteration=1
    
    while [ $(date +%s) -lt $end_time ]; do
        local timestamp=$(date +%H%M%S)
        
        # Scenario 1: Rapid deployment cycles (DevOps efficiency)
        if [ "$scenario_name" = "rapid-deployment" ]; then
            log_with_time "🚀 Rapid deployment cycle #$iteration"
            
            # Update app1 and app2 with new tags
            kubectl patch deployment app1 -n app1-dev -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"app1\",\"image\":\"ghcr.io/triplom/app1:rapid-$timestamp\"}]}}}}" 2>/dev/null
            kubectl patch deployment app2 -n app2-dev -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"app2\",\"image\":\"ghcr.io/triplom/app2:rapid-$timestamp\"}]}}}}" 2>/dev/null
            
            # Force ArgoCD sync
            kubectl annotate app app1-dev -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null
            kubectl annotate app app2-dev -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null
            
            sleep 60  # 1 minute between deployments
            
        # Scenario 2: Configuration drift simulation
        elif [ "$scenario_name" = "drift-recovery" ]; then
            log_with_time "🔄 Configuration drift scenario #$iteration"
            
            # Create drift by scaling deployments
            kubectl scale deployment app1 -n app1-qa --replicas=$((2 + iteration % 3)) 2>/dev/null
            kubectl scale deployment app2 -n app2-qa --replicas=$((3 + iteration % 2)) 2>/dev/null
            
            sleep 30
            
            # Trigger ArgoCD to detect and fix drift
            kubectl annotate app app1-qa -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null
            kubectl annotate app app2-qa -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null
            
            sleep 90  # 1.5 minutes between drift scenarios
            
        # Scenario 3: Multi-environment promotion
        elif [ "$scenario_name" = "promotion-flow" ]; then
            log_with_time "🌊 Environment promotion flow #$iteration"
            
            local tag="promote-$timestamp-v$iteration"
            
            # Promote through environments: dev -> qa -> prod
            log_with_time "  📦 Deploying $tag to dev"
            kubectl patch deployment app1 -n app1-dev -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"app1\",\"image\":\"ghcr.io/triplom/app1:$tag\"}]}}}}" 2>/dev/null
            sleep 30
            
            log_with_time "  📦 Promoting $tag to qa"
            kubectl patch deployment app1 -n app1-qa -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"app1\",\"image\":\"ghcr.io/triplom/app1:$tag\"}]}}}}" 2>/dev/null
            sleep 45
            
            log_with_time "  📦 Promoting $tag to prod"
            kubectl patch deployment app1 -n app1-prod -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"app1\",\"image\":\"ghcr.io/triplom/app1:$tag\"}]}}}}" 2>/dev/null
            
            # Sync all environments
            for env in dev qa prod; do
                kubectl annotate app app1-$env -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null
            done
            
            sleep 120  # 2 minutes between promotion flows
        fi
        
        iteration=$((iteration + 1))
    done
    
    log_with_time "✅ Scenario $scenario_name completed ($iteration iterations)"
}

# Function to monitor metrics in background
monitor_metrics() {
    log_with_time "📈 Starting metrics monitoring..."
    
    while true; do
        local apps=$(curl -s "http://localhost:9091/api/v1/query?query=count(argocd_app_info)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        local syncs=$(curl -s "http://localhost:9091/api/v1/query?query=sum(increase(argocd_app_sync_total[1m]))" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        
        log_with_time "📊 Metrics: $apps apps tracked, $syncs syncs/min"
        sleep 60
    done
}

echo "🎯 THESIS SCENARIO EXECUTION PLAN"
echo "================================="
echo "1. 🚀 Rapid deployment cycles (5 minutes) - DevOps efficiency"
echo "2. 🔄 Configuration drift recovery (5 minutes) - Self-healing capability"
echo "3. 🌊 Multi-environment promotion (5 minutes) - Deployment pipeline"
echo "4. 📈 Continuous monitoring throughout execution"
echo ""

# Start background metrics monitoring
monitor_metrics &
MONITOR_PID=$!

# Execute scenarios sequentially
create_deployment_scenario "rapid-deployment" 5
sleep 30
create_deployment_scenario "drift-recovery" 5
sleep 30
create_deployment_scenario "promotion-flow" 5

# Stop monitoring
kill $MONITOR_PID 2>/dev/null

# Final metrics check
echo ""
echo "📊 FINAL METRICS SUMMARY"
echo "========================"

log_with_time "Collecting final metrics for thesis analysis..."

# Check key metrics
TOTAL_APPS=$(curl -s "http://localhost:9091/api/v1/query?query=count(argocd_app_info)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
TOTAL_SYNCS=$(curl -s "http://localhost:9091/api/v1/query?query=sum(argocd_app_sync_total)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
SUCCESS_RATE=$(curl -s "http://localhost:9091/api/v1/query?query=deployment_success_rate:percentage" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "calculating...")

echo ""
log_with_time "🎊 THESIS METRICS GENERATION COMPLETE!"
echo "======================================"
echo "📈 Total ArgoCD Applications: $TOTAL_APPS"
echo "🔄 Total Sync Operations: $TOTAL_SYNCS"
echo "✅ Current Success Rate: $SUCCESS_RATE%"
echo ""
echo "📊 Chapter 6 Dashboard: http://localhost:3001/d/d0d4f0ff-38cc-4187-bf0e-727d04456241/chapter-6-gitops-efficiency-evaluation-thesis-research"
echo "🔍 Prometheus Queries: http://localhost:9091"
echo ""
echo "✅ Comprehensive thesis data generated - ready for analysis!"