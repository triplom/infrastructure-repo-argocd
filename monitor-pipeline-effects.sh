#!/bin/bash

# Chapter 6 Thesis: Real-time Pipeline Monitoring
# This script monitors the GitHub pipeline effects on ArgoCD applications

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
MONITOR_DURATION=600  # 10 minutes
CHECK_INTERVAL=15     # 15 seconds
ARGOCD_REPO="/home/marcel/ISCTE/THESIS/pull-based/infrastructure-repo-argocd"

echo -e "${PURPLE}📊 CHAPTER 6 THESIS: REAL-TIME PIPELINE MONITORING${NC}"
echo -e "${PURPLE}==================================================${NC}"
echo ""
echo -e "${BLUE}🎯 Monitoring Objective:${NC} Track GitHub pipeline effects on ArgoCD"
echo -e "${BLUE}⏱️  Monitor Duration:${NC} ${MONITOR_DURATION} seconds ($(($MONITOR_DURATION / 60)) minutes)"
echo -e "${BLUE}🔄 Check Interval:${NC} ${CHECK_INTERVAL} seconds"
echo -e "${BLUE}📦 Target Applications:${NC} app1-dev, app1-qa, app1-prod, app2-dev, app2-qa, app2-prod"
echo ""

# Function to get ArgoCD application status
get_argocd_status() {
    cd "${ARGOCD_REPO}"
    
    echo -e "${BLUE}📊 ArgoCD Applications Status ($(date +%H:%M:%S)):${NC}"
    
    # Get status for target applications
    for app in app1 app2; do
        for env in dev qa prod; do
            APP_NAME="${app}-${env}"
            if kubectl get application "${APP_NAME}" -n argocd &> /dev/null; then
                SYNC_STATUS=$(kubectl get application "${APP_NAME}" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
                HEALTH_STATUS=$(kubectl get application "${APP_NAME}" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
                REVISION=$(kubectl get application "${APP_NAME}" -n argocd -o jsonpath='{.status.sync.revision}' 2>/dev/null || echo "Unknown")
                
                # Color code based on status
                if [[ "$SYNC_STATUS" == "Synced" ]]; then
                    STATUS_COLOR="${GREEN}"
                elif [[ "$SYNC_STATUS" == "OutOfSync" ]]; then
                    STATUS_COLOR="${YELLOW}"
                else
                    STATUS_COLOR="${RED}"
                fi
                
                echo -e "${STATUS_COLOR}   • ${APP_NAME}: ${SYNC_STATUS}/${HEALTH_STATUS} (${REVISION:0:8})${NC}"
            else
                echo -e "${RED}   • ${APP_NAME}: Not found${NC}"
            fi
        done
    done
    echo ""
}

# Function to check for config repository updates
check_config_updates() {
    cd "${ARGOCD_REPO}"
    
    # Get latest commits
    echo -e "${BLUE}🔍 ArgoCD Config Repository Status:${NC}"
    
    # Fetch latest changes
    git fetch origin main &> /dev/null || true
    
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/main)
    
    if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
        echo -e "${YELLOW}📥 New commits detected in config repository!${NC}"
        echo -e "${BLUE}   Local:  ${LOCAL_COMMIT:0:8}${NC}"
        echo -e "${BLUE}   Remote: ${REMOTE_COMMIT:0:8}${NC}"
        
        # Show recent commits
        echo -e "${BLUE}📋 Recent commits:${NC}"
        git log --oneline -5 origin/main | head -3 | while read -r commit; do
            echo -e "${BLUE}     ${commit}${NC}"
        done
        
        # Pull updates
        echo -e "${YELLOW}🔄 Pulling latest changes...${NC}"
        git pull origin main
        echo -e "${GREEN}✅ Config repository updated${NC}"
    else
        echo -e "${GREEN}✅ Config repository up to date (${LOCAL_COMMIT:0:8})${NC}"
    fi
    echo ""
}

# Function to monitor GitHub Actions workflow
monitor_github_workflow() {
    echo -e "${BLUE}🚀 GitHub Actions Workflow Status:${NC}"
    echo -e "${BLUE}   • Workflow: external-apps-deployment.yml${NC}"
    echo -e "${BLUE}   • Expected Jobs: 18 matrix combinations${NC}"
    echo -e "${BLUE}   • Monitor at: https://github.com/triplom/infrastructure-repo/actions${NC}"
    
    # Simulate workflow status check
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))
    
    if [[ $elapsed_time -lt 120 ]]; then
        echo -e "${YELLOW}⏳ Pipeline likely queued/starting (${elapsed_time}s elapsed)${NC}"
    elif [[ $elapsed_time -lt 300 ]]; then
        echo -e "${BLUE}🔄 Pipeline likely building containers (${elapsed_time}s elapsed)${NC}"
    elif [[ $elapsed_time -lt 420 ]]; then
        echo -e "${GREEN}📤 Pipeline likely updating config repo (${elapsed_time}s elapsed)${NC}"
    else
        echo -e "${GREEN}✅ Pipeline should be complete (${elapsed_time}s elapsed)${NC}"
    fi
    echo ""
}

# Function to detect changes and log events
detect_changes() {
    static previous_status=""
    local current_status=""
    
    # Build current status string
    for app in app1 app2; do
        for env in dev qa prod; do
            APP_NAME="${app}-${env}"
            if kubectl get application "${APP_NAME}" -n argocd &> /dev/null; then
                SYNC_STATUS=$(kubectl get application "${APP_NAME}" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
                current_status="${current_status}${APP_NAME}:${SYNC_STATUS},"
            fi
        done
    done
    
    # Detect changes
    if [[ "$previous_status" != "" && "$previous_status" != "$current_status" ]]; then
        echo -e "${PURPLE}🎯 CHAPTER 6 THESIS: STATUS CHANGE DETECTED!${NC}"
        echo -e "${PURPLE}================================================${NC}"
        echo -e "${YELLOW}⏱️  Timestamp: $(date -u)${NC}"
        echo -e "${YELLOW}🔄 Change Type: ArgoCD Application Status${NC}"
        echo -e "${YELLOW}📊 Thesis Impact: GitOps sync behavior data collected${NC}"
        echo ""
    fi
    
    previous_status="$current_status"
}

# Main monitoring loop
main() {
    local start_time=$(date +%s)
    local end_time=$((start_time + MONITOR_DURATION))
    local iteration=0
    
    echo -e "${PURPLE}🎯 Starting Real-time Pipeline Monitoring${NC}"
    echo -e "${PURPLE}⏱️  Monitoring until: $(date -d @${end_time})${NC}"
    echo ""
    
    while [[ $(date +%s) -lt $end_time ]]; do
        iteration=$((iteration + 1))
        
        echo -e "${PURPLE}📊 MONITORING ITERATION ${iteration} - $(date +%H:%M:%S)${NC}"
        echo -e "${PURPLE}============================================${NC}"
        
        # Check various status points
        monitor_github_workflow
        check_config_updates
        get_argocd_status
        detect_changes
        
        echo -e "${BLUE}⏳ Next check in ${CHECK_INTERVAL} seconds...${NC}"
        echo ""
        echo "────────────────────────────────────────────────────────────────"
        echo ""
        
        # Wait for next iteration
        sleep $CHECK_INTERVAL
    done
    
    # Final summary
    local final_time=$(date +%s)
    local total_duration=$((final_time - start_time))
    
    echo -e "${PURPLE}📋 MONITORING COMPLETE${NC}"
    echo -e "${PURPLE}===================${NC}"
    echo -e "${GREEN}⏱️  Total Duration: ${total_duration} seconds${NC}"
    echo -e "${GREEN}🔄 Total Iterations: ${iteration}${NC}"
    echo -e "${GREEN}📊 Chapter 6 Data: Monitoring complete for thesis analysis${NC}"
    echo ""
    
    # Final status check
    echo -e "${BLUE}🏁 Final ArgoCD Application Status:${NC}"
    get_argocd_status
    
    echo -e "${PURPLE}🎓 Chapter 6 Thesis: Real-time monitoring data collected successfully!${NC}"
}

# Execute main function
main "$@"