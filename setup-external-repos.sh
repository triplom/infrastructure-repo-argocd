#!/bin/bash

echo "Setting up external repository access for ArgoCD..."

# Create repository secret for infrastructure-repo (push-based)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: infrastructure-repo-external
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/triplom/infrastructure-repo.git
  username: triplom
  password: ${GITHUB_TOKEN}
  insecure: "false"
  enableLfs: "false"
EOF

# Create repository secret for k8s-web-app-php
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: k8s-web-app-php-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/triplom/k8s-web-app-php.git
  username: triplom
  password: ${GITHUB_TOKEN}
  insecure: "false"
  enableLfs: "false"
EOF

echo "External repository secrets created successfully!"
echo "Don't forget to set the GITHUB_TOKEN environment variable before running this script."
