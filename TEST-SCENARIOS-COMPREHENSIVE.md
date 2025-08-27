# Comprehensive Test Scenarios for ArgoCD App-of-Apps Implementation

## Test Environment Setup

### Prerequisites

- Kubernetes cluster (Kind/GKE/EKS/AKS)
- ArgoCD installed and configured
- Access to GitHub repositories
- kubectl and argocd CLI tools

## Test Scenario Categories

---

## 1. Functional Testing Scenarios

### Test Case 1.1: Root Application Bootstrap

**Objective**: Validate the complete bootstrap process of the app-of-apps pattern

**Test Steps**:

```bash
# Step 1: Bootstrap the entire system
./bootstrap.sh

# Step 2: Verify root application deployment
kubectl get application root-app -n argocd

# Step 3: Check application status
kubectl describe application root-app -n argocd

# Step 4: Verify child applications are created
kubectl get applications -n argocd
```

**Expected Results**:

- Root application status: Synced and Healthy
- All child app-of-apps applications created:
  - app-of-apps
  - app-of-apps-monitoring  
  - app-of-apps-infra
- No sync errors in ArgoCD UI

**Success Criteria**:

- All applications show "Synced" and "Healthy" status
- No error events in kubectl describe output
- ArgoCD UI shows green status for all applications

---

### Test Case 1.2: Multi-Environment Application Deployment

**Objective**: Validate ApplicationSet deployment across dev/qa/prod environments

**Test Steps**:

```bash
# Step 1: Verify ApplicationSet creation
kubectl get applicationset -n argocd

# Step 2: Check generated applications
kubectl get applications -l argocd.argoproj.io/instance=app1 -n argocd

# Step 3: Verify namespace creation
kubectl get namespaces | grep -E "(app1|app2)-(dev|qa|prod)"

# Step 4: Check application deployments in each environment
for env in dev qa prod; do
  echo "Checking app1-$env:"
  kubectl get pods -n app1-$env
  kubectl get services -n app1-$env
done
```

**Expected Results**:

- ApplicationSets created successfully
- 6 applications generated (app1 and app2 × 3 environments each)
- All environment namespaces created
- Pods running in each environment namespace

**Success Criteria**:

- ApplicationSet reports 3 applications for each app
- All pods in Running state
- Services accessible within cluster

---

### Test Case 1.3: Infrastructure Component Deployment

**Objective**: Validate infrastructure components deployment through app-of-apps-infra

**Test Steps**:

```bash
# Step 1: Check infrastructure applications
kubectl get applications -l app=infrastructure -n argocd

# Step 2: Verify cert-manager deployment
kubectl get pods -n cert-manager
kubectl get crds | grep cert-manager

# Step 3: Verify ingress-nginx deployment
kubectl get pods -n ingress-nginx
kubectl get services -n ingress-nginx

# Step 4: Verify monitoring infrastructure
kubectl get pods -n monitoring
kubectl get servicemonitors -n monitoring
```

**Expected Results**:

- Infrastructure applications synced and healthy
- cert-manager pods running with CRDs installed
- ingress-nginx controller pod running with LoadBalancer service
- Monitoring infrastructure components deployed

**Success Criteria**:

- All infrastructure pods in Running state
- Required CRDs installed
- Services properly exposed

---

## 2. CI/CD Integration Testing

### Test Case 2.1: Application Update via CI/CD

**Objective**: Test the complete CI/CD pipeline integration with GitOps

**Test Setup**:

```bash
# Set up test environment variables
export TEST_IMAGE="ghcr.io/triplom/app1:test-$(date +%s)"
export GITHUB_TOKEN="your-token-here"
```

**Test Steps**:

```bash
# Step 1: Simulate CI/CD pipeline update
cd /home/marcel/ISCTE/THESIS/push-based/infrastructure-repo
git checkout -b test-update-$(date +%s)

# Step 2: Update image tag using kustomize
cd apps/app1/overlays/dev
kustomize edit set image app1=$TEST_IMAGE

# Step 3: Commit and push changes
git add .
git commit -m "Test: Update app1 image to $TEST_IMAGE"
git push origin HEAD

# Step 4: Monitor ArgoCD for automatic sync
watch "kubectl get applications app1-dev -n argocd -o jsonpath='{.status.sync.status}'"

# Step 5: Verify deployment update
kubectl get deployment app1 -n app1-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Expected Results**:

- Git commit successful
- ArgoCD detects change within sync interval (default 3 minutes)
- Application automatically syncs to new image
- Deployment updated with new image tag

**Success Criteria**:

- Application sync status changes to "Synced"
- Deployment image matches test image tag
- No sync errors reported
- Application remains healthy after update

---

### Test Case 2.2: Configuration Drift Detection and Resolution

**Objective**: Test ArgoCD's ability to detect and resolve configuration drift

**Test Steps**:

```bash
# Step 1: Record current state
kubectl get deployment app1 -n app1-dev -o yaml > original-deployment.yaml

# Step 2: Manually modify deployment (simulate drift)
kubectl patch deployment app1 -n app1-dev -p '{"spec":{"replicas":5}}'

# Step 3: Verify drift is detected
kubectl get application app1-dev -n argocd -o jsonpath='{.status.sync.status}'

# Step 4: Wait for auto-healing (if enabled) or manually sync
argocd app sync app1-dev

# Step 5: Verify drift is resolved
kubectl get deployment app1 -n app1-dev -o jsonpath='{.spec.replicas}'
```

**Expected Results**:

- Manual change creates drift (OutOfSync status)
- ArgoCD detects configuration drift
- Auto-healing restores desired state
- Application returns to Synced status

**Success Criteria**:

- Sync status changes to "OutOfSync" after manual change
- Auto-healing or manual sync restores original configuration
- Final state matches Git repository definition

---

## 3. Security and RBAC Testing

### Test Case 3.1: Project-based Access Control

**Objective**: Validate ArgoCD project-based RBAC implementation

**Test Steps**:

```bash
# Step 1: Verify projects exist
kubectl get appprojects -n argocd

# Step 2: Check project configurations
kubectl describe appproject applications -n argocd
kubectl describe appproject monitoring -n argocd
kubectl describe appproject infrastructure -n argocd

# Step 3: Test repository access restrictions
# Try to create application with unauthorized repository
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: unauthorized-app
  namespace: argocd
spec:
  project: applications
  source:
    repoURL: https://github.com/unauthorized/repo.git
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: test
EOF

# Step 4: Verify namespace restrictions
# Try to deploy to unauthorized namespace
```

**Expected Results**:

- All projects properly configured
- Repository restrictions enforced
- Namespace access controlled per project
- Unauthorized operations blocked

**Success Criteria**:

- Projects show correct source repositories
- Unauthorized repository access denied
- Namespace restrictions enforced
- Appropriate error messages for violations

---

## 4. Performance and Scalability Testing

### Test Case 4.1: Sync Performance Measurement

**Objective**: Measure application synchronization performance

**Test Steps**:

```bash
# Step 1: Create performance test script
cat <<'EOF' > sync-performance-test.sh
#!/bin/bash
START_TIME=$(date +%s%N)

# Trigger sync for all applications
argocd app sync --async app1-dev app1-qa app1-prod app2-dev app2-qa app2-prod

# Wait for all applications to sync
while true; do
  PENDING=$(kubectl get applications -n argocd -o json | jq -r '.items[] | select(.status.sync.status != "Synced") | .metadata.name' | wc -l)
  if [ "$PENDING" -eq 0 ]; then
    break
  fi
  sleep 1
done

END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME) / 1000000))
echo "Total sync time: ${DURATION}ms"
EOF

chmod +x sync-performance-test.sh

# Step 2: Run performance test
./sync-performance-test.sh

# Step 3: Measure individual application sync times
for app in app1-dev app1-qa app1-prod; do
  echo "Testing $app:"
  time argocd app sync $app --timeout 300
done
```

**Expected Results**:

- All applications sync successfully
- Sync times within acceptable limits
- No timeout errors
- Resource utilization within bounds

**Success Criteria**:

- Total sync time < 5 minutes for all applications
- Individual application sync time < 2 minutes
- CPU/Memory usage within cluster limits
- No failed synchronizations

---

### Test Case 4.2: Large-Scale Deployment Testing

**Objective**: Test system behavior with increased application count

**Test Setup**:

```bash
# Create additional test applications
for i in {3..10}; do
  mkdir -p /tmp/test-apps/app$i/{base,overlays/{dev,qa,prod}}
  
  # Create base manifests
  cat <<EOF > /tmp/test-apps/app$i/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app$i
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app$i
  template:
    metadata:
      labels:
        app: app$i
    spec:
      containers:
      - name: app$i
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

  # Create kustomization files
  echo "resources:\n- deployment.yaml" > /tmp/test-apps/app$i/base/kustomization.yaml
  
  for env in dev qa prod; do
    cat <<EOF > /tmp/test-apps/app$i/overlays/$env/kustomization.yaml
bases:
- ../../base
namePrefix: $env-
namespace: app$i-$env
EOF
  done
done
```

**Test Steps**:

```bash
# Step 1: Deploy additional applications via ApplicationSet
kubectl apply -f large-scale-applicationset.yaml

# Step 2: Monitor resource usage
kubectl top nodes
kubectl top pods -n argocd

# Step 3: Measure sync performance with increased load
time argocd app sync --all

# Step 4: Verify all applications are healthy
kubectl get applications -n argocd | grep -v Synced
```

**Expected Results**:

- System handles increased application count
- Resource usage remains within acceptable limits
- All applications sync successfully
- No performance degradation

**Success Criteria**:

- All applications reach Synced status
- ArgoCD components remain stable
- Cluster resources not exhausted
- Response times remain reasonable

---

## 5. Monitoring and Observability Testing

### Test Case 5.1: GitOps Metrics Validation

**Objective**: Validate monitoring stack and GitOps metrics collection

**Test Steps**:

```bash
# Step 1: Verify monitoring stack deployment
kubectl get pods -n monitoring

# Step 2: Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090 &
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job == "argocd-metrics")'

# Step 3: Verify ArgoCD metrics are being collected
curl -s http://localhost:9090/api/v1/query?query=argocd_app_info | jq .

# Step 4: Check Grafana dashboards
kubectl port-forward -n monitoring svc/grafana 3000:3000 &
# Verify GitOps dashboard exists and shows data

# Step 5: Test alerting rules
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | select(.name == "gitops-alerts")'
```

**Expected Results**:

- Monitoring stack fully operational
- ArgoCD metrics being collected
- Grafana dashboards showing GitOps data
- Alert rules properly configured

**Success Criteria**:

- All monitoring pods in Running state
- ArgoCD metrics available in Prometheus
- Grafana dashboards accessible and populated
- Alert rules firing appropriately

---

## 6. Disaster Recovery Testing

### Test Case 6.1: Complete System Recovery

**Objective**: Test recovery from complete system failure

**Test Steps**:

```bash
# Step 1: Backup current state
kubectl get applications -n argocd -o yaml > applications-backup.yaml
kubectl get secrets -n argocd -o yaml > secrets-backup.yaml

# Step 2: Simulate complete failure
kubectl delete namespace argocd
kubectl delete namespace app1-dev app1-qa app1-prod app2-dev app2-qa app2-prod
kubectl delete namespace monitoring cert-manager ingress-nginx

# Step 3: Reinstall ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 4: Bootstrap system recovery
./bootstrap.sh

# Step 5: Verify complete recovery
kubectl get applications -n argocd
kubectl get pods --all-namespaces | grep -E "(app1|app2|monitoring|cert-manager|ingress-nginx)"
```

**Expected Results**:

- Complete system restoration
- All applications redeployed
- Data consistency maintained
- No manual intervention required

**Success Criteria**:

- Bootstrap script completes successfully
- All applications reach Synced status
- Application data restored correctly
- Monitoring and infrastructure operational

---

## Test Execution Framework

### Automated Test Suite

```bash
#!/bin/bash
# comprehensive-test-suite.sh

RESULTS_DIR="test-results-$(date +%Y%m%d-%H%M%S)"
mkdir -p $RESULTS_DIR

# Function to run test and capture results
run_test() {
    local test_name=$1
    local test_script=$2
    
    echo "Running $test_name..."
    start_time=$(date +%s)
    
    if bash $test_script > "$RESULTS_DIR/$test_name.log" 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "✅ $test_name - PASSED (${duration}s)"
        echo "PASSED" > "$RESULTS_DIR/$test_name.result"
    else
        echo "❌ $test_name - FAILED"
        echo "FAILED" > "$RESULTS_DIR/$test_name.result"
    fi
}

# Execute all test scenarios
run_test "bootstrap" "test-bootstrap.sh"
run_test "multi-env-deployment" "test-multi-env.sh"
run_test "infrastructure-deployment" "test-infrastructure.sh"
run_test "cicd-integration" "test-cicd.sh"
run_test "configuration-drift" "test-drift.sh"
run_test "rbac-security" "test-rbac.sh"
run_test "sync-performance" "test-performance.sh"
run_test "monitoring-validation" "test-monitoring.sh"

# Generate summary report
echo "Test Execution Summary:" > "$RESULTS_DIR/summary.txt"
echo "======================" >> "$RESULTS_DIR/summary.txt"
for result in $RESULTS_DIR/*.result; do
    test_name=$(basename $result .result)
    status=$(cat $result)
    echo "$test_name: $status" >> "$RESULTS_DIR/summary.txt"
done

echo "Test results saved to: $RESULTS_DIR"
cat "$RESULTS_DIR/summary.txt"
```

### Test Metrics Collection

- Sync time measurements
- Resource utilization tracking
- Error rate monitoring
- Recovery time objectives

### Success Criteria Definition

- **Functional**: All applications deploy and operate correctly
- **Performance**: Sync times within acceptable limits
- **Security**: RBAC properly enforced
- **Reliability**: System recovers from failures automatically
- **Observability**: Complete monitoring and alerting operational

---

## Test Report Template

### Executive Summary

- Total tests executed: X
- Passed: Y
- Failed: Z
- Overall success rate: (Y/X * 100)%

### Detailed Results

For each test case:

- Test objective
- Execution status
- Performance metrics
- Issues identified
- Recommendations

### Recommendations

- Performance optimizations
- Security enhancements
- Operational improvements
- Future testing considerations

This comprehensive test suite validates all aspects of the ArgoCD app-of-apps implementation, ensuring reliability, security, and performance meet production requirements.
