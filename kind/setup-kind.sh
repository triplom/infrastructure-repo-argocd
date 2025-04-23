#!/usr/bin/env bash

# setup-kind.sh - Script to set up KIND clusters for development, qa, and production

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# Default configuration
ENVIRONMENTS=("dev" "qa" "prod")
FORCE_RECREATE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_ENV=""

# Display help information
show_help() {
  cat << EOF
Usage: $0 [options] [environment]

Options:
  -h, --help            Show this help message
  -f, --force           Force recreation of clusters if they exist
  
Environment:
  dev, qa, prod         Specify a single environment to create
                        (default: all environments)

Examples:
  $0                    Create all clusters (dev, qa, prod)
  $0 dev                Create only dev cluster
  $0 --force prod       Force recreation of prod cluster
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -f|--force)
      FORCE_RECREATE=true
      shift
      ;;
    dev|qa|prod)
      TARGET_ENV="$1"
      shift
      ;;
    *)
      echo "Error: Unknown option $1"
      show_help
      exit 1
      ;;
  esac
done

# Set log colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# Check if we are root - we shouldn't run as root
check_not_root() {
  if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
  fi
}

# Detect OS for platform-specific commands
detect_os() {
  case "$(uname -s)" in
    Linux*)     OS="Linux" ;;
    Darwin*)    OS="Mac" ;;
    CYGWIN*)    OS="Cygwin" ;;
    MINGW*)     OS="MinGw" ;;
    MSYS*)      OS="Msys" ;;
    *)          OS="Unknown" ;;
  esac
  log "Detected OS: $OS"
}

# Check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Install required tools
install_prerequisites() {
  log "Checking and installing prerequisites..."

  # Docker
  if ! command_exists docker; then
    log "Installing Docker..."
    if [[ "$OS" == "Linux" ]]; then
      sudo apt-get update
      sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || error "Failed to add Docker GPG key"
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || error "Failed to add Docker repository"
      sudo apt-get update
      sudo apt-get install -y docker-ce || error "Failed to install Docker"
      sudo usermod -aG docker "$USER"
      warn "Docker installed. You may need to log out and back in for group changes to take effect."
      warn "If you continue without logging out, you might need to use 'sudo' with docker commands."
    else
      error "Please install Docker for your platform and try again: https://docs.docker.com/get-docker/"
    fi
  fi

  # kubectl
  if ! command_exists kubectl; then
    log "Installing kubectl..."
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    log "Using kubectl version $KUBECTL_VERSION"
    curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl" || error "Failed to download kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/ || error "Failed to install kubectl"
  fi

  # KIND
  if ! command_exists kind; then
    log "Installing KIND..."
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64" || error "Failed to download KIND"
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/ || error "Failed to install KIND"
  fi

  # Helm
  if ! command_exists helm; then
    log "Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 || error "Failed to download Helm installation script"
    chmod 700 get_helm.sh
    ./get_helm.sh || error "Failed to install Helm"
    rm get_helm.sh
  fi

  success "All prerequisites installed successfully."
}

# Check if a KIND cluster exists
cluster_exists() {
  kind get clusters | grep -q "^$1$"
}

# Create a KIND cluster
create_cluster() {
  local env="$1"
  local cluster_name="${env}-cluster"
  local config_file="${SCRIPT_DIR}/clusters/${env}-cluster-config.yaml"

  # Check if the cluster already exists
  if cluster_exists "$cluster_name"; then
    if [[ "$FORCE_RECREATE" == "true" ]]; then
      log "Deleting existing $cluster_name cluster..."
      kind delete cluster --name "$cluster_name" || error "Failed to delete cluster $cluster_name"
    else
      warn "Cluster $cluster_name already exists. Skipping creation. Use --force to recreate."
      return 0
    fi
  fi

  # Check if configuration file exists
  if [[ ! -f "$config_file" ]]; then
    error "Cluster config file not found: $config_file"
  fi

  # Create the cluster
  log "Creating $cluster_name cluster..."
  if ! kind create cluster --config "$config_file" --wait 5m; then
    error "Failed to create $cluster_name cluster"
  fi
  
  # Generate kubeconfig file
  log "Generating kubeconfig for $cluster_name..."
  kind get kubeconfig --name "$cluster_name" > "${PARENT_DIR}/${env}-cluster-kubeconfig" || error "Failed to generate kubeconfig"
  
  # Generate base64 encoded kubeconfig
  log "Generating base64-encoded kubeconfig..."
  if [[ "$OS" == "Mac" ]]; then
    base64 -i "${PARENT_DIR}/${env}-cluster-kubeconfig" -o "${PARENT_DIR}/${env}-cluster-kubeconfig-base64.txt" || error "Failed to generate base64 kubeconfig"
  else
    base64 -w 0 "${PARENT_DIR}/${env}-cluster-kubeconfig" > "${PARENT_DIR}/${env}-cluster-kubeconfig-base64.txt" || error "Failed to generate base64 kubeconfig"
  fi
  
  # Set permissions for kubeconfig files
  chmod 600 "${PARENT_DIR}/${env}-cluster-kubeconfig" "${PARENT_DIR}/${env}-cluster-kubeconfig-base64.txt"

  # Verify cluster is working
  log "Verifying $cluster_name cluster is operational..."
  kubectl --context="kind-$cluster_name" cluster-info || error "Failed to connect to cluster $cluster_name"
  
  success "Cluster $cluster_name created and verified successfully."
}

# Main execution
main() {
  check_not_root
  detect_os
  install_prerequisites

  # Determine which environments to create
  local envs_to_create=()
  if [[ -n "$TARGET_ENV" ]]; then
    envs_to_create=("$TARGET_ENV")
  else
    envs_to_create=("${ENVIRONMENTS[@]}")
  fi
  
  log "Setting up KIND clusters for: ${envs_to_create[*]}"

  # Create each cluster
  for env in "${envs_to_create[@]}"; do
    create_cluster "$env"
  done
  
  # Switch to dev cluster by default
  if [[ ${#envs_to_create[@]} -gt 0 ]] && (cluster_exists "dev-cluster" || [[ "${envs_to_create[0]}" == "dev" ]]); then
    log "Switching to dev-cluster context..."
    kubectl config use-context kind-dev-cluster
  fi
  
  success "KIND cluster setup complete!"
  log "Kubeconfig files are available at:"
  for env in "${envs_to_create[@]}"; do
    echo "  - ${env}-cluster-kubeconfig"
  done
  log "Base64 encoded kubeconfig files for GitHub Actions are available at:"
  for env in "${envs_to_create[@]}"; do
    echo "  - ${env}-cluster-kubeconfig-base64.txt"
  done
}

# Run the script
main "$@"