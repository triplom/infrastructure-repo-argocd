#!/bin/bash

# Monitoring services access script
# Provides easy access to Prometheus, Grafana, and AlertManager

echo "=== Monitoring Services Access ==="
echo "Setting up port-forwards for monitoring stack..."

# Kill any existing port-forwards
echo "Cleaning up existing port-forwards..."
pkill -f "port-forward.*prometheus" || true
pkill -f "port-forward.*grafana" || true
pkill -f "port-forward.*alertmanager" || true

# Start port-forwards in background
echo "Starting port-forwards..."
kubectl port-forward svc/prometheus -n monitoring 9090:9090 > /dev/null 2>&1 &
kubectl port-forward svc/grafana -n monitoring 3000:3000 > /dev/null 2>&1 &
kubectl port-forward svc/alertmanager -n monitoring 9093:9093 > /dev/null 2>&1 &

# Wait a moment for services to start
sleep 3

echo ""
echo "🎉 Monitoring services are now accessible:"
echo ""
echo "📊 Prometheus:    http://localhost:9090"
echo "📈 Grafana:       http://localhost:3000"
echo "🚨 AlertManager:  http://localhost:9093"
echo ""
echo "Default Grafana credentials: admin/admin"
echo ""
echo "To stop all port-forwards:"
echo "  pkill -f 'port-forward.*(prometheus|grafana|alertmanager)'"
echo ""

# Show current port-forward processes
echo "Active port-forward processes:"
ps aux | grep port-forward | grep -E "(prometheus|grafana|alertmanager)" | grep -v grep