# Onboarding Guide

Welcome to the Iris ML API v4 project! This guide will help you get up and running.

## Prerequisites

Before starting, ensure you have the following installed:

| Tool | Version | Installation |
|------|---------|--------------|
| Docker | 24+ | [docker.com](https://www.docker.com/get-started) |
| Docker Compose | 2.20+ | Included with Docker Desktop |
| Java JDK | 17+ | [adoptium.net](https://adoptium.net/) |
| Python | 3.12+ | [python.org](https://www.python.org/downloads/) |
| Maven | 3.9+ | [maven.apache.org](https://maven.apache.org/download.cgi) |
| kubectl | 1.28+ | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| Terraform | 1.5+ | [terraform.io](https://www.terraform.io/downloads) |
| Azure CLI | 2.50+ | [docs.microsoft.com](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) |

## Quick Start (Local Development)

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd iris-azure-ml/v4
```

### 2. Train the Model

```bash
# Option A: Using Make
make train

# Option B: Manual
cd ml/training
pip install -r requirements.txt
python train.py
```

This creates `ml/models/model.pkl`.

### 3. Start Services

```bash
# Start all services with Docker Compose
make dev

# Or manually
docker-compose up -d --build
```

### 4. Verify Services

```bash
# Check health
make health-check

# Or manually
curl http://localhost:8080/health/live
curl http://localhost:5000/health/ready
```

### 5. Make a Prediction

```bash
make predict

# Or manually
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'
```

## Project Structure Overview

```
v4/
├── apps/                     # Application source code
│   ├── api-gateway/          # Java Spring Boot (port 8080)
│   │   ├── src/main/java/    # Java source files
│   │   ├── src/test/java/    # Unit tests
│   │   ├── Dockerfile        # Container build
│   │   └── pom.xml           # Maven dependencies
│   └── inference-service/    # Python FastAPI (port 5000)
│       ├── src/              # Python source files
│       ├── tests/            # Unit tests
│       ├── Dockerfile        # Container build
│       └── requirements.txt  # Python dependencies
├── infra/                    # Infrastructure as Code
│   ├── modules/              # Reusable Terraform modules
│   │   ├── aks/              # Azure Kubernetes Service
│   │   ├── acr/              # Container Registry
│   │   ├── storage/          # Blob Storage (models)
│   │   ├── keyvault/         # Secrets management
│   │   ├── networking/       # VNet, NSG
│   │   └── monitoring/       # Log Analytics, Alerts
│   └── environments/         # Environment configs
│       ├── dev/              # Development
│       └── prod/             # Production
├── k8s/                      # Kubernetes manifests
│   ├── base/                 # Base configurations
│   └── overlays/             # Environment patches
│       ├── dev/              # Dev overrides
│       └── prod/             # Prod overrides
├── .github/workflows/        # CI/CD Pipelines
├── ml/                       # ML Training
│   ├── training/             # Training scripts
│   └── models/               # Model artifacts
├── docs/                     # Documentation
├── docker-compose.yml        # Local development
└── Makefile                  # Common commands
```

## Development Workflows

### API Gateway Development (Java)

```bash
cd apps/api-gateway

# Run tests
mvn test

# Build JAR
mvn clean package -DskipTests

# Run locally (requires inference-service running)
mvn spring-boot:run
```

### Inference Service Development (Python)

```bash
cd apps/inference-service

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/ -v

# Run locally
MODEL_PATH=../../ml/models/model.pkl uvicorn src.app:app --reload --port 5000
```

### Kubernetes Development

```bash
# Validate manifests
make k8s-validate

# Show what would change
make k8s-diff

# Deploy to dev
make deploy-dev
```

### Terraform Development

```bash
cd infra/environments/dev

# Initialize
terraform init

# Format check
terraform fmt -check

# Plan
terraform plan -var="api_key=test123"

# Apply (with approval)
terraform apply -var="api_key=test123"
```

## Common Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make dev` | Start local development environment |
| `make test` | Run all tests |
| `make build` | Build all Docker images |
| `make lint` | Run linters |
| `make clean` | Clean build artifacts |
| `make deploy-dev` | Deploy to dev AKS |

## Environment Variables

### Local Development

Create a `.env` file in the `v4/` directory:

```bash
API_KEY=your-local-dev-key
```

### Kubernetes

Secrets are managed via:
- **Dev:** `k8s/overlays/dev/secrets.yaml`
- **Prod:** External Secrets Operator + Azure Key Vault

## Troubleshooting

### Docker Issues

```bash
# Reset everything
docker-compose down -v
docker-compose up -d --build

# View logs
docker-compose logs -f inference-service
docker-compose logs -f api-gateway
```

### Model Not Found

```bash
# Ensure model exists
ls -la ml/models/model.pkl

# If not, train it
make train
```

### Port Already in Use

```bash
# Check what's using the port
lsof -i :8080
lsof -i :5000

# Kill the process or change ports in docker-compose.yml
```

### Kubernetes Issues

```bash
# Check pod status
kubectl get pods -n iris-ml

# View pod logs
kubectl logs -f deployment/api-gateway -n iris-ml
kubectl logs -f deployment/inference-service -n iris-ml

# Describe pod for events
kubectl describe pod <pod-name> -n iris-ml
```

## Getting Help

- Check the [RUNBOOK.md](RUNBOOK.md) for operational procedures
- Review [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions
- Open an issue in the repository for bugs or questions
