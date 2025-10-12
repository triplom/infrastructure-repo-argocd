#!/bin/bash

echo "🎯 COMPLETE MONITORING STACK ACCESS GUIDE"
echo "=========================================="
echo ""

# Grafana Access
echo "📊 GRAFANA DASHBOARD ACCESS"
echo "==========================="
echo "🎯 Primary (NodePort): http://172.18.0.3:30300"
echo "🎯 Alternative (Port-forward): http://localhost:3000"
echo "   └── Command: kubectl port-forward svc/grafana-nodeport -n monitoring 3000:3000"
echo "🔐 Credentials: admin / admin123"
echo ""
echo "🧪 Grafana Connectivity:"
if curl -s http://172.18.0.3:30300 >/dev/null 2>&1; then
    echo "   ✅ NodePort (30300): WORKING"
else
    echo "   ❌ NodePort (30300): FAILED"
fi
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "   ✅ Port-forward (3000): WORKING"
else
    echo "   ⚠️  Port-forward (3000): NOT ACTIVE"
fi
echo ""

# Prometheus Access
echo "🔍 PROMETHEUS METRICS ACCESS"
echo "============================"
echo "🎯 Primary (NodePort): http://172.18.0.3:30900"
echo "🎯 Alternative (Port-forward): http://localhost:9090"
echo "   └── Command: kubectl port-forward svc/prometheus -n monitoring 9090:9090"
echo "🔐 No authentication required"
echo ""
echo "🧪 Prometheus Connectivity:"
if curl -s http://172.18.0.3:30900/graph >/dev/null 2>&1; then
    echo "   ✅ NodePort (30900): WORKING"
else
    echo "   ❌ NodePort (30900): FAILED"
fi
if curl -s http://localhost:9090/graph >/dev/null 2>&1; then
    echo "   ✅ Port-forward (9090): WORKING"
else
    echo "   ⚠️  Port-forward (9090): NOT ACTIVE"
fi
echo ""

# ArgoCD Metrics Validation
echo "📈 ARGOCD METRICS INTEGRATION"
echo "============================="
ARGOCD_METRICS=$(curl -s http://172.18.0.3:30900/api/v1/label/__name__/values 2>/dev/null | grep -o 'argocd_[^"]*' | wc -l)
echo "✅ ArgoCD metrics available: $ARGOCD_METRICS metrics"

# Sample ArgoCD queries
echo ""
echo "🔍 SAMPLE PROMETHEUS QUERIES FOR THESIS:"
echo "========================================"
echo "📊 Application Status:"
echo "   • count(argocd_app_info) - Total applications"
echo "   • count(argocd_app_info{sync_status=\"Synced\"}) - Synced apps"
echo "   • count(argocd_app_info{health_status=\"Healthy\"}) - Healthy apps"
echo ""
echo "📈 GitOps Performance:"
echo "   • rate(argocd_app_sync_total[5m]) - Sync operations per second"
echo "   • argocd_app_sync_duration_seconds - Sync duration"
echo "   • rate(argocd_server_api_request_total[5m]) - API requests per second"
echo ""

# Dashboard information
echo "📊 AVAILABLE GRAFANA DASHBOARDS:"
echo "================================"
kubectl get configmap -n monitoring -l grafana_dashboard=1 --no-headers 2>/dev/null | awk '{print "   🎯 " $1}'
echo ""

# Quick start commands
echo "🚀 QUICK START COMMANDS:"
echo "========================"
echo "Start Grafana port-forward:"
echo "   kubectl port-forward svc/grafana-nodeport -n monitoring 3000:3000 &"
echo ""
echo "Start Prometheus port-forward:"
echo "   kubectl port-forward svc/prometheus -n monitoring 9090:9090 &"
echo ""
echo "Check running port-forwards:"
echo "   ps aux | grep 'kubectl port-forward' | grep -v grep"
echo ""
echo "Kill all port-forwards:"
echo "   pkill -f 'kubectl port-forward'"
echo ""

# Browser commands
echo "🌐 OPEN IN BROWSER:"
echo "=================="
echo "For Linux/WSL:"
echo "   xdg-open http://172.18.0.3:30300  # Grafana"
echo "   xdg-open http://172.18.0.3:30900  # Prometheus"
echo ""
echo "For macOS:"
echo "   open http://172.18.0.3:30300  # Grafana"
echo "   open http://172.18.0.3:30900  # Prometheus"
echo ""

# Thesis workflow
echo "🎓 THESIS EVALUATION WORKFLOW:"
echo "=============================="
echo "1. 📊 Open Grafana: http://172.18.0.3:30300"
echo "2. 🔐 Login: admin / admin123"
echo "3. 🎯 Navigate to 'ArgoCD GitOps Dashboard'"
echo "4. 📈 Analyze pull-based GitOps metrics"
echo "5. 🔍 Use Prometheus for custom queries: http://172.18.0.3:30900"
echo "6. 📊 Create custom dashboards for deployment time analysis"
echo "7. ⚖️  Compare with push-based GitOps metrics"
echo ""
echo "🎊 COMPLETE MONITORING STACK READY FOR THESIS EVALUATION!"
echo "=========================================================="