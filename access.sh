#!/bin/bash
# access.sh - Consolidated access script for ArgoCD GitOps thesis setup
# Covers: ArgoCD UI, Grafana, Prometheus, Alertmanager, cluster status
#
# Usage:
#   ./access.sh argocd              # Port-forward ArgoCD UI (all clusters)
#   ./access.sh grafana             # Port-forward Grafana
#   ./access.sh prometheus          # Port-forward Prometheus
#   ./access.sh alertmanager        # Port-forward Alertmanager
#   ./access.sh monitoring          # Port-forward all monitoring services
#   ./access.sh status              # Show cluster and ArgoCD app status
#   ./access.sh all                 # Port-forward everything

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

KUBECONFIG_DEV="${HOME}/.kube/dev-config"
KUBECONFIG_QA="${HOME}/.kube/qa-config"
KUBECONFIG_PROD="${HOME}/.kube/prod-config"

# Use KUBECONFIG env var if set, otherwise default
CURRENT_KUBECONFIG="${KUBECONFIG:-${HOME}/.kube/config}"

print_header() {
  echo -e "${PURPLE}============================================================${NC}"
  echo -e "${PURPLE} $1${NC}"
  echo -e "${PURPLE}============================================================${NC}"
}

access_argocd() {
  print_header "ArgoCD UI Access"
  local ARGOCD_PASSWORD
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "<not found - run: argocd admin initial-password -n argocd>")
  echo -e "${BLUE}Username:${NC} admin"
  echo -e "${BLUE}Password:${NC} ${ARGOCD_PASSWORD}"
  echo -e "${GREEN}Starting port-forward on http://localhost:8080${NC}"
  echo "Press Ctrl+C to stop."
  kubectl port-forward svc/argocd-server -n argocd 8080:443
}

access_grafana() {
  print_header "Grafana Access"
  local GRAFANA_PASSWORD
  GRAFANA_PASSWORD=$(kubectl -n monitoring get secret grafana -o jsonpath="{.data.admin-password}" \
    2>/dev/null | base64 -d 2>/dev/null || echo "admin")
  echo -e "${BLUE}Username:${NC} admin"
  echo -e "${BLUE}Password:${NC} ${GRAFANA_PASSWORD}"
  echo -e "${GREEN}Starting port-forward on http://localhost:3000${NC}"
  echo "Press Ctrl+C to stop."
  kubectl port-forward svc/grafana -n monitoring 3000:80
}

access_prometheus() {
  print_header "Prometheus Access"
  echo -e "${GREEN}Starting port-forward on http://localhost:9090${NC}"
  echo "Press Ctrl+C to stop."
  kubectl port-forward svc/prometheus-server -n monitoring 9090:80
}

access_alertmanager() {
  print_header "Alertmanager Access"
  echo -e "${GREEN}Starting port-forward on http://localhost:9093${NC}"
  echo "Press Ctrl+C to stop."
  kubectl port-forward svc/alertmanager -n monitoring 9093:9093
}

access_monitoring() {
  print_header "Monitoring Stack Access (background)"
  echo -e "${YELLOW}Starting all monitoring port-forwards in background...${NC}"
  kubectl port-forward svc/grafana -n monitoring 3000:80 &>/dev/null &
  GRAFANA_PID=$!
  kubectl port-forward svc/prometheus-server -n monitoring 9090:80 &>/dev/null &
  PROMETHEUS_PID=$!
  kubectl port-forward svc/alertmanager -n monitoring 9093:9093 &>/dev/null &
  ALERTMANAGER_PID=$!
  echo -e "${GREEN}Grafana:${NC}      http://localhost:3000  (PID: ${GRAFANA_PID})"
  echo -e "${GREEN}Prometheus:${NC}   http://localhost:9090  (PID: ${PROMETHEUS_PID})"
  echo -e "${GREEN}Alertmanager:${NC} http://localhost:9093  (PID: ${ALERTMANAGER_PID})"
  echo ""
  echo "Kill all port-forwards: kill ${GRAFANA_PID} ${PROMETHEUS_PID} ${ALERTMANAGER_PID}"
  echo "Or: pkill -f 'kubectl port-forward'"
  wait
}

show_status() {
  print_header "Cluster & ArgoCD Status"
  echo -e "${BLUE}--- Kubernetes Nodes ---${NC}"
  kubectl get nodes -o wide 2>/dev/null || echo "Cannot reach cluster"
  echo ""
  echo -e "${BLUE}--- ArgoCD Applications ---${NC}"
  kubectl get applications -n argocd 2>/dev/null || echo "ArgoCD not accessible"
  echo ""
  echo -e "${BLUE}--- Monitoring Pods ---${NC}"
  kubectl get pods -n monitoring 2>/dev/null || echo "Monitoring namespace not found"
  echo ""
  echo -e "${BLUE}--- ArgoCD Pods ---${NC}"
  kubectl get pods -n argocd 2>/dev/null || echo "ArgoCD namespace not found"
}

access_all() {
  print_header "Starting All Port-Forwards"
  echo -e "${YELLOW}Starting ArgoCD, Grafana, Prometheus, Alertmanager in background...${NC}"
  kubectl port-forward svc/argocd-server -n argocd 8080:443 &>/dev/null &
  echo -e "${GREEN}ArgoCD:${NC}       https://localhost:8080  (PID: $!)"
  kubectl port-forward svc/grafana -n monitoring 3000:80 &>/dev/null &
  echo -e "${GREEN}Grafana:${NC}      http://localhost:3000   (PID: $!)"
  kubectl port-forward svc/prometheus-server -n monitoring 9090:80 &>/dev/null &
  echo -e "${GREEN}Prometheus:${NC}   http://localhost:9090   (PID: $!)"
  kubectl port-forward svc/alertmanager -n monitoring 9093:9093 &>/dev/null &
  echo -e "${GREEN}Alertmanager:${NC} http://localhost:9093   (PID: $!)"
  echo ""
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "<run: argocd admin initial-password -n argocd>")
  echo -e "${BLUE}ArgoCD credentials:${NC} admin / ${ARGOCD_PASSWORD}"
  echo ""
  echo "Kill all: pkill -f 'kubectl port-forward'"
  wait
}

CMD="${1:-help}"
case "$CMD" in
  argocd)       access_argocd ;;
  grafana)      access_grafana ;;
  prometheus)   access_prometheus ;;
  alertmanager) access_alertmanager ;;
  monitoring)   access_monitoring ;;
  status)       show_status ;;
  all)          access_all ;;
  help|*)
    echo "Usage: $0 {argocd|grafana|prometheus|alertmanager|monitoring|status|all}"
    echo ""
    echo "  argocd       - Port-forward ArgoCD UI to localhost:8080"
    echo "  grafana      - Port-forward Grafana to localhost:3000"
    echo "  prometheus   - Port-forward Prometheus to localhost:9090"
    echo "  alertmanager - Port-forward Alertmanager to localhost:9093"
    echo "  monitoring   - Port-forward all monitoring services (background)"
    echo "  status       - Show cluster, ArgoCD apps, and pod status"
    echo "  all          - Port-forward all services (background)"
    ;;
esac
