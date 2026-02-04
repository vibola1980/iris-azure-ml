# ============================================
# Makefile - Iris ML API v4 (Enterprise Template)
# ============================================
#
# Usage:
#   make help          Show available commands
#   make dev           Start local development environment
#   make test          Run all tests
#   make build         Build all Docker images
#   make deploy-dev    Deploy to dev environment
#

.PHONY: help dev build test clean deploy-dev deploy-prod train lint docker-up docker-down

# Default target
.DEFAULT_GOAL := help

# Variables
DOCKER_COMPOSE = docker-compose
KUBECTL = kubectl
KUSTOMIZE = kustomize
ENV ?= dev

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RESET  := \033[0m

# ============================================
# Help
# ============================================

help: ## Show this help message
	@echo "$(CYAN)Iris ML API v4 - Enterprise Template$(RESET)"
	@echo ""
	@echo "$(YELLOW)Usage:$(RESET)"
	@echo "  make <target>"
	@echo ""
	@echo "$(YELLOW)Targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

# ============================================
# Local Development
# ============================================

dev: docker-up ## Start local development environment
	@echo "$(GREEN)Development environment started$(RESET)"
	@echo "  API Gateway:       http://localhost:8080"
	@echo "  Inference Service: http://localhost:5000"
	@echo "  Swagger UI:        http://localhost:5000/docs"

docker-up: ## Start Docker Compose services
	$(DOCKER_COMPOSE) up -d --build

docker-down: ## Stop Docker Compose services
	$(DOCKER_COMPOSE) down

docker-logs: ## View Docker Compose logs
	$(DOCKER_COMPOSE) logs -f

docker-ps: ## Show Docker Compose status
	$(DOCKER_COMPOSE) ps

# ============================================
# Build
# ============================================

build: build-api-gateway build-inference-service ## Build all Docker images

build-api-gateway: ## Build API Gateway image
	@echo "$(CYAN)Building API Gateway...$(RESET)"
	docker build -t iris/api-gateway:latest ./apps/api-gateway

build-inference-service: ## Build Inference Service image
	@echo "$(CYAN)Building Inference Service...$(RESET)"
	docker build -t iris/inference-service:latest ./apps/inference-service

# ============================================
# Test
# ============================================

test: test-api-gateway test-inference-service ## Run all tests

test-api-gateway: ## Run API Gateway tests
	@echo "$(CYAN)Testing API Gateway...$(RESET)"
	cd apps/api-gateway && mvn test

test-inference-service: ## Run Inference Service tests
	@echo "$(CYAN)Testing Inference Service...$(RESET)"
	cd apps/inference-service && pytest tests/ -v

# ============================================
# Lint
# ============================================

lint: lint-python lint-terraform ## Run all linters

lint-python: ## Lint Python code
	@echo "$(CYAN)Linting Python code...$(RESET)"
	cd apps/inference-service && ruff check src/ tests/

lint-terraform: ## Lint Terraform code
	@echo "$(CYAN)Linting Terraform code...$(RESET)"
	terraform fmt -check -recursive infra/

fmt: fmt-python fmt-terraform ## Format all code

fmt-python: ## Format Python code
	cd apps/inference-service && ruff format src/ tests/

fmt-terraform: ## Format Terraform code
	terraform fmt -recursive infra/

# ============================================
# ML Training
# ============================================

train: ## Train the ML model
	@echo "$(CYAN)Training model...$(RESET)"
	cd ml/training && python train.py
	@echo "$(GREEN)Model trained and saved to ml/models/model.pkl$(RESET)"

# ============================================
# Kubernetes / Deploy
# ============================================

k8s-validate: ## Validate Kubernetes manifests
	@echo "$(CYAN)Validating Kubernetes manifests...$(RESET)"
	$(KUSTOMIZE) build k8s/overlays/$(ENV) | $(KUBECTL) apply --dry-run=client -f -

k8s-diff: ## Show diff between local and cluster
	$(KUSTOMIZE) build k8s/overlays/$(ENV) | $(KUBECTL) diff -f -

deploy-dev: ## Deploy to dev environment
	@echo "$(CYAN)Deploying to dev...$(RESET)"
	$(KUSTOMIZE) build k8s/overlays/dev | $(KUBECTL) apply -f -
	$(KUBECTL) rollout status deployment/api-gateway -n iris-ml
	$(KUBECTL) rollout status deployment/inference-service -n iris-ml
	@echo "$(GREEN)Deployment complete$(RESET)"

deploy-prod: ## Deploy to prod environment (requires approval)
	@echo "$(YELLOW)Warning: Deploying to PRODUCTION$(RESET)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	@echo "$(CYAN)Deploying to prod...$(RESET)"
	$(KUSTOMIZE) build k8s/overlays/prod | $(KUBECTL) apply -f -
	$(KUBECTL) rollout status deployment/api-gateway -n iris-ml
	$(KUBECTL) rollout status deployment/inference-service -n iris-ml
	@echo "$(GREEN)Production deployment complete$(RESET)"

k8s-status: ## Show Kubernetes deployment status
	@echo "$(CYAN)Pods:$(RESET)"
	$(KUBECTL) get pods -n iris-ml
	@echo ""
	@echo "$(CYAN)Services:$(RESET)"
	$(KUBECTL) get svc -n iris-ml
	@echo ""
	@echo "$(CYAN)HPA:$(RESET)"
	$(KUBECTL) get hpa -n iris-ml

# ============================================
# Infrastructure
# ============================================

tf-init: ## Initialize Terraform
	cd infra/environments/$(ENV) && terraform init

tf-plan: ## Run Terraform plan
	cd infra/environments/$(ENV) && terraform plan

tf-apply: ## Apply Terraform changes
	cd infra/environments/$(ENV) && terraform apply

tf-destroy: ## Destroy Terraform resources
	@echo "$(YELLOW)Warning: This will destroy all resources$(RESET)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	cd infra/environments/$(ENV) && terraform destroy

# ============================================
# Utilities
# ============================================

clean: ## Clean build artifacts
	@echo "$(CYAN)Cleaning build artifacts...$(RESET)"
	rm -rf apps/api-gateway/target
	rm -rf apps/inference-service/__pycache__
	rm -rf apps/inference-service/.pytest_cache
	rm -rf apps/inference-service/htmlcov
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)Clean complete$(RESET)"

health-check: ## Check service health
	@echo "$(CYAN)Checking API Gateway health...$(RESET)"
	curl -s http://localhost:8080/health/live | jq .
	@echo ""
	@echo "$(CYAN)Checking Inference Service health...$(RESET)"
	curl -s http://localhost:5000/health/ready | jq .

predict: ## Make a sample prediction
	@echo "$(CYAN)Making sample prediction...$(RESET)"
	curl -s -X POST http://localhost:8080/predict \
		-H "Content-Type: application/json" \
		-d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' | jq .

# ============================================
# Setup
# ============================================

setup-dev: ## Setup local development environment
	@echo "$(CYAN)Setting up development environment...$(RESET)"
	@echo "Installing Python dependencies..."
	cd apps/inference-service && pip install -r requirements.txt
	@echo "Installing Java dependencies..."
	cd apps/api-gateway && mvn dependency:resolve
	@echo "Creating models directory..."
	mkdir -p ml/models
	@echo "$(GREEN)Setup complete$(RESET)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(RESET)"
	@echo "  1. Run 'make train' to train the model"
	@echo "  2. Run 'make dev' to start the services"
