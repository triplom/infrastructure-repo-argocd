#!/bin/bash
set -e

# Create Kubernetes secrets for GitHub Container Registry authentication
for CLUSTER in dev-cluster qa-cluster prod-cluster; do
  echo "Configuring $CLUSTER to use GitHub Container Registry..."
  kubectl --context kind-$CLUSTER create namespace container-auth || true
  
  # Create secret for GitHub Container Registry
  kubectl --context kind-$CLUSTER create secret docker-registry github-registry-secret \
    --namespace=container-auth \
    --docker-server=ghcr.io \
    --docker-username=$GITHUB_USERNAME \
    --docker-password=$GITHUB_TOKEN \
    --docker-email=$GITHUB_EMAIL
    
  # Make the secret available to other namespaces
  kubectl --context kind-$CLUSTER create clusterrole registry-auth \
    --verb=use \
    --resource=secrets
   
  kubectl --context kind-$CLUSTER create clusterrolebinding serviceaccount-registry-auth \
    --clusterrole=registry-auth \
    --serviceaccount=container-auth:default
done