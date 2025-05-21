# File: Makefile

# Variables
SHELL := /bin/bash
CLUSTERS := dev-cluster qa-cluster prod-cluster

# Help target
.PHONY: help
help:
	@echo "GitOps Infrastructure Management"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  setup-clusters      Create KIND clusters for all environments"
	@echo "  setup-argocd        Install ArgoCD on current cluster"
	@echo "  bootstrap-argocd    Bootstrap ArgoCD with root application"
	@echo "  get-argocd-password Get the ArgoCD admin password"
	@echo "  port-forward-argocd Port forward ArgoCD UI to localhost:8080"
	@echo "  build-app           Build and push app1 Docker image"
	@echo "  github-setup	     Setup GitHub Container Registry access"
	@echo "  clean-clusters      Delete all KIND clusters"
	@echo "  setup-monitoring    Setup monitoring stack on current cluster"

# Setup all clusters
.PHONY: setup-clusters
setup-clusters:
	@echo "Creating KIND clusters..."
	@chmod +x kind/setup-kind.sh
	@./kind/setup-kind.sh

# ArgoCD setup
.PHONY: setup-argocd
setup-argocd:
	@echo "Installing ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -k infrastructure/argocd/base
	@echo "ArgoCD installed successfully!"

# Bootstrap ArgoCD with root application
.PHONY: bootstrap-argocd
bootstrap-argocd:
	@echo "Bootstrapping ArgoCD with root application..."
	kubectl apply -f infrastructure/argocd/applications/root.yaml
	@echo "Bootstrapping complete! Check ArgoCD UI for progress."

# Get ArgoCD admin password
.PHONY: get-argocd-password
get-argocd-password:
	@echo "ArgoCD initial admin password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

# Port forward ArgoCD UI
.PHONY: port-forward-argocd
port-forward-argocd:
	@echo "Port forwarding ArgoCD server to http://localhost:8080"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

# Build and push app1
.PHONY: build-app
build-app:
	@echo "Building and pushing app1 Docker image..."
	cd src/app1 && \
	docker build -t ghcr.io/triplom/app1:latest . && \
	docker push ghcr.io/triplom/app1:latest
	@echo "Image built and pushed successfully!"

# Setup GitHub Container Registry
.PHONY: github-setup
setup-registry:
	@if [ -z "$$GITHUB_PAT" ]; then \
		echo "Error: GITHUB_PAT environment variable not set"; \
		echo "Usage: GITHUB_PAT=<your_token> make setup-registry"; \
		exit 1; \
	fi
	@echo "Setting up GitHub Container Registry..."
	@chmod +x infrastructure/github-registry/setup-registry.sh
	@./infrastructure/github-registry/setup-registry.sh
	@echo "Registry setup complete!"

# Clean all clusters
.PHONY: clean-clusters
clean-clusters:
	@echo "Deleting KIND clusters..."
	@for cluster in $(CLUSTERS); do \
		echo "Deleting $$cluster..."; \
		kind delete cluster --name $$cluster; \
	done
	@echo "All clusters deleted."

# Setup monitoring
.PHONY: setup-monitoring
setup-monitoring:
	@echo "Setting up monitoring stack..."
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -k infrastructure/monitoring/overlays/dev
	@echo "Monitoring stack installed!"

# Setup ingress
.PHONY: setup-ingress
setup-ingress:
	@echo "Setting up ingress controller..."
	kubectl apply -k infrastructure/ingress-nginx/overlays/dev
	@echo "Ingress controller installed!"

# Setup cert-manager
.PHONY: setup-cert-manager
setup-cert-manager:
	@echo "Setting up cert-manager..."
	kubectl apply -k infrastructure/cert-manager/overlays/dev
	@echo "Cert-manager installed!"

# Setup all infrastructure on current cluster
.PHONY: setup-infra
setup-infra: setup-ingress setup-cert-manager setup-monitoring setup-argocd
	@echo "All infrastructure components installed!"

# Port forward Grafana
.PHONY: port-forward-grafana
port-forward-grafana:
	@echo "Port forwarding Grafana to http://localhost:3000"
	kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# Port forward application for testing
.PHONY: port-forward-app
port-forward-app:
	@echo "Port forwarding app1 to http://localhost:8081"
	kubectl port-forward svc/app1 -n app1-dev 8081:80

# Update application image
.PHONY: update-image
update-image:
	@if [ -z "$$VERSION" ]; then \
		echo "Error: VERSION environment variable not set"; \
		echo "Usage: VERSION=v1.0.0 make update-image"; \
		exit 1; \
	fi
	@echo "Updating app1 image to version $(VERSION)..."
	cd src/app1 && \
	docker build -t ghcr.io/triplom-argocd/app1:$(VERSION) . && \
	docker push ghcr.io/triplom/app1:$(VERSION) && \
	cd ../.. && \
	./update-image.sh app1 $(VERSION)
	@echo "Image updated and configuration committed!"