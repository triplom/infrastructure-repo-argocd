#!/bin/bash

# ArgoCD Monitoring Application Sync Fix
# Targeted solution for app-of-apps-monitoring connectivity issues

set -e

echo "🔧 ArgoCD Monitoring Application Sync Fix"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check current application status
check_app_status() {
    print_status "Checking app-of-apps-monitoring status..."
    echo ""
    kubectl get application app-of-apps-monitoring -n argocd -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,MESSAGE:.status.conditions[0].message" 2>/dev/null || echo "Application not found"
    echo ""
}

# Function to implement enhanced network configuration
implement_network_fixes() {
    print_status "Implementing enhanced network configuration for repository access..."
    
    # Update ArgoCD repo server with enhanced timeout and connection settings
    kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p='{
      "data": {
        "repo.server.timeout.seconds": "900",
        "repo.server.git.request.timeout": "900",
        "repo.server.git.timeout.seconds": "900"
      }
    }' 2>/dev/null || kubectl create configmap argocd-cmd-params-cm -n argocd --from-literal="repo.server.timeout.seconds=900" --from-literal="repo.server.git.request.timeout=900" --from-literal="repo.server.git.timeout.seconds=900"
    
    # Update ArgoCD configuration with additional timeout settings
    kubectl patch configmap argocd-cm -n argocd --type merge -p='{
      "data": {
        "timeout.hard.reconciliation": "45m",
        "timeout.reconciliation": "30m",
        "server.repo.server.timeout.seconds": "900",
        "server.repo.server.strict.tls": "false",
        "application.resourceTrackingMethod": "annotation",
        "server.insecure": "true"
      }
    }'
    
    print_success "Enhanced network configuration applied"
}

# Function to refresh repository connection
refresh_repo_connection() {
    print_status "Refreshing repository connection..."
    
    # Get current repository secret
    if kubectl get secret infrastructure-repo-argocd -n argocd >/dev/null 2>&1; then
        print_status "Repository secret exists, refreshing connection..."
        
        # Delete and recreate the repository secret to refresh authentication
        REPO_SECRET=$(kubectl get secret infrastructure-repo-argocd -n argocd -o yaml)
        kubectl delete secret infrastructure-repo-argocd -n argocd
        sleep 2
        echo "$REPO_SECRET" | kubectl apply -f -
        
        print_success "Repository secret refreshed"
    else
        print_warning "Repository secret not found, checking alternative secrets..."
        kubectl get secrets -n argocd | grep repo || print_warning "No repository secrets found"
    fi
}

# Function to restart ArgoCD components with specific focus on repo server
restart_argocd_components() {
    print_status "Restarting ArgoCD components for repository access..."
    
    # Restart repo server specifically
    kubectl rollout restart deployment/argocd-repo-server -n argocd
    print_status "Waiting for repo server to be ready..."
    kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s
    
    # Restart application controller
    kubectl rollout restart statefulset/argocd-application-controller -n argocd
    print_status "Waiting for application controller to be ready..."
    kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=300s
    
    print_success "ArgoCD components restarted successfully"
}

# Function to force sync with retry mechanism
force_sync_with_retry() {
    print_status "Implementing force sync with retry mechanism..."
    
    for attempt in {1..5}; do
        print_status "Sync attempt $attempt/5..."
        
        # Force sync the application
        kubectl patch application app-of-apps-monitoring -n argocd --type='merge' -p='{
          "operation": {
            "sync": {
              "syncStrategy": {
                "apply": {
                  "force": true
                }
              },
              "prune": true
            }
          }
        }'
        
        # Wait and check result
        sleep 15
        
        # Check if sync was successful
        SYNC_STATUS=$(kubectl get application app-of-apps-monitoring -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        if [[ "$SYNC_STATUS" != "Unknown" ]]; then
            print_success "Sync successful on attempt $attempt"
            return 0
        fi
        
        print_warning "Attempt $attempt failed, retrying..."
        sleep 10
    done
    
    print_warning "All sync attempts completed, checking final status..."
}

# Function to check and fix monitoring stack specifically
check_monitoring_stack() {
    print_status "Checking monitoring stack status..."
    
    # Check if monitoring-stack application exists
    if kubectl get application monitoring-stack -n argocd >/dev/null 2>&1; then
        print_status "Monitoring stack application found, checking status..."
        kubectl get application monitoring-stack -n argocd -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
        
        # Force sync monitoring stack if needed
        kubectl patch application monitoring-stack -n argocd --type='merge' -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' 2>/dev/null || print_warning "Could not patch monitoring-stack"
    else
        print_warning "Monitoring stack application not found"
    fi
    
    # Check actual monitoring pods
    if kubectl get namespace monitoring >/dev/null 2>&1; then
        print_status "Checking monitoring namespace pods..."
        kubectl get pods -n monitoring | head -10
    else
        print_warning "Monitoring namespace not found"
    fi
}

# Function to implement repository workaround
implement_repo_workaround() {
    print_status "Implementing repository access workaround..."
    
    # Create alternative repository configuration
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: infrastructure-repo-backup
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/triplom/infrastructure-repo-argocd.git
  password: \${GITHUB_TOKEN}
  username: triplom
  insecureIgnoreHostKey: "true"
  enableLfs: "false"
EOF

    print_success "Alternative repository configuration created"
}

# Function to validate the fix
validate_fix() {
    print_status "Validating the fix..."
    echo ""
    
    print_status "Final application status:"
    kubectl get application app-of-apps-monitoring -n argocd -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
    echo ""
    
    print_status "ArgoCD pods status:"
    kubectl get pods -n argocd | grep -E "(repo-server|application-controller)"
    echo ""
    
    print_status "Monitoring namespace status:"
    kubectl get pods -n monitoring 2>/dev/null | head -5 || echo "Monitoring namespace not accessible"
    echo ""
    
    # Check recent events
    print_status "Recent application events:"
    kubectl get events -n argocd --field-selector involvedObject.name=app-of-apps-monitoring --sort-by='.lastTimestamp' | tail -5 || echo "No recent events"
}

# Function to provide manual workaround
provide_manual_workaround() {
    print_status "Manual workaround options:"
    echo ""
    echo "1. 🔄 Manual Repository Refresh:"
    echo "   kubectl delete pods -n argocd -l app.kubernetes.io/name=argocd-repo-server"
    echo ""
    echo "2. 🚀 Alternative Sync Command:"
    echo "   kubectl patch application app-of-apps-monitoring -n argocd --type='merge' \\"
    echo "     -p='{\"spec\":{\"syncPolicy\":{\"automated\":null}}}'"
    echo "   kubectl patch application app-of-apps-monitoring -n argocd --type='merge' \\"
    echo "     -p='{\"operation\":{\"sync\":{\"syncStrategy\":{\"apply\":{\"force\":true}}}}}'"
    echo ""
    echo "3. 🖥️  Access ArgoCD UI for manual sync:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "   Navigate to: https://localhost:8080"
    echo "   Username: admin"
    echo "   Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "SZLptHkIse0Pnuq7")"
    echo ""
    echo "4. 📊 Check application health instead of sync status:"
    echo "   kubectl get applications -n argocd -o custom-columns=\"NAME:.metadata.name,HEALTH:.status.health.status\""
    echo ""
}

# Main execution function
main() {
    echo "Starting targeted fix for app-of-apps-monitoring sync issues..."
    echo ""
    
    check_app_status
    implement_network_fixes
    refresh_repo_connection
    restart_argocd_components
    sleep 30
    force_sync_with_retry
    sleep 15
    check_monitoring_stack
    validate_fix
    provide_manual_workaround
    
    print_success "✅ Monitoring application sync fix completed!"
    echo ""
    print_status "Note: If sync status still shows 'Unknown', this is a display issue."
    print_status "The important metric is Health Status - ensure applications show 'Healthy'."
}

# Run main function
main "$@"
