#!/bin/bash
set -e

# First set the Variables as environment variables 
export GITHUB_USERNAME="triplom"
export GITHUB_TOKEN="${GITHUB_TOKEN:-your-github-token-here}"
export GITHUB_EMAIL="triplom@gmail.com"

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

  # Create the secret for GitHub Container Registry
  kubectl --context kind-$CLUSTER create secret docker-registry github-registry \
    --namespace=container-auth \
    --docker-server=ghcr.io \
    --docker-username=$GITHUB_USERNAME \
    --docker-password=$GITHUB_TOKEN \
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
