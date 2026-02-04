# Iris ML API v4 - Azure AKS Enterprise Template

Enterprise-ready ML inference API for Iris flower classification, designed as a corporate template for Azure AKS deployments.

## Overview

This project provides a production-ready architecture for deploying ML models on Azure Kubernetes Service (AKS), featuring:

- **API Gateway** (Java/Spring Boot) - REST API, authentication, request routing
- **Inference Service** (Python/FastAPI) - ML model loading and predictions
- **Infrastructure as Code** (Terraform) - Complete Azure infrastructure
- **GitOps Ready** (Kustomize) - Environment-specific Kubernetes configurations
- **CI/CD Pipelines** (GitHub Actions) - Automated build, test, and deploy

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐     ┌─────────────────────────────────┐   │
│  │  Azure Blob     │     │         AKS Cluster              │   │
│  │  Storage        │     │  ┌───────────┐  ┌────────────┐  │   │
│  │  ────────────   │     │  │API Gateway│─▶│ Inference  │  │   │
│  │  models/        │◀────│  │  (Java)   │  │  (Python)  │  │   │
│  │  ├─ v1.0.0/     │     │  └───────────┘  └────────────┘  │   │
│  │  └─ v2.0.0/     │     │        ▲              ▲         │   │
│  └─────────────────┘     │        │              │         │   │
│                          │   Init Container downloads       │   │
│  ┌─────────────────┐     │   model from Blob on startup    │   │
│  │  Azure Key      │────▶│                                  │   │
│  │  Vault          │     └─────────────────────────────────┘   │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Java 17+ (for local API Gateway development)
- Python 3.12+ (for local Inference Service development)
- kubectl & kustomize (for Kubernetes deployment)
- Terraform 1.5+ (for infrastructure provisioning)
- Azure CLI (for Azure operations)

### Local Development

```bash
# 1. Clone the repository
cd v4

# 2. Train the model
make train

# 3. Start all services
make dev

# 4. Test the API
make health-check
make predict
```

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health/live` | GET | Liveness probe |
| `/health/ready` | GET | Readiness probe |
| `/predict` | POST | Classify iris measurements |
| `/docs` | GET | Swagger UI (Inference Service) |

### Sample Prediction

```bash
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

Response:
```json
{
  "predicted_class_id": 0,
  "predicted_class_name": "setosa",
  "probabilities": [0.97, 0.02, 0.01],
  "model_version": "1.0.0",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## Project Structure

```
v4/
├── apps/
│   ├── api-gateway/          # Java Spring Boot API Gateway
│   └── inference-service/    # Python FastAPI Inference Service
├── infra/                    # Terraform Infrastructure
│   ├── modules/              # Reusable Terraform modules
│   └── environments/         # Dev/Prod configurations
├── k8s/                      # Kubernetes manifests (Kustomize)
│   ├── base/                 # Base configurations
│   └── overlays/             # Environment-specific patches
├── .github/workflows/        # CI/CD Pipelines
├── ml/                       # ML Training scripts
├── docs/                     # Documentation
├── docker-compose.yml        # Local development
└── Makefile                  # Common commands
```

## Deployment

### Infrastructure (Terraform)

```bash
# Initialize Terraform
cd infra/environments/dev
terraform init

# Plan changes
terraform plan -var="api_key=your-api-key"

# Apply changes
terraform apply -var="api_key=your-api-key"
```

### Application (Kubernetes)

```bash
# Deploy to dev
make deploy-dev

# Deploy to prod (with confirmation)
make deploy-prod

# Check status
make k8s-status
```

### CI/CD Pipelines

- **CI - API Gateway**: Builds, tests, and pushes Docker image on changes to `apps/api-gateway/`
- **CI - Inference Service**: Builds, tests, and pushes Docker image on changes to `apps/inference-service/`
- **CD - Deploy**: Deploys to AKS (triggered manually or after CI completion)
- **Infrastructure - Terraform**: Plans and applies infrastructure changes

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `INFERENCE_SERVICE_URL` | URL of the inference service | `http://localhost:5000` |
| `MODEL_PATH` | Path to the model file | `models/model.pkl` |
| `MODEL_VERSION` | Model version string | `1.0.0` |
| `API_KEY` | Optional API key for authentication | (empty) |

### GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal credentials (JSON) |
| `ACR_LOGIN_SERVER` | Azure Container Registry login server |
| `ACR_USERNAME` | ACR username |
| `ACR_PASSWORD` | ACR password |
| `API_KEY` | API key for the application |

## Zero Downtime Guarantees

| Scenario | Mechanism | Result |
|---------|-----------|--------|
| Code deployment | `maxSurge: 1, maxUnavailable: 0` | Zero downtime |
| Model update | Rolling restart + Init Container | Zero downtime |
| Pod failure | Kubernetes auto-heal + PDB | ~seconds recovery |
| Scaling | HPA (CPU 70%, Memory 80%) | Automatic |

## Documentation

- [Architecture Decisions](docs/ARCHITECTURE.md)
- [Onboarding Guide](docs/ONBOARDING.md)
- [Runbook](docs/RUNBOOK.md)

## License

Internal use only - Corporate template for ML deployments.
