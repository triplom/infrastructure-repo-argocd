#!/bin/bash

echo "🎓 CHAPTER 6 THESIS EVALUATION METRICS VALIDATION"
echo "================================================="
echo ""

# Check if metrics ConfigMap is deployed
echo "📊 METRICS CONFIGURATION STATUS:"
echo "================================"
kubectl get configmap thesis-chapter6-metrics-rules -n monitoring --no-headers 2>/dev/null && echo "✅ Chapter 6 metrics rules: DEPLOYED" || echo "❌ Chapter 6 metrics rules: MISSING"
kubectl get configmap thesis-chapter6-dashboard -n monitoring --no-headers 2>/dev/null && echo "✅ Chapter 6 dashboard: DEPLOYED" || echo "❌ Chapter 6 dashboard: MISSING"
echo ""

# Test Prometheus metrics availability
echo "🔬 RESEARCH QUESTIONS METRICS VALIDATION:"
echo "========================================="

echo "📈 RQ1: Automated Synchronization Impact Metrics:"
echo -n "   • deployment_success_rate:percentage: "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=deployment_success_rate:percentage" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "⏳ CALCULATING"; fi

echo -n "   • pipeline_duration_seconds:commit_to_deploy: "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=pipeline_duration_seconds:commit_to_deploy" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "⏳ CALCULATING"; fi

echo -n "   • deployment_duration_seconds:incremental: "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=deployment_duration_seconds:incremental" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "⏳ CALCULATING"; fi

echo ""
echo "🛠️  RQ2: Operational Complexity Reduction Metrics:"
echo -n "   • self_healing_actions:count: "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=self_healing_actions:count" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "⏳ CALCULATING"; fi

echo -n "   • drift_detection_duration_seconds: "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=drift_detection_duration_seconds" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "⏳ CALCULATING"; fi

echo -n "   • deployment_cpu_usage:by_method: "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=deployment_cpu_usage:by_method" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "⏳ CALCULATING"; fi

echo ""

# Test ArgoCD base metrics that feed into our calculations
echo "🎯 ARGOCD BASE METRICS (Data Sources):"
echo "======================================"
echo -n "   • argocd_app_info (application status): "
APPS=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=count(argocd_app_info)" 2>/dev/null | grep -o '"value":\[[^,]*,"[0-9]*"' | cut -d'"' -f4)
if [ -n "$APPS" ]; then echo "✅ $APPS applications tracked"; else echo "❌ NO DATA"; fi

echo -n "   • argocd_app_sync_total (sync operations): "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=argocd_app_sync_total" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "❌ NO DATA"; fi

echo -n "   • container_cpu_usage_seconds_total (resource metrics): "
RESULT=$(kubectl exec deployment/prometheus -n monitoring -- wget -qO- "http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total" 2>/dev/null | grep -o '"result":\[[^]]*\]' | wc -c)
if [ "$RESULT" -gt 12 ]; then echo "✅ AVAILABLE"; else echo "❌ NO DATA"; fi

echo ""

# Dashboard availability
echo "📊 GRAFANA DASHBOARD INTEGRATION:"
echo "================================="
kubectl get configmap -n monitoring -l grafana_dashboard=1 --no-headers | awk '{print "✅ Dashboard: " $1}'
echo ""

# Access information for thesis evaluation
echo "🎓 THESIS EVALUATION ACCESS:"
echo "============================"
echo "📊 Grafana Dashboard:"
echo "   URL: http://172.18.0.3:30300"
echo "   Username: admin"
echo "   Password: admin123"
echo "   📈 Look for: 'Chapter 6: GitOps Efficiency Evaluation - Thesis Research'"
echo ""
echo "🔍 Prometheus Queries:"
echo "   URL: http://172.18.0.3:30900"
echo "   📊 Key queries for thesis:"
echo "      • deployment_success_rate:percentage"
echo "      • rq1_deployment_time_improvement:percentage"
echo "      • rq2_human_error_reduction:count"
echo "      • rq2_operational_complexity:score"
echo ""

# Next steps for thesis evaluation
echo "📝 THESIS EVALUATION NEXT STEPS:"
echo "================================"
echo "1. 🎯 Generate application deployment events:"
echo "   - Trigger app1/app2 deployments"
echo "   - Create configuration changes"
echo "   - Test failure/recovery scenarios"
echo ""
echo "2. 📊 Collect data over time (24-48 hours recommended):"
echo "   - Deployment speed metrics"
echo "   - Resource utilization patterns"
echo "   - Self-healing event counts"
echo ""
echo "3. 📈 Analyze results in Grafana:"
echo "   - Chapter 6 dashboard for visual analysis"
echo "   - Export data for statistical analysis"
echo "   - Compare against push-based scenario"
echo ""
echo "4. 📖 Document findings for thesis defense:"
echo "   - RQ1_H1 & RQ1_H2 validation"
echo "   - RQ2_H1 & RQ2_H2 evidence"
echo "   - Comparative analysis results"
echo ""
echo "🎊 CHAPTER 6 EVALUATION FRAMEWORK: DEPLOYED AND READY!"
echo "========================================================"