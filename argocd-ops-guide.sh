#!/bin/bash

# ArgoCD Quick Operations Guide
# Essential commands for ongoing ArgoCD management

echo "🎯 ArgoCD Quick Operations Guide"
echo "================================"
echo ""

# Function to show ArgoCD health
show_argocd_health() {
    echo "📊 ArgoCD Health Status:"
    kubectl get pods -n argocd
    echo ""
}

# Function to show application status
show_app_status() {
    echo "🚀 Application Status (Health Focus):"
    kubectl get applications -n argocd -o custom-columns="NAME:.metadata.name,HEALTH:.status.health.status,SYNC:.status.sync.status" | head -15
    echo ""
}

# Function to show monitoring stack
show_monitoring() {
    echo "📈 Monitoring Stack Status:"
    kubectl get pods -n monitoring | head -10
    echo ""
}

# Function to show infrastructure
show_infrastructure() {
    echo "🏗️ Infrastructure Components:"
    echo "Ingress Controller:"
    kubectl get pods -n ingress-nginx 2>/dev/null || echo "  Not found"
    echo "Certificate Manager:"
    kubectl get pods -n cert-manager 2>/dev/null | head -5 || echo "  Not found"
    echo "Application Workloads:"
    kubectl get pods -n app1-dev 2>/dev/null || echo "  No workloads"
    echo ""
}

# Function for quick sync
quick_sync() {
    local app_name=$1
    if [[ -z "$app_name" ]]; then
        echo "Usage: quick_sync <application-name>"
        echo "Available applications:"
        kubectl get applications -n argocd --no-headers | awk '{print "  - " $1}' | head -10
        return
    fi
    
    echo "🔄 Force syncing application: $app_name"
    kubectl patch application $app_name -n argocd --type='merge' \
        -p='{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}'
    echo "Sync command sent. Check status in a few moments."
}

# Function to access ArgoCD UI
access_ui() {
    echo "🖥️ ArgoCD UI Access:"
    echo "1. Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "2. Open: https://localhost:8080"
    echo "3. Username: admin"
    echo "4. Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "SZLptHkIse0Pnuq7")"
    echo ""
}

# Function to troubleshoot sync issues
troubleshoot_sync() {
    echo "🔧 Sync Issue Troubleshooting:"
    echo ""
    echo "1. Check ArgoCD repo server:"
    kubectl get pods -n argocd | grep repo-server
    echo ""
    echo "2. Recent application events:"
    kubectl get events -n argocd --sort-by='.lastTimestamp' | tail -5
    echo ""
    echo "3. Restart ArgoCD components if needed:"
    echo "   kubectl rollout restart deployment/argocd-repo-server -n argocd"
    echo "   kubectl rollout restart statefulset/argocd-application-controller -n argocd"
    echo ""
}

# Function to validate system
validate_system() {
    echo "✅ System Validation Summary:"
    echo ""
    
    # ArgoCD health
    ARGOCD_RUNNING=$(kubectl get pods -n argocd --no-headers | grep Running | wc -l)
    ARGOCD_TOTAL=$(kubectl get pods -n argocd --no-headers | wc -l)
    echo "ArgoCD: $ARGOCD_RUNNING/$ARGOCD_TOTAL pods running"
    
    # Applications
    TOTAL_APPS=$(kubectl get applications -n argocd --no-headers | wc -l)
    HEALTHY_APPS=$(kubectl get applications -n argocd -o custom-columns="HEALTH:.status.health.status" --no-headers | grep -c "Healthy" || echo "0")
    echo "Applications: $HEALTHY_APPS/$TOTAL_APPS healthy"
    
    # Monitoring
    MONITORING_RUNNING=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    echo "Monitoring: $MONITORING_RUNNING pods running"
    
    # Infrastructure
    INGRESS_RUNNING=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    CERT_RUNNING=$(kubectl get pods -n cert-manager --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    echo "Infrastructure: Ingress($INGRESS_RUNNING) + CertManager($CERT_RUNNING)"
    
    echo ""
    if [[ $ARGOCD_RUNNING -eq 7 && $HEALTHY_APPS -gt 15 && $MONITORING_RUNNING -eq 8 ]]; then
        echo "🎉 System Status: FULLY OPERATIONAL"
    else
        echo "⚠️ System Status: Needs attention"
    fi
    echo ""
}

# Main menu
case "${1:-help}" in
    "health")
        show_argocd_health
        ;;
    "apps")
        show_app_status
        ;;
    "monitoring")
        show_monitoring
        ;;
    "infra")
        show_infrastructure
        ;;
    "sync")
        quick_sync "$2"
        ;;
    "ui")
        access_ui
        ;;
    "troubleshoot")
        troubleshoot_sync
        ;;
    "validate")
        validate_system
        ;;
    "all")
        show_argocd_health
        show_app_status
        show_monitoring
        show_infrastructure
        validate_system
        ;;
    "help"|*)
        echo "ArgoCD Quick Operations Guide"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  health       - Show ArgoCD pod health"
        echo "  apps         - Show application status"
        echo "  monitoring   - Show monitoring stack"
        echo "  infra        - Show infrastructure components"
        echo "  sync <app>   - Force sync an application"
        echo "  ui           - Show UI access instructions"
        echo "  troubleshoot - Show troubleshooting steps"
        echo "  validate     - Run system validation"
        echo "  all          - Show all status information"
        echo ""
        echo "Examples:"
        echo "  $0 health"
        echo "  $0 sync app-of-apps-monitoring"
        echo "  $0 validate"
        echo ""
        ;;
esac
