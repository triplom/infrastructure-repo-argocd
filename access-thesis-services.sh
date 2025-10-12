#!/bin/bash

echo "🎓 CHAPTER 6 THESIS EVALUATION - SERVICE ACCESS SETUP"
echo "====================================================="
echo ""

# Kill any existing port forwards
echo "🧹 Cleaning up existing port forwards..."
pkill -f "kubectl port-forward.*grafana" 2>/dev/null || true
pkill -f "kubectl port-forward.*prometheus" 2>/dev/null || true
sleep 2

# Check service status
echo "📊 Checking service status..."
kubectl get pods -n monitoring -l app=grafana --no-headers | awk '{print "✅ Grafana: " $3}'
kubectl get pods -n monitoring -l app=prometheus --no-headers | awk '{print "✅ Prometheus: " $3}'
echo ""

# Test NodePort access (internal to Docker network)
echo "🔗 Testing NodePort access..."
if curl -s -o /dev/null -w "%{http_code}" http://172.18.0.3:30300 | grep -q "302"; then
    echo "✅ Grafana NodePort: Accessible at http://172.18.0.3:30300"
else
    echo "❌ Grafana NodePort: Not accessible"
fi

if curl -s -o /dev/null -w "%{http_code}" http://172.18.0.3:30900 | grep -q "405\|200"; then
    echo "✅ Prometheus NodePort: Accessible at http://172.18.0.3:30900"
else
    echo "❌ Prometheus NodePort: Not accessible"
fi
echo ""

# Set up port forwarding for external access
echo "🌐 Setting up port forwarding for external access..."

# Start Grafana port forward
kubectl port-forward svc/grafana -n monitoring 3001:3000 > /dev/null 2>&1 &
GRAFANA_PF_PID=$!
sleep 3

# Test Grafana port forward
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 | grep -q "302"; then
    echo "✅ Grafana Port Forward: http://localhost:3001"
    echo "   Username: admin"
    echo "   Password: admin123"
else
    echo "❌ Grafana Port Forward: Failed"
    kill $GRAFANA_PF_PID 2>/dev/null || true
fi

# Start Prometheus port forward
kubectl port-forward svc/prometheus -n monitoring 9091:9090 > /dev/null 2>&1 &
PROMETHEUS_PF_PID=$!
sleep 3

# Test Prometheus port forward
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9091 | grep -q "405\|200"; then
    echo "✅ Prometheus Port Forward: http://localhost:9091"
else
    echo "❌ Prometheus Port Forward: Failed"
    kill $PROMETHEUS_PF_PID 2>/dev/null || true
fi

echo ""
echo "🎯 ACCESS METHODS SUMMARY:"
echo "=========================="
echo ""
echo "📊 GRAFANA ACCESS:"
echo "  🌐 External (Port Forward): http://localhost:3001"
echo "  🔗 Internal (NodePort):     http://172.18.0.3:30300"
echo "  👤 Username: admin"
echo "  🔐 Password: admin123"
echo ""
echo "🔍 PROMETHEUS ACCESS:"
echo "  🌐 External (Port Forward): http://localhost:9091"
echo "  🔗 Internal (NodePort):     http://172.18.0.3:30900"
echo ""
echo "📈 THESIS DASHBOARD:"
echo "  Look for: 'Chapter 6: GitOps Efficiency Evaluation - Thesis Research'"
echo ""
echo "🛠️  STOP PORT FORWARDS:"
echo "  pkill -f 'kubectl port-forward'"
echo ""

# Save PIDs for cleanup
echo $GRAFANA_PF_PID > /tmp/grafana-pf.pid 2>/dev/null || true
echo $PROMETHEUS_PF_PID > /tmp/prometheus-pf.pid 2>/dev/null || true

echo "🎊 Services are now accessible for Chapter 6 thesis evaluation!"
echo "=============================================================="