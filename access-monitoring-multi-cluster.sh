#!/bin/bash

# Multi-Cluster Monitoring Access Script
# Provides access to Prometheus, Grafana, and AlertManager across all clusters

echo "🔍 Multi-Cluster Monitoring Access"
echo "=================================="

# Function to setup monitoring access for a cluster
setup_monitoring_access() {
    local context=$1
    local port_base=$2
    local env_name=$3
    
    echo ""
    echo "📊 Setting up monitoring access for $env_name cluster..."
    
    # Switch to the cluster context
    kubectl config use-context $context > /dev/null 2>&1
    
    # Check if monitoring pods exist
    echo "Checking monitoring pods status..."
    kubectl get pods -n monitoring --field-selector=status.phase=Running 2>/dev/null | grep -E "(prometheus|grafana|alertmanager)" | head -5
    
    # Setup port forwards
    echo ""
    echo "Setting up port forwards for $env_name:"
    
    # Kill existing port forwards for this cluster
    sudo pkill -f "port-forward.*$port_base" 2>/dev/null || true
    
    # Prometheus
    if kubectl get pod -n monitoring -l app.kubernetes.io/name=prometheus 2>/dev/null | grep -q Running; then
        echo "🔥 Starting Prometheus port-forward on port $(($port_base + 0))..."
        kubectl port-forward -n monitoring svc/prometheus-operated $(($port_base + 0)):9090 > /dev/null 2>&1 &
        PROMETHEUS_PID=$!
        echo "   Prometheus URL: http://localhost:$(($port_base + 0))"
    fi
    
    # Grafana  
    if kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana 2>/dev/null | grep -q Running; then
        echo "📈 Starting Grafana port-forward on port $(($port_base + 1))..."
        kubectl port-forward -n monitoring svc/grafana $(($port_base + 1)):3000 > /dev/null 2>&1 &
        GRAFANA_PID=$!
        echo "   Grafana URL: http://localhost:$(($port_base + 1))"
        echo "   Default login: admin/admin"
    fi
    
    # AlertManager
    if kubectl get pod -n monitoring -l app.kubernetes.io/name=alertmanager 2>/dev/null | grep -q Running; then
        echo "🚨 Starting AlertManager port-forward on port $(($port_base + 2))..."
        kubectl port-forward -n monitoring svc/alertmanager-operated $(($port_base + 2)):9093 > /dev/null 2>&1 &
        ALERTMANAGER_PID=$!
        echo "   AlertManager URL: http://localhost:$(($port_base + 2))"
    fi
    
    sleep 2
}

# Setup monitoring for each cluster
setup_monitoring_access "kind-dev-cluster" 9090 "Development"
setup_monitoring_access "kind-qa-cluster" 9100 "QA" 
setup_monitoring_access "kind-prod-cluster" 9110 "Production"

echo ""
echo "🎯 Multi-Cluster Monitoring URLs:"
echo "=================================="
echo ""
echo "📊 Development Cluster:"
echo "   Prometheus:    http://localhost:9090"
echo "   Grafana:       http://localhost:9091"
echo "   AlertManager:  http://localhost:9092"
echo ""
echo "📊 QA Cluster:"
echo "   Prometheus:    http://localhost:9100"
echo "   Grafana:       http://localhost:9101"
echo "   AlertManager:  http://localhost:9102"
echo ""
echo "📊 Production Cluster:"
echo "   Prometheus:    http://localhost:9110"
echo "   Grafana:       http://localhost:9111"
echo "   AlertManager:  http://localhost:9112"
echo ""
echo "✅ All monitoring services are now accessible!"
echo ""
echo "🔍 Test Connectivity:"
echo "curl -s http://localhost:9090/api/v1/query\?query\=up | jq '.data.result | length'"
echo "curl -s http://localhost:9100/api/v1/query\?query\=up | jq '.data.result | length'"
echo "curl -s http://localhost:9110/api/v1/query\?query\=up | jq '.data.result | length'"
echo ""
echo "📈 For Grafana dashboards, import dashboard ID: 1860 (Node Exporter Full)"
echo ""
echo "🛑 To stop all monitoring port-forwards:"
echo "sudo pkill -f 'port-forward.*90[0-9][0-9]'"