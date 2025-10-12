#!/bin/bash

echo "🎓 QUICK ACCESS - CHAPTER 6 THESIS SERVICES"
echo "==========================================="
echo ""

# Method 1: Direct NodePort access (works within Docker network)
echo "🔗 DIRECT ACCESS (NodePort - works from Docker containers):"
echo "   📊 Grafana:    http://172.18.0.3:30300"
echo "   🔍 Prometheus: http://172.18.0.3:30900"
echo ""

# Method 2: Port forward setup
echo "🌐 EXTERNAL ACCESS SETUP:"
echo "========================"

# Clean up existing forwards
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

echo "Setting up port forwards..."

# Grafana port forward
kubectl port-forward svc/grafana -n monitoring 3001:3000 &
GRAFANA_PID=$!
sleep 2

# Prometheus port forward  
kubectl port-forward svc/prometheus -n monitoring 9091:9090 &
PROMETHEUS_PID=$!
sleep 2

# Test accessibility
echo ""
if curl -s -o /dev/null http://localhost:3001; then
    echo "✅ Grafana:    http://localhost:3001 (admin/admin123)"
else
    echo "❌ Grafana:    Port forward failed"
fi

if curl -s -o /dev/null http://localhost:9091; then
    echo "✅ Prometheus: http://localhost:9091"
else
    echo "❌ Prometheus: Port forward failed"
fi

echo ""
echo "🎯 BROWSER ACCESS:"
echo "=================="
echo "📊 Open Grafana:    http://localhost:3001"
echo "🔍 Open Prometheus: http://localhost:9091"
echo ""
echo "📈 In Grafana, look for dashboard:"
echo "   'Chapter 6: GitOps Efficiency Evaluation - Thesis Research'"
echo ""
echo "🛑 To stop port forwards: pkill -f 'kubectl port-forward'"
echo ""
echo "🎊 Chapter 6 thesis services are ready for evaluation!"