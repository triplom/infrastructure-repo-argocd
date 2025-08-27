#!/bin/bash
set -e

# First set the Variables as environment variables 
<<<<<<< HEAD
# export GITHUB_USERNAME="your-username"
# export GITHUB_TOKEN="your-token"
# export GITHUB_EMAIL="your-email"
=======
 export GITHUB_USERNAME="triplom"
 export GITHUB_TOKEN="${GITHUB_TOKEN:-your-github-token-here}"
 export GITHUB_EMAIL="triplom@gmail.com"
>>>>>>> 9d78202 (fix)

# Check if required environment variables are set
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_EMAIL" ]; then
  echo "Error: Required environment variables not set."
  echo "Please set GITHUB_USERNAME, GITHUB_TOKEN and GITHUB_EMAIL before running this script."
  exit 1
fi

# Create Kubernetes secrets for GitHub Container Registry authentication
for CLUSTER in dev-cluster qa-cluster prod-cluster; do
  echo "Configuring $CLUSTER to use GitHub Container Registry..."
  
  # Create namespace if it doesn't exist
  kubectl --context kind-$CLUSTER create namespace container-auth || true
<<<<<<< HEAD
  
  # Delete existing secret if it exists
  kubectl --context kind-$CLUSTER delete secret github-registry-secret --namespace=container-auth 2>/dev/null || true
  
  # Create secret for GitHub Container Registry
  kubectl --context kind-$CLUSTER create secret docker-registry github-registry-secret \
=======

  # Create the secret for GitHub Container Registry
  kubectl --context kind-$CLUSTER create secret docker-registry github-registry \
>>>>>>> 9d78202 (fix)
    --namespace=container-auth \
    --docker-server=ghcr.io \
    --docker-username=$GITHUB_USERNAME \
    --docker-password=$GITHUB_TOKEN \
<<<<<<< HEAD
    --docker-email=$GITHUB_EMAIL
    
  # Make the secret available to other namespaces
  # Use apply instead of create to handle existing resources
  kubectl --context kind-$CLUSTER apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: registry-auth
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["use"]
EOF

  kubectl --context kind-$CLUSTER apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: serviceaccount-registry-auth
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: registry-auth
subjects:
- kind: ServiceAccount
  name: default
  namespace: container-auth
EOF

  echo "GitHub Container Registry configured successfully for $CLUSTER"
done

echo "GitHub Container Registry setup complete!"
=======
    --docker-email=$GITHUB_EMAIL || true

  # Add the secret to the default service account
  kubectl --context kind-$CLUSTER patch serviceaccount default \
    --namespace=container-auth \
    -p '{"imagePullSecrets": [{"name": "github-registry"}]}' || true
    
  # Create secret in all application namespaces
  for NAMESPACE in app1-dev app1-qa app1-prod app2-dev app2-qa app2-prod; do
    echo "Setting up GitHub Container Registry auth for $NAMESPACE in $CLUSTER..."
    
    # Create namespace if it doesn't exist
    kubectl --context kind-$CLUSTER create namespace $NAMESPACE || true
    
    # Create the secret in the application namespace
    kubectl --context kind-$CLUSTER create secret docker-registry github-registry \
      --namespace=$NAMESPACE \
      --docker-server=ghcr.io \
      --docker-username=$GITHUB_USERNAME \
      --docker-password=$GITHUB_TOKEN \
      --docker-email=$GITHUB_EMAIL || true

    # Patch the default service account to use the pull secret
    kubectl --context kind-$CLUSTER patch serviceaccount default \
      --namespace=$NAMESPACE \
      -p '{"imagePullSecrets": [{"name": "github-registry"}]}' || true
  done
done

echo "GitHub Container Registry authentication setup complete for all clusters!"
echo ""
echo "To use this in your deployment manifests, add:"
echo "  spec:"
echo "    imagePullSecrets:"
echo "    - name: github-registry"
echo ""
echo "Or the service account will automatically use it for deployments."
>>>>>>> 9d78202 (fix)
