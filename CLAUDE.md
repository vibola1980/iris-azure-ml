# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Multi-phase ML inference API project for Iris flower classification, deploying to Azure with Kubernetes-native patterns.

**Versions:**
- **v1**: FastAPI + ACI + Terraform (original, production-ready)
- **v2**: FastAPI with Model Registry abstraction (local/azure/mlflow)
- **v3**: Spring Boot Java implementation (in progress)
- **v4**: Azure AKS Enterprise Template (Java + Python microservices, Terraform, Kustomize, GitHub Actions)

## Development Commands

### v1 - FastAPI + Azure (Original)

```bash
# Local development
cd v1
pip install -r requirements.txt
export MODEL_PATH=models/model.pkl API_KEY=test123
uvicorn api.app:app --reload

# Train model
cd v1/training
pip install -r requirements.txt
python train.py  # Outputs to artifacts/model.pkl

# Docker build
cd v1
docker build -t iris-api:1.0.0 .

# Infrastructure (Azure)
cd v1/infra
terraform init
terraform apply

# Upload model to Azure
cd v1/scripts
./upload_model_to_fileshare.ps1 -KeyVaultName <kv> -StorageAccountName <sa> -FileShareName mlshare
```

### v2 - FastAPI with Model Registry

```bash
cd v2/iris-azure-ml
pip install -r api/requirements.txt
export MODEL_PATH=models/model.pkl MODEL_VERSION=1.0.0 API_KEY=test123
uvicorn api.app:app --reload

# Run tests
python -m pytest tests/

# Docker
docker-compose up
```

### v3 - Spring Boot + Python Inference

```bash
cd v3/iris-spring-boot

# Docker Compose (recommended)
docker-compose up -d
docker-compose ps
docker-compose logs -f

# Train model locally
python train_model.py

# Run Java tests
mvn test

# Manual development
# Terminal 1: Python inference service
cd inference-service && pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 5000

# Terminal 2: Java API
mvn spring-boot:run
```

### v4 - Azure AKS Enterprise Template

```bash
cd v4

# Local development (Docker Compose)
make train           # Train model
make dev             # Start all services
make health-check    # Verify services
make predict         # Test prediction

# Run tests
make test

# Infrastructure (Terraform)
cd infra/environments/dev
terraform init
terraform plan -var="api_key=your-key"
terraform apply -var="api_key=your-key"

# Deploy to Kubernetes
make deploy-dev      # Deploy to dev AKS
make k8s-status      # Check deployment status

# Build Docker images
make build
```

## Architecture

### v1 Architecture (Azure)

```
Azure Infrastructure (Terraform)
├── Container Registry (ACR) ← Docker images
├── Container Instances (ACI) ← Runs FastAPI
├── Storage Account + File Share ← model.pkl
└── Key Vault ← Secrets (API_KEY, storage-key)
```

### v2 Architecture (Kubernetes-native)

```
FastAPI Application
├── Health Probes
│   ├── /health/live   → livenessProbe
│   └── /health/ready  → readinessProbe
├── Model Registry Abstraction
│   ├── LocalFileSystem (dev)
│   ├── AzureBlobStorage (prod)
│   └── MLflow (enterprise)
└── POST /predict → Classification
```

### v3 Architecture (Microservices)

```
Java API (Spring Boot 3.2.1, port 8080)
├── /health/live, /health/ready, /predict
├── Calls Python service via HTTP
└── Metrics via Prometheus/Actuator

Python Inference Service (FastAPI, port 5000)
├── /health/*, /predict
├── Loads model.pkl via joblib
└── Returns predictions to Java API
```

### v4 Architecture (Azure AKS Enterprise)

```
Azure AKS Cluster
├── API Gateway (Java Spring Boot, port 8080)
│   ├── REST API, authentication, routing
│   └── Calls Inference Service via K8s Service
├── Inference Service (Python FastAPI, port 5000)
│   ├── Init Container downloads model from Blob Storage
│   └── ML inference with scikit-learn
├── Azure Blob Storage (model artifacts)
├── Azure Key Vault (secrets via External Secrets Operator)
└── Azure Monitor (logs, metrics, alerts)

Infrastructure (Terraform modules):
├── aks/        - Kubernetes cluster
├── acr/        - Container registry
├── storage/    - Blob storage for models
├── keyvault/   - Secrets management
├── networking/ - VNet, NSG
└── monitoring/ - Log Analytics, App Insights
```

## Key Entry Points

| Component | Path |
|-----------|------|
| v1 API | `v1/api/app.py` |
| v1 Terraform | `v1/infra/main.tf` |
| v1 Training | `v1/training/train.py` |
| v2 API | `v2/iris-azure-ml/api/app.py` |
| v2 Model Registry | `v2/iris-azure-ml/api/model_registry.py` |
| v3 Java API | `v3/iris-spring-boot/src/main/java/com/iris/` |
| v3 Python Service | `v3/iris-spring-boot/inference-service/app.py` |
| v3 Docker Compose | `v3/iris-spring-boot/docker-compose.yml` |
| v4 API Gateway | `v4/apps/api-gateway/src/main/java/com/iris/` |
| v4 Inference Service | `v4/apps/inference-service/src/app.py` |
| v4 Terraform | `v4/infra/environments/{dev,prod}/main.tf` |
| v4 K8s Manifests | `v4/k8s/base/` and `v4/k8s/overlays/` |
| v4 CI/CD | `v4/.github/workflows/` |
| v4 Docker Compose | `v4/docker-compose.yml` |

## API Endpoints (all versions)

```
GET  /health      → Health check
POST /predict     → Classification (requires X-API-Key header)
GET  /docs        → Swagger UI (FastAPI only)
```

## Environment Variables

```bash
MODEL_PATH=./models/model.pkl   # Path to trained model
API_KEY=your-secret-key         # API authentication
MODEL_VERSION=1.0.0             # Version tracking (v2)
MODEL_REGISTRY_TYPE=local       # Registry backend (v2): local|azure|mlflow
```

## Important Notes

- Model files (.pkl) are gitignored - train locally or download from Azure
- Documentation is in Portuguese (pt-BR)
- v1 has Terraform state files - be careful when running terraform commands
- v3 test scenarios in `v3/iris-spring-boot/docs/TESTING.md`
- v3 troubleshooting in `v3/iris-spring-boot/docs/TROUBLESHOOTING.md`
- v2 test scenarios in `v2/iris-azure-ml/TEST_PLAN.md`
- v4 architecture decisions in `v4/docs/ARCHITECTURE.md`
- v4 onboarding guide in `v4/docs/ONBOARDING.md`
- v4 operations runbook in `v4/docs/RUNBOOK.md`
