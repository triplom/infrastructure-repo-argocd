#!/bin/bash

# Quick Multi-Repository Status Check
# Validates readiness for complete CI/CD testing

echo "🚀 MULTI-REPOSITORY CI/CD READINESS CHECK"
echo "=========================================="
echo

# Repository connections
echo "📊 Repository Connection Status:"
kubectl get secrets -n argocd | grep repo | awk '{print "   ✅ " $1}'
echo

# ArgoCD health
echo "🏥 ArgoCD System Health:"
TOTAL_PODS=$(kubectl get pods -n argocd --no-headers | wc -l)
RUNNING_PODS=$(kubectl get pods -n argocd --no-headers | grep Running | wc -l)
echo "   Pods: $RUNNING_PODS/$TOTAL_PODS running"
echo

# Application distribution
echo "📦 Applications by Repository:"
echo
echo "   🏠 Main Repo (infrastructure-repo-argocd):"
kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.source.repoURL}{"\n"}{end}' | grep "infrastructure-repo-argocd" | awk '{print "      - " $1}'

echo
echo "   🏗️ External Repo (infrastructure-repo):"
kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.source.repoURL}{"\n"}{end}' | grep "infrastructure-repo.git" | awk '{print "      - " $1}'

echo
echo "   🐘 PHP Repo (k8s-web-app-php):"
kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.source.repoURL}{"\n"}{end}' | grep "k8s-web-app-php" | awk '{print "      - " $1}'

echo
echo "🎯 Current Deployment Status:"
echo "   App1 (working example):"
kubectl get pods --all-namespaces | grep app1 | awk '{print "      " $2 " - " $4}' || echo "      No pods found"

echo "   App2 (needs pipeline run):"
kubectl get pods --all-namespaces | grep app2 | head -3 | awk '{print "      " $2 " - " $4}' || echo "      No pods found"

echo "   External apps:"
kubectl get pods --all-namespaces | grep external | awk '{print "      " $2 " - " $4}' || echo "      No external app pods found"

echo "   PHP apps:"
kubectl get pods --all-namespaces | grep php | awk '{print "      " $2 " - " $4}' || echo "      No PHP app pods found"

echo
echo "🎯 TESTING PRIORITY ORDER:"
echo "   1. ✅ Test app1 pipeline (working example)"
echo "   2. 🔧 Test app2 pipeline (fix ImagePullBackOff)"
echo "   3. 🏗️ Test external-app pipeline"
echo "   4. 🐘 Test php-web-app pipeline"
echo
echo "🚀 Ready to begin multi-repository CI/CD testing!"
echo "Start at: https://github.com/triplom/infrastructure-repo-argocd/actions"
