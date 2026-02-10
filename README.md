# Iris Azure ML

Projeto de Machine Learning para classificacao de flores Iris, com multiplas implementacoes para deploy na Azure.

## Versoes

| Versao | Stack | Status | Descricao |
|--------|-------|--------|-----------|
| [v1](./v1/) | FastAPI + ACI + Terraform | ✅ Funcional | API Python com deploy via Azure Container Instances |
| [v2](./v2/) | FastAPI + Model Registry | ✅ Completo | API com abstracao de registry (local/azure/mlflow) |
| [v3](./v3/) | Spring Boot + Python | ✅ Completo | Microservicos Java + Python mantendo mesmo contrato de API |
| [v4](./v4/) | AKS + Terraform + GitOps | ✅ Completo | Template enterprise com AKS, Kustomize, ArgoCD e GitHub Actions |
| [v5](./v5/) | Databricks AutoML + AKS | 🚧 Em evolucao | v4 + Databricks AutoML, MLflow Registry e Init Container para modelo |

## Estrutura

```
iris-azure-ml/
├── v1/                 # FastAPI + ACI + Terraform (original)
│   ├── api/            # Codigo da API
│   ├── infra/          # Terraform para Azure
│   ├── training/       # Treinamento do modelo
│   └── scripts/        # Scripts utilitarios
├── v2/                 # FastAPI com Model Registry
├── v3/                 # Spring Boot + Python (microservicos)
├── v4/                 # AKS Enterprise Template
│   ├── apps/           # API Gateway (Java) + Inference Service (Python)
│   ├── infra/          # Terraform modular (AKS, ACR, Storage, KeyVault)
│   ├── k8s/            # Kustomize manifests + ArgoCD
│   ├── ml/             # Treinamento do modelo
│   └── .github/        # CI/CD workflows
└── v5/                 # Databricks AutoML + AKS
    ├── databricks/     # Notebooks + Jobs (AutoML training pipeline)
    ├── apps/           # API Gateway (Java) + Inference Service (Python)
    ├── infra/          # Terraform modular (+ Databricks workspace)
    ├── k8s/            # Kustomize manifests (+ Init Container)
    └── ml/             # Treinamento local (fallback)
```

## Pre-requisitos Gerais

- Azure CLI autenticado (`az login`)
- Docker instalado
- Python 3.11+ (para v1/v2/v4)
- Java 17+ (para v3/v4)
- Terraform >= 1.6.0 (para v1/v4)

## Quick Start

Escolha uma versao e siga o README especifico:

- **v1**: Deploy completo na Azure com ACI → [v1/README.md](./v1/README.md)
- **v2**: Desenvolvimento local com registry flexivel → [v2/iris-azure-ml/README.md](./v2/iris-azure-ml/README.md)
- **v3**: Microservicos Java + Python → [v3/iris-spring-boot/README.md](./v3/iris-spring-boot/README.md)
- **v4**: Enterprise AKS com GitOps → [v4/README.md](./v4/README.md)
- **v5**: Databricks AutoML + AKS → [v5/README.md](./v5/README.md)
