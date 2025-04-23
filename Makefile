.PHONY: setup-dev deploy-dev setup-registry validate-manifests

# Setup development environment
setup-dev:
	./kind/setup-kind.sh dev

# Setup local registry
setup-registry:
	./infrastructure/local-registry/setup-registry.sh

# Deploy app to development
deploy-dev:
	kubectl apply --validate=false -k apps/app1/overlays/dev

# Validate Kubernetes manifests (requires kubeconform)
validate-manifests:
	find ./apps -name "*.yaml" -not -path "*/kustomization.yaml" | xargs kubeconform -kubernetes-version 1.25.0

# Run tests
test-app:
	cd src/app1 && python -m pytest
