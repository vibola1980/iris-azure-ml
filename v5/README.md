# Iris ML API v5 - Databricks AutoML + AKS

Enterprise ML inference API with automated model training via Databricks AutoML.

## Overview

Evolution of v4 adding Databricks AutoML for automated model training, MLflow model registry, and model export to Azure Blob Storage. The AKS inference stack is inherited from v4 with an init container for dynamic model loading.

- **Databricks AutoML** - Automated model training and selection
- **MLflow Registry** - Model versioning and tracking
- **API Gateway** (Java/Spring Boot) - REST API, authentication, request routing
- **Inference Service** (Python/FastAPI) - ML model loading and predictions
- **Infrastructure as Code** (Terraform) - Azure infra + Databricks workspace
- **GitOps Ready** (Kustomize) - Environment-specific Kubernetes configurations

## Architecture

```
Databricks Workspace
├── Delta Table (Iris dataset)
├── AutoML (trains N models, picks best)
├── MLflow Registry (model versioning)
└── Job → Exports pkl → Azure Blob Storage
                              │
                              ▼
                        Azure Blob Storage
                        (models/iris-classifier/v{N}/model.pkl)
                              │
                              ▼
                        AKS Cluster
                        ├── Init Container (downloads pkl from Blob)
                        ├── Inference Service (FastAPI - loads pkl)
                        └── API Gateway (Spring Boot - routes requests)
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Java 17+ (for local API Gateway development)
- Python 3.12+ (for local Inference Service development)
- kubectl & kustomize (for Kubernetes deployment)
- Terraform 1.5+ (for infrastructure provisioning)
- Azure CLI (for Azure operations)
- Databricks CLI (for notebook/job management)

### Local Development

```bash
cd v5

# 1. Train model locally (fallback without Databricks)
make train

# 2. Start all services
make dev

# 3. Test the API
make health-check
make predict
```

### Databricks Training

```bash
# 1. Provision infrastructure (includes Databricks workspace)
make tf-init
make tf-apply

# 2. Upload notebooks to Databricks
make databricks-upload-notebooks

# 3. Create and run training job
make databricks-create-job
make databricks-run-job
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
v5/
├── apps/
│   ├── api-gateway/              # Java Spring Boot API Gateway
│   └── inference-service/        # Python FastAPI Inference Service
│       └── scripts/              # Init container scripts
├── databricks/                   # Databricks AutoML (NEW in v5)
│   ├── notebooks/                # Training pipeline notebooks
│   │   ├── 01_data_ingestion.py
│   │   ├── 02_automl_training.py
│   │   └── 03_model_export.py
│   └── jobs/                     # Job definitions
├── infra/                        # Terraform Infrastructure
│   ├── modules/
│   │   ├── databricks/           # Databricks module (NEW in v5)
│   │   ├── aks/
│   │   ├── acr/
│   │   ├── storage/
│   │   ├── keyvault/
│   │   ├── networking/
│   │   └── monitoring/
│   └── environments/             # Dev/Prod configurations
├── k8s/                          # Kubernetes manifests (Kustomize)
│   ├── base/                     # Base (includes init container)
│   └── overlays/                 # Environment-specific patches
├── ml/                           # Local ML Training (fallback)
├── docs/                         # Documentation
├── docker-compose.yml            # Local development
└── Makefile                      # Common commands
```

## What's New in v5 (vs v4)

| Feature | v4 | v5 |
|---------|----|----|
| Model Training | Manual `train.py` | Databricks AutoML |
| Model Registry | - | MLflow (Databricks) |
| Model Delivery | Baked into Docker image | Init Container from Blob |
| Infrastructure | AKS + ACR + Storage + KV | + Databricks Workspace |
| Model Update | Rebuild Docker image | Update ConfigMap + rollout restart |

## Deployment

### Infrastructure (Terraform)

```bash
cd infra/environments/dev
terraform init
terraform plan -var="api_key=your-api-key"
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
| `STORAGE_ACCOUNT` | Azure Storage account name | (from Terraform) |
| `MODEL_BLOB_NAME` | Blob path for model | `iris-classifier/v1.0.0/model.pkl` |
| `AUTOML_RUN_ID` | Databricks AutoML run ID | (from training job) |
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
- [Databricks Training](databricks/README.md)
- [Runbook](docs/RUNBOOK.md)

## License

Internal use only - Corporate template for ML deployments.
