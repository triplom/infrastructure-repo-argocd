#!/bin/bash

echo "🎯 GRAFANA ACCESS METHODS - COMPLETE GUIDE"
echo "==========================================="
echo ""

# Method 1: NodePort (KIND cluster IP)
echo "📊 METHOD 1: NodePort Access (Recommended)"
echo "==========================================="
echo "🌐 URL: http://172.18.0.3:30300"
echo "✅ Username: admin"
echo "✅ Password: admin123"
echo ""
echo "🧪 Testing NodePort access..."
if curl -s http://172.18.0.3:30300 >/dev/null 2>&1; then
    echo "✅ NodePort access: WORKING"
else
    echo "❌ NodePort access: FAILED"
fi
echo ""

# Method 2: Port Forward
echo "📊 METHOD 2: Port Forward to Localhost"
echo "======================================"
echo "🔧 Start port-forward: kubectl port-forward svc/grafana-nodeport -n monitoring 3000:3000"
echo "🌐 URL: http://localhost:3000"
echo "✅ Username: admin"
echo "✅ Password: admin123"
echo ""
echo "🧪 Testing localhost access..."
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "✅ Localhost access: WORKING"
else
    echo "❌ Localhost access: NOT AVAILABLE (run port-forward command above)"
fi
echo ""

# Browser launch helper
echo "🚀 QUICK BROWSER ACCESS"
echo "======================="
echo "For Linux/WSL:"
echo "   xdg-open http://172.18.0.3:30300"
echo "   # OR if port-forward is running:"
echo "   xdg-open http://localhost:3000"
echo ""
echo "For macOS:"
echo "   open http://172.18.0.3:30300"
echo "   # OR if port-forward is running:"
echo "   open http://localhost:3000"
echo ""
echo "Manual Browser:"
echo "   Navigate to: http://172.18.0.3:30300 (always works)"
echo "   Navigate to: http://localhost:3000 (only if port-forward active)"
echo ""

# Troubleshooting
echo "🔧 TROUBLESHOOTING"
echo "=================="
echo "If NodePort doesn't work:"
echo "1. Check KIND cluster status: kubectl get nodes"
echo "2. Verify service exists: kubectl get svc grafana-nodeport -n monitoring"
echo "3. Check pod is running: kubectl get pods -l app=grafana -n monitoring"
echo ""
echo "If port-forward doesn't work:"
echo "1. Kill existing processes: pkill -f 'kubectl port-forward.*grafana'"
echo "2. Start fresh: kubectl port-forward svc/grafana-nodeport -n monitoring 3000:3000"
echo "3. Wait 2 seconds, then try: curl http://localhost:3000"
echo ""

# Status check
echo "🔍 CURRENT STATUS"
echo "================"
kubectl get pods -l app=grafana -n monitoring --no-headers | awk '{print "✅ Grafana Pod: " $1 " - " $3}'
kubectl get svc grafana-nodeport -n monitoring --no-headers | awk '{print "✅ NodePort Service: " $1 " - " $5}'

# Final recommendation
echo ""
echo "💡 RECOMMENDATION"
echo "================="
echo "Use NodePort method (http://172.18.0.3:30300) as it's most reliable."
echo "Only use port-forward if you prefer localhost URLs."
echo ""
echo "🎓 READY FOR THESIS EVALUATION!"
echo "Username: admin | Password: admin123"