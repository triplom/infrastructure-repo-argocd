#!/usr/bin/env bash

set -euo pipefail

RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner-infra}"
REPO_URL="${REPO_URL:-https://github.com/triplom/infrastructure-repo-argocd}"
RUNNER_VERSION="${RUNNER_VERSION:-2.325.0}"

if [[ -z "${RUNNER_TOKEN:-}" ]]; then
  echo "RUNNER_TOKEN is required"
  echo "Generate it in: GitHub repo -> Settings -> Actions -> Runners -> New self-hosted runner"
  exit 1
fi

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

ARCHIVE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${ARCHIVE}"

if [[ ! -f ./config.sh ]]; then
  curl -L -o "$ARCHIVE" "$URL"
  tar xzf "$ARCHIVE"
fi

./config.sh \
  --url "$REPO_URL" \
  --token "$RUNNER_TOKEN" \
  --name "triplom-linux" \
  --labels "self-hosted,linux,x64,triplom-linux,homelab" \
  --work "_work" \
  --replace \
  --unattended

echo
echo "Runner configured in $RUNNER_DIR"
echo "To install as a service:"
echo "  cd $RUNNER_DIR && sudo ./svc.sh install && sudo ./svc.sh start"
echo "Or run interactively:"
echo "  cd $RUNNER_DIR && ./run.sh"
