#!/bin/bash

echo "🎓 CHAPTER 6 THESIS DASHBOARD - DIRECT ACCESS"
echo "============================================="
echo ""

# Check if port forward is active
if curl -s -o /dev/null "http://localhost:3001/api/health"; then
    echo "✅ Grafana is accessible at http://localhost:3001"
else
    echo "⚠️  Setting up Grafana port forward..."
    pkill -f "kubectl port-forward.*grafana" 2>/dev/null || true
    sleep 2
    kubectl port-forward svc/grafana -n monitoring 3001:3000 > /dev/null 2>&1 &
    sleep 3
fi

# Get dashboard information
DASHBOARD_URL=$(curl -s -u admin:admin123 "http://localhost:3001/api/search?query=Chapter%206" | jq -r '.[0].url' 2>/dev/null)

echo ""
echo "🎊 THESIS DASHBOARD READY!"
echo "========================="
echo ""
echo "📊 Dashboard: Chapter 6: GitOps Efficiency Evaluation - Thesis Research"
echo "🌐 Direct URL: http://localhost:3001${DASHBOARD_URL}"
echo "👤 Username: admin"
echo "🔐 Password: admin123"
echo ""
echo "📈 DASHBOARD PANELS:"
echo "==================="
echo "1. 🚀 RQ1: Deployment Speed Analysis"
echo "2. ✅ RQ1: Deployment Success Rate"  
echo "3. 🔄 RQ2: Self-Healing Actions"
echo "4. 📊 RQ2: Operational Complexity Score"
echo "5. 📋 ArgoCD Applications Status Matrix"
echo "6. 💾 Resource Utilization by Deployment Method"
echo "7. 🎯 RQ1 Hypothesis Validation"
echo "8. 🎯 RQ2 Hypothesis Validation"
echo ""
echo "🔍 RESEARCH QUESTIONS COVERAGE:"
echo "==============================="
echo "✅ RQ1: How does automated synchronization impact deployment speed and reliability?"
echo "✅ RQ2: How does ArgoCD reduce operational complexity vs push-based systems?"
echo ""
echo "📊 METRICS STATUS:"
echo "=================="

# Test key metrics
echo -n "📈 ArgoCD Apps Tracked: "
APPS=$(curl -s "http://localhost:9091/api/v1/query?query=count(argocd_app_info)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
echo "$APPS applications"

echo -n "🔄 Sync Operations: "
SYNCS=$(curl -s "http://localhost:9091/api/v1/query?query=argocd_app_sync_total" | jq -r '.data.result | length' 2>/dev/null || echo "0")
if [ "$SYNCS" -gt 0 ]; then echo "✅ Active"; else echo "⏳ Collecting"; fi

echo -n "📊 Chapter 6 Metrics: "
METRICS=$(curl -s "http://localhost:9091/api/v1/query?query=deployment_success_rate:percentage" | jq -r '.status' 2>/dev/null || echo "error")
if [ "$METRICS" = "success" ]; then echo "✅ Recording"; else echo "⏳ Calculating"; fi

echo ""
echo "🎊 READY FOR THESIS EVALUATION!"
echo "==============================="
echo "Open: http://localhost:3001${DASHBOARD_URL}"
echo ""