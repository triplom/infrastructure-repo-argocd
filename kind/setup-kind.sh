#!/bin/bash

set -e

echo "Installing KIND and required tools..."
# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
fi

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Install KIND if not present
if ! command -v kind &> /dev/null; then
    echo "Installing KIND..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/
fi

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Creating KIND clusters from configuration..."
# Create KIND clusters from config files
for env in dev qa prod; do
    kind create cluster --config "${SCRIPT_DIR}/clusters/${env}-cluster-config.yaml"
    
    # Generate kubeconfig file for each cluster
    kind get kubeconfig --name ${env}-cluster > ${env}-cluster-kubeconfig
    
    # Generate base64 encoded kubeconfig for GitHub Actions
    base64 -w 0 ${env}-cluster-kubeconfig > ${env}-cluster-kubeconfig-base64.txt
done

echo "Switching to dev cluster context..."
kubectl config use-context kind-dev-cluster

echo "KIND clusters created successfully!"
echo "Kubeconfig files are available at:"
echo "  - dev-cluster-kubeconfig"
echo "  - qa-cluster-kubeconfig"
echo "  - prod-cluster-kubeconfig"
echo "Base64 encoded kubeconfig files for GitHub Actions are available at:"
echo "  - dev-cluster-kubeconfig-base64.txt"
echo "  - qa-cluster-kubeconfig-base64.txt"
echo "  - prod-cluster-kubeconfig-base64.txt"